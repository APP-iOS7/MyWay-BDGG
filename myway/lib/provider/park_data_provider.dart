import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Geolocator 경로 확인
import 'package:myway/model/park_info.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/services/park_api_service.dart'; // ParkApiService 경로 확인

class ParkDataProvider extends ChangeNotifier {
  final ParkApiService _parkApiService = ParkApiService();

  List<ParkInfo> _allFetchedParks = [];
  List<ParkCourseInfo> _allGeneratedRecommendedCourses = [];

  bool _isLoadingParks = false;
  bool get isLoadingParks => _isLoadingParks;
  bool _isLoadingRecommendedCourses = false;
  bool get isLoadingRecommendedCourses => _isLoadingRecommendedCourses;
  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;
  String _apiError = '';
  String get apiError => _apiError;
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  List<ParkInfo> get allFetchedParks => List.unmodifiable(_allFetchedParks);
  List<ParkCourseInfo> get allGeneratedRecommendedCourses =>
      List.unmodifiable(_allGeneratedRecommendedCourses);

  bool _hasDataBeenFetched = false;

  final Set<String> _favoriteParkIds = {};
  final Set<String> _favoriteCourseIds = {};

  Set<String> get favoriteParkIds => Set.unmodifiable(_favoriteParkIds);
  Set<String> get favoriteCourseIds => Set.unmodifiable(_favoriteCourseIds);

  void toggleParkFavorite(String parkId) {
    if (parkId.isEmpty) return;
    if (_favoriteParkIds.contains(parkId)) {
      _favoriteParkIds.remove(parkId);
    } else {
      _favoriteParkIds.add(parkId);
    }
    notifyListeners();
  }

  bool isParkFavorite(String parkId) {
    if (parkId.isEmpty) return false;
    return _favoriteParkIds.contains(parkId);
  }

  void toggleCourseFavorite(String courseId) {
    if (courseId.isEmpty) {
      print("Provider Error: toggleCourseFavorite called with empty courseId.");
      return;
    }
    final bool isCurrentlyFavoriteInSet = _favoriteCourseIds.contains(courseId);
    bool newFavoriteState;

    if (isCurrentlyFavoriteInSet) {
      _favoriteCourseIds.remove(courseId);
      newFavoriteState = false;
    } else {
      _favoriteCourseIds.add(courseId);
      newFavoriteState = true;
    }

    final courseIndex = _allGeneratedRecommendedCourses.indexWhere(
      (c) => c.id == courseId,
    );
    if (courseIndex != -1) {
      _allGeneratedRecommendedCourses[courseIndex].isFavorite =
          newFavoriteState;
    } else {
    }
    notifyListeners();
  }

  bool isCourseFavorite(String courseId) {
    if (courseId.isEmpty) return false;
    return _favoriteCourseIds.contains(courseId);
  }

  Future<void> fetchAllDataIfNeeded() async {
    if (_hasDataBeenFetched && _allFetchedParks.isNotEmpty) {
      bool coursesUpdated = false;
      List<ParkCourseInfo> updatedCourses =
          _allGeneratedRecommendedCourses.map((course) {
            bool currentFavStatusInSet = _favoriteCourseIds.contains(course.id);
            if (course.isFavorite != currentFavStatusInSet) {
              coursesUpdated = true;
              return course.copyWith(isFavorite: currentFavStatusInSet);
            }
            return course;
          }).toList();
      if (coursesUpdated) {
        _allGeneratedRecommendedCourses = updatedCourses;
      }
      return;
    }

    _isLoadingLocation = true;
    _isLoadingParks = true;
    _isLoadingRecommendedCourses = true;
    _apiError = '';
    notifyListeners();

    try {
      try {
        _currentPosition = await _determinePosition();
      } catch (e) {
        _apiError =
            e.toString().contains("Exception: ")
                ? e.toString().split("Exception: ")[1]
                : e.toString();
      } finally {
        _isLoadingLocation = false;
      }

      _allFetchedParks = await _parkApiService.fetchAllParks();
      if (_allFetchedParks.isNotEmpty && _currentPosition != null) {
        for (var park in _allFetchedParks) {
          await park.calculateDistance(_currentPosition!);
        }
      }

      if (_allFetchedParks.isNotEmpty) {
        _generateAllRecommendedCoursesInternal();
      }
      _hasDataBeenFetched = true;
    } catch (e) {
      String errorMessage =
          e.toString().contains("Exception: ")
              ? e.toString().split("Exception: ")[1]
              : e.toString();
      if (_apiError.isEmpty) _apiError = "데이터 로딩 실패: $errorMessage";
      _allFetchedParks = [];
      _allGeneratedRecommendedCourses = [];
    } finally {
      _isLoadingParks = false;
      _isLoadingRecommendedCourses = false;
      notifyListeners();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다. 앱을 사용하려면 권한이 필요합니다.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 직접 권한을 허용해주세요.');
    }
    return await Geolocator.getCurrentPosition();
  }

  void _generateAllRecommendedCoursesInternal() {
    List<ParkCourseInfo> tempCourses = [];
    for (var park in _allFetchedParks) {
      String course1Id = "course_${park.id}_1"; 
      tempCourses.add(
        ParkCourseInfo(
          id: course1Id,
          parkId: park.id,
          parkName: park.name,
          title: "${park.name} 힐링 산책로",
          details:
              "아름다운 자연 속에서 여유를 즐길 수 있는 ${park.name}의 대표 코스입니다. 약 45분 소요됩니다.",
          imagePath: 'assets/images/course_placeholder_1.png', 
          isFavorite: _favoriteCourseIds.contains(course1Id),
        ),
      );

      String course2Id = "course_${park.id}_2"; 
      tempCourses.add(
        ParkCourseInfo(
          id: course2Id,
          parkId: park.id,
          parkName: park.name,
          title: "${park.name} 활력 충전 코스",
          details:
              "가벼운 운동과 함께 상쾌한 공기를 마실 수 있는 ${park.name}의 인기 코스입니다. 약 1시간 15분 소요됩니다.",
          imagePath: 'assets/images/course_placeholder_2.png', 
          isFavorite: _favoriteCourseIds.contains(course2Id),
        ),
      );

      String course3Id = "course_${park.id}_3"; 
      tempCourses.add(
        ParkCourseInfo(
          id: course3Id,
          parkId: park.id,
          parkName: park.name,
          title: "${park.name} 가족 나들이길",
          details:
              "온 가족이 함께 즐거운 시간을 보낼 수 있는 ${park.name}의 평탄한 코스입니다. 다양한 편의시설이 있습니다.",
          imagePath: 'assets/images/course_placeholder_3.png',
          isFavorite: _favoriteCourseIds.contains(course3Id),
        ),
      );
    }
    _allGeneratedRecommendedCourses = tempCourses;
  }

  Future<void> refreshData() async {
    _hasDataBeenFetched = false;
    await fetchAllDataIfNeeded();
  }
}
