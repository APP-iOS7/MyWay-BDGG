import 'package:flutter/material.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/screen/home/course_detail_screen.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _currentPark = widget.park;
  }

  Widget _buildUserRecordCardItem(StepModel record) {
    String formatDuration(String durationStr) {
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1]) ?? 0;
        int seconds = int.tryParse(parts[2]) ?? 0;
        String result = "";
        if (hours > 0) result += "$hours시간 ";
        if (minutes > 0 || hours > 0) result += "$minutes분 ";
        result += "$seconds초";
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CourseDetailScreen(
                  data: {
                    '이미지 Url': record.imageUrl,
                    '코스이름': record.courseName,
                    '종료시간': record.stopTime,
                    '거리': record.distance.toStringAsFixed(1),
                    '걸음수': record.steps,
                    '소요시간': formatDuration(record.duration),
                    '경로': record.route,
                  },
                ),
          ),
        );
      },
      child: Container(
        key: ValueKey('user_record_item_${record.id}'),
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
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
                          'assets/images/default_course_image.png',
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
                    record.courseName.isNotEmpty
                        ? record.courseName
                        : "코스 이름 없음",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GRAYSCALE_LABEL_950,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (record.parkName != null &&
                      record.parkName!.isNotEmpty) ...[
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
                  // Text(
                  //   "거리: ${record.distance.toStringAsFixed(1)}km",
                  //   style: const TextStyle(
                  //     fontSize: 12,
                  //     color: GRAYSCALE_LABEL_700,
                  //   ),
                  // ),
                  // Text(
                  //   "시간: ${formatDuration(record.duration)}",
                  //   style: const TextStyle(
                  //     fontSize: 12,
                  //     color: GRAYSCALE_LABEL_700,
                  //   ),
                  // ),
                  // Text(
                  //   "걸음: ${record.steps}보",
                  //   style: const TextStyle(
                  //     fontSize: 12,
                  //     color: GRAYSCALE_LABEL_700,
                  //   ),
                  // ),
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
      ),
    );
  }

  Widget _buildUserRecordsSection(ParkDataProvider provider) {
    if (provider.isLoadingUserRecords &&
        provider.allUserCourseRecords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: CircularProgressIndicator(color: BLUE_SECONDARY_500),
        ),
      );
    }

    if (provider.userRecordsError.isNotEmpty &&
        provider.allUserCourseRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            provider.userRecordsError,
            style: const TextStyle(color: RED_DANGER_TEXT_50, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final parkRecords =
        provider.allUserCourseRecords
            .where((record) => record.parkId == _currentPark.id)
            .toList();

    if (parkRecords.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: const Text(
          "이 공원에 대한 사용자 활동 기록이 아직 없습니다.",
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
        childAspectRatio: 1.0,
      ),
      itemCount: parkRecords.length,
      itemBuilder: (context, index) {
        final record = parkRecords[index];
        return _buildUserRecordCardItem(record);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  parkDataProvider.toggleParkFavorite(_currentPark.id);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    parkDataProvider.currentPosition != null)
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
                _buildUserRecordsSection(parkDataProvider),
              ],
            ),
          ),
        );
      },
    );
  }
}
