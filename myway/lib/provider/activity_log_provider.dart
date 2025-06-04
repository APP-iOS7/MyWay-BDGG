// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:myway/model/activity_period.dart';

// import '../const/colors.dart';

// // 데이터 상태를 더 정확하게 추적하기 위한 열거형
// enum DataStatus {
//   hasData, // 데이터가 있음
//   noDataInPeriod, // 해당 기간에 데이터가 없음 (다른 기간에는 있을 수 있음)
//   noDataAtAll, // 전체적으로 데이터가 없음
// }

// class ActivityLogProvider extends ChangeNotifier {
//   // 현재 데이터 상태
//   DataStatus _currentDataStatus = DataStatus.hasData;
//   DataStatus get currentDataStatus => _currentDataStatus;

//   String _selectedRange = '';
//   String get selectedRange => _selectedRange;

//   Future<Map<String, dynamic>> getMonthlyData(int year, int month) async {
//     final startOfMonth = DateTime(year, month, 1);
//     final endOfMonth = DateTime(year, month + 1, 0);

//     print('월간 데이터 조회 시작: $startOfMonth ~ $endOfMonth');

//     final snapshot =
//         await FirebaseFirestore.instance
//             .collection('trackingResult')
//             .doc(FirebaseAuth.instance.currentUser?.uid)
//             .get();

//     if (!snapshot.exists) {
//       print('문서가 존재하지 않습니다.');
//       _currentDataStatus = DataStatus.noDataAtAll;
//       return {'distance': 0, 'duration': Duration.zero, 'steps': 0, 'count': 0};
//     }

//     final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];
//     print('조회된 전체 데이터 수: ${data.length}');

//     // 전체 데이터가 없는 경우
//     if (data.isEmpty) {
//       print('전체 데이터가 없습니다.');
//       _currentDataStatus = DataStatus.noDataAtAll;
//       return {'distance': 0, 'duration': Duration.zero, 'steps': 0, 'count': 0};
//     }

//     // 해당 월의 데이터 필터링
//     final monthlyData =
//         data.where((item) {
//           final itemDate = DateTime.parse(item['종료시간']);
//           final isInRange =
//               itemDate.isAfter(startOfMonth) &&
//               itemDate.isBefore(endOfMonth.add(Duration(days: 1)));
//           print('데이터 확인: ${item['종료시간']} - 범위 내: $isInRange');
//           return isInRange;
//         }).toList();

//     print('월간 데이터 필터링 결과: ${monthlyData.length}개');

//     // 해당 월에 데이터가 없는 경우
//     if (monthlyData.isEmpty) {
//       print('선택한 월에 데이터가 없습니다.');
//       _currentDataStatus = DataStatus.noDataInPeriod;
//       return {'distance': 0, 'duration': Duration.zero, 'steps': 0, 'count': 0};
//     }

//     // 데이터가 있는 경우
//     _currentDataStatus = DataStatus.hasData;
//     final result = _aggregateData(monthlyData);
//     updateStats(result);
//     return result;
//   }

//   List<String> get availableWeeklyRanges {
//     final List<String> ranges = [];

//     // 기록 시작 시점과 오늘까지 기준 설정
//     final firstDate = DateTime(2024, 1, 1); // 실제로는 첫 기록일로 설정 추천
//     final today = DateTime.now();
//     DateTime current = firstDate;

//     while (current.isBefore(today)) {
//       final weekStart = current;
//       final weekEnd = current.add(Duration(days: 6));
//       final label =
//           '${weekStart.month}월 ${weekStart.day}일 ~ ${weekEnd.month}월 ${weekEnd.day}일';
//       ranges.add(label);
//       current = current.add(Duration(days: 7));
//     }

//     return ranges;
//   }

//   void updateSelectedRange(String range) async {
//     _selectedRange = range;

//     // 날짜 파싱
//     final parts = range.split(' ~ ');
//     final startParts = parts[0].split('월 ');
//     final endParts = parts[1].split('월 ');

//     final startDate = DateTime(
//       DateTime.now().year,
//       int.parse(startParts[0]),
//       int.parse(startParts[1].replaceAll('일', '')),
//     );
//     final endDate = DateTime(
//       DateTime.now().year,
//       int.parse(endParts[0]),
//       int.parse(endParts[1].replaceAll('일', '')),
//     );

//     _currentDate = startDate.add(Duration(days: 3)); // 주 중간값
//     await _fetchWeeklyDataFromFirestore(startDate, endDate);

//     notifyListeners();
//   }

