import 'package:flutter/material.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/step_model.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../provider/park_data_provider.dart'; 
import '../../const/colors.dart';

class ParkDetailScreen extends StatefulWidget {
  final ParkInfo park;
  const ParkDetailScreen({super.key, required this.park});

  @override
  State<ParkDetailScreen> createState() => _ParkDetailScreenState();
}

class _ParkDetailScreenState extends State<ParkDetailScreen> {
  late ParkInfo _currentPark;

  List<StepModel> _userCourseRecords = [];
  bool _isLoadingUserRecords = false;
  String _userRecordsError = '';

  @override
  void initState() {
    super.initState();
    _currentPark = widget.park;
    _fetchUserCourseRecords();
  }

  Future<void> _fetchUserCourseRecords() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUserRecords = true;
      _userRecordsError = '';
      _userCourseRecords = [];
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final trackingResultCollection = firestore.collection('trackingResult');
      final querySnapshot = await trackingResultCollection.get();

      List<StepModel> records = [];
      for (var userDoc in querySnapshot.docs) {
        final userData = userDoc.data();
        if (userData.containsKey('TrackingResult') &&
            userData['TrackingResult'] is List) {
          final List<dynamic> userTrackingResults = userData['TrackingResult'];
          for (var recordData in userTrackingResults) {
            // 현재 공원의 ID와 일치하는 기록만 필터링
            if (recordData is Map<String, dynamic> &&
                recordData['공원 ID'] == _currentPark.id) {
              try {
                records.add(StepModel.fromJson(recordData));
              } catch (e, s) {
                print(
                  "Error parsing StepModel from Firestore for park ${_currentPark.id}, record: $recordData, error: $e",
                );
                print("Stack trace: $s");
              }
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _userCourseRecords = records;
          _userCourseRecords.sort(
            (a, b) => b.stopTime.compareTo(a.stopTime),
          ); // 최신순 정렬
          _isLoadingUserRecords = false;
        });
      }
    } catch (e, s) {
      print("Error fetching user course records: $e");
      print("Stack trace: $s");
      if (mounted) {
        setState(() {
          _userRecordsError = "사용자 활동 기록을 불러오는 중 오류가 발생했습니다.";
          _isLoadingUserRecords = false;
        });
      }
    }
  }

  // 사용자 활동 기록 카드 아이템
  Widget _buildUserRecordCardItem(StepModel record) {
    String formatDuration(String durationStr) {
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1]) ?? 0;
        int seconds = int.tryParse(parts[2]) ?? 0;
        String result = "";
        if (hours > 0) result += "${hours}시간 ";
        if (minutes > 0 || hours > 0) result += "${minutes}분 ";
        result += "${seconds}초";
        return result.trim().isEmpty ? "0초" : result.trim();
      }
      return durationStr;
    }

    String formatStopTime(String stopTimeStr) {
      try {
        DateTime dt = DateTime.parse(stopTimeStr);
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        return stopTimeStr;
      }
    }

    return Container(
      key: ValueKey(
        'user_record_item_${record.parkId}_${record.stopTime}_${record.courseName}_${record.imageUrl}',
      ), // Key 고유성 강화
      decoration: BoxDecoration(
        color: BACKGROUND_COLOR,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(32, 32, 32, 0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12.0),
              ),
              child:
                  record.imageUrl.isNotEmpty
                      ? Image.network(
                        record.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: BLUE_SECONDARY_500,
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: GRAYSCALE_LABEL_400,
                                size: 40,
                              ),
                            ),
                      )
                      : Image.asset(
                        'assets/images/default_course_image.png', // 기본 이미지 경로
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: GRAYSCALE_LABEL_400,
                                size: 40,
                              ),
                            ),
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.courseName.isNotEmpty ? record.courseName : "코스 이름 없음",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GRAYSCALE_LABEL_950,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.parkName != null && record.parkName!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    record.parkName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GRAYSCALE_LABEL_500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  "거리: ${record.distance.toStringAsFixed(1)}km",
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                ),
                Text(
                  "시간: ${formatDuration(record.duration)}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                ),
                Text(
                  "걸음: ${record.steps}보",
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                ),
                Text(
                  formatStopTime(record.stopTime),
                  style: const TextStyle(
                    fontSize: 10,
                    color: GRAYSCALE_LABEL_600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 사용자 활동 기록 섹션 UI
  Widget _buildUserRecordsSection() {
    if (_isLoadingUserRecords) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: CircularProgressIndicator(color: BLUE_SECONDARY_500),
        ),
      );
    }

    if (_userRecordsError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            _userRecordsError,
            style: const TextStyle(color: RED_DANGER_TEXT_50, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_userCourseRecords.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: const Text(
          "이 공원에 대한 다른 사용자들의 활동 기록이 아직 없습니다.",
          style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.68,
      ),
      itemCount: _userCourseRecords.length,
      itemBuilder: (context, index) {
        final record = _userCourseRecords[index];
        return _buildUserRecordCardItem(record);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPageMargin = 20.0;
    // ParkDataProvider는 공원 즐겨찾기 기능을 위해 Consumer로 감싸는 것을 유지합니다.
    return Consumer<ParkDataProvider>(
      builder: (context, parkDataProvider, child) {
        bool isCurrentParkFavorite = parkDataProvider.isParkFavorite(
          _currentPark.id,
        );

        return Scaffold(
          backgroundColor: BACKGROUND_COLOR,
          appBar: AppBar(
            backgroundColor: BACKGROUND_COLOR,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: GRAYSCALE_LABEL_950,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _currentPark.name,
              style: const TextStyle(
                color: GRAYSCALE_LABEL_950,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  isCurrentParkFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                      isCurrentParkFavorite ? HEART_FILL : GRAYSCALE_LABEL_600,
                  size: 26,
                ),
                onPressed: () {
                  // ParkDataProvider를 통해 공원 즐겨찾기 상태 토글
                  parkDataProvider.toggleParkFavorite(_currentPark.id);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              horizontalPageMargin,
              horizontalPageMargin,
              horizontalPageMargin,
              20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 공원 기본 정보
                if (_currentPark.type.isNotEmpty)
                  Text(
                    _currentPark.type,
                    style: const TextStyle(
                      fontSize: 14,
                      color: GRAYSCALE_LABEL_700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                if (_currentPark.address.isNotEmpty)
                  Text(
                    _currentPark.address,
                    style: const TextStyle(
                      fontSize: 15,
                      color: GRAYSCALE_LABEL_800,
                    ),
                  ),
                if (_currentPark.distanceKm < 99999.0 &&
                    parkDataProvider.currentPosition !=
                        null) // 현재 위치가 있을 때만 거리 표시
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      "현재 위치에서 약 ${_currentPark.distanceKm.toStringAsFixed(1)}km",
                      style: const TextStyle(
                        fontSize: 13,
                        color: BLUE_SECONDARY_700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Divider(
                  color: GRAYSCALE_LABEL_200,
                  height: 24,
                  thickness: 1,
                ),

                // "추천 코스 목록" 섹션은 완전히 제거됨

                // 사용자 활동 기록
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0, top: 4.0),
                  child: Text(
                    "이 공원에서의 사용자 활동 기록",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: GRAYSCALE_LABEL_900,
                    ),
                  ),
                ),
                _buildUserRecordsSection(),
              ],
            ),
          ),
        );
      },
    );
  }
}

