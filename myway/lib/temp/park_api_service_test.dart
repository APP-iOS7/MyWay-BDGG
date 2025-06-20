import 'dart:convert';
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
    final jsonData = await fetchSinglePage(pageNo, numOfRows);
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
  Future<Map<String, dynamic>> fetchSinglePage(
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

    print('API 요청 URL: $url');
    print('검색 지역명: $targetInsttNm');

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      final decoded = utf8.decode(response.bodyBytes);

      print('API 응답 상태 코드: ${response.statusCode}');
      print(
        'API 응답 내용 (일부): ${decoded.length > 500 ? '${decoded.substring(0, 500)}...' : decoded}',
      );

      if (response.statusCode != 200) {
        throw Exception('API 상태 코드 오류: ${response.statusCode}, 응답: $decoded');
      }

      final jsonData = json.decode(decoded);
      print('파싱된 JSON 구조: ${jsonData.keys}');

      final responseBody = jsonData['response']?['body'];
      if (responseBody != null) {
        print('response body 구조: ${responseBody.keys}');
        print('totalCount: ${responseBody['totalCount']}');
        print('numOfRows: ${responseBody['numOfRows']}');
        print('pageNo: ${responseBody['pageNo']}');

        // 전체 데이터 수 확인
        final totalCount = responseBody['totalCount'];
        if (totalCount != null) {
          print('⚠️ API 전체 데이터 수: $totalCount');
          if (totalCount < 100) {
            print('⚠️ 경고: 전체 데이터가 $totalCount개밖에 없습니다!');
          }
        }
      } else {
        print('⚠️ response body가 null입니다!');
      }

      final items = jsonData['response']?['body']?['items'] ?? [];
      print('받아온 공원 아이템 수: ${items.length}');

      final parks =
          (items as List)
              .map((item) {
                try {
                  return ParkInfo.fromJson(item);
                } catch (e) {
                  print('공원 파싱 실패: $e, 아이템: $item');
                  return null;
                }
              })
              .where((park) => park != null)
              .cast<ParkInfo>()
              .toList();

      print('성공적으로 파싱된 공원 수: ${parks.length}');
      return parks;
    } catch (e) {
      print('API 호출 상세 에러: $e');
      throw Exception('공원 API 호출 실패: $e');
    }
  }
}
