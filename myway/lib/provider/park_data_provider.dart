import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Geolocator 경로 확인
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/services/park_api_service.dart'; // ParkApiService 경로 확인
import 'dart:math';

import 'package:uuid/uuid.dart';

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
      (c) => c.details.id == courseId,
    );
    if (courseIndex != -1) {
      _allGeneratedRecommendedCourses[courseIndex] =
          _allGeneratedRecommendedCourses[courseIndex].copyWith(
            isFavorite: newFavoriteState,
          );
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
            bool currentFavStatusInSet = _favoriteCourseIds.contains(
              course.details.id,
            );
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
      // 공원의 실제 위치를 기반으로 코스 경로 생성
      double parkLat = double.tryParse(park.latitude ?? '0') ?? 0;
      double parkLon = double.tryParse(park.longitude ?? '0') ?? 0;

      if (parkLat == 0 || parkLon == 0) continue;

      // 코스 1: 짧은 코스 (0.5km)
      String course1Id = "course_${park.id}_1";
      List<LatLng> shortRoute = _generateRoute(parkLat, parkLon, 0.5);
      tempCourses.add(
        ParkCourseInfo(
          title: park.name,
          park: park.name,
          date: DateTime.now(),
          parkId: park.id,
          parkName: park.name,
          isFavorite: _favoriteCourseIds.contains(course1Id),
          details: StepModel(
            id: Uuid().v4(),

            steps: 600,
            duration: '15',
            distance: 0.5,
            stopTime: '12:00',
            courseName: park.name,
            imageUrl:
                park.parkImage.isNotEmpty
                    ? park.parkImage
                    : 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: shortRoute,
          ),
        ),
      );

      // 코스 2: 중간 코스 (1.0km)
      String course2Id = "course_${park.id}_2";
      List<LatLng> mediumRoute = _generateRoute(parkLat, parkLon, 1.0);
      tempCourses.add(
        ParkCourseInfo(
          title: park.name,
          park: park.name,
          date: DateTime.now(),
          parkId: park.id,
          parkName: park.name,
          isFavorite: _favoriteCourseIds.contains(course2Id),
          details: StepModel(
            id: Uuid().v4(),
            steps: 1200,
            duration: '30',
            distance: 1.0,
            stopTime: '12:00',
            courseName: park.name,
            imageUrl:
                park.parkImage.isNotEmpty
                    ? park.parkImage
                    : 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: mediumRoute,
          ),
        ),
      );

      // 코스 3: 긴 코스 (1.5km)
      String course3Id = "course_${park.id}_3";
      List<LatLng> longRoute = _generateRoute(parkLat, parkLon, 1.5);
      tempCourses.add(
        ParkCourseInfo(
          title: park.name,
          park: park.name,
          date: DateTime.now(),
          parkId: park.id,
          parkName: park.name,
          isFavorite: _favoriteCourseIds.contains(course3Id),
          details: StepModel(
            id: Uuid().v4(),

            steps: 1800,
            duration: '45',
            distance: 1.5,
            stopTime: '12:00',
            courseName: park.name,
            imageUrl:
                park.parkImage.isNotEmpty
                    ? park.parkImage
                    : 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: longRoute,
          ),
        ),
      );
    }
    _allGeneratedRecommendedCourses = tempCourses;
  }

  // 주어진 중심점과 거리를 기반으로 경로 생성
  List<LatLng> _generateRoute(
    double centerLat,
    double centerLon,
    double distanceKm,
  ) {
    List<LatLng> route = [];
    int points = 5; // 경로 포인트 수
    double radius = distanceKm / 2; // 반경 (km)

    // 중심점을 시작점으로 추가
    route.add(LatLng(centerLat, centerLon));

    // 원형 경로 생성
    for (int i = 1; i <= points; i++) {
      double angle = (i * 2 * 3.14159) / points;
      double lat =
          centerLat + (radius * cos(angle) / 111.32); // 1도 = 약 111.32km
      double lon =
          centerLon +
          (radius * sin(angle) / (111.32 * cos(centerLat * 3.14159 / 180)));
      route.add(LatLng(lat, lon));
    }

    // 시작점으로 돌아오기
    route.add(LatLng(centerLat, centerLon));

    return route;
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
    const double nearbyFilterRadiusKm = 2.0; // 반경 2km 기준
    if (_currentPosition == null || _allFetchedParks.isEmpty) {
      return []; // 위치 정보가 없거나 공원 목록이 비어있으면 빈 리스트 반환
    }

    // 현재 위치에서 반경 2km 이내의 공원만 필터링
    final filteredParks2km =
        _allFetchedParks
            .where(
              (park) => (park.distanceKm) < nearbyFilterRadiusKm,
            ) // distanceInKm 사용
            .toList();

    // 거리에 따라 정렬 (선택 사항)
    filteredParks2km.sort((a, b) => (a.distanceKm).compareTo(b.distanceKm));

    return filteredParks2km;
  }

  // 반경 2km 이내 공원에 속한 추천 코스 목록을 반환하는 getter
  List<ParkCourseInfo> get nearbyRecommendedCourses2km {
    if (_currentPosition == null || _allGeneratedRecommendedCourses.isEmpty) {
      return []; // 위치 정보가 없거나 코스 목록이 비어있으면 빈 리스트 반환
    }

    // 2km 이내 공원의 ID 목록
    final nearbyParkIds2km =
        nearbyParks2km // 위에서 정의한 nearbyParks getter 사용
            .map((park) => park.id)
            .toSet();

    // 2km 이내 공원에 속한 코스만 필터링
    return _allGeneratedRecommendedCourses
        .where((course) => nearbyParkIds2km.contains(course.details.parkId))
        .toList();
  }
}
