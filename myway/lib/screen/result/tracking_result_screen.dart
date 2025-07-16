import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../const/colors.dart';
import '../../provider/map_provider.dart';

class TrackingResultScreen extends StatefulWidget {
  final StepModel result;
  final Uint8List courseImage;
  final String courseName;

  const TrackingResultScreen({
    super.key,
    required this.result,
    required this.courseName,
    required this.courseImage,
  });

  @override
  State<TrackingResultScreen> createState() => _TrackingResultScreenState();
}

class _TrackingResultScreenState extends State<TrackingResultScreen> {
  final repaintBoundary = GlobalKey();

  Future<void> saveCardAsImage() async {
    // Android 버전별 권한 처리
    if (Platform.isAndroid) {
      try {
        // 실제 Android API 레벨 확인
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        int androidSdkInt = androidInfo.version.sdkInt;

        print('Android SDK 버전: $androidSdkInt');

        if (androidSdkInt >= 33) {
          // Android 13 이상
          // Android 13 이상: READ_MEDIA_IMAGES 권한 필요
          PermissionStatus photosStatus = await Permission.photos.status;
          print('Photos 권한 상태: $photosStatus');
          if (photosStatus.isDenied) {
            photosStatus = await Permission.photos.request();
            print('Photos 권한 요청 결과: $photosStatus');
          }

          if (!photosStatus.isGranted) {
            if (photosStatus.isPermanentlyDenied) {
              // 설정으로 이동하도록 안내
              toastification.show(
                context: context,
                style: ToastificationStyle.flat,
                type: ToastificationType.error,
                autoCloseDuration: Duration(seconds: 2),
                alignment: Alignment.bottomCenter,
                title: Text('갤러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
              );
              await openAppSettings();
            } else {
              toastification.show(
                context: context,
                style: ToastificationStyle.flat,
                type: ToastificationType.error,
                autoCloseDuration: Duration(seconds: 2),
                alignment: Alignment.bottomCenter,
                title: Text('갤러리 접근 권한이 필요합니다'),
              );
            }
            return;
          }
        } else if (androidSdkInt >= 30) {
          // Android 11-12: MANAGE_EXTERNAL_STORAGE 또는 WRITE_EXTERNAL_STORAGE 권한 필요
          PermissionStatus manageStorageStatus =
              await Permission.manageExternalStorage.status;
          print('MANAGE_EXTERNAL_STORAGE 권한 상태: $manageStorageStatus');

          if (manageStorageStatus.isDenied) {
            manageStorageStatus =
                await Permission.manageExternalStorage.request();
            print('MANAGE_EXTERNAL_STORAGE 권한 요청 결과: $manageStorageStatus');
          }

          if (!manageStorageStatus.isGranted) {
            // WRITE_EXTERNAL_STORAGE로 대체 시도
            PermissionStatus storageStatus = await Permission.storage.status;
            if (storageStatus.isDenied) {
              storageStatus = await Permission.storage.request();
            }

            if (!storageStatus.isGranted) {
              toastification.show(
                context: context,
                style: ToastificationStyle.flat,
                type: ToastificationType.error,
                autoCloseDuration: Duration(seconds: 2),
                alignment: Alignment.bottomCenter,
                title: Text('저장소 접근 권한이 필요합니다'),
              );
              return;
            }
          }
        } else {
          // Android 10 이하: WRITE_EXTERNAL_STORAGE 권한 필요
          PermissionStatus storageStatus = await Permission.storage.status;
          print('Storage 권한 상태: $storageStatus');
          if (storageStatus.isDenied) {
            storageStatus = await Permission.storage.request();
            print('Storage 권한 요청 결과: $storageStatus');
          }

          if (!storageStatus.isGranted) {
            if (storageStatus.isPermanentlyDenied) {
              toastification.show(
                context: context,
                style: ToastificationStyle.flat,
                type: ToastificationType.error,
                autoCloseDuration: Duration(seconds: 2),
                alignment: Alignment.bottomCenter,
                title: Text('설정에서 저장소 접근 권한을 허용해주세요'),
              );
              await openAppSettings();
            } else {
              toastification.show(
                context: context,
                style: ToastificationStyle.flat,
                type: ToastificationType.error,
                autoCloseDuration: Duration(seconds: 2),
                alignment: Alignment.bottomCenter,
                title: Text('저장소 접근 권한이 필요합니다'),
              );
            }
            return;
          }
        }
      } catch (e) {
        print('권한 확인 중 오류: $e');
        // 오류 발생 시 기본 권한으로 시도
        PermissionStatus storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          toastification.show(
            context: context,
            style: ToastificationStyle.flat,
            type: ToastificationType.error,
            autoCloseDuration: Duration(seconds: 2),
            alignment: Alignment.bottomCenter,
            title: Text('저장소 접근 권한이 필요합니다'),
          );
          return;
        }
      }
    } else if (Platform.isIOS) {
      PermissionStatus photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied) {
        photosStatus = await Permission.photos.request();
      }
      if (!photosStatus.isGranted) {
        if (photosStatus.isPermanentlyDenied) {
          toastification.show(
            context: context,
            style: ToastificationStyle.flat,
            type: ToastificationType.error,
            autoCloseDuration: Duration(seconds: 2),
            alignment: Alignment.bottomCenter,
            title: Text('설정에서 갤러리 접근 권한을 허용해주세요.'),
          );
          await openAppSettings();
        } else {
          toastification.show(
            context: context,
            style: ToastificationStyle.flat,
            type: ToastificationType.error,
            autoCloseDuration: Duration(seconds: 2),
            alignment: Alignment.bottomCenter,
            title: Text('갤러리 접근 권한이 필요합니다.'),
          );
        }
        return;
      }
    }

