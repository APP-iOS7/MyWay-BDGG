import 'package:flutter/material.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/park_course_info.dart';
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

  Widget _buildCourseCardItem(
    ParkCourseInfo course,
    ParkDataProvider provider,
  ) {
    // ★★★ 각 카드를 그릴 때 Provider로부터 최신 즐겨찾기 상태를 가져옵니다. ★★★
    bool isFavoriteNow = provider.isCourseFavorite(course.details.id);
    // print("Detail Build Card: ${course.title} (ID: ${course.id}), isFavorite from Provider: $isFavoriteNow");

    return Container(
      // 이 Container에 ValueKey를 주어 GridView.builder가 아이템을 명확히 식별하도록 함
      key: ValueKey(course.details.id),
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                    ),
                    child: Image.asset(
                      course.details.imageUrl.isNotEmpty
                          ? course.details.imageUrl
                          : 'assets/images/default_course_image.png',
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      // InkWell에도 고유한 Key를 부여하여 터치 이벤트 처리를 명확하게 합니다.
                      key: ValueKey(course.details.id),
                      onTap: () {
                        provider.toggleCourseFavorite(course.details.id);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isFavoriteNow
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              isFavoriteNow ? HEART_FILL : GRAYSCALE_LABEL_600,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.details.courseName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: GRAYSCALE_LABEL_950,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  course.details.distance.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  course.details.duration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GRAYSCALE_LABEL_700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPageMargin = 20.0;
    return Consumer<ParkDataProvider>(
      builder: (context, parkDataProvider, child) {
        final coursesForThisPark =
            parkDataProvider.allGeneratedRecommendedCourses
                .where((course) => course.details.parkId == _currentPark.id)
                .toList();
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
            padding: const EdgeInsets.fromLTRB(
              horizontalPageMargin,
              horizontalPageMargin,
              horizontalPageMargin,
              0,
            ),
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
                if (_currentPark.distanceKm < 99999.0)
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
                    "추천 코스 목록",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: GRAYSCALE_LABEL_900,
                    ),
                  ),
                ),
                coursesForThisPark.isEmpty
                    ? Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: const Text(
                        "이 공원의 추천 코스가 아직 없습니다.",
                        style: TextStyle(
                          color: GRAYSCALE_LABEL_600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 0.70,
                          ),
                      itemCount: coursesForThisPark.length,
                      itemBuilder: (context, index) {
                        // GridView.builder의 itemBuilder에서 반환하는 각 카드 아이템에 ValueKey를 부여합니다.
                        // _buildCourseCardItem 내부에서 이미 InkWell에 Key를 주었으므로,
                        // 여기서는 중복으로 Key를 줄 필요는 없지만,
                        // 만약 _buildCourseCardItem 자체가 StatefulWidget이라면 여기에 Key를 주는 것이 좋습니다.
                        // 지금은 _buildCourseCardItem이 StatelessWidget과 유사하게 동작하므로, 내부의 Key로 충분할 수 있습니다.
                        // 명확성을 위해 아이템 전체를 Key로 감싸는 것을 고려할 수 있습니다.
                        final course = coursesForThisPark[index];
                        return _buildCourseCardItem(course, parkDataProvider);
                      },
                    ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
