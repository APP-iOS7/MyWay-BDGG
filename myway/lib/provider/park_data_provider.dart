import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/services/park_api_service.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkDataProvider extends ChangeNotifier {
  final ParkApiService _parkApiService = ParkApiService();

  List<ParkInfo> _allFetchedParks = [];
  List<ParkCourseInfo> _allGeneratedRecommendedCourses = [];
  List<StepModel> _allUserCourseRecords = [];

  bool _isLoadingParks = false;
  bool _isLoadingRecommendedCourses = false;
  bool _isLoadingUserRecords = false;
  bool _isLoadingLocation = false;
  String _apiError = '';
  String _userRecordsError = '';
  Position? _currentPosition;

  bool _hasDataBeenFetched = false;

  final Set<String> _favoriteParkIds = {};
  final Set<String> _favoriteCourseIds = {};

  // Getters
  bool get isLoadingParks => _isLoadingParks;
  bool get isLoadingRecommendedCourses => _isLoadingRecommendedCourses;
  bool get isLoadingUserRecords => _isLoadingUserRecords;
  bool get isLoadingLocation => _isLoadingLocation;
  String get apiError => _apiError;
  String get userRecordsError => _userRecordsError;
  Position? get currentPosition => _currentPosition;

  List<ParkInfo> get allFetchedParks => List.unmodifiable(_allFetchedParks);
  List<ParkCourseInfo> get allGeneratedRecommendedCourses => List.unmodifiable(_allGeneratedRecommendedCourses);
  List<StepModel> get allUserCourseRecords => List.unmodifiable(_allUserCourseRecords);
  
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
    }
    notifyListeners();
  }

  bool isCourseFavorite(String courseId) {
    if (courseId.isEmpty) return false;
    return _favoriteCourseIds.contains(courseId);
  }

  Future<void> fetchAllDataIfNeeded() async {
    if (_hasDataBeenFetched) return;

    _isLoadingLocation = true;
    _isLoadingParks = true;
    _isLoadingRecommendedCourses = true;
    _isLoadingUserRecords = true;
    _apiError = '';
    notifyListeners();

    try {
      try {
        _currentPosition = await _determinePosition();
      } catch (e) {
        _apiError = e.toString().contains("Exception: ")
            ? e.toString().split("Exception: ")[1]
            : e.toString();
      } finally {
        _isLoadingLocation = false;
      }

      _allFetchedParks = await _parkApiService.fetchAllParks();
      if (_allFetchedParks.isNotEmpty && _currentPosition != null) {
        await Future.wait(
          _allFetchedParks.map((park) => park.calculateDistance(_currentPosition!)),
        );
      }

      if (_allFetchedParks.isNotEmpty) {
        _generateAllRecommendedCoursesInternal();
      }
      
      await _fetchUserCourseRecordsInternal();

      _hasDataBeenFetched = true;
    } catch (e) {
      String errorMessage = e.toString().contains("Exception: ")
          ? e.toString().split("Exception: ")[1]
          : e.toString();
      if (_apiError.isEmpty) _apiError = "데이터 로딩 실패: $errorMessage";
      _allFetchedParks = [];
      _allGeneratedRecommendedCourses = [];
      _allUserCourseRecords = [];
    } finally {
      _isLoadingParks = false;
      _isLoadingRecommendedCourses = false;
      _isLoadingUserRecords = false;
      notifyListeners();
    }
  }
  
  Future<void> _fetchUserCourseRecordsInternal() async {
    _userRecordsError = '';
    try {
      final firestore = FirebaseFirestore.instance;
      final trackingResultCollection = firestore.collection('trackingResult');
      final querySnapshot = await trackingResultCollection.get();

      List<StepModel> records = [];
      for (var userDoc in querySnapshot.docs) {
        final userData = userDoc.data();
        if (userData.containsKey('TrackingResult') && userData['TrackingResult'] is List) {
          final List<dynamic> userTrackingResults = userData['TrackingResult'];
          for (var recordData in userTrackingResults) {
            if (recordData is Map<String, dynamic>) {
              try {
                records.add(StepModel.fromJson(recordData));
              } catch (e, s) {
                print("Error parsing StepModel from Firestore, record: $recordData, error: $e, stack: $s");
              }
            }
          }
        }
      }
      _allUserCourseRecords = records;
      _allUserCourseRecords.sort((a, b) => b.stopTime.compareTo(a.stopTime)); // 최신순 정렬
    } catch (e, s) {
      print("Error fetching all user course records: $e, stack: $s");
      _userRecordsError = "사용자 활동 기록을 불러오는 중 오류가 발생했습니다.";
      _allUserCourseRecords = [];
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
      double parkLat = double.tryParse(park.latitude ?? '0') ?? 0;
      double parkLon = double.tryParse(park.longitude ?? '0') ?? 0;
      if (parkLat == 0 || parkLon == 0) continue;

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
            imageUrl: park.parkImage.isNotEmpty ? park.parkImage : 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: shortRoute,
          ),
        ),
      );

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
            imageUrl: park.parkImage.isNotEmpty ? park.parkImage : 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: mediumRoute,
          ),
        ),
      );

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
            imageUrl: park.parkImage.isNotEmpty ? park.parkImage : 'assets/images/course_placeholder_1.png',
            parkId: park.id,
            parkName: park.name,
            route: longRoute,
          ),
        ),
      );
    }
    _allGeneratedRecommendedCourses = tempCourses;
  }

  List<LatLng> _generateRoute(double centerLat, double centerLon, double distanceKm) {
    List<LatLng> route = [];
    int points = 5;
    double radius = distanceKm / 2;

    route.add(LatLng(centerLat, centerLon));

    for (int i = 1; i <= points; i++) {
      double angle = (i * 2 * 3.14159) / points;
      double lat = centerLat + (radius * cos(angle) / 111.32);
      double lon = centerLon + (radius * sin(angle) / (111.32 * cos(centerLat * 3.14159 / 180)));
      route.add(LatLng(lat, lon));
    }

    route.add(LatLng(centerLat, centerLon));
    return route;
  }

  Future<void> refreshData() async {
    _hasDataBeenFetched = false;
    await fetchAllDataIfNeeded();
  }

  List<ParkInfo> get nearbyParks {
    const double nearbyFilterRadiusKm = 5.0;
    if (_currentPosition == null || _allFetchedParks.isEmpty) {
      return [];
    }
    final filteredParks = _allFetchedParks.where((park) => park.distanceKm < nearbyFilterRadiusKm).toList();
    filteredParks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return filteredParks;
  }

  List<ParkCourseInfo> get nearbyRecommendedCourses {
    if (_currentPosition == null || _allGeneratedRecommendedCourses.isEmpty) {
      return [];
    }
    final nearbyParkIds = nearbyParks.map((park) => park.id).toSet();
    return _allGeneratedRecommendedCourses.where((course) => nearbyParkIds.contains(course.details.parkId)).toList();
  }

  List<ParkInfo> get nearbyParks2km {
    const double nearbyFilterRadiusKm = 2.0;
    if (_currentPosition == null || _allFetchedParks.isEmpty) {
      return [];
    }
    final filteredParks2km = _allFetchedParks.where((park) => park.distanceKm < nearbyFilterRadiusKm).toList();
    filteredParks2km.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return filteredParks2km;
  }

  List<ParkCourseInfo> get nearbyRecommendedCourses2km {
    if (_currentPosition == null || _allGeneratedRecommendedCourses.isEmpty) {
      return [];
    }
    final nearbyParkIds2km = nearbyParks2km.map((park) => park.id).toSet();
    return _allGeneratedRecommendedCourses.where((course) => nearbyParkIds2km.contains(course.details.parkId)).toList();
  }
}