    try {
      // RepaintBoundary가 준비되었는지 확인
      final renderObject = repaintBoundary.currentContext?.findRenderObject();
      if (renderObject == null) {
        throw Exception('RepaintBoundary를 찾을 수 없습니다. 위젯이 아직 렌더링되지 않았을 수 있습니다.');
      }

      final boundary = renderObject as RenderRepaintBoundary;

      // 이미지 캡처
      print('이미지 캡처 시작...');
      final image = await boundary.toImage(pixelRatio: 3.0); // 더 높은 해상도
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('이미지를 바이트 데이터로 변환할 수 없습니다.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      print('이미지 크기: ${pngBytes.length} bytes');

      // 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'MyWay_ResultCard_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');

      print('임시 파일 경로: ${file.path}');
      await file.writeAsBytes(pngBytes);

      // 파일이 실제로 생성되었는지 확인
      if (!await file.exists()) {
        throw Exception('임시 파일 생성에 실패했습니다.');
      }

      print('임시 파일 크기: ${await file.length()} bytes');

      // 갤러리에 저장
      print('갤러리 저장 시작...');
      final result = await GallerySaver.saveImage(
        file.path,
        albumName: 'MyWay', // 앨범 이름 지정
      );

      print('갤러리 저장 결과: $result');

      // 임시 파일 삭제
      try {
        await file.delete();
        print('임시 파일 삭제 완료');
      } catch (deleteError) {
        print('임시 파일 삭제 실패: $deleteError');
      }

      if (result == true) {
        toastification.show(
          context: context,
          style: ToastificationStyle.flat,
          type: ToastificationType.success,
          autoCloseDuration: Duration(seconds: 3),
          alignment: Alignment.bottomCenter,
          title: Text('이미지가 갤러리에 저장되었습니다'),
        );
      } else {
        throw Exception('GallerySaver가 false를 반환했습니다.');
      }
    } catch (e) {
      print('이미지 저장 실패 상세: $e');
      toastification.show(
        context: context,
        style: ToastificationStyle.flat,
        type: ToastificationType.error,
        autoCloseDuration: Duration(seconds: 3),
        alignment: Alignment.bottomCenter,
        title: Text('이미지 저장에 실패했습니다: ${e.toString()}'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);
    final mapProvider = Provider.of<MapProvider>(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Text(
            '산책완료',
            style: TextStyle(
              color: GRAYSCALE_LABEL_950,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: GRAYSCALE_LABEL_200,
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        RepaintBoundary(
                          key: repaintBoundary,
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 15,
                                  child: Image.memory(
                                    widget.courseImage,
                                    gaplessPlayback: true,
                                    width: double.infinity,

                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) =>
                                            const Text('이미지를 불러올 수 없습니다'),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10),
                                      Text(
                                        widget.courseName,
                                        style: TextStyle(
                                          color: GRAYSCALE_LABEL_950,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        stepProvider.formattedStopTime,
                                        style: TextStyle(
                                          color: GRAYSCALE_LABEL_800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.result.parkName ?? '정보 없음',
                                            style: TextStyle(
                                              color: GRAYSCALE_LABEL_950,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '${widget.result.distance}',
                                                    style: TextStyle(
                                                      color:
                                                          GRAYSCALE_LABEL_950,
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '거리(km)',
                                                    style: TextStyle(
                                                      color:
                                                          GRAYSCALE_LABEL_500,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 20),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    widget.result.duration,
                                                    style: TextStyle(
                                                      color:
                                                          GRAYSCALE_LABEL_950,
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '시간',
                                                style: TextStyle(
                                                  color: GRAYSCALE_LABEL_500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 30),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '${widget.result.steps}',
                                                    style: TextStyle(
                                                      color:
                                                          GRAYSCALE_LABEL_950,
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '걸음수',
                                                style: TextStyle(
                                                  color: GRAYSCALE_LABEL_500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          saveCardAsImage();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(5),

                          decoration: BoxDecoration(
                            color: STORE_IMAGE_BUTTON,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '이미지 저장',
                                  style: TextStyle(
                                    color: WHITE,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    saveCardAsImage();
                                  },
                                  icon: Icon(
                                    Icons.file_download_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                          stepProvider.resetTracking();
                          mapProvider.resetState();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ORANGE_PRIMARY_500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '홈 으로',
                                style: TextStyle(
                                  color: GRAYSCALE_LABEL_950,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
