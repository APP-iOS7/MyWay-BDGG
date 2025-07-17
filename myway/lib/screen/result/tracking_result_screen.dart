import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/provider/step_provider.dart';
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
    if (await _requestPermission()) {
      try {
        // 캡처
        RenderRepaintBoundary boundary =
            repaintBoundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        // 임시 파일로 저장
        final String tempPath =
            '${Directory.systemTemp.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.png';
        File imgFile = File(tempPath);
        await imgFile.writeAsBytes(pngBytes);

        // 갤러리에 저장
        final result = await GallerySaver.saveImage(imgFile.path);
        // final savedPath = result ?? '저장 실패';

        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: Duration(seconds: 2),
          title: Text('이미지 저장 완료'),
        );
      } catch (e) {
        debugPrint('Error: $e');
      }
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: Duration(seconds: 2),
        title: Text('권한이 거부 되었습니다'),
      );
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status =
          await [
            Permission.storage,
            Permission.photos,
            Permission.mediaLibrary,
          ].request();
      return status.values.any((st) => st.isGranted);
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return false;
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
