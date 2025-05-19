import 'package:flutter/material.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/theme/colors.dart';
import 'package:provider/provider.dart';

enum ActivityPeriod { weekly, monthly }

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  ActivityPeriod _selectedPeriod = ActivityPeriod.weekly;
  final String _currentDisplayDateWeekly = "2025년 5월 1주";
  final String _currentDisplayDateMonthly = "2025년";

  final Map<String, double> weeklyChartData = {
    "월": 80.0,
    "화": 60.0,
    "수": 85.0,
    "목": 20.0,
    "금": 70.0,
    "토": 100.0,
    "일": 65.0,
  };
  final Map<String, double> monthlyChartData = {
    "1월": 10.0,
    "2월": 15.0,
    "3월": 70.0,
    "4월": 90.0,
    "5월": 100.0,
    "6월": 75.0,
    "7월": 10.0,
    "8월": 20.0,
    "9월": 85.0,
    "10월": 30.0,
    "11월": 5.0,
    "12월": 12.0,
  };

  @override
  void initState() {
    super.initState();
    print('ActivityLogScreen initState called. Instance: $this');
  }

  Widget _buildPeriodSelector() {
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
              onTap: () {
                if (mounted)
                  setState(() => _selectedPeriod = ActivityPeriod.weekly);
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _selectedPeriod == ActivityPeriod.weekly
                          ? BACKGROUND_COLOR
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border:
                      _selectedPeriod == ActivityPeriod.weekly
                          ? Border.all(color: GRAYSCALE_LABEL_300, width: 1.0)
                          : null,
                  boxShadow:
                      _selectedPeriod == ActivityPeriod.weekly
                          ? [
                            BoxShadow(
                              color: GRAYSCALE_LABEL_950.withOpacity(0.05),
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
                        _selectedPeriod == ActivityPeriod.weekly
                            ? GRAYSCALE_LABEL_950
                            : GRAYSCALE_LABEL_600,
                    fontWeight:
                        _selectedPeriod == ActivityPeriod.weekly
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
              onTap: () {
                if (mounted)
                  setState(() => _selectedPeriod = ActivityPeriod.monthly);
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _selectedPeriod == ActivityPeriod.monthly
                          ? BACKGROUND_COLOR
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border:
                      _selectedPeriod == ActivityPeriod.monthly
                          ? Border.all(color: GRAYSCALE_LABEL_300, width: 1.0)
                          : null,
                  boxShadow:
                      _selectedPeriod == ActivityPeriod.monthly
                          ? [
                            BoxShadow(
                              color: GRAYSCALE_LABEL_950.withOpacity(0.05),
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
                        _selectedPeriod == ActivityPeriod.monthly
                            ? GRAYSCALE_LABEL_950
                            : GRAYSCALE_LABEL_600,
                    fontWeight:
                        _selectedPeriod == ActivityPeriod.monthly
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

  Widget _buildDateSelector() {
    return Row(
      children: [
        Text(
          _selectedPeriod == ActivityPeriod.weekly
              ? _currentDisplayDateWeekly
              : _currentDisplayDateMonthly,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GRAYSCALE_LABEL_950,
          ),
        ),
        Icon(Icons.arrow_drop_down, color: GRAYSCALE_LABEL_700, size: 28),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: GRAYSCALE_LABEL_950,
          ),
        ),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: GRAYSCALE_LABEL_600)),
      ],
    );
  }

  Widget _buildSimpleBarChart() {
    final data =
        _selectedPeriod == ActivityPeriod.weekly
            ? weeklyChartData
            : monthlyChartData;
    final maxValue =
        data.isNotEmpty
            ? data.values.reduce((curr, next) => curr > next ? curr : next)
            : 1.0;

    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 10),
      height: 180,
      decoration: BoxDecoration(
        color: GRAYSCALE_LABEL_50,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: GRAYSCALE_LABEL_950.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            data.entries.map((entry) {
              final barHeight =
                  entry.value / (maxValue == 0 ? 1 : maxValue) * 100;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: _selectedPeriod == ActivityPeriod.weekly ? 22 : 12,
                    height:
                        barHeight < 5 ? 5 : (barHeight > 100 ? 100 : barHeight),
                    decoration: BoxDecoration(
                      color: CHIP_YELLOW_700,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 11, color: GRAYSCALE_LABEL_600),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);
    print('ActivityLogScreen build called. Instance: $this');

    const double horizontalPageMargin = 20.0;
    const double labelToTextMargin = 5.0;

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
            _buildPeriodSelector(),
            SizedBox(height: 24),
            _buildDateSelector(),
            SizedBox(height: labelToTextMargin + 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  stepProvider.distanceKm,
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
              style: TextStyle(fontSize: 12, color: GRAYSCALE_LABEL_600),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(stepProvider.formattedElapsed),
                Text('${stepProvider.steps}'),
              ],
            ),
            SizedBox(height: 24),
            _buildSimpleBarChart(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
