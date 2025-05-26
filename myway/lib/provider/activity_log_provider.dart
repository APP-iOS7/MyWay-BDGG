import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/model/activity_period.dart';

class ActivityLogProvider extends ChangeNotifier {
  // Firestore 데이터 처리
  Future<Map<String, dynamic>> getWeeklyData(DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    final snapshot =
        await FirebaseFirestore.instance
            .collection('trackingResult')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();

    final data = snapshot.data()?['TrackingResult'] as List<dynamic>;

    final weeklyData =
        data.where((item) {
          final itemDate = DateTime.parse(item['종료시간']);
          return itemDate.isAfter(startOfWeek) &&
              itemDate.isBefore(endOfWeek.add(Duration(days: 1)));
        }).toList();

    final result = _aggregateData(weeklyData);
    updateStats(result);
    return result;
  }

  Future<Map<String, dynamic>> getMonthlyData(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('trackingResult')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();
    final data = snapshot.data()?['TrackingResult'] as List<dynamic>;

    final monthlyData =
        data.where((item) {
          final itemDate = DateTime.parse(item['종료시간']);
          return itemDate.isAfter(startOfMonth) &&
              itemDate.isBefore(endOfMonth.add(Duration(days: 1)));
        }).toList();

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

    for (var item in data) {
      totalDistance += double.tryParse(item['거리'].toString()) ?? 0;

      // 시간 계산
      final timeStr = item['소요시간'].toString();
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        try {
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          totalDuration += Duration(hours: hours, minutes: minutes);
        } catch (e) {
          print('시간 파싱 오류: $timeStr');
        }
      }

      totalSteps += int.tryParse(item['걸음수'].toString()) ?? 0;
    }

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

  List<String> get availableMonths =>
      List.generate(12, (index) => '${index + 1}월');
  String get selectedMonth => _selectedMonth;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    final monthNumber = int.parse(month.replaceAll('월', ''));
    _currentDate = DateTime(_currentDate.year, monthNumber, 1);
    loadData(); // 월 변경 시 데이터 로드
    notifyListeners();
  }

  ActivityLogProvider() {
    _currentDate = DateTime.now();
    _updateDateInfo();
  }

  void _updateDateInfo() {
    final currentMonth = _currentDate.month;
    final currentYear = _currentDate.year;

    availableWeeks = _getWeeksInMonth(currentYear, currentMonth);

    final currentWeek = _getWeekNumber(_currentDate);
    _currentDisplayDateWeekly = "$currentYear년 $currentMonth월 $currentWeek주";
    _currentDisplayDateMonthly = "$currentYear년 $currentMonth월";

    notifyListeners();
  }

  // 주차 계산 메서드
  int _getWeekNumber(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final dayOfMonth = date.day;
    return ((dayOfMonth + firstWeekday - 1) / 7).ceil();
  }

  // 특정 월의 모든 주차 목록 생성
  List<String> _getWeeksInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final firstWeek = _getWeekNumber(firstDay);
    final lastWeek = _getWeekNumber(lastDay);

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
    availableWeeks = _getWeeksInMonth(_currentDate.year, monthNumber);
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
    // _currentDisplayDateWeekly =
    //     "${_currentDate.year}년 ${_currentDate.month}월 $weekNumber주";
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
}
