import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myway/model/park_info.dart';
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

  // /// 위치 정보 필요 시
  // Future<void> fetchCurrentPosition() async {
  //   try {
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) throw Exception('위치 서비스 꺼짐');

  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       if (permission == LocationPermission.denied) {
  //         throw Exception('위치 권한 거부됨');
  //       }
  //     }

  //     if (permission == LocationPermission.deniedForever) {
  //       throw Exception('위치 권한 영구 거부됨');
  //     }

  //     _currentPosition = await Geolocator.getCurrentPosition();
  //     print('현재 위치: $_currentPosition');
  //     notifyListeners();
  //   } catch (e) {
  //     _apiError = '위치 정보 오류: $e';
  //   }
  // }

  // Future<void> fetchNearbyParks2km() async {
  //   _isLoadingNearbyParks = true;
  //   _apiError = '';
  //   _nearbyParks.clear();
  //   notifyListeners();
  //   print('현재 위치: $_currentPosition');

  //   try {
  //     _currentPosition = await Geolocator.getCurrentPosition();

  //     final placemarks = await placemarkFromCoordinates(
  //       _currentPosition!.latitude,
  //       _currentPosition!.longitude,
  //     );
  //     final region = placemarks.first;
  //     final targetInsttNm = '${region.administrativeArea} ${region.locality}';

  //     final parks = await _parkApiService.fetchParksByRegion(
  //       targetInsttNm: targetInsttNm,
  //     );

  //     await Future.wait(
  //       parks.map((p) => p.calculateDistance(_currentPosition!)),
  //     );

  //     _nearbyParks =
  //         parks.where((p) => p.distanceKm < 2.0).toList()
  //           ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

  //     for (final p in parks) {
  //       print('${p.name} → ${p.distanceKm.toStringAsFixed(2)}km');
  //     }
  //   } catch (e) {
  //     _apiError = '2km 이내 공원 불러오기 실패: $e';
  //   } finally {
  //     _isLoadingNearbyParks = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchNearbyParks2km() async {
    _isLoadingNearbyParks = true;
    _apiError = '';
    _nearbyParks.clear();
    notifyListeners();

    try {
      // 🔥 위치 권한 체크 추가
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 활성화해주세요.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('위치 권한이 거부되었습니다. 권한을 허용해주세요.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 활성화해주세요.');
      }

      // 현재 위치 가져오기
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      print(
        '현재 위치: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );

      // 주소 정보 가져오기
      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isEmpty) {
        throw Exception('현재 위치의 주소 정보를 가져올 수 없습니다.');
      }

      final region = placemarks.first;
      final targetInsttNm = '${region.administrativeArea} ${region.locality}';
      print('검색 지역: $targetInsttNm');

      // 해당 지역의 공원들 가져오기
      final parks = await _parkApiService.fetchParksByRegion(
        targetInsttNm: targetInsttNm,
      );
      print('가져온 공원 수: ${parks.length}');

      // 각 공원의 거리 계산
      await Future.wait(
        parks.map((p) => p.calculateDistance(_currentPosition!)),
      );

      // 2km 이내 공원 필터링 및 정렬
      _nearbyParks =
          parks.where((p) => p.distanceKm <= 2.0).toList()
            ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      print('2km 이내 공원 수: ${_nearbyParks.length}');
      for (final p in _nearbyParks) {
        print('${p.name} → ${p.distanceKm.toStringAsFixed(2)}km');
      }

      if (_nearbyParks.isEmpty) {
        _apiError = '2km 이내에 공원이 없습니다.';
      }
    } catch (e) {
      _apiError = '2km 이내 공원 불러오기 실패: $e';
      print('에러 상세: $e');
    } finally {
      _isLoadingNearbyParks = false;
      notifyListeners();
    }
  }
}
