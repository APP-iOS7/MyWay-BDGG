import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/temp/course_data.dart';

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
  int? selectedIndex;
  LocationData? currentPosition;
  bool _initialPositionSet = false;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // 맵 컨트롤러가 생성된 후에 현재 위치로 이동
    _updateCurrentLocation();
  }

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      // 위치 서비스가 활성화되어 있는지 확인
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('위치 서비스를 활성화할 수 없습니다.');
          return;
        }
      }
      print("위치서비스 통과");

      // 위치 권한 확인
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('위치 권한을 얻을 수 없습니다.');
          return;
        }
      }
      print("위치 권한 통과");

      // 위치 정보 설정
      location.changeSettings(
        accuracy: LocationAccuracy.high,
        // distanceFilter: 10,
        interval: 5000,
      );

      // 위치 정보 가져오기
      _getLocation();

      // 위치가 변경될 때마다 업데이트
      location.onLocationChanged.listen((LocationData newLocation) {
        _updateLocation(newLocation);
      });
    } catch (e) {
      print('위치 서비스 초기화 중 오류 발생: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      currentPosition = await location.getLocation();
      print('📍 현재 위치 가져옴: $currentPosition');

      if (currentPosition != null && mounted) {
        setState(() {
          _updateLocation(currentPosition!);
        });
      }
    } catch (e) {
      print('위치 가져오기 오류: $e');
    }
  }

  void _updateLocation(LocationData locationData) {
    if (!mounted) return;

    setState(() {
      currentPosition = locationData;
      print(
        '📍 위치 업데이트됨: 위도=${locationData.latitude}, 경도=${locationData.longitude}',
      );
    });

    _updateCurrentLocation();
  }

  void _updateCurrentLocation() {
    if (!mounted) return;
    if (currentPosition != null && mapController != null) {
      LatLng position = LatLng(
        currentPosition!.latitude ?? 35.1691,
        currentPosition!.longitude ?? 129.0874,
      );

      // 초기 위치 설정이 안 되었다면 카메라 이동
      if (!_initialPositionSet) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(position, 17.0),
        );
        _initialPositionSet = true;
      }

      // 트래킹 중이라면 경로 추가
      if (isTracking && mounted) {
        route.add(position);
        _updatePolylines();
      }
    }
  }

  void _updatePolylines() {
    if (!mounted) return;

    if (route.isNotEmpty) {
      setState(() {
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: ORANGE_PRIMARY_500,
            width: 5,
            points: List.from(route), // 복사본 생성
          ),
        );
        print(polylines);
      });
    }
  }

  // void _startTracking() {
  //   print("트래킹 시작");
  //   route.clear();
  //   polylines.clear();

  //   if (mounted) {
  //     setState(() {
  //       isTracking = true;
  //     });
  //   }

  //   location.changeSettings(
  //     accuracy: LocationAccuracy.high,
  //     distanceFilter: 10,
  //   );

  //   // 시작 위치 추가
  //   if (currentPosition != null) {
  //     LatLng position = LatLng(
  //       currentPosition!.latitude ?? 35.1691,
  //       currentPosition!.longitude ?? 129.0874,
  //     );
  //     route.add(position);
  //     _updatePolylines();
  //   }
  // }

  void stopTracking() {
    setState(() {
      isTracking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              return GoogleMap(
                onMapCreated: _onMapCreated,
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
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      snapSizes: [0.3, 0.7],
      snap: false,
      builder: (BuildContext context, scrollSheetController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10),
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  color: GRAYSCALE_LABEL_300,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(top: 8, bottom: 8),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '추천코스',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '추천 코스 선택시 지도에 경로가 표시됩니다.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: GRAYSCALE_LABEL_600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return StartTrackingScreen(
                                course:
                                    selectedIndex != null
                                        ? courses[selectedIndex!]
                                        : null,
                              );
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ORANGE_PRIMARY_500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Icon(Icons.play_arrow_rounded, color: WHITE),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              if (selectedIndex != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    height: 20,
                    child: Row(
                      children: [
                        Text(
                          '선택된 코스: ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          courses[selectedIndex!].title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '${courses[selectedIndex!].distance}km',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: GRAYSCALE_LABEL_800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(height: 20),
              Divider(color: GRAYSCALE_LABEL_200, thickness: 1),
              const SizedBox(height: 5),
              // 추천 코스 리스트
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.builder(
                    controller: scrollSheetController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2열
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: CourseData.getCourses().length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // 선택된 카드만 선택 가능하도록 설정
                            selectedIndex =
                                selectedIndex == index ? null : index;
                          });
                          print('selectedIndex: $selectedIndex');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                selectedIndex == index
                                    ? ORANGE_PRIMARY_500
                                    : WHITE,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: GRAYSCALE_LABEL_200,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                child: Image.network(
                                  courses[index].imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 120,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 30,
                                    color:
                                        selectedIndex == index
                                            ? WHITE
                                            : ORANGE_PRIMARY_500,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            courses[index].title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            '${courses[index].distance}km',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: GRAYSCALE_LABEL_800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        courses[index].park,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: GRAYSCALE_LABEL_800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
