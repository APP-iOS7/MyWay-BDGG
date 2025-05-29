import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myway/screen/result/course_name_screen.dart';
import 'package:provider/provider.dart';

import '../../provider/step_provider.dart';
import '/const/colors.dart';
import '/screen/map/course_recommend_bottomsheet.dart';
import '/model/course_model.dart';
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

  TrackingStatus? _prevStatus;
  Course? _prevCourse;

  @override
  void initState() {
    super.initState();
    walkingRoute.clear();
    polylines.clear();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    super.dispose();
    _tracking = false;
    location.onLocationChanged.drain();
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
    polylines.clear();
    setState(() {
      _tracking = true; // 추적 상태로 변경
    });
    location.changeSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);

    // 위치 추적 시작
    location.onLocationChanged.listen((LocationData currentLocation) {
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
    final Uint8List? imageBytes = await mapController!.takeSnapshot();
    final stepProvider = Provider.of<StepProvider>(context, listen: false);

    stepProvider.stopTracking();

    if (imageBytes != null && imageBytes.isNotEmpty) {
      debugPrint('📍 이미지 캡처 성공, 길이: ${imageBytes.length}');
      debugPrint('PNG signature: ${imageBytes.sublist(0, 8)}');

      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지도 캡처에 실패했습니다')));
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
    }
  }

  void drawRecommendPolylines(Course? selectedCourse) {
    if (selectedCourse == null || selectedCourse == _prevCourse) return;
    _prevCourse = selectedCourse;

    // 기존 추천 경로만 제거
    polylines.removeWhere((p) => p.polylineId.value == 'recommended');

    // 추천 경로 다시 그리기
    final recommendCourse = Polyline(
      polylineId: const PolylineId('recommended'),
      color: BLUE_SECONDARY_600,
      width: 5,
      points: selectedCourse.route,
    );
    polylines.add(recommendCourse);
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);
    final mapProvider = Provider.of<MapProvider>(context);
    final status = stepProvider.status;
    final selectedCourse = Provider.of<MapProvider>(context).selectedCourse;
    drawRecommendPolylines(selectedCourse);
    if (mapProvider.isTracking && !_tracking) {
      startLocationTracking();
    }
    if (_prevStatus != TrackingStatus.stopped &&
        status == TrackingStatus.stopped) {
      _tracking = false;
      stopLocationTracking();
    }
    _prevStatus = status;
    mapProvider.setMapLoading(isLoading);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WHITE,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // 뒤로가기 버튼을 누르면 Provider의 상태 변경
            Provider.of<MapProvider>(
              context,
              listen: false,
            ).showCourseRecommendBottomSheet();
            Navigator.of(context).pop();
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

              // if (mapProvider.selectedCourse != null) {
              //   print("provider selectedCourse is not null");
              //   drawRecommendPolylines(mapProvider.selectedCourse!);
              // }
              // if (mapProvider.selectedCourse == null) {
              //   print("provider selectedCourse is null");
              //   polylines.clear();
              // }
              return Column(
                children: [
                  SizedBox(
                    height: mapHeight,
                    child:
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
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
                              myLocationEnabled: true,
                              polylines: polylines,
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
