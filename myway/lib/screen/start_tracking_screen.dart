import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myway/colors.dart';

import '../park_model.dart';

class StartTrackingScreen extends StatefulWidget {
  final Park? park;
  // final Course? course;
  const StartTrackingScreen({super.key, this.park});

  @override
  _StartTrackingScreenState createState() => _StartTrackingScreenState();
}

class _StartTrackingScreenState extends State<StartTrackingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  Location location = Location();
  bool isTracking = false;
  List<LatLng> route = [];
  Set<Polyline> polylines = {};

  final LatLng _center = const LatLng(35.1691, 129.0874);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    print('📍 location: $location');
    print('park name: ${widget.park}');
    // _startTracking();
  }

  void _startTracking() {
    route.clear();
    polylines.clear();
    setState(() {
      isTracking = true;
    });

    location.onLocationChanged.listen((LocationData currentLocation) {
      if (isTracking) {
        // 경로 추적 중
        setState(() {
          print('📍 latitude: ${currentLocation.latitude.toString()}');
          print('📍 longitude: ${currentLocation.longitude.toString()}');
          LatLng position = LatLng(
            currentLocation.latitude ?? 0.0,
            currentLocation.longitude ?? 0.0,
          );
          route.add(position);
          polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              color: ORANGE_PRIMARY_500,
              width: 5,
              points: route,
            ),
          );
          // 카메라 위치 이동
          mapController?.animateCamera(CameraUpdate.newLatLng(position));
        });
      }
    });
  }

  void stopTracking() {
    setState(() {
      isTracking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          // GoogleMap
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 17.0),
            myLocationEnabled: true,
            polylines: polylines,
          ),
          // 하단 컨테이너
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: WHITE,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GRAYSCALE_LABEL_300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                  ),
                  // 하단 버튼
                  // Padding(
                  //   padding: const EdgeInsets.all(20.0),
                  //   child: Row(
                  //     children: [
                  //       SizedBox(
                  //         height: 56,
                  //         width: double.infinity,
                  //         child: ElevatedButton(
                  //           onPressed: () {
                  //             // 선택 완료 로직
                  //           },
                  //           style: ElevatedButton.styleFrom(
                  //             backgroundColor: ORANGE_PRIMARY_500,
                  //             foregroundColor: Colors.white,
                  //             elevation: 0,
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(8),
                  //             ),
                  //           ),
                  //           child: const Text(
                  //             "일시정지",
                  //             style: TextStyle(
                  //               fontSize: 18,
                  //               fontWeight: FontWeight.w600,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //       SizedBox(
                  //         height: 56,
                  //         width: double.infinity,
                  //         child: ElevatedButton(
                  //           onPressed: () {
                  //             // 선택 완료 로직
                  //           },
                  //           style: ElevatedButton.styleFrom(
                  //             backgroundColor: ORANGE_PRIMARY_500,
                  //             foregroundColor: Colors.white,
                  //             elevation: 0,
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(8),
                  //             ),
                  //           ),
                  //           child: const Text(
                  //             "선택 종료",
                  //             style: TextStyle(
                  //               fontSize: 18,
                  //               fontWeight: FontWeight.w600,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
