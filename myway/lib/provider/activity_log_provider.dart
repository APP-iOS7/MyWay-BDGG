import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myway/model/activity_period.dart';

import '../const/colors.dart';

class ActivityLogProvider extends ChangeNotifier {
  // Firestore 데이터 처리
  Future<Map<String, dynamic>> getWeeklyData(DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    print('주간 데이터 조회 시작: $startOfWeek ~ $endOfWeek');

    final snapshot =
        await FirebaseFirestore.instance
            .collection('trackingResult')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();

    if (!snapshot.exists) {
      print('문서가 존재하지 않습니다.');
      return {'distance': 0, 'duration': Duration.zero, 'steps': 0, 'count': 0};
    }

    final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];
    print('조회된 데이터 수: ${data.length}');

    final weeklyData =
        data.where((item) {
          final itemDate = DateTime.parse(item['종료시간']);
          final isInRange =
              itemDate.isAfter(startOfWeek) &&
              itemDate.isBefore(endOfWeek.add(Duration(days: 1)));
          print('데이터 확인: ${item['종료시간']} - 범위 내: $isInRange');
          return isInRange;
        }).toList();

    print('주간 데이터 필터링 결과: ${weeklyData.length}개');
    final result = _aggregateData(weeklyData);
    updateStats(result);
    return result;
  }

  Future<Map<String, dynamic>> getMonthlyData(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    print('월간 데이터 조회 시작: $startOfMonth ~ $endOfMonth');

    final snapshot =
        await FirebaseFirestore.instance
            .collection('trackingResult')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();

    if (!snapshot.exists) {
      print('문서가 존재하지 않습니다.');
      return {'distance': 0, 'duration': Duration.zero, 'steps': 0, 'count': 0};
    }

    final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];
    print('조회된 데이터 수: ${data.length}');

    final monthlyData =
        data.where((item) {
          final itemDate = DateTime.parse(item['종료시간']);
          final isInRange =
              itemDate.isAfter(startOfMonth) &&
              itemDate.isBefore(endOfMonth.add(Duration(days: 1)));
          print('데이터 확인: ${item['종료시간']} - 범위 내: $isInRange');
          return isInRange;
        }).toList();

    print('월간 데이터 필터링 결과: ${monthlyData.length}개');
    final result = _aggregateData(monthlyData);
    updateStats(result);
    return result;
  }

  Future<void> loadData() async {
    if (_selectedPeriod == ActivityPeriod.weekly) {
      final data = await getWeeklyData(_currentDate);
      updateStats(data);
    } else {
      final data = await getMonthlyData(_currentDate.year, _currentDate.month);
      updateStats(data);
    }
  }

  Map<String, dynamic> _aggregateData(List<dynamic> data) {
    double totalDistance = 0;
    Duration totalDuration = Duration.zero;
    int totalSteps = 0;

    print('데이터 집계 시작: ${data.length}개의 항목');

    for (var item in data) {
      print('항목 처리 중: ${item.toString()}');

      totalDistance += double.tryParse(item['거리'].toString()) ?? 0;

      // 시간 계산
      final timeStr = item['소요시간'].toString();
      print('소요시간 문자열: $timeStr');

      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        // HH:mm 또는 HH:mm:ss 형식 모두 처리
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
          print(
            '시간 변환 성공: ${duration.inHours}시간 ${duration.inMinutes.remainder(60)}분 ${duration.inSeconds.remainder(60)}초',
          );
        } catch (e) {
          print('시간 파싱 오류: $timeStr - $e');
        }
      } else {
        print('시간 형식 오류: $timeStr (예상 형식: HH:mm 또는 HH:mm:ss)');
      }

      totalSteps += int.tryParse(item['걸음수'].toString()) ?? 0;
    }

    print('집계 결과:');
    print('- 총 거리: $totalDistance km');
    print(
      '- 총 소요시간: ${totalDuration.inHours}시간 ${totalDuration.inMinutes.remainder(60)}분',
    );
    print('- 총 걸음수: $totalSteps');

    return {
      'distance': totalDistance,
      'duration': totalDuration,
      'steps': totalSteps,
      'count': data.length,
    };
  }

  // 날짜 관련 상태
  late DateTime _currentDate;
  late String _currentDisplayDateWeekly;
  late String _currentDisplayDateMonthly;
  late List<String> availableWeeks;

  String _selectedMonth = '${DateTime.now().month}월';

  // 통계 데이터 추가
  double _totalDistance = 0;
  Duration _totalDuration = Duration.zero;
  int _totalCount = 0;
  int _totalSteps = 0;

  // Getters
  double get totalDistance => _totalDistance;
  String get formattedTotalDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_totalDuration.inHours);
    final minutes = twoDigits(_totalDuration.inMinutes.remainder(60));
    return '$hours시간 $minutes분';
  }

  int get totalCount => _totalCount;
  int get totalSteps => _totalSteps;

  // 데이터 업데이트 메서드
  void updateStats(Map<String, dynamic> data) {
    _totalDistance = data['distance'] ?? 0;
    _totalDuration = data['duration'] as Duration;
    _totalCount = data['count'] ?? 0;
    _totalSteps = data['steps'] ?? 0;
    notifyListeners();
  }

  List<String> get availableMonths {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    if (_currentDate.year == currentYear) {
      // 현재 년도인 경우 5월부터 현재 월까지
      return List.generate(currentMonth - 4, (index) => '${index + 5}월');
    } else {
      // 이전 년도인 경우 5월부터 12월까지
      return List.generate(8, (index) => '${index + 5}월');
    }
  }

  String get selectedMonth => _selectedMonth;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    final monthNumber = int.parse(month.replaceAll('월', ''));
    _currentDate = DateTime(_currentDate.year, monthNumber, 1);
    loadData(); // 월 변경 시 데이터 로드
    notifyListeners();
  }

  ActivityLogProvider() {
    _currentDate = DateTime(2025, 5, 1); // 초기값을 2025년 5월 1일로 설정
    _updateDateInfo();
  }

  void _updateDateInfo() {
    final currentMonth = _currentDate.month;
    final currentYear = _currentDate.year;

    availableWeeks = getWeeksInMonth(currentYear, currentMonth);

    final currentWeek = getWeekNumber(_currentDate);
    _currentDisplayDateWeekly = "$currentYear년 $currentMonth월 $currentWeek주";
    _currentDisplayDateMonthly = "$currentYear년 $currentMonth월";

    notifyListeners();
  }

  // 주차 계산 메서드
  int getWeekNumber(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final dayOfMonth = date.day;
    return ((dayOfMonth + firstWeekday - 1) / 7).ceil();
  }

  // 특정 월의 모든 주차 목록 생성
  List<String> getWeeksInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final firstWeek = getWeekNumber(firstDay);
    final lastWeek = getWeekNumber(lastDay);

    return List.generate(
      lastWeek - firstWeek + 1,
      (index) => '${firstWeek + index}주',
    );
  }

  // 주간/월간 선택 상태
  ActivityPeriod _selectedPeriod = ActivityPeriod.weekly;
  ActivityPeriod get selectedPeriod => _selectedPeriod;

  // 현재 선택된 월
  String _selectedValue = '';
  String get currentSelectedValue => _selectedValue;

  // 현재 선택된 주
  String _selectedWeek = '1주';
  String get selectedWeek => _selectedWeek;

  // 현재 표시 날짜
  String get currentDisplayDateWeekly => _currentDisplayDateWeekly;
  String get currentDisplayDateMonthly => _currentDisplayDateMonthly;

  // 선택 가능한 주착 목록
  List<String> get currentAvailableWeeks => availableWeeks;

  // 주간/월간 선택 변경
  void setPeriod(ActivityPeriod period) {
    _selectedPeriod = period;
    loadData(); // 기간 변경 시 데이터 로드
    notifyListeners();
  }

  void setSelectedWeek(String week) {
    _selectedWeek = week;
    notifyListeners();
  }

  // 월 선택 변경
  void updateSelectedMonth(String month) {
    _selectedValue = month;
    final monthNumber = int.parse(month.replaceAll('월', ''));
    availableWeeks = getWeeksInMonth(_currentDate.year, monthNumber);
    notifyListeners();
  }

  // 주 선택 변경
  void updateSelectedWeek(String week) {
    _selectedWeek = week;
    final weekNumber = int.parse(week.replaceAll('주', ''));
    // 주차에 해당하는 날짜 계산
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final dayOffset = (weekNumber - 1) * 7 - (firstWeekday - 1);
    _currentDate = firstDayOfMonth.add(Duration(days: dayOffset));
    loadData(); // 주 변경 시 데이터 로드
    notifyListeners();
  }

  // 이전 월로 이동
  void goToPreviousMonth() {
    _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    _updateDateInfo();
  }

  // 현재 월의 첫 날
  DateTime get startOfMonth =>
      DateTime(_currentDate.year, _currentDate.month, 1);

  // 현재 월의 마지막 날
  DateTime get endOfMonth =>
      DateTime(_currentDate.year, _currentDate.month + 1, 0);

  // 현재 주의 첫 날
  DateTime get startOfWeek {
    final firstDayOfWeek = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );
    return DateTime(
      firstDayOfWeek.year,
      firstDayOfWeek.month,
      firstDayOfWeek.day,
    );
  }

  // 현재 주의 마지막 날
  DateTime get endOfWeek {
    final lastDayOfWeek = startOfWeek.add(Duration(days: 6));
    return DateTime(lastDayOfWeek.year, lastDayOfWeek.month, lastDayOfWeek.day);
  }

  // 날짜 포맷팅 메서드
  String formatData(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // 시간 포멧팅 메서드
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes';
  }

  // 현재 날짜가 유효한지 확인
  bool isValidDate(DateTime date) {
    return date.isAfter(DateTime(2020)) && date.isBefore(DateTime(2025));
  }

  // 날짜 범위가 유효한지 확인
  bool isValidDateRang(DateTime start, DateTime end) {
    return start.isBefore(end) &&
        start.isAfter(DateTime(2020)) &&
        start.isBefore(DateTime(2025));
  }

  // 현재 날짜 getter
  DateTime get currentDate => _currentDate;

  // 현재 월과 주차 표시
  String get currentMonthAndWeek =>
      "${_currentDate.month}월 ${getWeekNumber(_currentDate)}주";

  // 현재 년도 getter
  int get currentYear => _currentDate.year;

  // 사용 가능한 년도 목록 (2025년부터 현재 년도까지)
  List<int> get availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 2024, (index) => 2025 + index);
  }

  // 현재 년도, 월, 주차 표시
  String get currentYearMonthAndWeek =>
      "${_currentDate.year}년 ${_currentDate.month}월 ${getWeekNumber(_currentDate)}주";

  // 년도 변경
  void updateYear(int year) {
    _currentDate = DateTime(year, _currentDate.month, _currentDate.day);
    _updateDateInfo();
    loadData();
    notifyListeners();
  }

  // 사용 가능한 년도와 월 조합 목록 생성
  List<String> get availableYearMonthCombinations {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;
    final List<String> combinations = [];

    // 2025년 5월부터 현재까지의 모든 조합 생성
    for (int year = 2025; year <= currentYear; year++) {
      int startMonth = (year == 2025) ? 5 : 1;
      int endMonth = (year == currentYear) ? currentMonth : 12;

      for (int month = startMonth; month <= endMonth; month++) {
        combinations.add('$year년 $month월');
      }
    }

    return combinations;
  }

  // 현재 선택된 년도와 월
  String get currentYearMonth => "${_currentDate.year}년 ${_currentDate.month}월";

  // 주차 선택을 위한 드롭다운 아이템 생성
  List<DropdownMenuItem<String>> getWeekDropdownItems() {
    final weeks = getWeeksInMonth(_currentDate.year, _currentDate.month);
    return weeks.map((week) {
      return DropdownMenuItem<String>(
        value: week,
        child: Text(
          week,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: GRAYSCALE_LABEL_950,
          ),
        ),
      );
    }).toList();
  }

  // 주간 차트 데이터
  Future<List<FlSpot>> get weeklyChartData async {
    final startOfWeek = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );
    final List<FlSpot> spots = [];

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayData = await _getDayData(date);
      spots.add(FlSpot(i.toDouble(), dayData['distance'] ?? 0.0));
    }

    return spots;
  }

  // 월간 차트 데이터
  Future<List<BarChartGroupData>> get monthlyChartData async {
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

    return groups;
  }

  // 특정 날짜의 데이터 조회
  Future<Map<String, dynamic>> _getDayData(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

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
          return itemDate.isAfter(startOfDay) && itemDate.isBefore(endOfDay);
        }).toList();

    return _aggregateData(dayData);
  }

  // 특정 월의 데이터 조회
  Future<Map<String, dynamic>> _getMonthData(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0);

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
          return itemDate.isAfter(startOfMonth) &&
              itemDate.isBefore(endOfMonth.add(Duration(days: 1)));
        }).toList();

    return _aggregateData(monthData);
  }
}
