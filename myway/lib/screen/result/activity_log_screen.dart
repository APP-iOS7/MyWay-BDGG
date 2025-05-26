import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/model/activity_period.dart';
import 'package:myway/provider/activity_log_provider.dart';
import 'package:provider/provider.dart';

import '../../const/colors.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  // Widget _buildSimpleBarChart() {
  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityLogProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPageMargin = 20.0;
    const double labelToTextMargin = 5.0;

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
          body: SingleChildScrollView(
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
                      activityProvider.totalDistance.toString(),
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
                        "km",
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
                  "거리",
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
                // _buildSimpleBarChart(),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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
      children: [
        Text(
          activityProvider.selectedPeriod == ActivityPeriod.weekly
              ? activityProvider.currentDisplayDateWeekly
              : activityProvider.currentDisplayDateMonthly,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GRAYSCALE_LABEL_950,
          ),
        ),
        SizedBox(width: 5),
        if (activityProvider.selectedPeriod == ActivityPeriod.weekly) ...[
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: activityProvider.selectedMonth,
              items:
                  activityProvider.availableMonths.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  activityProvider.setSelectedMonth(newValue);
                }
              },
            ),
          ),
          SizedBox(width: 5),
          // 주 선택 드롭다운
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: activityProvider.selectedWeek,
              items:
                  activityProvider.currentAvailableWeeks.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  activityProvider.updateSelectedWeek(newValue);
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ActivityLogProvider activityProvider,
  ) {
    return Row(
      spacing: 20,
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
}
