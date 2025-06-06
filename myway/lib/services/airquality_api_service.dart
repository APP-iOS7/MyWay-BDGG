import 'dart:convert';
import 'package:http/http.dart' as http;

import '../const/key.dart';

class AirQualityService {
  final String _apiKey = airquality_api_key;

  Future<Map<String, dynamic>?> fetchAirQuality(String sido) async {
    final uri = Uri.parse(
      'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
      '?serviceKey=$_apiKey'
      '&returnType=json'
      '&sidoName=$sido'
      '&ver=1.0',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('API 요청 실패: $e');
    }
    return null;
  }
}
