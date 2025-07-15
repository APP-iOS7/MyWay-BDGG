import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myway/model/activity_period.dart';

import '../const/colors.dart';

// 데이터 상태를 더 정확하게 추적하기 위한 열거형
enum DataStatus {
  hasData, // 데이터가 있음
  noDataInPeriod, // 해당 기간에 데이터가 없음 (다른 기간에는 있을 수 있음)
  noDataAtAll, // 전체적으로 데이터가 없음
}

class ActivityLogProvider extends ChangeNotifier {
  // 현재 데이터 상태
  DataStatus _currentDataStatus = DataStatus.hasData;
  DataStatus get currentDataStatus => _currentDataStatus;

  // 주간 기록 관련
  String _selectedRange = '';
  String get selectedRange => _selectedRange;

  // 주간/월간 선택 상태
  ActivityPeriod _selectedPeriod = ActivityPeriod.weekly;
  ActivityPeriod get selectedPeriod => _selectedPeriod;

  // 날짜 관련 상태
  late DateTime _currentDate;
  DateTime get currentDate => _currentDate;

  // 통계 데이터
  double _totalDistance = 0;
  Duration _totalDuration = Duration.zero;
  int _totalCount = 0;
  int _totalSteps = 0;

  // Getters
  double get totalDistance => _totalDistance;
  String get formattedTotalDuration {
    if (_totalDuration == Duration.zero) {
      return '00시간 00분';
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_totalDuration.inHours);
    final minutes = twoDigits(_totalDuration.inMinutes.remainder(60));
    return '$hours시간 $minutes분';
  }

  int get totalCount => _totalCount;
  int get totalSteps => _totalSteps;

  // 데이터 상태 확인 메서드들
  bool get hasNoData => _currentDataStatus == DataStatus.noDataAtAll;
  bool get hasNoDataInCurrentPeriod =>
      _currentDataStatus == DataStatus.noDataInPeriod;
  bool get hasData => _currentDataStatus == DataStatus.hasData;

  // 데이터 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 현재 년월 정보
  int get currentYear => _currentDate.year;
  String get currentYearMonth => '$currentYear년 ${_currentDate.month}월';

  // 주간 범위 생성 (월요일~일요일 기준)
  List<String> get availableWeeklyRanges {
    final List<String> ranges = [];
    final now = DateTime.now();

    // 현재 날짜 기준으로 과거 12주 정도 생성
    for (int i = 11; i >= 0; i--) {
      final weekStart = _getMondayOfWeek(now.subtract(Duration(days: i * 7)));
      final weekEnd = weekStart.add(Duration(days: 6));

      final label =
          '${weekStart.month}월 ${weekStart.day}일 ~ ${weekEnd.month}월 ${weekEnd.day}일';
      ranges.add(label);
    }

    return ranges;
  }

