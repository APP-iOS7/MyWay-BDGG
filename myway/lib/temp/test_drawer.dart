// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';

// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   GoogleMapController? _controller;
//   final Location _location = Location();
//   bool _tracking = false; // 경로 추적 상태
//   final List<LatLng> _route = []; // 경로를 저장할 리스트
//   final Set<Polyline> _polylines = {}; // 지도에 표시할 Polyline

//   @override
//   void initState() {
//     super.initState();
//   }

//   // 경로 추적 시작
//   void _startTracking() {
//     _route.clear(); // 이전 경로 초기화
//     _polylines.clear(); // 지도에서 경로 초기화
//     setState(() {
//       _tracking = true; // 추적 상태로 변경
//     });

//     // 위치 추적 시작
//     _location.onLocationChanged.listen((LocationData currentLocation) {
//       if (_tracking) {
//         setState(() {
//           print("latitude : ${currentLocation.latitude!}");
//           print("longitude : ${currentLocation.longitude!}");
//           LatLng position = LatLng(
//             currentLocation.latitude!,
//             currentLocation.longitude!,
//           );
//           _route.add(position); // 새로운 좌표 추가
//           _polylines.add(
//             Polyline(
//               polylineId: PolylineId("route"),
//               points: _route,
//               color: Colors.blue,
//               width: 5,
//             ),
//           );
//           _controller?.animateCamera(
//             CameraUpdate.newLatLng(position),
//           ); // 카메라 위치 이동
//         });
//       }
//     });
//   }

//   // 경로 추적 중지
//   void _stopTracking() {
//     setState(() {
//       _tracking = false; // 추적 중지 상태로 변경
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("맵 루트 표시 테스트"), centerTitle: true),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 2,
//             child: GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: LatLng(35.1691, 129.0874), // 초기 카메라 위치
//                 zoom: 17,
//               ),
//               myLocationEnabled: true, // 현재 위치 표시
//               onMapCreated: (GoogleMapController controller) {
//                 _controller = controller;
//               },
//               polylines: _polylines, // 경로를 지도에 표시
//             ),
//             // child: Container(),
//           ),
//           Expanded(
//             child: Center(
//               child: ElevatedButton(
//                 onPressed: _tracking ? _stopTracking : _startTracking,
//                 child: Text(_tracking ? '중지' : '시작'),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