//   Future<void> _fetchWeeklyDataFromFirestore(
//     DateTime start,
//     DateTime end,
//   ) async {
//     final snapshot =
//         await FirebaseFirestore.instance
//             .collection('trackingResult')
//             .doc(FirebaseAuth.instance.currentUser?.uid)
//             .get();

//     if (!snapshot.exists) {
//       _currentDataStatus = DataStatus.noDataAtAll;
//       updateStats({
//         'distance': 0.0,
//         'duration': Duration.zero,
//         'steps': 0,
//         'count': 0,
//       });
//       return;
//     }

//     final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];

//     final weeklyData =
//         data.where((item) {
//           final itemDate = DateTime.parse(item['종료시간']);
//           return itemDate.isAfter(start.subtract(Duration(seconds: 1))) &&
//               itemDate.isBefore(end.add(Duration(days: 1)));
//         }).toList();

//     if (weeklyData.isEmpty) {
//       _currentDataStatus = DataStatus.noDataInPeriod;
//       updateStats({
//         'distance': 0.0,
//         'duration': Duration.zero,
//         'steps': 0,
//         'count': 0,
//       });
//       return;
//     }

//     final result = _aggregateData(weeklyData);
//     _currentDataStatus = DataStatus.hasData;
//     updateStats(result);
//   }

//   Future<void> loadData() async {
//     try {
//       if (_selectedPeriod == ActivityPeriod.monthly) {
//         final data = await getMonthlyData(
//           _currentDate.year,
//           _currentDate.month,
//         );
//         print('월간 데이터 로드 결과: $data');
//         updateStats(data);
//       }
//     } catch (e) {
//       print('데이터 로드 중 오류 발생: $e');
//       // 오류 발생 시 데이터 없음으로 처리
//       _currentDataStatus = DataStatus.noDataAtAll;
//       updateStats({
//         'distance': 0,
//         'duration': Duration.zero,
//         'steps': 0,
//         'count': 0,
//       });
//     }
//   }

//   Map<String, dynamic> _aggregateData(List<dynamic> data) {
//     double totalDistance = 0;
//     Duration totalDuration = Duration.zero;
//     int totalSteps = 0;

//     print('데이터 집계 시작: ${data.length}개의 항목');

//     for (var item in data) {
//       print('항목 처리 중: ${item.toString()}');

//       final distance =
//           (item['거리'] is int)
//               ? (item['거리'] as int).toDouble()
//               : double.tryParse(item['거리'].toString()) ?? 0.0;
//       totalDistance += distance;
//       print('거리: $distance km');

//       // 시간 계산
//       final timeStr = item['소요시간'].toString();
//       print('소요시간 문자열: $timeStr');

//       final parts = timeStr.split(':');
//       if (parts.length >= 2) {
//         try {
//           final hours = int.tryParse(parts[0]) ?? 0;
//           final minutes = int.tryParse(parts[1]) ?? 0;
//           final seconds = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
//           final duration = Duration(
//             hours: hours,
//             minutes: minutes,
//             seconds: seconds,
//           );
//           totalDuration += duration;
//           print(
//             '시간 변환 성공: ${duration.inHours}시간 ${duration.inMinutes.remainder(60)}분 ${duration.inSeconds.remainder(60)}초',
//           );
//         } catch (e) {
//           print('시간 파싱 오류: $timeStr - $e');
//         }
//       } else {
//         print('시간 형식 오류: $timeStr (예상 형식: HH:mm 또는 HH:mm:ss)');
//       }

//       // 걸음수 계산
//       final steps = int.tryParse(item['걸음수'].toString()) ?? 0;
//       totalSteps += steps;
//       print('걸음수: $steps');
//     }

//     print('최종 집계 결과:');
//     print('- 총 거리: $totalDistance km');
//     print(
//       '- 총 소요시간: ${totalDuration.inHours}시간 ${totalDuration.inMinutes.remainder(60)}분',
//     );
//     print('- 총 걸음수: $totalSteps');

//     return {
//       'distance': totalDistance,
//       'duration': totalDuration,
//       'steps': totalSteps,
//       'count': data.length,
//     };
//   }

//   // 날짜 관련 상태
//   late DateTime _currentDate;
//   late String _currentDisplayDateWeekly;
//   late String _currentDisplayDateMonthly;
//   late List<String> availableWeeks;

//   String _selectedMonth = '${DateTime.now().month}월';

//   // 통계 데이터 추가
//   double _totalDistance = 0;
//   Duration _totalDuration = Duration.zero;
//   int _totalCount = 0;
//   int _totalSteps = 0;

