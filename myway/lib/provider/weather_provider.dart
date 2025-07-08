// ignore_for_file: avoid_print

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

      // 디버깅 (개발 중에만 사용)
      await debugLocation();

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
      if (placemarks.isEmpty) {
        print('Placemark 결과 없음');
        return '위치 불명';
      }

      final placemark = placemarks.first;
      final adminArea = placemark.administrativeArea ?? '';

      print('역지오코딩 결과:');
      print('- administrativeArea: $adminArea');
      print('- locality: ${placemark.locality}');
      print('- subAdministrativeArea: ${placemark.subAdministrativeArea}');
      print('- thoroughfare: ${placemark.thoroughfare}');

      const regionMap = {
        '서울특별시': '서울',
        '부산광역시': '부산',
        '대구광역시': '대구',
        '인천광역시': '인천',
        '광주광역시': '광주',
        '대전광역시': '대전',
        '울산광역시': '울산',
        '세종특별자치시': '세종',
        '경기도': '경기',
        '강원도': '강원',
        '강원특별자치도': '강원',
        '충청북도': '충북',
        '충청남도': '충남',
        '전라북도': '전북',
        '전북특별자치도': '전북',
        '전라남도': '전남',
        '경상북도': '경북',
        '경상남도': '경남',
        '제주특별자치도': '제주',
      };

      final mappedRegion = regionMap[adminArea];
      if (mappedRegion != null) {
        print('지역 매핑 성공: $adminArea -> $mappedRegion');
        return mappedRegion;
      }

      if (adminArea.isNotEmpty) {
        print('매핑되지 않은 지역: $adminArea (원본 반환)');
        return adminArea;
      }

      final locality = placemark.locality ?? '';
      if (locality.isNotEmpty) {
        print('locality 사용: $locality');
        return locality;
      }

      print('위치 정보 부족 - 좌표: ($lat, $lon)');
      return '위치 불명';
    } catch (e) {
      print('역지오코딩 실패: $e');
      print('실패한 좌표: ($lat, $lon)');
      return '위치 불명';
    }
  }

  Future<void> debugLocation() async {
    try {
      final current = await location.getLocation();
      print('=== 위치 디버깅 ===');
      print('위도: ${current.latitude}');
      print('경도: ${current.longitude}');
      print('정확도: ${current.accuracy}m');
      print('위치 제공자: ${current.provider}');

      if (current.latitude != null && current.longitude != null) {
        final cityName = await _getAddressFromCoordinates(
          current.latitude!,
          current.longitude!,
        );
        print('최종 도시명: $cityName');
      }
    } catch (e) {
      print('위치 디버깅 실패: $e');
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
    final dateTime = WeatherServiceHelper.getSafeUltraSrtNcstDateTime(now);

    final data = await _weatherApi.fetchCurrentWeather(
      baseDate: dateTime['date']!,
      baseTime: dateTime['time']!,
      nx: nx,
      ny: ny,
    );

    if (data != null) {
      final items = data['response']['body']['items']['item'] as List<dynamic>;
      String currentRain = '0';

      for (var item in items) {
        switch (item['category']) {
          case 'T1H':
            temperature = item['obsrValue'];
            break;
          case 'REH':
            humidity = item['obsrValue'];
            break;
          case 'RN1':
            currentRain = item['obsrValue'];
            rainProb = (currentRain != '0') ? '비 ${currentRain}mm' : '0';
            break;
          case 'PTY':
            if (item['obsrValue'] != '0') {
              _updateWeatherFromPty(item['obsrValue'], now);
              return;
            }
            break;
        }
      }

      if (currentRain != '0' &&
          double.tryParse(currentRain) != null &&
          double.parse(currentRain) > 0) {
        weatherStatus = '비';
        weatherIconPath = 'assets/icons/weather_rain.svg';
        print('실시간 강수량 감지: ${currentRain}mm - 비 아이콘으로 설정');
      }
    }
  }

  void _updateWeatherFromPty(String pty, DateTime now) {
    switch (pty) {
      case '1':
        weatherStatus = '비';
        weatherIconPath = _getWeatherIconPath(
          '비',
          WeatherServiceHelper.isNightTime(now),
        );
        break;
      case '2':
        weatherStatus = '비/눈';
        weatherIconPath = _getWeatherIconPath(
          '비',
          WeatherServiceHelper.isNightTime(now),
        );
        break;
      case '3':
        weatherStatus = '눈';
        weatherIconPath = _getWeatherIconPath(
          '눈',
          WeatherServiceHelper.isNightTime(now),
        );
        break;
      case '4':
        weatherStatus = '소나기';
        weatherIconPath = _getWeatherIconPath(
          '소나기',
          WeatherServiceHelper.isNightTime(now),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _fetchSkyPty(String nx, String ny) async {
    if (weatherStatus == '비' ||
        weatherStatus == '눈' ||
        weatherStatus == '소나기' ||
        weatherStatus == '천둥') {
      print('실시간 강수 상태 유지: $weatherStatus');
      return;
    }

    final now = DateTime.now();
    final baseDateTime = WeatherServiceHelper.getSafeForecastDateTime(now);
    final targetDateTime = WeatherServiceHelper.getFcstTargetDateTime(now);

    final data = await _weatherApi.fetchForecastWeather(
      baseDate: baseDateTime['date']!,
      baseTime: baseDateTime['time']!,
      nx: nx,
      ny: ny,
    );

    if (data != null) {
      try {
        final items =
            data['response']['body']['items']['item'] as List<dynamic>;

        final currentPtyItem = items.firstWhere(
          (e) =>
              e['category'] == 'PTY' &&
              e['fcstTime'] == targetDateTime['time'] &&
              e['fcstDate'] == targetDateTime['date'],
          orElse: () => null,
        );

        if (currentPtyItem != null && currentPtyItem['fcstValue'] != '0') {
          _updateWeatherFromPty(currentPtyItem['fcstValue'], now);
          return;
        }

        final skyItem = items.firstWhere(
          (e) =>
              e['category'] == 'SKY' &&
              e['fcstTime'] == targetDateTime['time'] &&
              e['fcstDate'] == targetDateTime['date'],
          orElse: () => null,
        );

        if (skyItem != null) {
          final sky = skyItem['fcstValue'];
          weatherStatus = _getWeatherStatusFromSky(sky);
          weatherIconPath = _getWeatherIconPath(
            weatherStatus,
            WeatherServiceHelper.isNightTime(now),
          );
        } else {
          print('정확한 시간대 데이터 없음 - 가장 가까운 시간 찾기');
          _findClosestTimeData(items, targetDateTime['time']!);
        }
      } catch (e) {
        print('SKY/PTY 데이터 파싱 오류: $e');
        weatherStatus = '정보 없음';
        weatherIconPath = 'assets/icons/weather_cloud.svg';
      }
    }
  }

  String _getWeatherStatusFromSky(String sky) {
    switch (sky) {
      case '1':
        return '맑음';
      case '3':
        return '구름조금';
      case '4':
        return '흐림';
      default:
        return '맑음';
    }
  }

  void _findClosestTimeData(List<dynamic> items, String targetTime) {
    final targetHour = int.parse(targetTime.substring(0, 2));

    final Map<int, Map<String, String>> timeData = {};

    for (var item in items) {
      if (item['category'] == 'SKY' || item['category'] == 'PTY') {
        final timeStr = item['fcstTime'] as String;
        final hour = int.parse(timeStr.substring(0, 2));

        timeData.putIfAbsent(hour, () => {});
        timeData[hour]![item['category']] = item['fcstValue'];
      }
    }

    int? closestHour;
    int minDiff = 24;

    for (final hour in timeData.keys) {
      int diff;
      if (hour >= targetHour) {
        diff = hour - targetHour;
      } else {
        diff = (24 - targetHour) + hour;
      }

      if (diff < minDiff &&
          timeData[hour]!.containsKey('SKY') &&
          timeData[hour]!.containsKey('PTY')) {
        minDiff = diff;
        closestHour = hour;
      }
    }

    if (closestHour != null) {
      final sky = timeData[closestHour]!['SKY']!;
      final pty = timeData[closestHour]!['PTY']!;
      weatherStatus = _getWeatherStatus(sky, pty);
      weatherIconPath = _getWeatherIconPath(
        weatherStatus,
        WeatherServiceHelper.isNightTime(DateTime.now()),
      );
      print('폴백: $closestHour시 데이터 사용 (목표: $targetHour시)');
    } else {
      weatherStatus = '정보 없음';
      weatherIconPath = 'assets/icons/weather_cloud.svg';
      print('사용 가능한 날씨 데이터 없음');
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
    final baseDateTime = WeatherServiceHelper.getSafeForecastDateTime(now);

    final data = await _weatherApi.fetchForecastWeather(
      baseDate: baseDateTime['date']!,
      baseTime: baseDateTime['time']!,
      nx: nx,
      ny: ny,
    );
    if (data != null) {
      try {
        final items =
            data['response']['body']['items']['item'] as List<dynamic>;
        final forecastMap = <String, Map<String, String>>{};

        final currentHour = now.hour;
        final targetHours = <int>[];

        for (int i = 0; i < 8; i++) {
          int hour = ((currentHour ~/ 3) * 3 + (i * 3)) % 24;
          targetHours.add(hour);
        }

        for (var item in items) {
          final fcstDate = item['fcstDate'] as String;
          final fcstTime = item['fcstTime'] as String;
          final hour = int.parse(fcstTime.substring(0, 2));

          if (!targetHours.contains(hour)) continue;

          final dateTimeKey = '${fcstDate}_$fcstTime';

          forecastMap.putIfAbsent(
            dateTimeKey,
            () => {'date': fcstDate, 'time': fcstTime},
          );

          switch (item['category']) {
            case 'TMP':
              forecastMap[dateTimeKey]!['temp'] = item['fcstValue'];
              break;
            case 'SKY':
              forecastMap[dateTimeKey]!['sky'] = item['fcstValue'];
              break;
            case 'PTY':
              forecastMap[dateTimeKey]!['pty'] = item['fcstValue'];
              break;
          }
        }

        final sortedEntries =
            forecastMap.entries.toList()..sort((a, b) {
              final aDateTime = DateTime.parse(
                '${a.value['date']} ${a.value['time']?.substring(0, 2)}:00:00',
              );
              final bDateTime = DateTime.parse(
                '${b.value['date']} ${b.value['time']?.substring(0, 2)}:00:00',
              );
              return aDateTime.compareTo(bDateTime);
            });

        hourlyForecast =
            sortedEntries
                .where(
                  (entry) =>
                      entry.value['temp'] != null &&
                      entry.value['sky'] != null &&
                      entry.value['pty'] != null,
                )
                .take(8)
                .map((entry) {
                  final time = entry.value['time']!;
                  final timeLabel = '${time.substring(0, 2)}시';
                  final status = _getWeatherStatus(
                    entry.value['sky'] ?? '1',
                    entry.value['pty'] ?? '0',
                  );

                  final hour = int.parse(time.substring(0, 2));
                  final isNight = hour < 6 || hour >= 18;
                  final iconPath = _getWeatherIconPath(status, isNight);

                  return {
                    'time': timeLabel,
                    'temp': '${entry.value['temp']}\u00b0',
                    'icon': iconPath,
                  };
                })
                .toList();

        print('시간별 예보 수집 완료: ${hourlyForecast.length}개');
      } catch (e) {
        print('시간별 예보 파싱 오류: $e');
        hourlyForecast = [];
      }
    } else {
      print('시간별 예보 데이터 없음');
      hourlyForecast = [];
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

  static Map<String, String> getSafeUltraSrtNcstDateTime(DateTime now) {
    DateTime baseDateTime =
        now.minute < 40 ? now.subtract(Duration(hours: 1)) : now;

    return {
      'date': formatDate(baseDateTime),
      'time': '${baseDateTime.hour.toString().padLeft(2, '0')}00',
    };
  }

  static Map<String, String> getSafeForecastDateTime(DateTime now) {
    final times = [2, 5, 8, 11, 14, 17, 20, 23];

    int selectedHour = times.first;
    for (final t in times) {
      if (now.hour >= t) {
        selectedHour = t;
      } else {
        break;
      }
    }

    DateTime baseDateTime;
    if (now.hour < 2) {
      baseDateTime = DateTime(now.year, now.month, now.day - 1, 23, 0);
      selectedHour = 23;
    } else {
      baseDateTime = DateTime(now.year, now.month, now.day, selectedHour, 0);
    }

    return {
      'date': formatDate(baseDateTime),
      'time': '${selectedHour.toString().padLeft(2, '0')}00',
    };
  }

  static String getFcstTargetTime(DateTime now) {
    int targetHour = now.minute >= 45 ? now.hour + 1 : now.hour;

    if (targetHour >= 24) {
      targetHour = 0;
    }

    return '${targetHour.toString().padLeft(2, '0')}00';
  }

  static Map<String, String> getFcstTargetDateTime(DateTime now) {
    DateTime targetDateTime;

    if (now.minute >= 45) {
      targetDateTime = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    } else {
      targetDateTime = DateTime(now.year, now.month, now.day, now.hour, 0);
    }

    return {
      'date': formatDate(targetDateTime),
      'time': '${targetDateTime.hour.toString().padLeft(2, '0')}00',
    };
  }

  static bool isNightTime(DateTime now) {
    return now.hour < 6 || now.hour >= 18;
  }
}
