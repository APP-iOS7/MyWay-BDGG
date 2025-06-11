import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/park_info.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myway/util/csv_loader.dart';

import '../model/step_model.dart';

class ParkDataProvider extends ChangeNotifier {
  List<ParkInfo> _allParks = [];
  final Set<String> _favoriteParkIds = {};
  Position? _currentPosition;
  bool _isLoading = false;
  String _error = '';
  List<ParkInfo> nearbyParks = [];

  List<StepModel> _allUserCourseRecords = [];
  String _userRecordsError = '';
  bool _isLoadingUserRecords = false;
  bool _isLoadingLocation = false;
  bool _disposed = false; // dispose 상태 추적

  final List<ParkCourseInfo> _recommendedCourse = [];

  List<StepModel> get allUserCourseRecords => _allUserCourseRecords;
  String get userRecordsError => _userRecordsError;
  bool get isLoadingUserRecords => _isLoadingUserRecords;
  Set<String> get favoriteParkIds => _favoriteParkIds;
  bool get hasUserRecords => _allUserCourseRecords.isNotEmpty;
  bool get isLoadingLocation => _isLoadingLocation;
  List<ParkInfo> get allParks => _allParks;
  bool get isLoading => _isLoading;
  String get error => _error;
  Position? get currentPosition => _currentPosition;

  void setCurrentPosition(Position? position) {
    _currentPosition = position;
    _safeNotifyListeners();
  }

  List<ParkCourseInfo> get nearbyRecommendedCourses {
    const double radiusKm = 2.0;
    final nearbyParkIds =
        _allParks
            .where((park) => park.distanceKm < radiusKm)
            .map((park) => park.id)
            .toSet();

    return _recommendedCourse
        .where((course) => nearbyParkIds.contains(course.details.parkId))
        .toList();
  }

  bool isFavorite(String parkId) => _favoriteParkIds.contains(parkId);

  void toggleFavorite(String parkId) async {
    if (_favoriteParkIds.contains(parkId)) {
      _favoriteParkIds.remove(parkId);
    } else {
      _favoriteParkIds.add(parkId);
    }
    _safeNotifyListeners();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid);
      await docRef.set({
        'favorites': _favoriteParkIds.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firestore 찜 저장 실패: $e");
    }
  }

  Future<void> loadFavoritesFromFirestore() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['favorites'] is List) {
          _favoriteParkIds
            ..clear()
            ..addAll(List<String>.from(data['favorites']));
          _safeNotifyListeners();
        }
      }
    } catch (e) {
      print("Firestore 찜 불러오기 실패: $e");
    }
  }

  Future<void> loadParksFromCsv() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      _allParks = await loadParksFromCSV();
      _error = '';
    } catch (e) {
      _error = 'CSV 로딩 실패: $e';
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> fetchCurrentLocationAndCalculateDistance() async {
    _isLoadingLocation = true;
    _safeNotifyListeners();
    try {
      _currentPosition = await _determinePosition();
      for (final park in _allParks) {
        await park.calculateDistance(_currentPosition!);
      }

      _error = '';
    } catch (e) {
      _error = '위치 가져오기 실패: $e';
    }

    _isLoadingLocation = false;
    _safeNotifyListeners();
  }

  Future<void> initialize() async {
    await loadParksFromCsv();
    await fetchCurrentLocationAndCalculateDistance();
    await _fetchUserCourseRecordsInternal();
  }

  Future<void> _fetchUserCourseRecordsInternal() async {
    _isLoadingUserRecords = true;
    _userRecordsError = '';
    _safeNotifyListeners();

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
            if (recordData is Map<String, dynamic>) {
              try {
                records.add(StepModel.fromJson(recordData));
              } catch (e, s) {
                print(
                  "Error parsing StepModel from Firestore, record: $recordData, error: $e, stack: $s",
                );
              }
            }
          }
        }
      }
      print(records.length);
      _allUserCourseRecords = records;
      _allUserCourseRecords.sort((a, b) => b.stopTime.compareTo(a.stopTime));
    } catch (e, s) {
      print("Error fetching all user course records: $e, stack: $s");
      _userRecordsError = "사용자 활동 기록을 불러오는 중 오류가 발생했습니다.";
      _allUserCourseRecords = [];
    }

    _isLoadingUserRecords = false;
    _safeNotifyListeners();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
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

  void _safeNotifyListeners() {
    if (_disposed) return;

    try {
      _safeNotifyListeners();
    } catch (e) {
      print('MapProvider: notifyListeners 호출 중 오류 발생: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true; // dispose 상태 설정
    super.dispose();
  }
}
