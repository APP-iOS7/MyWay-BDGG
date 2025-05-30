// provider/park_data_provider.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/services/park_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 사용자 ID 가져오기 위해
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용

class ParkDataProvider extends ChangeNotifier {
  final ParkApiService _parkApiService = ParkApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  List<ParkCourseInfo> get allGeneratedRecommendedCourses => List.unmodifiable(_allGeneratedRecommendedCourses);

  bool _hasDataBeenFetched = false;
  bool _favoritesLoadedFromFirestore = false;

  Set<String> _favoriteParkIds = {};
  Set<String> _favoriteCourseIds = {};

  Set<String> get favoriteParkIds => Set.unmodifiable(_favoriteParkIds);
  Set<String> get favoriteCourseIds => Set.unmodifiable(_favoriteCourseIds);

  ParkDataProvider() {
    // 사용자가 로그인하면 즐겨찾기를 로드합니다.
    // 또는 fetchAllDataIfNeeded 호출 시 로드할 수도 있습니다.
    // 여기서는 사용자 상태 변경을 감지하여 로드하는 것이 더 안정적일 수 있습니다.
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadFavoritesFromFirestore(user.uid);
      } else {
        // 로그아웃 시 즐겨찾기 초기화
        _favoriteParkIds.clear();
        _favoriteCourseIds.clear();
        _favoritesLoadedFromFirestore = false;
        notifyListeners();
      }
    });
    // 앱 시작 시 현재 사용자가 있다면 즉시 로드 시도
    User? currentUser = _auth.currentUser;
    if (currentUser != null && !_favoritesLoadedFromFirestore) {
        _loadFavoritesFromFirestore(currentUser.uid);
    }
  }

  Future<void> _loadFavoritesFromFirestore(String userId) async {
    if (userId.isEmpty || _favoritesLoadedFromFirestore) return;

    print("Provider: Loading favorites from Firestore for user $userId");
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _favoriteParkIds = Set<String>.from(data['favoriteParkIds'] as List<dynamic>? ?? []);
        _favoriteCourseIds = Set<String>.from(data['favoriteCourseIds'] as List<dynamic>? ?? []);
        print("Provider: Favorites loaded from Firestore - Parks: $_favoriteParkIds, Courses: $_favoriteCourseIds");
      } else {
        print("Provider: No favorite document found for user $userId. Initializing empty sets.");
        _favoriteParkIds = {};
        _favoriteCourseIds = {};
      }
      _favoritesLoadedFromFirestore = true;
    } catch (e) {
      print("Error loading favorites from Firestore: $e");
      _favoriteParkIds = {}; // 에러 시 안전하게 초기화
      _favoriteCourseIds = {};
    }
    // 즐겨찾기 로드 후 UI 갱신이 필요할 수 있음
    // fetchAllDataIfNeeded 내부에서 isFavorite 동기화 후 notifyListeners 호출
    notifyListeners(); // 로드 완료 알림
  }

  Future<void> _updateUserFavoritesInFirestore(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(userId).set({
        'favoriteParkIds': _favoriteParkIds.toList(),
        'favoriteCourseIds': _favoriteCourseIds.toList(),
      }, SetOptions(merge: true)); // merge:true는 다른 필드를 덮어쓰지 않음
      print("Provider: User favorites updated in Firestore for user $userId");
    } catch (e) {
      print("Error updating user favorites in Firestore: $e");
    }
  }

  void toggleParkFavorite(String parkId) {
    if (parkId.isEmpty) return;
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("Provider Error: User not logged in to toggle park favorite.");
      return;
    }

    if (_favoriteParkIds.contains(parkId)) {
      _favoriteParkIds.remove(parkId);
    } else {
      _favoriteParkIds.add(parkId);
    }
    _updateUserFavoritesInFirestore(currentUser.uid);
    notifyListeners();
  }

  bool isParkFavorite(String parkId) {
    if (parkId.isEmpty) return false;
    return _favoriteParkIds.contains(parkId);
  }

  void toggleCourseFavorite(String courseId) {
    if (courseId.isEmpty) { return; }
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("Provider Error: User not logged in to toggle course favorite.");
      return;
    }
    print("Provider: Toggling favorite for course ID: $courseId for user ${currentUser.uid}");

    final bool isCurrentlyFavoriteInSet = _favoriteCourseIds.contains(courseId);
    bool newFavoriteState;

    if (isCurrentlyFavoriteInSet) {
      _favoriteCourseIds.remove(courseId);
      newFavoriteState = false;
    } else {
      _favoriteCourseIds.add(courseId);
      newFavoriteState = true;
    }

    final courseIndex = _allGeneratedRecommendedCourses.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      _allGeneratedRecommendedCourses[courseIndex].isFavorite = newFavoriteState;
    }
    _updateUserFavoritesInFirestore(currentUser.uid);
    notifyListeners();
  }

  bool isCourseFavorite(String courseId) {
    if (courseId.isEmpty) return false;
    return _favoriteCourseIds.contains(courseId);
  }

  Future<void> fetchAllDataIfNeeded() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null && !_favoritesLoadedFromFirestore) {
      await _loadFavoritesFromFirestore(currentUser.uid); // 즐겨찾기 로드 보장
    }

    if (_hasDataBeenFetched && _allFetchedParks.isNotEmpty) {
      bool coursesUpdated = false;
      List<ParkCourseInfo> updatedCourses = _allGeneratedRecommendedCourses.map((course) {
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
       if(!_isLoadingParks && !_isLoadingRecommendedCourses && !_isLoadingLocation) {
          notifyListeners();
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
        _apiError = e.toString().contains("Exception: ") ? e.toString().split("Exception: ")[1] : e.toString();
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
      String errorMessage = e.toString().contains("Exception: ") ? e.toString().split("Exception: ")[1] : e.toString();
      if (_apiError.isEmpty) _apiError = "데이터 로딩 실패: $errorMessage";
      _allFetchedParks = [];
      _allGeneratedRecommendedCourses = [];
    } finally {
      _isLoadingParks = false;
      _isLoadingRecommendedCourses = false;
      notifyListeners();
    }
  }

  Future<Position> _determinePosition() async { /* 이전과 동일 */
    bool serviceEnabled; LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { return Future.error('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.'); }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { return Future.error('위치 권한이 거부되었습니다. 앱을 사용하려면 권한이 필요합니다.'); }
    }
    if (permission == LocationPermission.deniedForever) { return Future.error('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 직접 권한을 허용해주세요.'); }
    return await Geolocator.getCurrentPosition();
  }

  void _generateAllRecommendedCoursesInternal() {
    List<ParkCourseInfo> tempCourses = [];
    for (var park in _allFetchedParks) {
      String course1Id = "course_${park.id}_1";
      tempCourses.add(ParkCourseInfo(id: course1Id, parkId: park.id, parkName: park.name, title: "${park.name} 힐링 산책로", details: "자연 속에서 여유를 즐기는 코스.", imagePath: 'assets/images/course_placeholder_1.png', isFavorite: _favoriteCourseIds.contains(course1Id)));
      String course2Id = "course_${park.id}_2";
      tempCourses.add(ParkCourseInfo(id: course2Id, parkId: park.id, parkName: park.name, title: "${park.name} 활력 충전 코스", details: "운동과 함께 상쾌함을 느끼는 코스.", imagePath: 'assets/images/course_placeholder_2.png', isFavorite: _favoriteCourseIds.contains(course2Id)));
      String course3Id = "course_${park.id}_3";
      tempCourses.add(ParkCourseInfo(id: course3Id, parkId: park.id, parkName: park.name, title: "${park.name} 가족 나들이길", details: "온 가족이 함께하는 평탄한 코스.", imagePath: 'assets/images/course_placeholder_3.png', isFavorite: _favoriteCourseIds.contains(course3Id)));
    }
    _allGeneratedRecommendedCourses = tempCourses;
  }

  Future<void> refreshData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
        _favoritesLoadedFromFirestore = false; // 즐겨찾기 강제 재로드
        await _loadFavoritesFromFirestore(currentUser.uid);
    }
    _hasDataBeenFetched = false;
    await fetchAllDataIfNeeded();
  }
}