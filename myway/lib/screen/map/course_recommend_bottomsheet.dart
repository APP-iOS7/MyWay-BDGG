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
  List<StepModel> _allTrackingResults = []; // 모든 TrackingResult 데이터
  bool _isLoadingTrackingResults = false;

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
      final querySnapshot =
          await trackingResultCollection
              .get(); // Firestore에서 모든 사용자의 trackingResult 컬렉션을 가져옴

      List<StepModel> allResults = [];

      for (var userDoc in querySnapshot.docs) {
        final userData = userDoc.data();
        if (userData.containsKey('TrackingResult') &&
            userData['TrackingResult'] is List) {
          final List<dynamic> userTrackingResults = userData['TrackingResult'];

          for (var recordData in userTrackingResults) {
            final parkIdFromRecord = recordData['공원 ID'];

            print('원본 데이터: 코스이름=${recordData['코스이름']}, 공원ID=$parkIdFromRecord');

            // 1단계: parkId가 완전히 비어있거나 null인 경우 완전 제외
            if (parkIdFromRecord == null ||
                parkIdFromRecord.toString().trim().isEmpty ||
                parkIdFromRecord == 'null' ||
                parkIdFromRecord.toString() == 'null') {
              print('제외됨: parkId가 null/empty');
              continue;
            }

            // 2단계: 근처 공원에 포함되지 않으면 제외
            if (!nearbyParkIds.contains(parkIdFromRecord)) {
              print('제외됨: 근처 공원에 포함되지 않음');
              continue;
            }

            if (recordData is Map<String, dynamic>) {
              try {
                final stepModel = StepModel.fromJson(recordData);
                final parkId = parkIdFromRecord as String;

                print(
                  '데이터 확인: parkId=$parkId, stepModel.parkId=${stepModel.parkId}, courseName=${stepModel.courseName}',
                );

                // 3단계: stepModel에서도 다시 한번 확인
                if (stepModel.parkId != null &&
                    stepModel.parkId!.trim().isNotEmpty &&
                    stepModel.parkId != 'null' &&
                    stepModel.parkId == parkId) {
                  allResults.add(stepModel);
                  print('데이터 추가됨: $parkId - ${stepModel.courseName}');
                } else {
                  print('제외됨: stepModel parkId 검증 실패 (${stepModel.parkId})');
                }
              } catch (e) {
                print('운동 기록 데이터 변환 중 오류 발생: $e');
              }
            }
          }
        }
      }

      // ID 기준으로 중복 제거 및 최신순 정렬
      final unigueResults = <String, StepModel>{};
      for (final result in allResults) {
        final uniqueKey =
            result.id.isNotEmpty
                ? result.id
                : '${result.courseName}_${result.stopTime}_${result.parkId}';

        print(
          '결과 처리: ID=${result.id}, courseName=${result.courseName}, key=$uniqueKey',
        );

        if (!unigueResults.containsKey(uniqueKey)) {
          unigueResults[uniqueKey] = result;
          print('추가: $uniqueKey');
        } else {
          print('중복 제외: $uniqueKey');
        }
      }
      // 최신순으로 정렬 코드
      final deuplicatedResults = unigueResults.values.toList();
      deuplicatedResults.sort((a, b) => b.stopTime.compareTo(a.stopTime));

      print('전체 최종 결과: ${deuplicatedResults.length}개');
      for (int i = 0; i < deuplicatedResults.length; i++) {
        final result = deuplicatedResults[i];
        print(
          '$i: ${result.courseName} - ${result.parkName} (${result.stopTime})',
        );
      }
      if (mounted) {
        setState(() {
          _allTrackingResults = deuplicatedResults;
          _isLoadingTrackingResults = false;
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

  // 공원 정보를 가져오는 메서드
  ParkInfo? _getParkInfo(String parkId) {
    final parkDataProvider = Provider.of<ParkDataProvider>(
      context,
      listen: false,
    );

    try {
      return parkDataProvider.nearbyParks2km.firstWhere(
        (park) => park.id == parkId,
      );
    } catch (e) {
      return null;
    }
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
        // 조건이 맞으면 자동으로 TrackingResult 가져오기
        if (!parkDataProvider.isLoadingParks &&
            !parkDataProvider.isLoadingLocation &&
            _allTrackingResults.isEmpty &&
            !_isLoadingTrackingResults) {
          // 2km 이내 공원들의 TrackingResult 가져오기
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
                  if (selectedIndex != null && _allTrackingResults.isNotEmpty)
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
                              _allTrackingResults[selectedIndex!].courseName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              '${_allTrackingResults[selectedIndex!].distance.toStringAsFixed(1)}km',
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
                              : _allTrackingResults.isEmpty
                              ? _buildEmptyParksWithTrackingMessage() // 데이터가 없을때 표시되는 메시지 Widget
                              : GridView.builder(
                                controller: scrollSheetController,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, // 2열
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 0.72, // 카드의 가로:세로 비율 조정
                                    ),
                                itemCount: _allTrackingResults.length,
                                itemBuilder: (context, index) {
                                  final trackingResult =
                                      _allTrackingResults[index];
                                  final parkInfo = _getParkInfo(
                                    trackingResult.parkId!,
                                  );

                                  return SizedBox(
                                    height: 350, // 고정 높이 설정
                                    child: _buildTrackingCard(
                                      trackingResult,
                                      parkInfo,
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

  // 개별 TrackingResult 카드를 빌드하는 메서드
  Widget _buildTrackingCard(
    StepModel trackingResult,
    ParkInfo? parkInfo,
    int index,
  ) {
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
            // 트래킹 결과 이미지
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
                    trackingResult.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: trackingResult.imageUrl,
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
            // 코스이름
            Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: ORANGE_PRIMARY_500, size: 24),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trackingResult.courseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: GRAYSCALE_LABEL_950,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 공원이름
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trackingResult.parkName ?? parkInfo?.name ?? '공원 정보 없음',
                    style: TextStyle(color: GRAYSCALE_LABEL_700, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),

            // 트레킹 상세 정보
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildTrackingResultItem(trackingResult),
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
        int hours = int.tryParse(parts[0]) ?? 0; // 시
        int minutes = int.tryParse(parts[1]) ?? 0; // 분
        int seconds = int.tryParse(parts[2]) ?? 0; // 초

        // 시간이 있는경우
        if (hours > 0) {
          return '$hours시간 $minutes분';
        }
        // 분이 있는경우
        else if (minutes > 0) {
          return '$minutes분 $seconds초';
        }
        // 초만 있는 경우
        else {
          return '$seconds초';
        }
      }
      // 잘못된 형식이면 원본 문자열 반환
      return durationStr;
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
                Text(
                  '${result.distance}km',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: GRAYSCALE_LABEL_800,
                  ),
                  maxLines: 1,
                ),
                SizedBox(width: 4),
                Text(
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