  // 월요일 찾기 (주의 시작일)
  DateTime _getMondayOfWeek(DateTime date) {
    final daysSinceMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysSinceMonday));
  }

  // 사용 가능한 년월 조합 목록
  List<String> get availableYearMonthCombinations {
    final now = DateTime.now();
    final List<String> combinations = [];

    // 현재 년도부터 2년 전까지
    for (int year = now.year - 2; year <= now.year; year++) {
      int maxMonth = (year == now.year) ? now.month : 12;
      int minMonth = 1;

      for (int month = minMonth; month <= maxMonth; month++) {
        combinations.add('$year년 $month월');
      }
    }

    return combinations;
  }

  ActivityLogProvider() {
    _currentDate = DateTime.now();
    _initializeCurrentWeek();
  }

  // 현재 주차로 초기화
  void _initializeCurrentWeek() {
    final now = DateTime.now();
    final mondayOfCurrentWeek = _getMondayOfWeek(now);
    final sundayOfCurrentWeek = mondayOfCurrentWeek.add(Duration(days: 6));

    _selectedRange =
        '${mondayOfCurrentWeek.month}월 ${mondayOfCurrentWeek.day}일 ~ ${sundayOfCurrentWeek.month}월 ${sundayOfCurrentWeek.day}일';

    // 현재 주차 데이터 로드
    _fetchWeeklyDataFromFirestore(mondayOfCurrentWeek, sundayOfCurrentWeek);
  }

  // 주간 범위 업데이트
  void updateSelectedRange(String range) async {
    _isLoading = true;
    notifyListeners();
    _selectedRange = range;

    // 날짜 파싱
    final parts = range.split(' ~ ');
    final startParts = parts[0].split('월 ');
    final endParts = parts[1].split('월 ');

    final startDate = DateTime(
      DateTime.now().year,
      int.parse(startParts[0]),
      int.parse(startParts[1].replaceAll('일', '')),
    );
    final endDate = DateTime(
      DateTime.now().year,
      int.parse(endParts[0]),
      int.parse(endParts[1].replaceAll('일', '')),
    );

    _currentDate = startDate.add(Duration(days: 3)); // 주 중간값
    await _fetchWeeklyDataFromFirestore(startDate, endDate);
    await fetchWeeklyChartData();
    _isLoading = false;
    notifyListeners();
  }

  // 주간 데이터 조회
  Future<void> _fetchWeeklyDataFromFirestore(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('trackingResult')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

      if (!snapshot.exists) {
        _currentDataStatus = DataStatus.noDataAtAll;
        updateStats({
          'distance': 0.0,
          'duration': Duration.zero,
          'steps': 0,
          'count': 0,
        });
        return;
      }

      final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];

      final weeklyData =
          data.where((item) {
            final itemDate = DateTime.parse(item['종료시간']);
            return itemDate.isAfter(start.subtract(Duration(seconds: 1))) &&
                itemDate.isBefore(end.add(Duration(days: 1)));
          }).toList();

      if (weeklyData.isEmpty) {
        _currentDataStatus = DataStatus.noDataInPeriod;
        updateStats({
          'distance': 0.0,
          'duration': Duration.zero,
          'steps': 0,
          'count': 0,
        });
        return;
      }

      final result = _aggregateData(weeklyData);
      _currentDataStatus = DataStatus.hasData;
      updateStats(result);
    } catch (e) {
      print('주간 데이터 로드 중 오류 발생: $e');
      _currentDataStatus = DataStatus.noDataAtAll;
      updateStats({
        'distance': 0.0,
        'duration': Duration.zero,
        'steps': 0,
        'count': 0,
      });
    }
  }

  // 월간 데이터 조회
  Future<Map<String, dynamic>> getMonthlyData(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('trackingResult')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

      if (!snapshot.exists) {
        _currentDataStatus = DataStatus.noDataAtAll;
        return {
          'distance': 0,
          'duration': Duration.zero,
          'steps': 0,
          'count': 0,
        };
      }

      final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];

      if (data.isEmpty) {
        _currentDataStatus = DataStatus.noDataAtAll;
        return {
          'distance': 0,
          'duration': Duration.zero,
          'steps': 0,
          'count': 0,
        };
      }

      final monthlyData =
          data.where((item) {
            final itemDate = DateTime.parse(item['종료시간']);
            return itemDate.isAfter(
                  startOfMonth.subtract(Duration(seconds: 1)),
                ) &&
                itemDate.isBefore(endOfMonth.add(Duration(days: 1)));
          }).toList();

      if (monthlyData.isEmpty) {
        _currentDataStatus = DataStatus.noDataInPeriod;
        return {
          'distance': 0,
          'duration': Duration.zero,
          'steps': 0,
          'count': 0,
        };
      }

      _currentDataStatus = DataStatus.hasData;
      final result = _aggregateData(monthlyData);
      return result;
    } catch (e) {
      print('월간 데이터 로드 중 오류 발생: $e');
      _currentDataStatus = DataStatus.noDataAtAll;
      return {'distance': 0, 'duration': Duration.zero, 'steps': 0, 'count': 0};
    }
  }

  // 데이터 집계
  Map<String, dynamic> _aggregateData(List<dynamic> data) {
    double totalDistance = 0;
    Duration totalDuration = Duration.zero;
    int totalSteps = 0;

    for (var item in data) {
      // 거리 계산
      final distance =
          (item['거리'] is int)
              ? (item['거리'] as int).toDouble()
              : double.tryParse(item['거리'].toString()) ?? 0.0;
      totalDistance += distance;

      // 시간 계산
      final timeStr = item['소요시간'].toString();
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        try {
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          final seconds = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
          final duration = Duration(
            hours: hours,
            minutes: minutes,
            seconds: seconds,
          );
          totalDuration += duration;
        } catch (e) {
          print('시간 파싱 오류: $timeStr - $e');
        }
      }

      // 걸음수 계산
      final steps = int.tryParse(item['걸음수'].toString()) ?? 0;
      totalSteps += steps;
    }

    return {
      'distance': totalDistance,
      'duration': totalDuration,
      'steps': totalSteps,
      'count': data.length,
    };
  }

  // 데이터 로드
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_selectedPeriod == ActivityPeriod.monthly) {
        final data = await getMonthlyData(
          _currentDate.year,
          _currentDate.month,
        );
        updateStats(data);
      } else {
        // 주간 데이터의 경우 이미 updateSelectedRange에서 로드됨
        if (_selectedRange.isEmpty) {
          _initializeCurrentWeek();
        }
      }
    } catch (e) {
      print('데이터 로드 중 오류 발생: $e');
      _currentDataStatus = DataStatus.noDataAtAll;
      updateStats({
        'distance': 0,
        'duration': Duration.zero,
        'steps': 0,
        'count': 0,
      });
    }
    _isLoading = false;
    notifyListeners();
  }

  // 데이터 업데이트
  void updateStats(Map<String, dynamic> data) {
    _totalDistance =
        (data['distance'] is int)
            ? (data['distance'] as int).toDouble()
            : (data['distance'] as double?) ?? 0.0;
    _totalDuration = data['duration'] as Duration;
    _totalCount = data['count'] ?? 0;
    _totalSteps = data['steps'] ?? 0;

    notifyListeners();
  }

  // 주간/월간 선택 변경
  void setPeriod(ActivityPeriod period) {
    _selectedPeriod = period;
    _isLoading = true;
    notifyListeners();
    if (period == ActivityPeriod.weekly) {
      _currentDate = DateTime.now();
      if (_selectedRange.isEmpty) {
        _initializeCurrentWeek();
      }
      // 주간 통계 fetch
      final parts = _selectedRange.split(' ~ ');
      final startParts = parts[0].split('월 ');
      final endParts = parts[1].split('월 ');
      final startDate = DateTime(
        DateTime.now().year,
        int.parse(startParts[0]),
        int.parse(startParts[1].replaceAll('일', '')),
      );
      final endDate = DateTime(
        DateTime.now().year,
        int.parse(endParts[0]),
        int.parse(endParts[1].replaceAll('일', '')),
      );
      _fetchWeeklyDataFromFirestore(startDate, endDate);
      fetchWeeklyChartData();
    } else {
      _currentDate = DateTime.now();
      // 월간 통계 fetch
      getMonthlyData(_currentDate.year, _currentDate.month).then(updateStats);
      fetchMonthlyChartData();
    }
  }

  // 년도 변경 (월간 기록용)
  void updateYearMonth(String yearMonth) {
    _isLoading = true;
    notifyListeners();
    final parts = yearMonth.split('년 ');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1].replaceAll('월', ''));
    _currentDate = DateTime(year, month, 1);
    // 월간 통계 fetch
    getMonthlyData(_currentDate.year, _currentDate.month).then(updateStats);
    fetchMonthlyChartData();
    // loadData에서 isLoading false 처리
  }

  // UI 메시지
  String getNoDataMessage() {
    switch (_currentDataStatus) {
      case DataStatus.noDataAtAll:
        return '데이터가 없습니다.';
      case DataStatus.noDataInPeriod:
        if (_selectedPeriod == ActivityPeriod.weekly) {
          return '이 주에는 데이터가 없습니다.';
        } else {
          return '이 달에는 데이터가 없습니다.';
        }
      case DataStatus.hasData:
        return '';
    }
  }

  // 차트 데이터 - 주간
  // 차트 데이터 상태
  List<FlSpot> _weeklyChartData = [];
  List<BarChartGroupData> _monthlyChartData = [];
  String? _chartError;
  List<FlSpot> get weeklyChartData => _weeklyChartData;
  List<BarChartGroupData> get monthlyChartData => _monthlyChartData;
  String? get chartError => _chartError;

  // 주간 차트 데이터 fetch
  Future<void> fetchWeeklyChartData() async {
    _isLoading = true;
    _chartError = null;
    notifyListeners();
    try {
      if (_selectedRange.isEmpty) {
        _weeklyChartData = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      final parts = _selectedRange.split(' ~ ');
      final startParts = parts[0].split('월 ');
      final startDate = DateTime(
        DateTime.now().year,
        int.parse(startParts[0]),
        int.parse(startParts[1].replaceAll('일', '')),
      );
      final List<FlSpot> spots = [];
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final dayData = await _getDayData(date);
        spots.add(FlSpot(i.toDouble(), dayData['distance'] ?? 0.0));
      }
      _weeklyChartData = spots;
    } catch (e) {
      _chartError = '주간 차트 데이터를 불러오는데 실패했습니다.';
      _weeklyChartData = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // 월간 차트 데이터 fetch
  Future<void> fetchMonthlyChartData() async {
    _isLoading = true;
    _chartError = null;
    notifyListeners();
    try {
      final List<BarChartGroupData> groups = [];
      for (int month = 1; month <= 12; month++) {
        final date = DateTime(_currentDate.year, month, 1);
        final monthData = await _getMonthData(date);
        groups.add(
          BarChartGroupData(
            x: month,
            barRods: [
              BarChartRodData(
                toY: monthData['distance'] ?? 0.0,
                color: YELLOW_INFO_BASE_30,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
      _monthlyChartData = groups;
    } catch (e) {
      _chartError = '월간 차트 데이터를 불러오는데 실패했습니다.';
      _monthlyChartData = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // 특정 날짜의 데이터 조회
  Future<Map<String, dynamic>> _getDayData(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('trackingResult')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

      if (!snapshot.exists) {
        return {'distance': 0.0, 'duration': Duration.zero, 'steps': 0};
      }

      final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];

      final dayData =
          data.where((item) {
            final itemDate = DateTime.parse(item['종료시간']);
            return itemDate.isAfter(
                  startOfDay.subtract(Duration(seconds: 1)),
                ) &&
                itemDate.isBefore(endOfDay);
          }).toList();

      return _aggregateData(dayData);
    } catch (e) {
      print('일간 데이터 조회 오류: $e');
      return {'distance': 0.0, 'duration': Duration.zero, 'steps': 0};
    }
  }

  // 특정 월의 데이터 조회
  Future<Map<String, dynamic>> _getMonthData(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('trackingResult')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

      if (!snapshot.exists) {
        return {'distance': 0.0, 'duration': Duration.zero, 'steps': 0};
      }

      final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];

      final monthData =
          data.where((item) {
            final itemDate = DateTime.parse(item['종료시간']);
            return itemDate.isAfter(
                  startOfMonth.subtract(Duration(seconds: 1)),
                ) &&
                itemDate.isBefore(endOfMonth.add(Duration(days: 1)));
          }).toList();

      return _aggregateData(monthData);
    } catch (e) {
      print('월간 데이터 조회 오류: $e');
      return {'distance': 0.0, 'duration': Duration.zero, 'steps': 0};
    }
  }
}