//   // Getters
//   double get totalDistance => _totalDistance;
//   String get formattedTotalDuration {
//     if (_totalDuration == Duration.zero) {
//       return '00시간 00분';
//     }

//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final hours = twoDigits(_totalDuration.inHours);
//     final minutes = twoDigits(_totalDuration.inMinutes.remainder(60));
//     return '$hours시간 $minutes분';
//   }

//   int get totalCount => _totalCount;
//   int get totalSteps => _totalSteps;

//   // 데이터 상태를 확인하는 편의 메서드들
//   bool get hasNoData => _currentDataStatus == DataStatus.noDataAtAll;
//   bool get hasNoDataInCurrentPeriod =>
//       _currentDataStatus == DataStatus.noDataInPeriod;
//   bool get hasData => _currentDataStatus == DataStatus.hasData;

//   // 주간 데이터 상태 확인
//   bool get hasNoWeeklyData =>
//       _selectedPeriod == ActivityPeriod.weekly &&
//       (_currentDataStatus == DataStatus.noDataInPeriod ||
//           _currentDataStatus == DataStatus.noDataAtAll);

//   // 월간 데이터 상태 확인
//   bool get hasNoMonthlyData =>
//       _selectedPeriod == ActivityPeriod.monthly &&
//       (_currentDataStatus == DataStatus.noDataInPeriod ||
//           _currentDataStatus == DataStatus.noDataAtAll);

//   // UI에서 표시할 메시지를 반환하는 메서드
//   String getNoDataMessage() {
//     switch (_currentDataStatus) {
//       case DataStatus.noDataAtAll:
//         return '데이터가 없습니다';
//       case DataStatus.noDataInPeriod:
//         if (_selectedPeriod == ActivityPeriod.weekly) {
//           return '이 주에는 데이터가 없습니다';
//         } else {
//           return '이 달에는 데이터가 없습니다';
//         }
//       case DataStatus.hasData:
//         return '';
//     }
//   }

//   // 데이터 업데이트 메서드
//   void updateStats(Map<String, dynamic> data) {
//     print('updateStats 호출: $data');

//     _totalDistance =
//         (data['distance'] is int)
//             ? (data['distance'] as int).toDouble()
//             : (data['distance'] as double?) ?? 0.0;
//     _totalDuration = data['duration'] as Duration;
//     _totalCount = data['count'] ?? 0;
//     _totalSteps = data['steps'] ?? 0;

//     print('업데이트된 값:');
//     print('거리: $_totalDistance');
//     print('시간: $_totalDuration');
//     print('횟수: $_totalCount');
//     print('걸음수: $_totalSteps');

//     notifyListeners();
//   }

//   List<String> get availableMonths {
//     final currentYear = DateTime.now().year;
//     final currentMonth = DateTime.now().month;

//     if (_currentDate.year == currentYear) {
//       return List.generate(currentMonth - 4, (index) => '${index + 5}월');
//     } else {
//       return List.generate(8, (index) => '${index + 5}월');
//     }
//   }

//   String get selectedMonth => _selectedMonth;

//   void setSelectedMonth(String month) {
//     _selectedMonth = month;
//     final monthNumber = int.parse(month.replaceAll('월', ''));
//     _currentDate = DateTime(_currentDate.year, monthNumber, 1);

//     // 새로운 주차 목록 생성
//     final newAvailableWeeks = getWeeksInMonth(_currentDate.year, monthNumber);
//     availableWeeks = newAvailableWeeks;

//     // 현재 선택된 주차가 새로운 목록에 있는지 확인
//     if (!newAvailableWeeks.contains(_selectedWeek)) {
//       // 현재 날짜와 같은 년월이면 현재 주차로, 아니면 첫 번째 주차로 설정
//       final now = DateTime.now();
//       if (_currentDate.year == now.year && monthNumber == now.month) {
//         final curretWeek = getWeekNumber(now);
//         _selectedWeek = '$curretWeek주';
//       } else {
//         _selectedWeek =
//             newAvailableWeeks.isNotEmpty ? newAvailableWeeks.first : '1주';
//       }
//     }
//     loadData();
//     notifyListeners();
//   }

//   ActivityLogProvider() {
//     _currentDate = DateTime.now();
//     _updateDateInfo();
//   }

//   void _updateDateInfo() {
//     final currentMonth = _currentDate.month;
//     final currentYear = _currentDate.year;

