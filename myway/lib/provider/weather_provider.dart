import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import '../services/airquality_api_service.dart';
import '../services/weather_api_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherApiService _weatherApi = WeatherApiService();
  final AirQualityService _airApi = AirQualityService();
  final loc.Location location = loc.Location();

  bool isLoading = true;
  String cityName = '현재 위치';

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

    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        print('위치 권한 거부됨');
        cityName = '위치 권한 필요';
        isLoading = false;
        notifyListeners();
        return;
      }

      final current = await location.getLocation();
      final grid = convertToGrid(current.latitude!, current.longitude!);
      cityName = await _getAddressFromCoordinates(
        current.latitude!,
        current.longitude!,
      );

      final nx = grid['nx']!;
      final ny = grid['ny']!;

      await Future.wait([
        _fetchCurrentWeather(nx, ny),
        _fetchSkyPty(nx, ny),
        _fetchAirQuality(cityName),
        _fetchHourlyForecast(nx, ny),
      ]);
    } catch (e) {
      print('위치 기반 날씨 로딩 오류: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> _checkLocationPermission() async {
    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) {
        return false;
      }
    }

    final serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      final enabled = await location.requestService();
      if (!enabled) return false;
    }

    return true;
  }

  Future<String> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      final adminArea = placemarks.first.administrativeArea ?? '서울특별시';

      if (adminArea.contains('서울')) return '서울';
      if (adminArea.contains('부산')) return '부산';
      if (adminArea.contains('대구')) return '대구';
      if (adminArea.contains('인천')) return '인천';
      if (adminArea.contains('광주')) return '광주';
      if (adminArea.contains('대전')) return '대전';
      if (adminArea.contains('울산')) return '울산';
      if (adminArea.contains('세종')) return '세종';
      if (adminArea.contains('경기')) return '경기';
      if (adminArea.contains('강원')) return '강원';
      if (adminArea.contains('충북')) return '충북';
      if (adminArea.contains('충남')) return '충남';
      if (adminArea.contains('전북')) return '전북';
      if (adminArea.contains('전남')) return '전남';
      if (adminArea.contains('경북')) return '경북';
      if (adminArea.contains('경남')) return '경남';
      if (adminArea.contains('제주')) return '제주';

      return '서울'; // fallback (혹시라도 실패할 경우)
    } catch (e) {
      print('역지오코딩 실패: $e');
      return '위치 불명';
    }
  }

  Map<String, String> convertToGrid(double lat, double lon) {
    const RE = 6371.00877, GRID = 5.0;
    const SLAT1 = 30.0, SLAT2 = 60.0, OLON = 126.0, OLAT = 38.0;
    const XO = 43, YO = 136;
    final DEGRAD = pi / 180.0;
    final re = RE / GRID;
    final slat1 = SLAT1 * DEGRAD, slat2 = SLAT2 * DEGRAD;
    final olon = OLON * DEGRAD, olat = OLAT * DEGRAD;

    var sn =
        log(cos(slat1) / cos(slat2)) /
        log(tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5));
    var sf = pow(tan(pi * 0.25 + slat1 * 0.5), sn) * cos(slat1) / sn;
    var ro = re * sf / pow(tan(pi * 0.25 + olat * 0.5), sn);
    var ra = re * sf / pow(tan(pi * 0.25 + lat * DEGRAD * 0.5), sn);
    var theta = lon * DEGRAD - olon;
    if (theta > pi) theta -= 2 * pi;
    if (theta < -pi) theta += 2 * pi;
    theta *= sn;

    final nx = (ra * sin(theta) + XO + 0.5).floor();
    final ny = (ro - ra * cos(theta) + YO + 0.5).floor();

    return {'nx': nx.toString(), 'ny': ny.toString()};
  }

  Future<void> _fetchCurrentWeather(String nx, String ny) async {
    final now = DateTime.now();
    final baseDate = WeatherServiceHelper.formatDate(now);
    final baseTime = WeatherServiceHelper.getSafeUltraSrtNcstBaseTime(now);

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

  Future<void> _fetchSkyPty(String nx, String ny) async {
    final now = DateTime.now();
    final baseDate = WeatherServiceHelper.formatDate(now);
    final baseTime = WeatherServiceHelper.getSafeForecastBaseTime(now);
    final fcstTime = WeatherServiceHelper.getFcstTargetTime(now);

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

  Future<void> _fetchAirQuality(String region) async {
    final data = await _airApi.fetchAirQuality(region);
    if (data != null) {
      final items = data['response']['body']['items'] as List<dynamic>;
      final first = items.first;
      pm10Value = first['pm10Value'] ?? '-';
      pm25Value = first['pm25Value'] ?? '-';
      pm10Grade = _getDustGrade(int.tryParse(pm10Value));
      pm25Grade = _getDustGrade(int.tryParse(pm25Value));
    }
  }

  Future<void> _fetchHourlyForecast(String nx, String ny) async {
    final now = DateTime.now();
    final baseDate = WeatherServiceHelper.formatDate(now);
    final baseTime = WeatherServiceHelper.getSafeForecastBaseTime(now);

    final data = await _weatherApi.fetchForecastWeather(
      baseDate: baseDate,
      baseTime: baseTime,
      nx: nx,
      ny: ny,
    );

    if (data != null) {
      final items = data['response']['body']['items']['item'] as List<dynamic>;
      final forecastMap = <String, Map<String, String>>{};

      for (var item in items) {
        final time = item['fcstTime'];
        if (!_isEvery3Hour(time)) continue;

        forecastMap.putIfAbsent(time, () => {});
        if (item['category'] == 'TMP')
          forecastMap[time]!['temp'] = item['fcstValue'];
        if (item['category'] == 'SKY')
          forecastMap[time]!['sky'] = item['fcstValue'];
        if (item['category'] == 'PTY')
          forecastMap[time]!['pty'] = item['fcstValue'];
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
              'temp': '${e.value['temp']}\u00b0',
              'icon': iconPath,
            };
          }).toList();
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
