import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/screen/map/course_recommend_bottomsheet.dart';
import 'package:myway/temp/test_latlng.dart';
import 'package:provider/provider.dart';

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
  bool isTracking = false;
  List<LatLng> route = [];
  Set<Polyline> polylines = {};
  int? selectedIndex;
  LocationData? currentPosition;
  bool _initialPositionSet = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    route = TestLatlng().getTestLatlng();

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
          accuracy: LocationAccuracy.high,
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

  Future<void> _getLocation() async {
    print('📍 getLocation');
    currentPosition = await location.getLocation();
    if (currentPosition != null && mounted) {
      print('📍 currentPosition getLocation : $currentPosition');

      setState(() {
        isLoading = false;
        _updateLocation(currentPosition!);
      });
    }
  }

  void _updateLocation(LocationData locationData) {
    print('📍 updateLocation');

    if (!mounted) return;
    setState(() {
      currentPosition = locationData;
      print('📍 currentPosition updateLocation : $currentPosition');
    });

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
        polylines.clear();
        polylines.add(
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

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WHITE,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                    polylines: polylines,
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
