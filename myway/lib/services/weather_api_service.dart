import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherApiService {
  final String _rawApiKey =
      '6uNs/cNMeEpn9W2R9ffJaV3u6Wba2Z2GIS20vcJVsgyQG59gzIIzQFJhgnnyveDsBFFOaZ+O2k9Xb0YxzGCUpQ==';

  // 실황 날씨 API
  Future<Map<String, dynamic>?> fetchCurrentWeather({
    required String baseDate,
    required String baseTime,
    required String nx,
    required String ny,
  }) async {
    final uri = Uri.parse(
      'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst'
      '?serviceKey=${Uri.encodeComponent(_rawApiKey)}'
      '&pageNo=1'
      '&numOfRows=100'
      '&dataType=JSON'
      '&base_date=$baseDate'
      '&base_time=$baseTime'
      '&nx=$nx'
      '&ny=$ny',
    );

    try {
      final response = await http.get(uri);
      print('요청 URL: $uri');
      print('응답 상태코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response']['header']['resultCode'] == '00') {
          return data;
        } else {
          print('API 오류: ${data['response']['header']['resultMsg']}');
        }
      } else {
        print('HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('실황 날씨 파싱 실패: $e');
    }
    return null;
  }

  // 예보 날씨 API (SKY, PTY 등 추출용)
  Future<Map<String, dynamic>?> fetchForecastWeather({
    required String baseDate,
    required String baseTime,
    required String nx,
    required String ny,
  }) async {
    final uri = Uri.parse(
      'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
      '?serviceKey=${Uri.encodeComponent(_rawApiKey)}'
      '&pageNo=1'
      '&numOfRows=1000'
      '&dataType=JSON'
      '&base_date=$baseDate'
      '&base_time=$baseTime'
      '&nx=$nx'
      '&ny=$ny',
    );

    try {
      final response = await http.get(uri);
      print('예보 요청 URL: $uri');
      print('예보 응답 코드: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response']['header']['resultCode'] == '00') {
          return data;
        } else {
          print('예보 API 오류: ${data['response']['header']['resultMsg']}');
        }
      } else {
        print('예보 HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('예보 날씨 파싱 실패: $e');
    }
    return null;
  }
}
