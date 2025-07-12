import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/park_info.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myway/util/csv_loader.dart';
import 'package:flutter/scheduler.dart';

import '../model/step_model.dart';

// 상수들을 클래스로 분리
class ParkDataConstants {
  static const int recordsPerPage = 20;
  static const int maxRecords = 1000;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

class ParkDataProvider extends ChangeNotifier {
  List<ParkInfo> _allParks = [];
  final Set<String> _favoriteParkIds = {};
  Position? _currentPosition;
  bool _isLoading = false;
  String _error = '';
  List<ParkInfo> nearbyParks = [];

  // 페이징 관련 변수들
  DocumentSnapshot? _lastDocument;
  bool _hasMoreRecords = true;
  int _retryAttempts = 0;

  List<StepModel> _allUserCourseRecords = [];
  String _userRecordsError = '';
  bool _isLoadingUserRecords = false;
  bool _isLoadingLocation = false;
  bool _disposed = false;

  // 중복 방지를 위한 Set
  final Set<String> _processedRecordIds = {};

  // CSV 로드 상태 추적
  bool _csvLoaded = false;
  bool get csvLoaded => _csvLoaded;

  final List<ParkCourseInfo> _recommendedCourse = [];

  // Getters
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
    // 이미 로드되어 있으면 중복 로딩 방지
    if (_allParks.isNotEmpty) {
      print('CSV 데이터가 이미 로드되어 있어서 건너뜀');
      return;
    }

    // 이미 로딩 중이면 중복 호출 방지
    if (_isLoading) {
      print('CSV 데이터 로딩 중이어서 건너뜀');
      return;
    }

    _isLoading = true;
    _safeNotifyListeners();