//     availableWeeks = getWeeksInMonth(currentYear, currentMonth);

//     final currentWeek = getWeekNumber(_currentDate);
//     // 현재 주차를 선택된 주차로 설정
//     _selectedWeek = '$currentWeek 주';
//     _currentDisplayDateWeekly = "$currentYear년 $currentMonth월 $currentWeek주";
//     _currentDisplayDateMonthly = "$currentYear년 $currentMonth월";

//     notifyListeners();
//   }

//   // 주차 계산 메서드
//   int getWeekNumber(DateTime date) {
//     final firstDayOfMonth = DateTime(date.year, date.month, 1);
//     final firstWeekday = firstDayOfMonth.weekday;
//     final dayOfMonth = date.day;

//     // 첫 번째 주의 시작일 계산
//     final firstWeekStart = firstDayOfMonth.subtract(
//       Duration(days: firstWeekday - 1),
//     );

//     // 해당 날짜까지의 일수를 7로 나누어 주차 계산
//     final daysDifference = date.difference(firstWeekStart).inDays;
//     final weekNumber = (daysDifference / 7).floor() + 1;

//     // 월의 첫 날이 월요일이 아닌 경우, 첫 주의 일수를 고려하여 조정
//     if (firstWeekday != DateTime.monday) {
//       // 첫 주의 일수가 4일 이상인 경우에만 1주차로 계산
//       if (dayOfMonth <= (8 - firstWeekday)) {
//         return 1;
//       }
//     }

//     return weekNumber;
//   }

//   // 특정 월의 모든 주차 목록 생성
//   List<String> getWeeksInMonth(int year, int month) {
//     final firstDay = DateTime(year, month, 1);
//     final lastDay = DateTime(year, month + 1, 0);

//     // 첫번째 주의 월요일
//     DateTime firstWeekStart = firstDay;
//     while (firstWeekStart.weekday != DateTime.monday) {
//       firstWeekStart = firstWeekStart.subtract(Duration(days: 1));
//     }

//     // 마지막 주의 일요일
//     DateTime lastWeekEnd = lastDay;
//     while (lastWeekEnd.weekday != DateTime.sunday) {
//       lastWeekEnd = lastWeekEnd.add(Duration(days: 1));
//     }

//     // 전체 주 수 계산
//     final totalWeeks = (lastWeekEnd.difference(firstWeekStart).inDays + 1) ~/ 7;

//     // 주차 목록 생성
//     List<String> weeks = [];
//     for (int i = 0; i < totalWeeks; i++) {
//       final weekStart = firstWeekStart.add(Duration(days: i * 7));
//       final weekEnd = weekStart.add(Duration(days: 6));

//       // 해당 주가 이번 달과 겹치는지 확인
//       if (weekEnd.month == month || weekStart.month == month) {
//         weeks.add('${i + 1}주');
//       }
//     }

//     return weeks;
//   }

//   // 주간/월간 선택 상태
//   ActivityPeriod _selectedPeriod = ActivityPeriod.weekly;
//   ActivityPeriod get selectedPeriod => _selectedPeriod;

//   // 현재 선택된 월
//   String _selectedValue = '';
//   String get currentSelectedValue => _selectedValue;

//   // 현재 선택된 주 (초기값을 현재 주차로 설정)
//   String _selectedWeek = '1주';
//   String get selectedWeek => _selectedWeek;

//   // 현재 표시 날짜
//   String get currentDisplayDateWeekly => _currentDisplayDateWeekly;
//   String get currentDisplayDateMonthly => _currentDisplayDateMonthly;

//   // 선택 가능한 주착 목록
//   List<String> get currentAvailableWeeks => availableWeeks;

//   // 주간/월간 선택 변경
//   void setPeriod(ActivityPeriod period) {
//     _selectedPeriod = period;
//     if (period == ActivityPeriod.weekly) {
//       _currentDate = DateTime.now();
//       _updateDateInfo();

//       // 현재 주차로 설정
//       final currentWeek = getWeekNumber(DateTime.now());
//       _selectedWeek = '$currentWeek주';
//     }
//     loadData();
//     notifyListeners();
//   }

//   void setSelectedWeek(String week) {
//     _selectedWeek = week;
//     notifyListeners();
//   }

//   // 월 선택 변경
//   void updateSelectedMonth(String month) {
//     _selectedValue = month;
//     final monthNumber = int.parse(month.replaceAll('월', ''));
//     availableWeeks = getWeeksInMonth(_currentDate.year, monthNumber);
//     notifyListeners();
//   }

