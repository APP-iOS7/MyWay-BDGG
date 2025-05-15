import 'package:flutter/material.dart';

import '../services/airquality_api_service.dart';
import '../services/weather_api_service.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherApiService _weatherApi = WeatherApiService();
  final AirQualityService _airApi = AirQualityService();

  bool isLoading = true;

  String temperature = '-';
  String humidity = '-';
  String rainProb = '-';
  String weatherStatus = '-';
  String weatherIconPath = 'assets/icons/weather_sun.svg';

  String pm10Value = '-';
  String pm25Value = '-';
  String pm10Grade = '-';
  String pm25Grade = '-';

  Future<void> loadWeather() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchCurrentWeather(),
      _fetchSkyPty(),
      _fetchAirQuality(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchCurrentWeather() async {
    final now = DateTime.now();
    final baseDate =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final baseTime = _getUltraSrtNcstBaseTime(now);
    const nx = '59';
    const ny = '126';

    final data = await _weatherApi.fetchCurrentWeather(
      baseDate: baseDate,
      baseTime: baseTime,
      nx: nx,
      ny: ny,
    );

    if (data != null) {
      final items = data['response']['body']['items']['item'] as List<dynamic>;

      for (var item in items) {
        switch (item['category']) {
          case 'T1H':
            temperature = item['obsrValue'];
            break;
          case 'REH':
            humidity = item['obsrValue'];
            break;
          case 'RN1':
            rainProb =
                (item['obsrValue'] != '0') ? '비 ${item['obsrValue']}mm' : '0';
            break;
        }
      }
    }
  }

  Future<void> _fetchSkyPty() async {
    final now = DateTime.now();
    final baseDate =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final baseTime = _getForecastBaseTime(now);
    final fcstTime = _getFcstTime(now);
    const nx = '59';
    const ny = '126';

    final data = await _weatherApi.fetchForecastWeather(
      baseDate: baseDate,
      baseTime: baseTime,
      nx: nx,
      ny: ny,
    );

    if (data != null) {
      final items = data['response']['body']['items']['item'] as List<dynamic>;

      final sky =
          items.firstWhere(
            (e) => e['category'] == 'SKY' && e['fcstTime'] == fcstTime,
          )['fcstValue'];
      final pty =
          items.firstWhere(
            (e) => e['category'] == 'PTY' && e['fcstTime'] == fcstTime,
          )['fcstValue'];

      weatherStatus = _getWeatherStatus(sky, pty);
      weatherIconPath = _getWeatherIconPath(weatherStatus, _isNightTime(now));
    }
  }

  Future<void> _fetchAirQuality() async {
    final data = await _airApi.fetchAirQuality('서울');
    if (data != null) {
      final items = data['response']['body']['items'] as List<dynamic>;
      final first = items.first;

      pm10Value = first['pm10Value'] ?? '-';
      pm25Value = first['pm25Value'] ?? '-';
      pm10Grade = _getDustGrade(int.tryParse(pm10Value));
      pm25Grade = _getDustGrade(int.tryParse(pm25Value));
    }
  }

  String _getUltraSrtNcstBaseTime(DateTime now) =>
      (now.minute < 40 ? now.subtract(Duration(hours: 1)) : now).hour
          .toString()
          .padLeft(2, '0') +
      '00';

  String _getForecastBaseTime(DateTime now) {
    final times = [2, 5, 8, 11, 14, 17, 20, 23];
    return times.where((t) => now.hour >= t).last.toString().padLeft(2, '0') +
        '00';
  }

  String _getFcstTime(DateTime now) =>
      (now.minute >= 45 ? now.hour + 1 : now.hour).toString().padLeft(2, '0') +
      '00';

  bool _isNightTime(DateTime now) => now.hour < 6 || now.hour >= 18;

  String _getWeatherStatus(String sky, String pty) {
    if (pty != '0') {
      switch (pty) {
        case '1':
          return '비';

        case '3':
          return '눈';
        case '4':
          return '소나기';
        case '5':
        case '6':
          return '천둥';
      }
    }
    switch (sky) {
      case '1':
        return '맑음';
      case '3':
        return '구름조금';
      case '4':
        return '흐림';
    }
    return '맑음';
  }

  String _getWeatherIconPath(String status, bool isNight) {
    switch (status) {
      case '맑음':
        return isNight
            ? 'assets/icons/weather_moon.svg'
            : 'assets/icons/weather_sun.svg';
      case '구름조금':
        return 'assets/icons/weather_clsun.svg';
      case '흐림':
        return 'assets/icons/weather_cloud.svg';
      case '비':
        return 'assets/icons/weather_rain.svg';
      case '소나기':
        return 'assets/icons/weather_rain.svg';

      case '눈':
        return 'assets/icons/weather_snow.svg';
      case '천둥':
        return 'assets/icons/weather_thunder.svg';
      default:
        return 'assets/icons/weather_cloud.svg';
    }
  }

  String _getDustGrade(int? value) {
    if (value == null) return '-';
    if (value <= 30) return '좋음';
    if (value <= 80) return '보통';
    if (value <= 150) return '나쁨';
    return '매우 나쁨';
  }
}
