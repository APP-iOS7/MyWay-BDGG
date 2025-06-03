import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Geolocator 경로 확인
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/step_model.dart';
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
    } else {}
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
          title: 'test',
          park: 'test',
          date: DateTime.now(),
          parkId: park.id,
          parkName: park.name,
          id: course1Id,
          isFavorite: _favoriteCourseIds.contains(course1Id),
          details: StepModel(
            steps: 100,
            duration: '100',
            distance: '100',
            stopTime: '12:00',
            courseName: 'test',
            imageUrl: 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: [
              LatLng(37.40020, 126.93613),
              LatLng(37.400120, 126.93657),
              LatLng(37.39948, 126.93656),
              LatLng(37.39948, 126.93656),
              LatLng(37.399476, 126.937293),

              LatLng(37.39953, 126.93780),
              LatLng(37.400076, 126.938185),
              LatLng(37.400675, 126.93859),
              LatLng(37.40129, 126.93866),
              LatLng(37.401855, 126.938573),
              LatLng(37.40216, 126.93897),
            ],
          ),
        ),
      );

      String course2Id = "course_${park.id}_2";
      tempCourses.add(
        ParkCourseInfo(
          title: 'test',
          park: 'test',
          date: DateTime.now(),
          parkId: park.id,
          parkName: park.name,
          id: course2Id,
          isFavorite: _favoriteCourseIds.contains(course2Id),
          details: StepModel(
            steps: 100,
            duration: '100',
            distance: '100',
            stopTime: '12:00',
            courseName: 'test',
            imageUrl: 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: [
              LatLng(37.40020, 126.93613),
              LatLng(37.400120, 126.93657),
              LatLng(37.39948, 126.93656),
              LatLng(37.39948, 126.93656),
              LatLng(37.399476, 126.937293),

              LatLng(37.39953, 126.93780),
              LatLng(37.400076, 126.938185),
              LatLng(37.400675, 126.93859),
              LatLng(37.40129, 126.93866),
              LatLng(37.401855, 126.938573),
              LatLng(37.40216, 126.93897),
            ],
          ),
        ),
      );
      String course3Id = "course_${park.id}_3";
      tempCourses.add(
        ParkCourseInfo(
          title: 'test',
          park: 'test',
          date: DateTime.now(),
          parkId: park.id,
          parkName: park.name,
          id: course3Id,
          isFavorite: _favoriteCourseIds.contains(course3Id),
          details: StepModel(
            steps: 100,
            duration: '100',
            distance: '100',
            stopTime: '12:00',
            courseName: 'test',
            imageUrl: 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: [
              LatLng(37.40020, 126.93613),
              LatLng(37.400120, 126.93657),
              LatLng(37.39948, 126.93656),
              LatLng(37.39948, 126.93656),
              LatLng(37.399476, 126.937293),

              LatLng(37.39953, 126.93780),
              LatLng(37.400076, 126.938185),
              LatLng(37.400675, 126.93859),
              LatLng(37.40129, 126.93866),
              LatLng(37.401855, 126.938573),
              LatLng(37.40216, 126.93897),
            ],
          ),
        ),
      );
    }
    _allGeneratedRecommendedCourses = tempCourses;
  }

  Future<void> refreshData() async {
    _hasDataBeenFetched = false;
    await fetchAllDataIfNeeded();
  }

  // 반경 5km 이내의 공원 목록을 반환하는 getter
  List<ParkInfo> get nearbyParks {
    const double nearbyFilterRadiusKm = 5.0; // 반경 5km 기준
    if (_currentPosition == null || _allFetchedParks.isEmpty) {
      return []; // 위치 정보가 없거나 공원 목록이 비어있으면 빈 리스트 반환
    }

    // 현재 위치에서 반경 5km 이내의 공원만 필터링
    final filteredParks =
        _allFetchedParks
            .where(
              (park) => (park.distanceKm) < nearbyFilterRadiusKm,
            ) // distanceInKm 사용
            .toList();

    // 거리에 따라 정렬 (선택 사항)
    filteredParks.sort((a, b) => (a.distanceKm).compareTo(b.distanceKm));

    return filteredParks;
  }

  // 반경 5km 이내 공원에 속한 추천 코스 목록을 반환하는 getter
  List<ParkCourseInfo> get nearbyRecommendedCourses {
    if (_currentPosition == null || _allGeneratedRecommendedCourses.isEmpty) {
      return []; // 위치 정보가 없거나 코스 목록이 비어있으면 빈 리스트 반환
    }

    // 5km 이내 공원의 ID 목록
    final nearbyParkIds =
        nearbyParks // 위에서 정의한 nearbyParks getter 사용
            .map((park) => park.id)
            .toSet();

    // 5km 이내 공원에 속한 코스만 필터링
    return _allGeneratedRecommendedCourses
        .where((course) => nearbyParkIds.contains(course.details.parkId))
        .toList();
  }

  // 반경 2km 이내의 공원 목록을 반환하는 getter(course_recommended_bottom_sheet에 서 사용 )
  List<ParkInfo> get nearbyParks2km {
    const double nearbyFilterRadiusKm = 2.0; // 반경 5km 기준
    if (_currentPosition == null || _allFetchedParks.isEmpty) {
      return []; // 위치 정보가 없거나 공원 목록이 비어있으면 빈 리스트 반환
    }

    // 현재 위치에서 반경 2km 이내의 공원만 필터링
    final filteredParks =
        _allFetchedParks
            .where(
              (park) => (park.distanceKm) < nearbyFilterRadiusKm,
            ) // distanceInKm 사용
            .toList();

    // 거리에 따라 정렬 (선택 사항)
    filteredParks.sort((a, b) => (a.distanceKm).compareTo(b.distanceKm));

    return filteredParks;
  }

  // 반경 2km 이내 공원에 속한 추천 코스 목록을 반환하는 getter
  List<ParkCourseInfo> get nearbyRecommendedCourses2km {
    print("DEBUG nearbyRecommendedCourses2km: 현재 위치 = $_currentPosition");
    print(
      "DEBUG nearbyRecommendedCourses2km: 전체 코스 수 = ${_allGeneratedRecommendedCourses.length}",
    );

    if (_currentPosition == null || _allGeneratedRecommendedCourses.isEmpty) {
      print(
        "DEBUG nearbyRecommendedCourses2km: 빈 리스트 반환 - 위치=${_currentPosition != null}, 코스=${_allGeneratedRecommendedCourses.length}",
      );
      return []; // 위치 정보가 없거나 코스 목록이 비어있으면 빈 리스트 반환
    }

    // 2km 이내 공원의 ID 목록
    final nearbyParkIds =
        nearbyParks2km // 위에서 정의한 nearbyParks getter 사용
            .map((park) => park.id)
            .toSet();

    print(
      "DEBUG nearbyRecommendedCourses2km: 2km 내 공원 수 = ${nearbyParks2km.length}",
    );
    print("DEBUG nearbyRecommendedCourses2km: 2km 내 공원 IDs = $nearbyParkIds");

    // 각 코스의 parkId 출력
    for (var course in _allGeneratedRecommendedCourses) {
      print("DEBUG course: ID=${course.id}, parkId=${course.details.parkId}");
    }

    // 2km 이내 공원에 속한 코스만 필터링
    final result =
        _allGeneratedRecommendedCourses
            .where((course) => nearbyParkIds.contains(course.details.parkId))
            .toList();

    print("DEBUG nearbyRecommendedCourses2km: 필터링된 코스 수 = ${result.length}");
    return result;
  }
}
