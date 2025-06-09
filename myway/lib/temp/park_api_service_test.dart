import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myway/model/park_info.dart';

import '../const/key.dart';

class ParkApiServiceTest {
  final String _serviceKeyEncoded = park_api_key;
  final String _baseUrl =
      "http://api.data.go.kr/openapi/tn_pubr_public_cty_park_info_api";

  Future<List<ParkInfo>> fetchParkPage(int pageNo, int numOfRows) async {
    final jsonData = await _fetchSinglePage(pageNo, numOfRows);
    final List<dynamic> items = jsonData['response']?['body']?['items'] ?? [];

    final parks =
        items
            .map((e) {
              try {
                return ParkInfo.fromJson(e);
              } catch (_) {
                return null;
              }
            })
            .where((e) => e != null)
            .cast<ParkInfo>()
            .toList();

    return parks;
  }

  /// 개별 페이지 요청
  Future<Map<String, dynamic>> _fetchSinglePage(
    int pageNo,
    int numOfRows,
  ) async {
    final encodedKey = Uri.encodeComponent(_serviceKeyEncoded);
    final url =
        '$_baseUrl?serviceKey=$encodedKey&pageNo=$pageNo&numOfRows=$numOfRows&type=json';

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      final body = utf8.decode(response.bodyBytes);
      stopwatch.stop();

      debugPrint(
        "✅ Page $pageNo fetched in ${stopwatch.elapsedMilliseconds}ms",
      );

      if (response.statusCode == 200) {
        return json.decode(body);
      } else {
        throw Exception("API 호출 실패: ${response.statusCode}, $body");
      }
    } catch (e) {
      throw Exception("페이지($pageNo) 호출 중 오류: $e");
    }
  }

  Future<List<ParkInfo>> fetchParksByRegion({
    required String targetInsttNm,
    int pageNo = 1,
    int numOfRows = 300,
  }) async {
    final encodedKey = Uri.encodeComponent(_serviceKeyEncoded);

    final url =
        '$_baseUrl'
        '?serviceKey=$encodedKey&pageNo=$pageNo&numOfRows=$numOfRows&instt_nm=$targetInsttNm&type=json';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      final decoded = utf8.decode(response.bodyBytes);

      if (response.statusCode != 200) {
        throw Exception('API 상태 코드 오류: ${response.statusCode}');
      }

      final jsonData = json.decode(decoded);
      final items = jsonData['response']?['body']?['items'] ?? [];

      return (items as List).map((item) {
        return ParkInfo.fromJson(item);
      }).toList();
    } catch (e) {
      throw Exception('공원 API 호출 실패: $e');
    }
  }
}
