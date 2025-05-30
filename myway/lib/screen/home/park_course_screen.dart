import 'package:flutter/material.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/park_course_info.dart'; // ParkCourseInfo 임포트
import '../../const/colors.dart';

class ParkCourseScreen extends StatefulWidget {
  final ParkInfo park;

  const ParkCourseScreen({super.key, required this.park});

  @override
  State<ParkCourseScreen> createState() => _ParkCourseScreenState();
}

class _ParkCourseScreenState extends State<ParkCourseScreen> {
  late ParkInfo _currentPark;
  List<ParkCourseInfo> _displayedCourses = [];
  // bool _isEditMode = false; // 편집 모드 관련 상태 제거
  bool _representativeParkIsFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentPark = widget.park;
    _generateExampleCoursesForCurrentPark();
    _representativeParkIsFavorite = false; // 실제로는 저장된 값에서 불러와야 함
  }

  void _generateExampleCoursesForCurrentPark() {
    _displayedCourses = [];
    _displayedCourses.add(
      ParkCourseInfo(
        id: 'course_${_currentPark.id}_1',
        parkId: _currentPark.id,
        parkName: _currentPark.name,
        title: "${_currentPark.name} 코스 1",
        details: "${_currentPark.name} 둘레길 산책",
        imagePath: 'assets/images/map_placeholder.png',
      ),
    );
    _displayedCourses.add(
      ParkCourseInfo(
        id: 'course_${_currentPark.id}_2',
        parkId: _currentPark.id,
        parkName: _currentPark.name,
        title: "${_currentPark.name} 코스 2",
        details: "${_currentPark.name} 호수변 힐링 코스",
        imagePath: 'assets/images/map_placeholder.png',
      ),
    );
    _displayedCourses.add(
      ParkCourseInfo(
        id: 'course_${_currentPark.id}_3',
        parkId: _currentPark.id,
        parkName: _currentPark.name,
        title: "${_currentPark.name} 코스 3",
        details: "${_currentPark.name} 숲속 탐방로",
        imagePath: 'assets/images/map_placeholder.png',
      ),
    );
    if (mounted) setState(() {});
  }

  // _toggleEditMode, _clearSelections, _deleteSelectedCourses, _addCourse 메서드 제거

  Widget _buildCourseCardItem(ParkCourseInfo course) {
    return GestureDetector(
      onTap: () {
        // print("View course: ${course.title}");
        // 코스 상세 화면으로 이동하는 로직 추가 가능
      },
      child: Container(
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
                        course.imagePath.isNotEmpty
                            ? course.imagePath
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
                        onTap: () {
                          if (mounted)
                            setState(
                              () => course.isFavorite = !course.isFavorite,
                            ); /* TODO: 즐겨찾기 저장 */
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            course.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                course.isFavorite
                                    ? HEART_FILL
                                    : GRAYSCALE_LABEL_600,
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
                    course.title,
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
                    course.details,
                    style: const TextStyle(
                      fontSize: 12,
                      color: GRAYSCALE_LABEL_700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPageMargin = 20.0;
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
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: Text(
          _currentPark.name,
          style: const TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [
          // "추가", "편집" 버튼 제거됨
          // 여기에 다른 액션 버튼이 필요하다면 추가할 수 있습니다. (예: 공유 버튼 등)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(horizontalPageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentPark.type.isNotEmpty)
                          Text(
                            _currentPark.type,
                            style: const TextStyle(
                              fontSize: 13,
                              color: GRAYSCALE_LABEL_600,
                            ),
                          ),
                        const SizedBox(height: 2),
                        if (_currentPark.address.isNotEmpty)
                          Text(
                            _currentPark.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: GRAYSCALE_LABEL_700,
                            ),
                          ),
                        if (_currentPark.distanceKm < 99999.0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "현재 위치에서 약 ${_currentPark.distanceKm.toStringAsFixed(1)}km",
                              style: const TextStyle(
                                fontSize: 12,
                                color: BLUE_SECONDARY_700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (mounted)
                          setState(
                            () =>
                                _representativeParkIsFavorite =
                                    !_representativeParkIsFavorite,
                          ); /* TODO: 공원 즐겨찾기 저장 */
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          _representativeParkIsFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              _representativeParkIsFavorite
                                  ? HEART_FILL
                                  : GRAYSCALE_LABEL_600,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: GRAYSCALE_LABEL_200, height: 20, thickness: 1),
            const Padding(
              padding: EdgeInsets.only(bottom: 10.0, top: 4.0),
              child: Text(
                "추천 코스 목록",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GRAYSCALE_LABEL_800,
                ),
              ),
            ),
            _displayedCourses.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.0),
                    child: Text(
                      "이 공원의 추천 코스가 아직 없습니다.",
                      style: TextStyle(
                        color: GRAYSCALE_LABEL_600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _displayedCourses.length,
                  itemBuilder: (context, index) {
                    return _buildCourseCardItem(_displayedCourses[index]);
                  },
                ),
          ],
        ),
      ),
    );
  }
}
