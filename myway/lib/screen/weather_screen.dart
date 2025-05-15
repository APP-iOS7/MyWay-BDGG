import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../viewmodel/weather_viewmodel.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Icon(Icons.arrow_back),
        title: Text('서울특별시'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body:
          vm.isLoading
              ? Center(child: CircularProgressIndicator())
              : Center(
                child: Column(
                  children: [
                    SvgPicture.asset(vm.weatherIconPath, height: 300),
                    Text(
                      '${vm.temperature}°',
                      style: TextStyle(
                        fontSize: 75,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      vm.weatherStatus,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color(0xfffbf4ec),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '오늘의 날씨는 ${vm.weatherStatus}이며 기온은 ${vm.temperature}도입니다.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        _buildInfoCard(
                          label: "습도",
                          icon: Icons.water_drop_rounded,
                          value: '${vm.humidity}%',
                          color: Color(0xff93C5D8),
                        ),
                        SizedBox(width: 20),
                        _buildInfoCard(
                          label: "강수확률",
                          icon: Icons.water_drop,
                          value:
                              vm.rainProb.contains('비')
                                  ? vm.rainProb
                                  : '${vm.rainProb}%',
                          color: Color(0xff164F6D),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        _buildInfoCard(
                          label: "미세먼지",
                          icon: _getQualityIcon(vm.pm10Grade),
                          value: vm.pm10Grade,
                          color: _getQualityColor(vm.pm10Grade),
                        ),
                        SizedBox(width: 20),
                        _buildInfoCard(
                          label: "초미세먼지",
                          icon: _getQualityIcon(vm.pm25Grade),
                          value: vm.pm25Grade,
                          color: _getQualityColor(vm.pm25Grade),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Container(
        width: 210,
        height: 114,
        decoration: BoxDecoration(
          color: Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 12,
              child: Text(label, style: TextStyle(fontSize: 16)),
            ),
            Positioned(
              bottom: 8,
              right: 12,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  SizedBox(width: 5),
                  Text(value, style: TextStyle(fontSize: 25, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getQualityIcon(String grade) {
    switch (grade) {
      case '좋음':
        return Icons.sentiment_satisfied;
      case '보통':
        return Icons.sentiment_neutral;
      case '나쁨':
        return Icons.sentiment_dissatisfied;
      case '매우 나쁨':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.error;
    }
  }

  Color _getQualityColor(String grade) {
    switch (grade) {
      case '좋음':
        return Color(0xff006E18);
      case '보통':
        return Color(0xff1A78EC);
      case '나쁨':
        return Color(0xffFFB327);
      case '매우 나쁨':
        return Color(0xffE40730);
      default:
        return Colors.grey;
    }
  }
}