    try {
      print('CSV 데이터 로딩 시작');
      _allParks = await loadParksFromCSV();
      _error = '';
      _csvLoaded = true;
      print('CSV 데이터 로딩 완료: ${_allParks.length}개 공원');
    } catch (e) {
      _error = 'CSV 로딩 실패: $e';
      _csvLoaded = false;
      print('CSV 로딩 실패: $e');
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> fetchCurrentLocationAndCalculateDistance() async {
    _isLoadingLocation = true;
    _safeNotifyListeners();
    try {
      _currentPosition = await _determinePosition();

      // 병렬 처리로 성능 개선
      final futures = _allParks.map(
        (park) => park.calculateDistance(_currentPosition!),
      );
      await Future.wait(futures);

      _error = '';
    } catch (e) {
      _error = '위치 가져오기 실패: $e';
    }

    _isLoadingLocation = false;
    _safeNotifyListeners();
  }

  // provider에 에러 메시지 저장
  String _initError = '';
  String get initError => _initError;

  Future<void> initialize() async {
    try {
      print('ParkDataProvider 초기화 시작');
      print('초기화 시작 시 공원 데이터 개수: ${_allParks.length}');
      _resetUserRecords();

      // CSV 데이터는 홈스크린에서만 로드하므로 여기서는 건너뜀
      if (_allParks.isEmpty) {
        print('CSV 데이터가 없지만 홈스크린에서 로드할 예정이므로 건너뜀');
      } else {
        print('CSV 데이터가 이미 로드되어 있음: ${_allParks.length}개');
      }

      // 위치 정보와 사용자 레코드를 병렬로 처리
      await Future.wait([
        fetchCurrentLocationAndCalculateDistance(),
        loadMoreUserCourseRecords(),
      ]);

      _initError = '';
      print('ParkDataProvider 초기화 완료');
      print('최종 공원 데이터 개수: ${_allParks.length}');
    } catch (e) {
      _initError = '초기화 중 오류: $e';
      print('ParkDataProvider 초기화 실패: $e');
      _safeNotifyListeners();
    }
  }

  // 사용자 레코드만 독립적으로 초기화하는 메서드 추가
  Future<void> initializeUserRecords() async {
    try {
      print('사용자 레코드 초기화 시작');
      _resetUserRecords();
      await loadMoreUserCourseRecords();
      print('사용자 레코드 초기화 완료: ${_allUserCourseRecords.length}개');
    } catch (e) {
      print('사용자 레코드 초기화 실패: $e');
      _userRecordsError = '사용자 레코드 초기화 실패: $e';
      _safeNotifyListeners();
    }
  }

  void _resetUserRecords() {
    _allUserCourseRecords.clear();
    _processedRecordIds.clear();
    _lastDocument = null;
    _hasMoreRecords = true;
    _retryAttempts = 0;
    _userRecordsError = '';
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
      await _fetchUserCourseRecords();
      _retryAttempts = 0; // 성공 시 재시도 횟수 리셋
    } catch (e) {
      await _handleLoadError(e);
    } finally {
      _isLoadingUserRecords = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _fetchUserCourseRecords() async {
    final firestore = FirebaseFirestore.instance;
    final trackingResultCollection = firestore.collection('trackingResult');

    // 디버깅을 위해 orderBy 제거하고 단순 쿼리로 변경
    Query query = trackingResultCollection.limit(
      ParkDataConstants.recordsPerPage,
    );

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final querySnapshot = await query.get();

    print('Firestore 쿼리 결과: ${querySnapshot.docs.length}개 문서');

    if (querySnapshot.docs.isEmpty) {
      print('Firestore에서 문서를 찾을 수 없습니다.');
      _hasMoreRecords = false;
      return;
    }

    // 마지막 문서 저장 (다음 페이징용)
    _lastDocument = querySnapshot.docs.last;

    final List<StepModel> newRecords = [];
    int validRecordsCount = 0;

    for (var userDoc in querySnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>?;
      print('문서 ID: ${userDoc.id}, 데이터 키: ${userData?.keys.toList()}');

      if (userData != null &&
          userData.containsKey('TrackingResult') &&
          userData['TrackingResult'] is List) {
        final List<dynamic> userTrackingResults = userData['TrackingResult']!;
        print('TrackingResult 배열 크기: ${userTrackingResults.length}');

        for (var recordData in userTrackingResults) {
          if (recordData is Map<String, dynamic>) {
            try {
              final stepModel = StepModel.fromJson(recordData);
              print('StepModel 파싱 성공: ${stepModel.courseName}');

              // 중복 체크
              if (!_processedRecordIds.contains(stepModel.id)) {
                _processedRecordIds.add(stepModel.id);
                newRecords.add(stepModel);
                validRecordsCount++;
                print('새 레코드 추가: ${stepModel.courseName}');
              } else {
                print('중복 레코드 건너뜀: ${stepModel.courseName}');
              }
            } catch (e, s) {
              print('Error parsing StepModel: $e, stack: $s');
              print('문제가 된 데이터: $recordData');
              // 개별 레코드 파싱 실패는 로그만 남기고 계속 진행
            }
          } else {
            print('recordData가 Map이 아님: ${recordData.runtimeType}');
          }
        }
      } else {
        print('TrackingResult 필드가 없거나 List가 아님');
      }
    }

    // 새 레코드 추가 및 정렬
    print('처리된 레코드 수: $validRecordsCount');
    print('새로 추가된 레코드 수: ${newRecords.length}');
    print('전체 레코드 수: ${_allUserCourseRecords.length}');

    if (newRecords.isNotEmpty) {
      _allUserCourseRecords.addAll(newRecords);
      _allUserCourseRecords.sort((a, b) => b.stopTime.compareTo(a.stopTime));

      // 메모리 관리: 최대 레코드 수 제한
      _manageMemoryUsage();
    } else {
      print('새 레코드가 없습니다.');
    }

    // 더 불러올 데이터가 있는지 확인
    if (querySnapshot.docs.length < ParkDataConstants.recordsPerPage) {
      _hasMoreRecords = false;
      print('더 이상 불러올 데이터가 없습니다.');
    }
  }

  void _manageMemoryUsage() {
    if (_allUserCourseRecords.length > ParkDataConstants.maxRecords) {
      // 가장 오래된 레코드들 제거
      final recordsToKeep =
          _allUserCourseRecords.take(ParkDataConstants.maxRecords).toList();

      _allUserCourseRecords = recordsToKeep;

      // processedRecordIds도 정리
      final keptIds = recordsToKeep.map((record) => record.id).toSet();
      _processedRecordIds.retainAll(keptIds);
    }
  }

  Future<void> _handleLoadError(dynamic error) async {
    _retryAttempts++;

    if (_retryAttempts <= ParkDataConstants.maxRetryAttempts) {
      // 재시도 로직
      await Future.delayed(ParkDataConstants.retryDelay);
      _userRecordsError =
          '데이터 로딩 중 오류가 발생했습니다. 재시도 중... ($_retryAttempts/${ParkDataConstants.maxRetryAttempts})';
      _safeNotifyListeners();

      // 재시도
      await _fetchUserCourseRecords();
    } else {
      // 최대 재시도 횟수 초과
      _hasMoreRecords = false;
      _setErrorMessage(error);
    }
  }

  void _setErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          _userRecordsError = '데이터 접근 권한이 없습니다.';
          break;
        case 'unavailable':
          _userRecordsError = '네트워크 연결을 확인해주세요.';
          break;
        case 'resource-exhausted':
          _userRecordsError = '서버 부하로 인해 일시적으로 사용할 수 없습니다.';
          break;
        default:
          _userRecordsError = '네트워크 오류: ${error.message}';
      }
    } else if (error is FormatException) {
      _userRecordsError = '데이터 형식 오류: ${error.message}';
    } else {
      _userRecordsError = '알 수 없는 오류가 발생했습니다: $error';
    }
  }

  // 메모리 정리 메서드
  void clearOldRecords() {
    if (_allUserCourseRecords.length > ParkDataConstants.maxRecords) {
      final recordsToKeep =
          _allUserCourseRecords.take(ParkDataConstants.maxRecords).toList();

      _allUserCourseRecords = recordsToKeep;
      _processedRecordIds.clear();
      _processedRecordIds.addAll(recordsToKeep.map((record) => record.id));

      _safeNotifyListeners();
    }
  }

  // 강제 새로고침
  Future<void> refreshUserRecords() async {
    _resetUserRecords();
    await loadMoreUserCourseRecords();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