//   // 주 선택 변경
//   void updateSelectedWeek(String week) {
//     _selectedWeek = week;
//     final weekNumber = int.parse(week.replaceAll('주', ''));

//     // 해당 월의 첫 번째 날
//     final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);

//     // 첫번째 주의 월요일 계산
//     final firstWeekStart = firstDayOfMonth.subtract(
//       Duration(days: firstDayOfMonth.weekday - 1),
//     );

//     // 선택된 주차의 시작일 계산
//     final selectedWeekStart = firstWeekStart.add(
//       Duration(days: (weekNumber - 1) * 7),
//     );

//     // 선택된 주의 중간 날짜로 _currentDate 설정 (해당 주의 수요일)
//     _currentDate = selectedWeekStart.add(Duration(days: 2));

//     // 만약 계산된 날짜가 해당 월을 벗어나면 해당 월 내의 날짜로 조정
//     if (_currentDate.month != firstDayOfMonth.month) {
//       if (_currentDate.isBefore(firstDayOfMonth)) {
//         _currentDate = firstDayOfMonth;
//       } else {
//         final lastDayOfMonth = DateTime(
//           _currentDate.year,
//           _currentDate.month + 1,
//           0,
//         );
//         _currentDate = lastDayOfMonth;
//       }
//     }

//     print('주차 변경: $week -> _currentDate: $_currentDate');

//     loadData(); // 주 변경 시 데이터 로드
//     notifyListeners();
//   }

//   // 이전 월로 이동
//   void goToPreviousMonth() {
//     _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
//     _updateDateInfo();
//   }

//   // 현재 월의 첫 날
//   DateTime get startOfMonth =>
//       DateTime(_currentDate.year, _currentDate.month, 1);

//   // 현재 월의 마지막 날
//   DateTime get endOfMonth =>
//       DateTime(_currentDate.year, _currentDate.month + 1, 0);

//   // 현재 주의 첫 날
//   DateTime get startOfWeek {
//     final firstDayOfWeek = _currentDate.subtract(
//       Duration(days: _currentDate.weekday - 1),
//     );
//     return DateTime(
//       firstDayOfWeek.year,
//       firstDayOfWeek.month,
//       firstDayOfWeek.day,
//     );
//   }

//   // 현재 주의 마지막 날
//   DateTime get endOfWeek {
//     final lastDayOfWeek = startOfWeek.add(Duration(days: 6));
//     return DateTime(lastDayOfWeek.year, lastDayOfWeek.month, lastDayOfWeek.day);
//   }

//   // 날짜 포맷팅 메서드
//   String formatData(DateTime date) {
//     return '${date.year}년 ${date.month}월 ${date.day}일';
//   }

//   // 시간 포멧팅 메서드
//   String formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final hours = twoDigits(duration.inHours);
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     return '$hours:$minutes';
//   }

//   // 현재 날짜가 유효한지 확인
//   bool isValidDate(DateTime date) {
//     return date.isAfter(DateTime(2020)) && date.isBefore(DateTime(2025));
//   }

//   // 날짜 범위가 유효한지 확인
//   bool isValidDateRang(DateTime start, DateTime end) {
//     return start.isBefore(end) &&
//         start.isAfter(DateTime(2020)) &&
//         start.isBefore(DateTime(2025));
//   }

//   // 현재 날짜 getter
//   DateTime get currentDate => _currentDate;

//   // 현재 월과 주차 표시
//   String get currentMonthAndWeek =>
//       "${_currentDate.month}월 ${getWeekNumber(_currentDate)}주";

//   // 현재 년도 getter
//   int get currentYear => _currentDate.year;

//   // 사용 가능한 년도 목록 (2025년부터 현재 년도까지)
//   List<int> get availableYears {
//     final currentYear = DateTime.now().year;
//     return List.generate(currentYear - 2024, (index) => 2025 + index);
//   }

//   // 현재 년도, 월, 주차 표시
//   String get currentYearMonthAndWeek =>
//       "${_currentDate.year}년 ${_currentDate.month}월 ${getWeekNumber(_currentDate)}주";

//   // 년도 변경
//   void updateYear(int year) {
//     _currentDate = DateTime(year, _currentDate.month, _currentDate.day);
//     _updateDateInfo();

//     // 새로운 년월의 주차 목록을 먼저 생성
//     final newAvailableWeeks = getWeeksInMonth(year, _currentDate.month);

