import 'package:flutter/material.dart';
import 'package:myway/screen/alert/countdown_diallog.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/temp/course_data.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<MapProvider, StepProvider>(
      builder: (context, mapProvider, stepProvider, child) {
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
                            print('버튼 클릭');
                            if (Provider.of<MapProvider>(
                                  context,
                                  listen: false,
                                ).isMapLoading ==
                                false) {
                              print('내부');
                              mapProvider.setTracking(true);
                              mapProvider.showStartTrackingBottomSheet();
                              CountdownDiallog.show(
                                context,
                                onComplete: () {
                                  stepProvider.startTracking();
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (Provider.of<MapProvider>(
                                          context,
                                          listen: false,
                                        ).isMapLoading ==
                                        false)
                                    ? ORANGE_PRIMARY_500
                                    : GRAYSCALE_LABEL_300,
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
                              print("선택");
                              setState(() {
                                selectedIndex =
                                    selectedIndex == index ? null : index;
                                if (selectedIndex != null) {
                                  mapProvider.selectCourse(
                                    courses[selectedIndex!],
                                  );
                                } else {
                                  mapProvider.selectCourse(null);
                                }
                              });
                              print('selectedIndex: $selectedIndex');
                              print('course; ${mapProvider.selectedCourse}');
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
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Center(
                                          child: Text('이미지 로딩중 에러'),
                                        );
                                      },
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
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
      },
    );
  }
}
