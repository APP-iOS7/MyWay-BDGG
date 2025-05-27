import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:provider/provider.dart';

import '/provider/weather_provider.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(weatherProvider.cityName),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body:
          weatherProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.03),
                    SvgPicture.asset(
                      weatherProvider.weatherIconPath,
                      height: screenHeight * 0.15,
                    ),
                    Text(
                      '${weatherProvider.temperature}°',
                      style: TextStyle(
                        fontSize: screenHeight * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weatherProvider.weatherStatus,
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Container(
                      height: screenHeight * 0.15,
                      margin: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAC1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: weatherProvider.hourlyForecast.length,
                        itemBuilder: (context, index) {
                          final item = weatherProvider.hourlyForecast[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item['time'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                SvgPicture.asset(
                                  item['icon'] ??
                                      'assets/icons/weather_sun.svg',
                                  width: 28,
                                  height: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['temp'] ?? '-',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      label: "습도",
                                      icon: Icons.water_drop_rounded,
                                      value: '${weatherProvider.humidity}%',
                                      color: const Color(0xff93C5D8),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildInfoCard(
                                      label: "강수확률",
                                      icon: Icons.water_drop,
                                      value:
                                          weatherProvider.rainProb.contains('비')
                                              ? weatherProvider.rainProb
                                              : '${weatherProvider.rainProb}%',
                                      color: const Color(0xff164F6D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
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
                                  const SizedBox(width: 10),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text(label, style: const TextStyle(fontSize: 20))],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(width: 10),
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
        return const Color(0xff006E18);
      case '보통':
        return const Color(0xff1A78EC);
      case '나쁨':
        return const Color(0xffFFB327);
      case '매우 나쁨':
        return const Color(0xffE40730);
      default:
        return Colors.grey;
    }
  }
}
