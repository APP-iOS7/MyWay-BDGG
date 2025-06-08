import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/provider/park_data_provider.dart';
import 'package:myway/screen/alert/countdown_diallog.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/step_model.dart';
import '/const/colors.dart';
import '/provider/map_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CourseRecommendBottomsheet extends StatefulWidget {
  const CourseRecommendBottomsheet({super.key});

  @override
  State<CourseRecommendBottomsheet> createState() =>
      _CourseRecommendBottomsheetState();
}

class _CourseRecommendBottomsheetState
    extends State<CourseRecommendBottomsheet> {
  int? selectedIndex;
  Map<String, List<StepModel>> _parkTrackingResults = {};
  bool _isLoadingTrackingResults = false;
  List<ParkInfo> _parksWithTrackingResults = [];

  // Firestore에서 2km 이내 공원들의 TrackingResult를 가져오는 메서드
  Future<void> _fetchTrackingResultsForNearbyParks(
    List<String> nearbyParkIds,
  ) async {
    if (nearbyParkIds.isEmpty) return;

    if (!mounted) return;

    setState(() {
      _isLoadingTrackingResults = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final trackingResultCollection = firestore.collection('trackingResult');
      final querySnapshot = await trackingResultCollection.get();

      Map<String, List<StepModel>> parkResults = {};

      for (var userDoc in querySnapshot.docs) {
        final userData = userDoc.data();
        if (userData.containsKey('TrackingResult') &&
            userData['TrackingResult'] is List) {
          final List<dynamic> userTrackingResults = userData['TrackingResult'];

          for (var recordData in userTrackingResults) {
            if (recordData is Map<String, dynamic> &&
                recordData['공원 ID'] != null &&
                nearbyParkIds.contains(recordData['공원 ID'])) {
              try {
                final stepModel = StepModel.fromJson(recordData);
                final parkId = recordData['공원 ID'] as String;

                if (!parkResults.containsKey(parkId)) {
                  parkResults[parkId] = [];
                }
                parkResults[parkId]!.add(stepModel);
              } catch (e) {
                print('운동 기록 데이터 변환 중 오류 발생: $e');
              }
            }
          }
        }
      }

      // 각 공원별로 최신순으로 정렬
      parkResults.forEach((parkId, results) {
        results.sort((a, b) => b.stopTime.compareTo(a.stopTime));
      });

      if (mounted) {
        setState(() {
          _parkTrackingResults = parkResults;
          _isLoadingTrackingResults = false;
          _updateParksWithTrackingResults();
        });
      }
    } catch (e) {
      print('운동 기록 데이터를 가져오는 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrackingResults = false;
        });
      }
    }
  }

  // TrackingResult가 있는 공원들만 필터링하는 메서드
  void _updateParksWithTrackingResults() {
    final parkDataProvider = Provider.of<ParkDataProvider>(
      context,
      listen: false,
    );

    _parksWithTrackingResults =
        parkDataProvider.nearbyParks2km
            .where((park) => _parkTrackingResults.containsKey(park.id))
            .toList();

    // 거리순으로 정렬
    _parksWithTrackingResults.sort(
      (a, b) => a.distanceKm.compareTo(b.distanceKm),
    );
  }

  @override
  void initState() {
    super.initState();
    // 컴포넌트가 초기화될 때 ParkDataProvider의 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parkDataProvider = Provider.of<ParkDataProvider>(
        context,
        listen: false,
      );
      parkDataProvider.fetchAllDataIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<MapProvider, StepProvider, ParkDataProvider>(
      builder: (context, mapProvider, stepProvider, parkDataProvider, child) {
        // TrackingResult 로딩 최적화
        if (!parkDataProvider.isLoadingParks &&
            !parkDataProvider.isLoadingLocation &&
            _parkTrackingResults.isEmpty &&
            !_isLoadingTrackingResults) {
          // 2km 이내 공원들의 TrackingResult 가져오기 (build 완료 후 실행)
          final nearbyParkIds =
              parkDataProvider.nearbyParks2km.map((park) => park.id).toList();
          if (nearbyParkIds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchTrackingResultsForNearbyParks(nearbyParkIds);
            });
          }
        }

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
                                    '내 주변 추천코스',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '내 주변 2km 이내 공원의 추천 코스 입니다.',
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
                              CountdownDialog.show(
                                context,
                                onComplete: () {
                                  stepProvider.startTracking();
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            overlayColor: Colors.transparent,
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
                  if (selectedIndex != null &&
                      _parksWithTrackingResults.isNotEmpty)
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
                              _parksWithTrackingResults[selectedIndex!].name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              '${_parksWithTrackingResults[selectedIndex!].distanceKm.toStringAsFixed(1)}km',
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

                  // TrackingResult가 있는 공원 리스트
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child:
                          parkDataProvider.isLoadingParks ||
                                  parkDataProvider.isLoadingLocation ||
                                  _isLoadingTrackingResults
                              ? _buildLoadingIndicator()
                              : _parksWithTrackingResults.isEmpty
                              ? _buildEmptyParksWithTrackingMessage()
                              : GridView.builder(
                                controller: scrollSheetController,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, // 2열
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 0.72, // 카드의 가로:세로 비율 조정
                                    ),
                                itemCount: _parksWithTrackingResults.length,
                                itemBuilder: (context, index) {
                                  final park = _parksWithTrackingResults[index];
                                  final trackingResults =
                                      _parkTrackingResults[park.id]!;

                                  return SizedBox(
                                    height: 300, // 고정 높이 설정
                                    child: _buildParkWithTrackingCard(
                                      park,
                                      trackingResults,
                                      index,
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

  // 로딩 인디케이터 위젯
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: ORANGE_PRIMARY_500),
          SizedBox(height: 16),
          Text(
            "주변 공원 정보를 불러오는 중입니다...",
            style: TextStyle(color: GRAYSCALE_LABEL_700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 주변 코스가 없을 때 표시할 메시지 위젯
  Widget _buildEmptyParksWithTrackingMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48, color: GRAYSCALE_LABEL_400),
          SizedBox(height: 16),
          Text(
            "반경 2km 이내에 추천할 코스가 없습니다.",
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

  // TrackingResult가 있는 공원 카드를 빌드하는 메서드
  Widget _buildParkWithTrackingCard(
    ParkInfo park,
    List<StepModel> trackingResults,
    int index,
  ) {
    // TackingResult 뿌리기
    final recentResults = trackingResults.toList();

    return Container(
      margin: EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: WHITE,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              selectedIndex == index ? ORANGE_PRIMARY_500 : GRAYSCALE_LABEL_200,
          width: selectedIndex == index ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GRAYSCALE_LABEL_200.withAlpha(128),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = selectedIndex == index ? null : index;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 공원 이미지 추가
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                color: GRAYSCALE_LABEL_200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child:
                    trackingResults.isNotEmpty &&
                            trackingResults[0].imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          // 비동기 처리
                          imageUrl: trackingResults[0].imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: ORANGE_PRIMARY_500,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => _buildDefaultImage(),
                        )
                        : _buildDefaultImage(),
              ),
            ),
            SizedBox(height: 8),
            // 공원 기본 정보
            Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: ORANGE_PRIMARY_500,
                        size: 24,
                      ),
                      Text(
                        trackingResults[0].courseName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GRAYSCALE_LABEL_950,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    park.name,
                    style: TextStyle(color: GRAYSCALE_LABEL_700, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),

            ...recentResults.map((result) => _buildTrackingResultItem(result)),
            if (trackingResults.length > 3)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '외 ${trackingResults.length - 3}개의 기록이 더 있습니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: GRAYSCALE_LABEL_500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // 최신 활동 기록들
          ],
        ),
      ),
    );
  }

  // 개별 TrackingResult 아이템을 빌드하는 메서드
  Widget _buildTrackingResultItem(StepModel result) {
    String formatDuration(String durationStr) {
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1]) ?? 0;
        int seconds = int.tryParse(parts[2]) ?? 0;
        if (hours > 0) {
          return '$hours시간 $minutes분';
        } else if (minutes > 0) {
          return '$minutes분 $seconds초';
        } else {
          return '$seconds초';
        }
      }
      return durationStr;
    }

    // String formatDate(String stopTimeStr) {
    //   try {
    //     DateTime dt = DateTime.parse(stopTimeStr);
    //     final now = DateTime.now();
    //     final difference = now.difference(dt);

    //     if (difference.inDays == 0) {
    //       return '오늘';
    //     } else if (difference.inDays == 1) {
    //       return '어제';
    //     } else if (difference.inDays < 7) {
    //       return '${difference.inDays}일 전';
    //     } else {
    //       return '${dt.month}/${dt.day}';
    //     }
    //   } catch (e) {
    //     return stopTimeStr;
    //   }
    // }

    String formatNumber(dynamic number) {
      if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(1)}k';
      }
      return number.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: GRAYSCALE_LABEL_100,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_walk, size: 16, color: Colors.green[600]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AutoSizeText(
                  '${formatNumber(result.distance)}km',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: GRAYSCALE_LABEL_800,
                  ),
                  maxLines: 1,
                ),
                SizedBox(width: 4),
                AutoSizeText(
                  formatDuration(result.duration),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: GRAYSCALE_LABEL_800,
                  ),
                  // overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 기본 이미지 위젯
  Widget _buildDefaultImage() {
    return Container(
      color: GRAYSCALE_LABEL_200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: GRAYSCALE_LABEL_400,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              '이미지 없음',
              style: TextStyle(color: GRAYSCALE_LABEL_500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
