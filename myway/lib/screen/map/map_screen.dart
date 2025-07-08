import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/screen/alert/dialog.dart';
import 'package:myway/screen/result/course_name_screen.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../provider/step_provider.dart';
import '/const/colors.dart';
import '/screen/map/course_recommend_bottomsheet.dart';
import '/provider/map_provider.dart';
import 'start_tracking_bottomsheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  Location location = Location();
  List<LatLng> walkingRoute = [];
  Set<Polyline> polylines = {};
  int? selectedIndex;
  LatLng? currentPosition;
  bool _tracking = false; // 경로 추적 상태
  bool isLoading = true;
  final Set<Marker> _markers = {};

  TrackingStatus? _prevStatus;
  ParkCourseInfo? _prevCourse;

  @override
  void initState() {
    super.initState();
    walkingRoute.clear();
    polylines.clear();
    _checkLocationPermission();

    // initState에서 mapProvider 로딩 상태 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.setMapLoading(isLoading);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tracking = false;
    location.onLocationChanged.drain();
    if (mapController != null) {
      mapController!.dispose();
      mapController = null;
    }
  }

  Future<void> _loadUserPhotoAndMarker() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('🔍 _loadUserPhotoAndMarker 시작');
    debugPrint('🔍 currentPosition: $currentPosition');

    if (user == null || currentPosition == null) {
      debugPrint('🔍 user 또는 currentPosition이 null');
      _addDefaultUserMarker();
      return;
    }

    try {
      // Firestore에서 프로필 이미지 URL 가져오기
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      String? profileImageUrl;
      if (doc.exists && doc.data() != null) {
        profileImageUrl = doc.data()!['profileImage'] as String?;
        debugPrint('🔍 Firestore에서 가져온 profileImage URL: $profileImageUrl');
      }

      // Firestore에 프로필 이미지가 없으면 Firebase Auth의 photoURL 사용
      if (profileImageUrl == null || profileImageUrl.isEmpty) {
        profileImageUrl = user.photoURL;
        debugPrint('🔍 Firebase Auth에서 가져온 photoURL: $profileImageUrl');
      }

      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        try {
          final Uint8List markerIcon = await _getBytesFromNetworkImage(
            profileImageUrl,
            width: 60,
          );
          debugPrint('🔍 마커 아이콘 생성 성공, 크기: ${markerIcon.length} bytes');

          final Marker marker = Marker(
            markerId: MarkerId('user_profile'),
            position: currentPosition!,
            icon: BitmapDescriptor.bytes(markerIcon),
            infoWindow: InfoWindow(title: user.displayName ?? '사용자'),
          );

          setState(() {
            _markers.removeWhere((m) => m.markerId.value == 'user_profile');
            _markers.add(marker);
          });
          debugPrint('🔍 프로필 마커 추가 성공. 전체 마커 수: ${_markers.length}');
        } catch (e) {
          debugPrint('🔍 마커 이미지 로드 실패: $e');
          _addDefaultUserMarker();
        }
      } else {
        debugPrint('🔍 프로필 이미지 URL이 없음');
        _addDefaultUserMarker();
      }
    } catch (e) {
      debugPrint('🔍 Firestore 접근 실패: $e');
      _addDefaultUserMarker();
    }
  }

  void _addDefaultUserMarker() {
    if (currentPosition != null) {
      final Marker marker = Marker(
        markerId: MarkerId('user_profile'),
        position: currentPosition!,
        infoWindow: InfoWindow(title: '현재 위치'),
      );

      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'user_profile');
        _markers.add(marker);
      });
    }
  }

  void _updateUserMarkerPosition(LatLng newPosition) {
    final existingMarker = _markers.firstWhere(
      (marker) => marker.markerId.value == 'user_profile',
      orElse: () => Marker(markerId: MarkerId('none'), position: LatLng(0, 0)),
    );

    if (existingMarker.markerId.value != 'none') {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'user_profile');
        _markers.add(existingMarker.copyWith(positionParam: newPosition));
      });
    }
  }

  Future<Uint8List> _getBytesFromNetworkImage(
    String url, {
    int width = 100,
  }) async {
    final http.Response response = await http.get(Uri.parse(url));
    final Uint8List bytes = response.bodyBytes;

    // 원본 이미지를 디코딩
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ui.Image originalImage = frame.image;

    // 원형 마커 이미지 생성
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = width.toDouble();
    final radius = size / 2;

    // 배경 (흰색 원형 테두리)
    final backgroundPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius, backgroundPaint);

    // 프로필 이미지를 원형으로 클리핑
    canvas.save();
    final clipPath =
        Path()..addOval(
          Rect.fromCircle(center: Offset(radius, radius), radius: radius - 4),
        );
    canvas.clipPath(clipPath);

    // 이미지 그리기
    final srcRect = Rect.fromLTWH(
      0,
      0,
      originalImage.width.toDouble(),
      originalImage.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(4, 4, size - 8, size - 8);
    canvas.drawImageRect(originalImage, srcRect, dstRect, Paint());
    canvas.restore();

    // 테두리 그리기
    final borderPaint =
        Paint()
          ..color = Color(0xFFFF8A00) // ORANGE_PRIMARY_500
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawCircle(Offset(radius, radius), radius - 1.5, borderPaint);

    // 이미지를 PNG로 변환
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, width);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    originalImage.dispose();
    picture.dispose();
    img.dispose();

    return byteData!.buffer.asUint8List();
  }

  Future<void> _checkLocationPermission() async {
    PermissionStatus permissionStatus = await location.hasPermission();

    // 권한이 거부된 경우
    if (permissionStatus == PermissionStatus.denied) {
      print("위치 권한 거부됨");
      // 권한 요청 다이얼로그 띄우기
      _showPermissionDeniedDialog();
    }
    // 권한이 영구적으로 거부된 경우
    else if (permissionStatus == PermissionStatus.deniedForever) {
      print("위치 권한 영구적으로 거부됨");
      // 설정 화면으로 이동 안내
      _showPermanentPermissionDeniedDialog();
    } else {
      print('위치 권한 허용');
      if (permissionStatus == PermissionStatus.granted) {
        location.changeSettings(
          accuracy: LocationAccuracy.high,
          interval: 1000,
        );
        _getLocation();
      }
    }
  }

  // 권한 거부 후 다이얼로그
  // TODO: 권한 요청 후 확인 필요
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("위치 권한 요청"),
          content: Text("위치 권한을 허용해야 앱을 정상적으로 사용할 수 있습니다."),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: GRAYSCALE_LABEL_100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      shadowColor: Colors.transparent,
                      overlayColor: GRAYSCALE_LABEL_800,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      '취소',
                      style: TextStyle(color: GRAYSCALE_LABEL_900),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: ORANGE_PRIMARY_500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      overlayColor: ORANGE_PRIMARY_800,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      // 권한 요청
                      PermissionStatus status =
                          await location.requestPermission();
                      if (status == PermissionStatus.granted) {
                        print("위치 권한 허용됨");
                      } else {
                        print("위치 권한 거부됨");
                      }
                    },
                    child: Text(
                      '다시 시도',
                      style: TextStyle(color: GRAYSCALE_LABEL_900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 영구적으로 거부된 경우 다이얼로그
  // TODO: 설정 화면으로 이동하는 기능 추가
  void _showPermanentPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 0,
          backgroundColor: WHITE,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            "위치 권한 영구 거부",
            style: TextStyle(
              color: GRAYSCALE_LABEL_900,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            "위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 수동으로 허용해야 합니다.",
            style: TextStyle(
              fontSize: 16,
              color: GRAYSCALE_LABEL_700,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: 12,
            left: 12,
            right: 12,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: GRAYSCALE_LABEL_100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      shadowColor: Colors.transparent,
                      overlayColor: GRAYSCALE_LABEL_800,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      '취소',
                      style: TextStyle(color: GRAYSCALE_LABEL_900),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: ORANGE_PRIMARY_500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      overlayColor: ORANGE_PRIMARY_800,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      '설정으로 이동',
                      style: TextStyle(color: GRAYSCALE_LABEL_900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 위치 추적 시작
  void startLocationTracking() {
    walkingRoute.clear(); // 이전 경로 초기화
    // polylines.clear();
    setState(() {
      _tracking = true; // 추적 상태로 변경
    });
    location.changeSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);

    // 위치 추적 시작
    location.onLocationChanged.listen((LocationData currentLocation) {
      if (!mounted) return;

      final trackingStatus =
          Provider.of<StepProvider>(context, listen: false).status;

      if (trackingStatus != TrackingStatus.running) return;

      if (_tracking) {
        setState(() {
          print("latitude : ${currentLocation.latitude!}");
          print("longitude : ${currentLocation.longitude!}");

          LatLng position = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
          walkingRoute.add(position); // 좌표 추가

          // 현재 위치 업데이트
          currentPosition = position;

          // 사용자 마커 위치 업데이트
          _updateUserMarkerPosition(position);

          polylines.add(
            Polyline(
              polylineId: PolylineId("route"),
              points: walkingRoute,
              color: ORANGE_PRIMARY_500,
              width: 5,
            ),
          );
          mapController?.animateCamera(CameraUpdate.newLatLng(position));
        });
      }
    });
  }

  // 위치 추적 중지
  void stopLocationTracking() async {
    print('📍 stopLocationTracking');
    print('📍 위치 추적 일시정지됨');
    _tracking = false;
    // mapController null 체크 추가
    if (mapController == null) {
      print('📍 mapController가 null입니다');
      return;
    }

    setState(() {
      polylines.removeWhere((p) => p.polylineId.value == 'recommended');
    });

    // await Future.delayed(const Duration(milliseconds: 1000));
    await WidgetsBinding.instance.endOfFrame;
    final Uint8List? imageBytes = await mapController?.takeSnapshot();
    final stepProvider = Provider.of<StepProvider>(context, listen: false);

    stepProvider.stopTracking();
    stepProvider.setRoute(walkingRoute);

    polylines.removeWhere((p) => p.polylineId.value == 'route');

    if (imageBytes != null && imageBytes.isNotEmpty) {
      debugPrint('📍 이미지 캡처 성공, 길이: ${imageBytes.length}');
      debugPrint('PNG signature: ${imageBytes.sublist(0, 8)}');

      if (!context.mounted) return;

      if (!context.mounted) return;
      Navigator.pop(context); // 현재 화면 닫기
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CourseNameScreen(
                courseImage: imageBytes,
                stepModel: stepProvider.currentStepModel!,
              ),
        ),
      );
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: Duration(seconds: 2),
        title: Text('지도 캡처에 실패했습니다'),
      );
    }
  }

  Future<void> _getLocation() async {
    print('📍 getLocation');

    final current = await location.getLocation();
    if (mounted) {
      setState(() {
        currentPosition = LatLng(current.latitude!, current.longitude!);
        if (currentPosition != null) {
          isLoading = false;
          print('📍 currentPosition getLocation : $currentPosition');
          // 첫 위치 설정
          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(
                  currentPosition!.latitude,
                  currentPosition!.longitude + 0.01,
                ),
                17.0,
              ),
            );
          }
        }
      });

      // currentPosition이 설정된 후 프로필 마커 로드
      await _loadUserPhotoAndMarker();

      // setState 완료 후 mapProvider 업데이트
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final mapProvider = Provider.of<MapProvider>(context, listen: false);
        mapProvider.setMapLoading(isLoading);
      });
    }
  }

  void drawRecommendPolylines(ParkCourseInfo? selectedCourse) {
    if (selectedCourse == null || identical(selectedCourse, _prevCourse)) {
      return;
    }
    _prevCourse = selectedCourse;

    // 기존 추천 경로 제거
    polylines.removeWhere((p) => p.polylineId.value == 'recommended');

    // 추천 경로 다시 그리기
    final recommendCourse = Polyline(
      polylineId: const PolylineId('recommended'),
      color: BLUE_SECONDARY_600,
      width: 5,
      points: selectedCourse.details.route,
    );
    polylines.add(recommendCourse);
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);
    final mapProvider = Provider.of<MapProvider>(context);
    final status = stepProvider.status;
    final selectedCourse = Provider.of<MapProvider>(context).selectedCourse;
    print('mapProvider.selectedCourse: ${mapProvider.selectedCourse}');

    if (mapProvider.selectedCourse == null) {
      print('null course');
      // 추천 코스가 선택되지 않은 경우 특정 polyline 그리지않음
      polylines.removeWhere((p) => p.polylineId.value == 'recommended');
    } else {
      print('drawLine');
      drawRecommendPolylines(selectedCourse);
    }

    if (mapProvider.isTracking && !_tracking) {
      startLocationTracking();
    }
    // 상태 변화 체크를 안전하게 처리
    if (_prevStatus != null &&
        _prevStatus != TrackingStatus.stopped &&
        status == TrackingStatus.stopped) {
      _tracking = false;
      // build 중이 아닌 시점에 실행되도록 스케줄링
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stopLocationTracking();
      });
    }
    _prevStatus = status;

    // build() 메서드 내에서 mapProvider 상태 변경 제거
    // mapProvider.setMapLoading(isLoading); <- 이 줄 제거

    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: WHITE,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ConfirmationDialog(
                  title: '화면을 나가시겠습니까?',
                  content: '진행 중인 정보가 사라질 수 있습니다.',
                  cancelText: '취소',
                  confirmText: '확인',
                  onConfirm: () {
                    Provider.of<MapProvider>(
                      context,
                      listen: false,
                    ).showCourseRecommendBottomSheet();
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    Navigator.pushReplacementNamed(context, 'home'); // 실제 뒤로가기
                  },
                );
              },
            );
          },
        ),
        title: Text(
          '마이웨이',
          style: TextStyle(
            color: GRAYSCALE_LABEL_900,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final mapHeight = constraints.maxHeight - 200;

              return Column(
                children: [
                  SizedBox(
                    height: mapHeight,
                    child:
                        isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: ORANGE_PRIMARY_500,
                              ),
                            )
                            : GoogleMap(
                              onMapCreated: (controller) {
                                mapController = controller;
                              },
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  currentPosition?.latitude ?? 35.1691,
                                  currentPosition?.longitude ?? 129.0874,
                                ),
                                zoom: 17.0,
                              ),
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              polylines: polylines,
                              markers: _markers,
                            ),
                  ),
                  SizedBox(height: 200),
                ],
              );
            },
          ),
          if (mapProvider.isCourseRecommendBottomSheetVisible)
            CourseRecommendBottomsheet(),
          if (mapProvider.isStartTrackingBottomSheetVisible)
            StartTrackingBottomsheet(),
        ],
      ),
    );
  }
}
