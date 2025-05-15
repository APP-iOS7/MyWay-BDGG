import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../provider/weather_provider.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('서울특별시'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body:
          weatherProvider.isLoading
              ? Center(child: CircularProgressIndicator())
              : Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        weatherProvider.weatherIconPath,
                        height: 150,
                      ),
                      Text(
                        '${weatherProvider.temperature}°',
                        style: TextStyle(
                          fontSize: 75,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        weatherProvider.weatherStatus,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFEAC1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Consumer<WeatherProvider>(
                            builder: (context, vm, _) {
                              final forecast = vm.hourlyForecast;
                              if (forecast.isEmpty) {
                                return Center(child: Text('시간별 예보를 불러오는 중...'));
                              }

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: forecast.length,
                                itemBuilder: (context, index) {
                                  final item = forecast[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 25,
                                      right: 25,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item['time'] ?? '',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 6),
                                        SvgPicture.asset(
                                          item['icon'] ??
                                              'assets/icons/weather_sun.svg',
                                          width: 30,
                                          height: 30,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          item['temp'] ?? '-',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                label: "습도",
                                icon: Icons.water_drop_rounded,
                                value: '${weatherProvider.humidity}%',
                                color: Color(0xff93C5D8),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildInfoCard(
                                label: "강수확률",
                                icon: Icons.water_drop,
                                value:
                                    weatherProvider.rainProb.contains('비')
                                        ? weatherProvider.rainProb
                                        : '${weatherProvider.rainProb}%',
                                color: Color(0xff164F6D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                label: "미세먼지",
                                icon: _getQualityIcon(
                                  weatherProvider.pm10Grade,
                                ),
                                value: weatherProvider.pm10Grade,
                                color: _getQualityColor(
                                  weatherProvider.pm10Grade,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildInfoCard(
                                label: "초미세먼지",
                                icon: _getQualityIcon(
                                  weatherProvider.pm25Grade,
                                ),
                                value: weatherProvider.pm25Grade,
                                color: _getQualityColor(
                                  weatherProvider.pm25Grade,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text(label, style: TextStyle(fontSize: 20))],
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, size: 40, color: color),
                SizedBox(width: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
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
