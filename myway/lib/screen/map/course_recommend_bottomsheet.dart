import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myway/screen/alert/countdown_diallog.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/provider/park_data_provider.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/course_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '/const/colors.dart';
import '/provider/map_provider.dart';

class CourseRecommendBottomsheet extends StatefulWidget {
  const CourseRecommendBottomsheet({super.key});

  @override
  State<CourseRecommendBottomsheet> createState() =>
      _CourseRecommendBottomsheetState();
}

class _CourseRecommendBottomsheetState
    extends State<CourseRecommendBottomsheet> {
  int? selectedIndex;
  List<Course> _nearbyCourses = [];

  // ParkCourseInfo를 Course 모델로 변환하는 헬퍼 메서드
  Course _convertToCourse(ParkCourseInfo parkCourse) {
    // 임시 더미 경로 데이터 (실제 앱에서는 API 등에서 가져오는 것이 좋음)
    List<LatLng> dummyRoute = [
      LatLng(37.40020, 126.93613),
      LatLng(37.400120, 126.93657),
      LatLng(37.39948, 126.93656),
      LatLng(37.399476, 126.937293),
      LatLng(37.39953, 126.93780),
    ];

    return Course(
      title: parkCourse.title,
      park: parkCourse.parkName ?? '정보 없음',
      date: DateTime.now(),
      distance: 2.0, // 임시값, 실제로는 계산된 값 사용
      duration: '30분', // 임시값
      steps: 3000, // 임시값
      imageUrl:
          parkCourse.imagePath.startsWith('http')
              ? parkCourse.imagePath
              : 'https://picsum.photos/250?image=9', // 이미지 경로가 URL이 아니면 임시 URL 사용
      route: dummyRoute,
    );
  }

  @override
  void initState() {
    super.initState();
    // 컴포넌트가 초기화될 때 ParkDataProvider의 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);
      provider.fetchAllDataIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<MapProvider, StepProvider, ParkDataProvider>(
      builder: (context, mapProvider, stepProvider, parkDataProvider, child) {
        // 반경 5km 이내의 추천 코스 변환
        _nearbyCourses =
            parkDataProvider.nearbyRecommendedCourses
                .map((parkCourse) => _convertToCourse(parkCourse))
                .toList();
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          snapSizes: [0.4, 0.7],
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
                                    '내 주변 5km 추천코스',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '내 주변 5km 이내 공원의 추천 코스입니다.',
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
                            if (!mapProvider.isMapLoading) {
                              mapProvider.setTracking(true);
                              mapProvider.showStartTrackingBottomSheet();
                              CountdownDiallog.show(
                                context,
                                onComplete: () {
                                  stepProvider.startTracking();
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('지도 로딩 중입니다. 잠시 후 다시 시도해주세요.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ORANGE_PRIMARY_500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            '시작',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: WHITE,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (selectedIndex != null && _nearbyCourses.isNotEmpty)
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
                              _nearbyCourses[selectedIndex!].title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              '${_nearbyCourses[selectedIndex!].distance}km',
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
                      child:
                          parkDataProvider.isLoadingParks ||
                                  parkDataProvider.isLoadingLocation
                              ? _buildLoadingIndicator()
                              : _nearbyCourses.isEmpty
                              ? _buildEmptyNearbyCoursesMessage()
                              : GridView.builder(
                                controller: scrollSheetController,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, // 2열
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount: _nearbyCourses.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      print("선택");
                                      setState(() {
                                        selectedIndex =
                                            selectedIndex == index
                                                ? null
                                                : index;
                                        if (selectedIndex != null) {
                                          mapProvider.selectCourse(
                                            _nearbyCourses[selectedIndex!],
                                          );
                                        } else {
                                          mapProvider.selectCourse(null);
                                        }
                                      });
                                      print('selectedIndex: $selectedIndex');
                                      print(
                                        'course; ${mapProvider.selectedCourse}',
                                      );
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              topRight: Radius.circular(8),
                                            ),
                                            child: _buildCourseImage(
                                              _nearbyCourses[index].imageUrl,
                                              width: double.infinity,
                                              height: 120,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 25,
                                                color:
                                                    selectedIndex == index
                                                        ? WHITE
                                                        : ORANGE_PRIMARY_500,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _nearbyCourses[index]
                                                          .title,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 10.0,
                                                          ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            _nearbyCourses[index]
                                                                .park,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  GRAYSCALE_LABEL_800,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${_nearbyCourses[index].distance}km',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  GRAYSCALE_LABEL_800,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
      },
    );
  }

  // 코스 이미지를 표시하는 위젯
  Widget _buildCourseImage(
    String imagePath, {
    required double width,
    required double height,
  }) {
    // 이미지 경로가 http로 시작하면 네트워크 이미지, 아니면 에셋 이미지로 처리
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: width, height: height, color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Text('이미지 로딩중 에러'));
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: GRAYSCALE_LABEL_200,
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: GRAYSCALE_LABEL_500,
              ),
            ),
          );
        },
      );
    }
  }

  // 로딩 인디케이터 위젯
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: ORANGE_PRIMARY_500),
          SizedBox(height: 16),
          Text(
            "주변 공원 정보를 불러오는 중...",
            style: TextStyle(color: GRAYSCALE_LABEL_700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 주변 코스가 없을 때 표시할 메시지 위젯
  Widget _buildEmptyNearbyCoursesMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48, color: GRAYSCALE_LABEL_400),
          SizedBox(height: 16),
          Text(
            "반경 5km 이내에 추천할 코스가 없습니다.",
            style: TextStyle(
              color: GRAYSCALE_LABEL_700,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "다른 위치로 이동하거나 위치 권한을 확인해주세요.",
            style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
