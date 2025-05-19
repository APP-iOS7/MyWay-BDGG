import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/screen/map/course_recommend_bottomsheet.dart';
import 'package:myway/temp/test_latlng.dart';
import 'package:provider/provider.dart';

import '../../model/course_model.dart';
import '../../provider/map_provider.dart';
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
  List<LatLng> route = [];
  Set<Polyline> walkingPolylines = {};
  Set<Polyline> recommendCourse = {};
  int? selectedIndex;
  LocationData? currentPosition;
  bool _initialPositionSet = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // route = TestLatlng().getTestLatlng();

    route.clear();
    recommendCourse.clear();
    walkingPolylines.clear();
    _checkLocationPermission();
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
          accuracy: LocationAccuracy.powerSave,
          interval: 1000,
        );
        _getLocation();
      }
    }
  }

  // 권한 거부 후 다이얼로그
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("위치 권한 요청"),
          content: Text("위치 권한을 허용해야 앱을 정상적으로 사용할 수 있습니다."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // 권한 요청
                PermissionStatus status = await location.requestPermission();
                if (status == PermissionStatus.granted) {
                  print("위치 권한 허용됨");
                } else {
                  print("위치 권한 거부됨");
                }
              },
              child: Text("다시 시도"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("취소"),
            ),
          ],
        );
      },
    );
  }

  // 영구적으로 거부된 경우 다이얼로그
  void _showPermanentPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("위치 권한 영구 거부"),
          content: Text("위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 수동으로 허용해야 합니다."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 앱 설정 화면으로 이동
              },
              child: Text("설정으로 가기"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("취소"),
            ),
          ],
        );
      },
    );
  }

  // 위치 추적 시작
  void startLocationTracking() {
    print('📍 startLocationTracking');
    // location.changeSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    location.changeSettings(accuracy: LocationAccuracy.high, interval: 3000);

    route.clear();
    walkingPolylines.clear();

    location.onLocationChanged.listen((LocationData locationData) {
      if (context.read<MapProvider>().isTracking) {
        setState(() {
          print(currentPosition);
          print(currentPosition?.latitude);
          print(currentPosition?.longitude);
          // print("latitude : "+currentPosition.latitude.toString());
          // print("longitude : "+currentLocation.longitude!.toString());
          LatLng position = LatLng(
            (currentPosition?.latitude ?? 0.0) + 0.1,
            (currentPosition?.longitude ?? 0.0) + 0.1,
          );
          route.add(position);
          print('route $route');
          print('walkingPolylines $walkingPolylines');
          walkingPolylines.add(
            Polyline(
              polylineId: PolylineId("route"),
              points: route,
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
  void stopLocationTracking() {
    print('📍 stopLocationTracking');
    print('📍 위치 추적 일시정지됨');
  }

  Future<void> _getLocation() async {
    print('📍 getLocation');

    try {
      // 초기 로딩 시 고정밀도로 위치 정보 가져오기
      currentPosition = await location.getLocation();
      if (currentPosition != null && mounted) {
        print('📍 currentPosition getLocation : $currentPosition');

        setState(() {
          isLoading = false;
          _updateLocation(currentPosition!);
        });
      }
    } catch (e) {
      print('위치 정보 가져오기 오류: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateLocation(LocationData locationData) {
    if (!mounted) return;
    setState(() {
      currentPosition = locationData;
      print('📍 currentPosition updateLocation : $currentPosition');
    });

    // 첫 위치 설정
    if (!_initialPositionSet &&
        currentPosition != null &&
        mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentPosition!.latitude!, currentPosition!.longitude!),
          17.0,
        ),
      );
      _initialPositionSet = true;
    }

    // 추적 모드일 때만 경로에 위치 추가
    if (context.read<MapProvider>().isTracking) {
      route.add(
        LatLng(currentPosition!.latitude!, currentPosition!.longitude!),
      );
      _updatePolylines();
    }
  }

  void _updatePolylines() {
    print('📍 _updatePolylines');
    if (route.isNotEmpty) {
      setState(() {
        recommendCourse.clear();
        recommendCourse.add(
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.orange,
            width: 5,
            points: List.from(route),
          ),
        );
      });
    }
  }

  void drawRecommendPolylines(Course selectedCourse) {
    print('📍 drawRecommendPolylines');
    recommendCourse.clear();
    recommendCourse.add(
      Polyline(
        polylineId: PolylineId(selectedCourse.title),
        color: BLUE_SECONDARY_600,
        width: 5,
        points: selectedCourse.route,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    if (mapProvider.isTracking) {
      startLocationTracking();
    } else {
      stopLocationTracking();
    }

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
          Consumer<MapProvider>(
            builder: (context, mapProvider, child) {
              if (mapProvider.selectedCourse != null) {
                print("provider selectedCourse is not null");
                drawRecommendPolylines(mapProvider.selectedCourse!);
              }
              if (mapProvider.selectedCourse == null) {
                print("provider selectedCourse is null");
                recommendCourse.clear();
                walkingPolylines.clear();
                route.clear();
              }
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return isLoading
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
                        polylines: walkingPolylines,
                      );
                },
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
