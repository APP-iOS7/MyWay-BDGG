import 'package:flutter/material.dart';

import '../services/airquality_api_service.dart';
import '../services/weather_api_service.dart';

class WeatherProvider extends ChangeNotifier {
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

  List<Map<String, String>> hourlyForecast = [];

  Future<void> loadWeather() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchCurrentWeather(),
      _fetchSkyPty(),
      _fetchAirQuality(),
      _fetchHourlyForecast(),
    ]);

    isLoading = false;
    notifyListeners();

    await _fetchHourlyForecast();
  }

  Future<void> _fetchCurrentWeather() async {
    final now = DateTime.now();
    final baseDate = WeatherServiceHelper.formatDate(now);
    final baseTime = WeatherServiceHelper.getSafeUltraSrtNcstBaseTime(now);
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
    final baseDate = WeatherServiceHelper.formatDate(now);
    final baseTime = WeatherServiceHelper.getSafeForecastBaseTime(now);
    final fcstTime = WeatherServiceHelper.getFcstTargetTime(now);
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

      final skyItem = items.firstWhere(
        (e) => e['category'] == 'SKY' && e['fcstTime'] == fcstTime,
        orElse: () => null,
      );
      final ptyItem = items.firstWhere(
        (e) => e['category'] == 'PTY' && e['fcstTime'] == fcstTime,
        orElse: () => null,
      );

      if (skyItem != null && ptyItem != null) {
        final sky = skyItem['fcstValue'];
        final pty = ptyItem['fcstValue'];

        weatherStatus = _getWeatherStatus(sky, pty);
        weatherIconPath = _getWeatherIconPath(
          weatherStatus,
          WeatherServiceHelper.isNightTime(now),
        );
      }
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

  Future<void> _fetchHourlyForecast() async {
    final now = DateTime.now();
    final baseDate = WeatherServiceHelper.formatDate(now);
    final baseTime = WeatherServiceHelper.getSafeForecastBaseTime(now);

    final data = await _weatherApi.fetchForecastWeather(
      baseDate: baseDate,
      baseTime: baseTime,
      nx: '59',
      ny: '126',
    );

    if (data != null) {
      final items = data['response']['body']['items']['item'] as List<dynamic>;

      final forecastMap = <String, Map<String, String>>{};
      for (var item in items) {
        final time = item['fcstTime'];
        if (!_isEvery3Hour(time)) continue;

        forecastMap.putIfAbsent(time, () => {});
        if (item['category'] == 'TMP') {
          forecastMap[time]!['temp'] = item['fcstValue'];
        } else if (item['category'] == 'SKY') {
          forecastMap[time]!['sky'] = item['fcstValue'];
        } else if (item['category'] == 'PTY') {
          forecastMap[time]!['pty'] = item['fcstValue'];
        }
      }

      hourlyForecast =
          forecastMap.entries.map((e) {
            final timeLabel = '${e.key.substring(0, 2)}시';
            final status = _getWeatherStatus(
              e.value['sky'] ?? '1',
              e.value['pty'] ?? '0',
            );
            final iconPath = _getWeatherIconPath(status, false);
            return {
              'time': timeLabel,
              'temp': '${e.value['temp']}°',
              'icon': iconPath,
            };
          }).toList();

      notifyListeners();
    }
  }

  bool _isEvery3Hour(String fcstTime) {
    final hour = int.tryParse(fcstTime.substring(0, 2)) ?? 0;
    return hour % 3 == 0;
  }

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

class WeatherServiceHelper {
  static String formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  static String getSafeUltraSrtNcstBaseTime(DateTime now) {
    final baseTime = (now.minute < 40) ? now.subtract(Duration(hours: 1)) : now;
    return '${baseTime.hour.toString().padLeft(2, '0')}00';
  }

  static String getSafeForecastBaseTime(DateTime now) {
    final times = [2, 5, 8, 11, 14, 17, 20, 23];
    int selected = times.first;
    for (final t in times) {
      if (now.hour >= t) selected = t;
    }
    return '${selected.toString().padLeft(2, '0')}00';
  }

  static String getFcstTargetTime(DateTime now) {
    final targetHour = now.minute >= 45 ? now.hour + 1 : now.hour;
    return '${targetHour.toString().padLeft(2, '0')}00';
  }

  static bool isNightTime(DateTime now) {
    return now.hour < 6 || now.hour >= 18;
  }
}
