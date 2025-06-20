import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/model/activity_period.dart';
import 'package:myway/provider/activity_log_provider.dart';
import 'package:provider/provider.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드 및 현재 주차 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityProvider = context.read<ActivityLogProvider>();
      // 주간기록 모드 일때 현재 주차로 설정
      if (activityProvider.selectedPeriod == ActivityPeriod.weekly) {}
      // activityProvider.loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityLogProvider>(
      builder: (context, activityProvider, child) {
        return Scaffold(
          backgroundColor: BACKGROUND_COLOR,
          appBar: AppBar(
            backgroundColor: BACKGROUND_COLOR,
            elevation: 0,
            title: Text(
              "나의 활동 기록",
              style: TextStyle(
                color: GRAYSCALE_LABEL_950,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: _buildBody(activityProvider),
        );
      },
    );
  }

  Widget _buildBody(ActivityLogProvider activityProvider) {
    // 전체 데이터가 없는경우
    if (activityProvider.hasNoData) {
      return _buildNoDataMessage();
    }

    // 선택된 기간에 데이터가 없는 경우
    if (activityProvider.hasNoDataInCurrentPeriod) {
      return _buildNoDataInPeriodMessage(activityProvider);
    }

    // 데이터가 있는 경우
    return _buildDataContent(activityProvider);
  }

  // 전체 데이터가 없을때의 메시지
  Widget _buildNoDataMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 200),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '저장된 활동이 없습니다.',
              style: TextStyle(
                fontSize: 20,
                color: GRAYSCALE_LABEL_800,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '산책을 시작해서 나만의 활동을 기록 해보세요!',
              style: TextStyle(
                fontSize: 16,
                color: GRAYSCALE_LABEL_600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 선택된 기간에 데이터가 없을 때의 메시지
  Widget _buildNoDataInPeriodMessage(ActivityLogProvider activityProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(context, activityProvider),
          SizedBox(height: 24),
          _buildDateSelector(context, activityProvider),
          SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 30,
                  color: BLUE_SECONDARY_500,
                ),
                SizedBox(height: 10),
                Text(
                  activityProvider.getNoDataMessage(),
                  style: TextStyle(
                    fontSize: 18,
                    color: GRAYSCALE_LABEL_900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '다른 기간을 선택해보세요',
                  style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 데이터가 있을 때의 내용
  Widget _buildDataContent(ActivityLogProvider activityProvider) {
    const double horizontalPageMargin = 20.0;
    const double labelToTextMargin = 5.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPageMargin,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildPeriodSelector(context, activityProvider),
          SizedBox(height: 24),
          _buildDateSelector(context, activityProvider),
          SizedBox(height: labelToTextMargin + 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                activityProvider.totalDistance.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: GRAYSCALE_LABEL_950,
                  height: 1.1,
                ),
              ),
              SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GRAYSCALE_LABEL_950,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: labelToTextMargin - 1),
          Text(
            '거리',
            style: TextStyle(
              fontSize: 14,
              color: GRAYSCALE_LABEL_800,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          Row(
            spacing: 20,
            children: [_buildStatItem(context, activityProvider)],
          ),
          SizedBox(height: 24),
          _buildBarChart(context, activityProvider),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // 주간기록 / 월간기록 선택 버튼
  Widget _buildPeriodSelector(
    BuildContext context,
    ActivityLogProvider activityProvider,
  ) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: GRAYSCALE_LABEL_100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => activityProvider.setPeriod(ActivityPeriod.weekly),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      activityProvider.selectedPeriod == ActivityPeriod.weekly
                          ? BACKGROUND_COLOR
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border:
                      activityProvider.selectedPeriod == ActivityPeriod.weekly
                          ? Border.all(color: GRAYSCALE_LABEL_300, width: 1.0)
                          : null,
                  boxShadow:
                      activityProvider.selectedPeriod == ActivityPeriod.weekly
                          ? [
                            BoxShadow(
                              color: GRAYSCALE_LABEL_950.withAlpha(1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ]
                          : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  "주간 기록",
                  style: TextStyle(
                    color:
                        activityProvider.selectedPeriod == ActivityPeriod.weekly
                            ? GRAYSCALE_LABEL_950
                            : GRAYSCALE_LABEL_600,
                    fontWeight:
                        activityProvider.selectedPeriod == ActivityPeriod.weekly
                            ? FontWeight.bold
                            : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => activityProvider.setPeriod(ActivityPeriod.monthly),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      activityProvider.selectedPeriod == ActivityPeriod.monthly
                          ? BACKGROUND_COLOR
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border:
                      activityProvider.selectedPeriod == ActivityPeriod.monthly
                          ? Border.all(color: GRAYSCALE_LABEL_300, width: 1.0)
                          : null,
                  boxShadow:
                      activityProvider.selectedPeriod == ActivityPeriod.monthly
                          ? [
                            BoxShadow(
                              color: GRAYSCALE_LABEL_950.withAlpha(1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ]
                          : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  "월간 기록",
                  style: TextStyle(
                    color:
                        activityProvider.selectedPeriod ==
                                ActivityPeriod.monthly
                            ? GRAYSCALE_LABEL_950
                            : GRAYSCALE_LABEL_600,
                    fontWeight:
                        activityProvider.selectedPeriod ==
                                ActivityPeriod.monthly
                            ? FontWeight.bold
                            : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 선택버튼
  Widget _buildDateSelector(
    BuildContext context,
    ActivityLogProvider activityProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (activityProvider.selectedPeriod == ActivityPeriod.weekly)
          Theme(
            data: Theme.of(context).copyWith(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: ORANGE_PRIMARY_500.withValues(alpha: 0.3),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                focusColor: Colors.transparent,
                dropdownColor: Colors.white,
                // value 설정 수정
                value:
                    activityProvider.selectedRange.isEmpty
                        ? null
                        : activityProvider.selectedRange,
                hint: Text(
                  '주를 선택하세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: GRAYSCALE_LABEL_600,
                  ),
                ),
                items:
                    activityProvider.availableWeeklyRanges.map((range) {
                      return DropdownMenuItem<String>(
                        value: range,
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: GRAYSCALE_LABEL_950,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    activityProvider.updateSelectedRange(newValue);
                  }
                },
                selectedItemBuilder: (BuildContext context) {
                  return activityProvider.availableWeeklyRanges.map((range) {
                    return Center(
                      child: Text(
                        range,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: GRAYSCALE_LABEL_950,
                        ),
                      ),
                    );
                  }).toList();
                },
                icon: Icon(
                  Icons.keyboard_arrow_down_outlined,
                  color: GRAYSCALE_LABEL_950,
                ),
              ),
            ),
          )
        else
          // 월간 선택 시 드롭다운
          Theme(
            data: Theme.of(context).copyWith(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: ORANGE_PRIMARY_500.withValues(alpha: 0.3),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: activityProvider.currentYearMonth,
                focusColor: Colors.transparent,
                dropdownColor: Colors.white,
                items:
                    activityProvider.availableYearMonthCombinations.map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: GRAYSCALE_LABEL_950,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    activityProvider.updateYearMonth(newValue);
                  }
                },

                selectedItemBuilder: (BuildContext context) {
                  return activityProvider.availableYearMonthCombinations.map((
                    String value,
                  ) {
                    return Center(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: GRAYSCALE_LABEL_950,
                        ),
                      ),
                    );
                  }).toList();
                },
                icon: Icon(
                  Icons.keyboard_arrow_down_outlined,
                  color: GRAYSCALE_LABEL_950,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ActivityLogProvider activityProvider,
  ) {
    return Row(
      spacing: 50,
      children: [
        _buildValueText(
          value: activityProvider.formattedTotalDuration,
          title: '시간',
        ),
        _buildValueText(
          value: activityProvider.totalCount.toString(),
          title: '횟수',
        ),
        _buildValueText(
          value: activityProvider.totalSteps.toString(),
          title: '걸음수',
        ),
      ],
    );
  }

  Widget _buildValueText({required String value, required String title}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: GRAYSCALE_LABEL_950,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: GRAYSCALE_LABEL_800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    ActivityLogProvider activityProvider,
  ) {
    return Container(
      height: 330,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: GRAYSCALE_LABEL_950.withAlpha(10),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          // 주간 기록
          Expanded(
            child:
                activityProvider.selectedPeriod == ActivityPeriod.weekly
                    ? FutureBuilder<List<FlSpot>>(
                      future: activityProvider.weeklyChartData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: ORANGE_PRIMARY_500,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '데이터를 불러오는데 실패했습니다.',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_600,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '표시할 데이터가 없습니다.',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_600,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        double maxYValue = snapshot.data!
                            .map((e) => e.y)
                            .reduce((a, b) => a > b ? a : b);

                        maxYValue = ((maxYValue / 5).ceil() * 5);
                        return BarChart(
                          BarChartData(
                            maxY: maxYValue,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                tooltipMargin: 5,
                                tooltipPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                getTooltipColor:
                                    (_) => Colors.black.withAlpha(90),
                                getTooltipItem: (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) {
                                  return BarTooltipItem(
                                    '${rod.toY.toStringAsFixed(1)}km',
                                    TextStyle(
                                      color: WHITE,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ),
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()} km',
                                      style: TextStyle(
                                        color: GRAYSCALE_LABEL_900,
                                        fontSize: 13,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = [
                                      '월',
                                      '화',
                                      '수',
                                      '목',
                                      '금',
                                      '토',
                                      '일',
                                    ];
                                    return Text(
                                      days[value.toInt()],
                                      style: TextStyle(
                                        color: GRAYSCALE_LABEL_900,
                                        fontSize: 13,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups:
                                snapshot.data?.asMap().entries.map((enrty) {
                                  return BarChartGroupData(
                                    x: enrty.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: enrty.value.y,
                                        color: YELLOW_INFO_BASE_30,
                                        width: 16,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }).toList() ??
                                [],
                          ),
                        );
                      },
                    )
                    // 월간 기록
                    : FutureBuilder<List<BarChartGroupData>>(
                      future: activityProvider.monthlyChartData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: ORANGE_PRIMARY_500,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '차트를 불러오는데 실패했습니다.',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_600,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '표시할 데이터가 없습니다.',
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_600,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        double maxY = snapshot.data!
                            .map((e) => e.barRods.first.toY)
                            .fold<double>(
                              0,
                              (prev, curr) => curr > prev ? curr : prev,
                            );

                        maxY = ((maxY / 10).ceil() * 10);
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 12 * 40,
                            height: 330,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: BarChart(
                                BarChartData(
                                  maxY: maxY,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipMargin: 5,
                                      tooltipPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      getTooltipColor:
                                          (_) => Colors.black.withAlpha(90),
                                      getTooltipItem: (
                                        group,
                                        groupIndex,
                                        rod,
                                        rodIndex,
                                      ) {
                                        return BarTooltipItem(
                                          '${rod.toY.toStringAsFixed(1)}km',
                                          TextStyle(
                                            color: WHITE,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        interval: 10,
                                        showTitles: true,
                                        reservedSize: 40,

                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()} km',
                                            style: TextStyle(
                                              color: GRAYSCALE_LABEL_900,
                                              fontSize: 13,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()}월',
                                            style: TextStyle(
                                              color: GRAYSCALE_LABEL_900,
                                              fontSize: 13,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: false,
                                        reservedSize: 20,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: snapshot.data ?? [],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
