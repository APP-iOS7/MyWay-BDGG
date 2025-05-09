import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myway/colors.dart';

import '../park_model.dart';
import 'start_tracking_screen.dart';

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

  late TabController _tabController;

  Park? selectedPark;
  List<Park> parks = [
    Park(
      name: "서울숲",
      address: "서울특별시 성동구 성수동1가 685-1",
      kind: "근린공원",
      latitude: 37.5449,
      longitude: 127.0452,
      imageUrl: "https://example.com/image.jpg",
    ),
    Park(
      name: "한강공원",
      address: "서울특별시 용산구 한강로2가 1-1",
      kind: "대공원",
      latitude: 37.5299,
      longitude: 126.9737,
      imageUrl: "https://example.com/image.jpg",
    ),
    // 더 많은 공원 데이터...
  ];

  final LatLng _center = const LatLng(35.1691, 129.0874);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onParkSelect(Park park) {
    setState(() {
      if (selectedPark == park) {
        selectedPark = null; // 이미 선택된 공원은 취소
      } else {
        selectedPark = park; // 공원 선택
      }
    });
  }

  void _onSelectionComplete() {
    if (selectedPark != null) {
      // 선택 완료 후 다른 화면으로 이동 (예시로 ParkDetailPage로 이동)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StartTrackingScreen(park: selectedPark!),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    print('📍 location: $location');
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // TabController 해제
    super.dispose();
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
          // GoogleMap: 화면 전체를 차지하는 지도
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

                  // 탭 메뉴
                  TabBar(
                    controller: _tabController,
                    labelColor: BLACK,
                    unselectedLabelColor: GRAYSCALE_LABEL_500,
                    indicatorColor: BLACK,
                    indicatorSize: TabBarIndicatorSize.tab,
                    onTap: (index) {
                      if (index == 0) {
                        // _scrollToRegion();
                      } else {
                        // _scrollToCategory();
                      }
                    },
                    tabs: const [Tab(text: "공원"), Tab(text: "추천코스")],
                  ),

                  // 탭 컨텐츠
                  Expanded(
                    child: ListView.builder(
                      itemCount: parks.length,
                      itemBuilder: (context, index) {
                        final park = parks[index]; // 각 공원 데이터 가져오기

                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: ORANGE_PRIMARY_500,
                          ),
                          title: Row(
                            children: [
                              Text(
                                park.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: BLACK,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                park.kind,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  color: GRAYSCALE_LABEL_600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(park.address),
                          trailing:
                              selectedPark == park
                                  ? const Icon(
                                    Icons.check,
                                    color: GREEN_SECONDARY_600,
                                  ) // 선택된 항목에 체크 표시
                                  : null,
                          tileColor:
                              selectedPark == park ? GREEN_SECONDARY_600 : null,
                          onTap: () {
                            // 공원 클릭 시 동작 예시
                            print("Tapped on ${park.name}");
                            _onParkSelect(park);
                          },
                        );
                      },
                    ),
                  ),
                  // 하단 버튼
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // 선택 완료 로직
                          _onSelectionComplete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ORANGE_PRIMARY_500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "선택 완료",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
