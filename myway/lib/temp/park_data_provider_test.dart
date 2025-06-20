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
      print('주소 정보: ${region.toString()}');
      print('administrativeArea: ${region.administrativeArea}');
      print('locality: ${region.locality}');
      print('subAdministrativeArea: ${region.subAdministrativeArea}');

      // 여러 형식으로 시도
      List<String> searchTargets =
          [
            '${region.administrativeArea} ${region.locality}',
            '${region.administrativeArea}',
            '${region.locality}',
            '${region.subAdministrativeArea}',
          ].where((s) => s.trim().isNotEmpty).toList();

      print('시도할 검색 지역들: $searchTargets');

      List<ParkInfo> allParks = [];

      // 지역 검색은 데이터가 적으므로 바로 전체 데이터 가져오기
      print('전체 공원 데이터를 가져온 후 거리로 필터링');

      // 먼저 API의 전체 데이터 수 확인
      try {
        print('1페이지로 전체 데이터 수 확인 중...');
        final firstPageData = await _parkApiService.fetchSinglePage(1, 10);
        final totalCount =
            firstPageData['response']?['body']?['totalCount'] ?? 0;
        print('API 전체 데이터 수: $totalCount');

        if (totalCount > 0) {
          // 전체 데이터를 가져오기 위해 필요한 페이지 수 계산
          final maxRowPerPage = 1000;
          final totalPages = (totalCount / maxRowPerPage).ceil();
          print('필요한 페이지 수: $totalPages');

          // 여러 페이지에서 공원 데이터 가져오기 (최대 10페이지)
          for (int page = 1; page <= totalPages && page <= 10; page++) {
            try {
              print('$page 페이지 로딩 중... ($page/$totalPages)');
              final pageParks = await _parkApiService.fetchParkPage(
                page,
                maxRowPerPage,
              );
              allParks.addAll(pageParks);
              print('$page 페이지에서 ${pageParks.length}개 공원 가져옴');

              // 데이터가 적으면 더 이상 페이지가 없다고 판단
              if (pageParks.length < maxRowPerPage) {
                print('$page 페이지가 마지막 페이지로 판단됨');
                break;
              }
            } catch (e) {
              print('$page 페이지 로딩 실패: $e');
              break;
            }
          }
        } else {
          throw Exception('API에서 전체 데이터 수를 확인할 수 없습니다');
        }
      } catch (e) {
        print('전체 데이터 가져오기 실패: $e');

        // fallback: 기본 3페이지만 가져오기
        print('fallback: 기본 3페이지만 가져오기');

        for (int page = 1; page <= 3; page++) {
          try {
            print('$page 페이지 로딩 중...');
            final pageParks = await _parkApiService.fetchParkPage(page, 1000);
            allParks.addAll(pageParks);
            print('$page 페이지에서 ${pageParks.length}개 공원 가져옴');

            // 데이터가 적으면 더 이상 페이지가 없다고 판단
            if (pageParks.length < 1000) {
              print('$page 페이지가 마지막 페이지로 판단됨');
              break;
            }
          } catch (e) {
            print('$page 페이지 로딩 실패: $e');
            break;
          }
        }
      }
      print('총 가져온 공원 수: ${allParks.length}');
      final parks = allParks;
      print('가져온 공원 수: ${parks.length}');

      // 각 공원의 거리 계산
      await Future.wait(
        parks.map((p) => p.calculateDistance(_currentPosition!)),
      );

      // 모든 공원의 거리 확인 (디버깅용)
      parks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      print('\n=== 모든 공원 거리 정보 (가까운 순) ===');
      for (int i = 0; i < parks.length && i < 20; i++) {
        final p = parks[i];
        print('${i + 1}. ${p.name} -> ${p.distanceKm.toStringAsFixed(2)}km');
        print(' 주소: ${p.address}');
        print(' 좌표: ${p.latitude}, ${p.longitude}');
      }
      print('===========================\n');
      // 2km 이내 공원 필터링 및 정렬
      _nearbyParks =
          parks.where((p) => p.distanceKm <= 5.0).toList()
            ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      print('5km 이내 공원 수: ${_nearbyParks.length}');
      for (final p in _nearbyParks) {
        print('${p.name} → ${p.distanceKm.toStringAsFixed(2)}km');
      }

      // 실제로는 2km 이내만 보여주가ㅣ
      final actual2kmParks = parks.where((p) => p.distanceKm <= 2.0).toList();
      print('\n실제 2km 이내 공원 수: ${actual2kmParks.length}');
      for (final p in actual2kmParks) {
        print('${p.name} -> ${p.distanceKm.toStringAsFixed(2)}km');
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
