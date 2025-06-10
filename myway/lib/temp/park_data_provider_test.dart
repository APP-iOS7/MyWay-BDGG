import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myway/model/park_info.dart';
import 'package:myway/services/park_api_service.dart';

import '../model/step_model.dart';
import 'park_api_service_test.dart';

class ParkDataProviderTest extends ChangeNotifier {
  final ParkApiServiceTest _parkApiService = ParkApiServiceTest();

  /// pagination 상태
  final List<ParkInfo> _paginatedParks = [];
  List<ParkInfo> get paginatedParks => List.unmodifiable(_paginatedParks);

  int _currentPage = 1;
  final int _rowsPerPage = 300;

  bool _isPaginatedLoading = false;
  bool get isPaginatedLoading => _isPaginatedLoading;

  bool _hasMoreParks = true;
  bool get hasMoreParks => _hasMoreParks;

  String _apiError = '';
  String get apiError => _apiError;

  /// 위치 상태 (필요 시 사용)
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  List<ParkInfo> _nearbyParks = [];
  List<ParkInfo> get nearbyParks => List.unmodifiable(_nearbyParks);

  bool _isLoadingNearbyParks = false;
  bool get isLoadingNearbyParks => _isLoadingNearbyParks;

  bool _isLoadingUserRecords = false;
  bool get isLoadingUserRecords => _isLoadingUserRecords;

  List<StepModel> _allUserCourseRecords = [];
  List<StepModel> get allUserCourseRecords =>
      List.unmodifiable(_allUserCourseRecords);

  String _userRecordsError = '';
  String get userRecordsError => _userRecordsError;

  /// 초기 로딩 (1페이지)
  Future<void> loadInitialParkPage() async {
    _paginatedParks.clear();
    _currentPage = 1;
    _hasMoreParks = true;
    _apiError = '';
    _isPaginatedLoading = true;
    notifyListeners();

    try {
      final parks = await _parkApiService.fetchParkPage(
        _currentPage,
        _rowsPerPage,
      );
      _paginatedParks.addAll(parks);
      _currentPage++;
      _hasMoreParks = parks.length == _rowsPerPage;

      if (_currentPosition != null) {
        await Future.wait(
          parks.map((p) => p.calculateDistance(_currentPosition!)),
        );
      }
    } catch (e) {
      _apiError = '공원 초기 로딩 실패: $e';
    } finally {
      _isPaginatedLoading = false;
      notifyListeners();
    }
  }

  /// 다음 페이지 로딩
  Future<void> loadNextParkPage() async {
    if (_isPaginatedLoading || !_hasMoreParks) return;

    _isPaginatedLoading = true;
    notifyListeners();

    try {
      final parks = await _parkApiService.fetchParkPage(
        _currentPage,
        _rowsPerPage,
      );

      if (_currentPosition != null) {
        await Future.wait(
          parks.map((p) => p.calculateDistance(_currentPosition!)),
        );
      }
      _paginatedParks.addAll(parks);
      _currentPage++;
      _hasMoreParks = parks.length == _rowsPerPage;
    } catch (e) {
      _apiError = '공원 다음 페이지 로딩 실패: $e';
    } finally {
      _isPaginatedLoading = false;
      notifyListeners();
    }
  }

  /// 위치 정보 필요 시
  Future<void> fetchCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('위치 서비스 꺼짐');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('위치 권한 거부됨');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('위치 권한 영구 거부됨');
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      print('현재 위치: $_currentPosition');
      notifyListeners();
    } catch (e) {
      _apiError = '위치 정보 오류: $e';
    }
  }

  Future<void> fetchUserCourseRecordsInternal() async {
    _isLoadingUserRecords = true;
    _userRecordsError = '';
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
      _allUserCourseRecords = records;
      _allUserCourseRecords.sort(
        (a, b) => b.stopTime.compareTo(a.stopTime),
      ); // 최신순 정렬
    } catch (e, s) {
      print("Error fetching all user course records: $e, stack: $s");
      _userRecordsError = "사용자 활동 기록을 불러오는 중 오류가 발생했습니다.";
      _allUserCourseRecords = [];
    } finally {
      print(_allUserCourseRecords.length);

      _isLoadingUserRecords = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyParks2km() async {
    _isLoadingNearbyParks = true;
    _apiError = '';
    _nearbyParks.clear();
    notifyListeners();

    try {
      _currentPosition = await Geolocator.getCurrentPosition();

      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final region = placemarks.first;
      final targetInsttNm = '${region.administrativeArea} ${region.locality}';

      final parks = await _parkApiService.fetchParksByRegion(
        targetInsttNm: targetInsttNm,
      );

      await Future.wait(
        parks.map((p) => p.calculateDistance(_currentPosition!)),
      );

      _nearbyParks =
          parks.where((p) => p.distanceKm < 2.0).toList()
            ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      for (final p in parks) {
        print('${p.name} → ${p.distanceKm.toStringAsFixed(2)}km');
      }
    } catch (e) {
      _apiError = '2km 이내 공원 불러오기 실패: $e';
    } finally {
      _isLoadingNearbyParks = false;
      notifyListeners();
    }
  }
}
