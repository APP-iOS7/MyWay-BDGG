import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/park_info.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myway/util/csv_loader.dart';
import 'package:flutter/scheduler.dart';

import '../model/step_model.dart';

class ParkDataProvider extends ChangeNotifier {
  List<ParkInfo> _allParks = [];
  final Set<String> _favoriteParkIds = {};
  Position? _currentPosition;
  bool _isLoading = false;
  String _error = '';
  List<ParkInfo> nearbyParks = [];
  int _lastFetchedPage = 0;
  final int _recordsPerPage = 20;

  List<StepModel> _allUserCourseRecords = [];
  String _userRecordsError = '';
  bool _isLoadingUserRecords = false;
  bool _isLoadingLocation = false;
  bool _disposed = false; // dispose 상태 추적
  bool _hasMoreRecords = true;

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
  bool get hasMoreRecords => _hasMoreRecords;
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
    _allUserCourseRecords.clear();
    _lastFetchedPage = 0;
    _hasMoreRecords = true;
    await loadParksFromCsv();
    await fetchCurrentLocationAndCalculateDistance();
    await loadMoreUserCourseRecords(); // 초기 1페이지만 로딩
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

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  Future<void> loadMoreUserCourseRecords() async {
    if (_isLoadingUserRecords || !_hasMoreRecords) return;

    _isLoadingUserRecords = true;
    _userRecordsError = '';
    _safeNotifyListeners();

    try {
      final firestore = FirebaseFirestore.instance;
      final trackingResultCollection = firestore.collection('trackingResult');

      // 페이징 처리: 전체 문서에서 _lastFetchedPage 기준으로 오프겟 적용
      final querySnapshot = await trackingResultCollection.get();
      final allDocs = querySnapshot.docs;

      final start = _lastFetchedPage * _recordsPerPage;
      final end = start + _recordsPerPage;

      if (start >= allDocs.length) {
        _hasMoreRecords = false;
      } else {
        final subDocs = allDocs.sublist(
          start,
          end > allDocs.length ? allDocs.length : end,
        );

        List<StepModel> newRecords = [];

        for (var userDoc in subDocs) {
          final userData = userDoc.data();
          if (userData.containsKey('TrackingResult') &&
              userData['TrackingResult'] is List) {
            final List<dynamic> userTrackingResults =
                userData['TrackingResult'];
            for (var recordData in userTrackingResults) {
              if (recordData is Map<String, dynamic>) {
                try {
                  newRecords.add(StepModel.fromJson(recordData));
                } catch (e, s) {
                  print('Error parsing StepModel: $e, stack: $s');
                }
              }
            }
          }
        }

        _allUserCourseRecords.addAll(newRecords);
        _allUserCourseRecords.sort((a, b) => b.stopTime.compareTo(a.stopTime));
        _lastFetchedPage++;

        if (subDocs.length < _recordsPerPage) {
          _hasMoreRecords = false;
        }
      }
    } catch (e, s) {
      print('Error loading paginated records: $e, stack: $s');
      _userRecordsError = '코스 데이터를 불러오지 못했습니다.';
    }

    _isLoadingUserRecords = false;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true; // dispose 상태 설정
    super.dispose();
  }
}