//     // 현재 선택된 주차가 새로운 목록에 있는지 확인
//     if (!newAvailableWeeks.contains(_selectedWeek)) {
//       // 현재 날짜와 같은 년월이면 현재 주차로, 아니면 첫 번째 주차로 설정
//       final now = DateTime.now();
//       if (year == now.year && _currentDate.month == now.month) {
//         final currentWeek = getWeekNumber(now);
//         _selectedWeek = '$currentWeek주';
//       } else {
//         _selectedWeek =
//             newAvailableWeeks.isNotEmpty ? newAvailableWeeks.first : '1주';
//       }
//     }
//     loadData();
//     notifyListeners();
//   }

//   // 사용 가능한 년도와 월 조합 목록 생성
//   List<String> get availableYearMonthCombinations {
//     final now = DateTime.now();
//     final List<String> combinations = [];

//     // 현재 년도부터 2년 전까지
//     for (int year = now.year - 2; year <= now.year; year++) {
//       // 현재 년도인 경우 현재 월까지만
//       int maxMonth = (year == now.year) ? now.month : 12;
//       // 2년 전부터는 1월부터
//       int minMonth = (year == now.year - 2) ? 1 : 1;

//       for (int month = minMonth; month <= maxMonth; month++) {
//         combinations.add('$year년 $month월');
//       }
//     }

//     return combinations;
//   }

//   // 현재 선택된 년도와 월
//   String get currentYearMonth {
//     return '$currentYear년 $_selectedMonth';
//   }

//   // 주간 차트 데이터
//   Future<List<FlSpot>> get weeklyChartData async {
//     final startOfWeek = _currentDate.subtract(
//       Duration(days: _currentDate.weekday - 1),
//     );
//     final List<FlSpot> spots = [];

//     for (int i = 0; i < 7; i++) {
//       final date = startOfWeek.add(Duration(days: i));
//       final dayData = await _getDayData(date);
//       spots.add(FlSpot(i.toDouble(), dayData['distance'] ?? 0.0));
//     }

//     return spots;
//   }

//   // 월간 차트 데이터
//   Future<List<BarChartGroupData>> get monthlyChartData async {
//     final List<BarChartGroupData> groups = [];

//     for (int month = 1; month <= 12; month++) {
//       final date = DateTime(_currentDate.year, month, 1);
//       final monthData = await _getMonthData(date);
//       groups.add(
//         BarChartGroupData(
//           x: month,
//           barRods: [
//             BarChartRodData(
//               toY: monthData['distance'] ?? 0.0,
//               color: YELLOW_INFO_BASE_30,
//               width: 16,
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ],
//         ),
//       );
//     }

//     return groups;
//   }

//   // 특정 날짜의 데이터 조회
//   Future<Map<String, dynamic>> _getDayData(DateTime date) async {
//     final startOfDay = DateTime(date.year, date.month, date.day);
//     final endOfDay = startOfDay.add(Duration(days: 1));

//     final snapshot =
//         await FirebaseFirestore.instance
//             .collection('trackingResult')
//             .doc(FirebaseAuth.instance.currentUser?.uid)
//             .get();

//     if (!snapshot.exists) {
//       return {'distance': 0.0, 'duration': Duration.zero, 'steps': 0};
//     }

//     final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];

//     final dayData =
//         data.where((item) {
//           final itemDate = DateTime.parse(item['종료시간']);
//           return itemDate.isAfter(startOfDay) && itemDate.isBefore(endOfDay);
//         }).toList();

//     return _aggregateData(dayData);
//   }

//   // 특정 월의 데이터 조회
//   Future<Map<String, dynamic>> _getMonthData(DateTime date) async {
//     final startOfMonth = DateTime(date.year, date.month, 1);
//     final endOfMonth = DateTime(date.year, date.month + 1, 0);

//     final snapshot =
//         await FirebaseFirestore.instance
//             .collection('trackingResult')
//             .doc(FirebaseAuth.instance.currentUser?.uid)
//             .get();

//     if (!snapshot.exists) {
//       return {'distance': 0.0, 'duration': Duration.zero, 'steps': 0};
//     }

//     final data = snapshot.data()?['TrackingResult'] as List<dynamic>? ?? [];

//     final monthData =
//         data.where((item) {
//           final itemDate = DateTime.parse(item['종료시간']);
//           return itemDate.isAfter(startOfMonth) &&
//               itemDate.isBefore(endOfMonth.add(Duration(days: 1)));
//         }).toList();

//     return _aggregateData(monthData);
//   }
// }

import 'package:flutter/material.dart';

class ActivityLogProvider extends ChangeNotifier {}
