import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:myway/model/park_info.dart';

import '../const/key.dart';

class ParkApiService {
  final String _serviceKeyEncoded = park_api_key;
  final String _baseUrl =
      "http://api.data.go.kr/openapi/tn_pubr_public_cty_park_info_api";

  Future<Map<String, dynamic>> _fetchSinglePage(
    int pageNo,
    int numOfRows,
  ) async {
    final String encodedApiKey = Uri.encodeComponent(_serviceKeyEncoded);
    final String queryParams =
        "?serviceKey=$encodedApiKey"
        "&pageNo=${pageNo.toString()}"
        "&numOfRows=${numOfRows.toString()}"
        "&type=json";
    final String fullUrl = _baseUrl + queryParams;

    http.Response? response;
    String responseBodyForErrorLog = "N/A";

    try {
      final uri = Uri.parse(fullUrl);
      response = await http.get(uri).timeout(const Duration(seconds: 30));
      responseBodyForErrorLog = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBodyForErrorLog);
        return jsonData;
      } else {
        throw Exception(
          'API 호출 실패 (페이지: $pageNo, 상태 코드: ${response.statusCode}, 응답: $responseBodyForErrorLog)',
        );
      }
    } on SocketException catch (e) {
      throw Exception('네트워크 연결을 확인해주세요: $e');
    } on TimeoutException catch (e) {
      throw Exception('API 요청 시간이 초과되었습니다: $e');
    } on FormatException catch (e) {
      throw Exception(
        'API 응답 데이터 처리 중 오류가 발생했습니다: $e. 응답: $responseBodyForErrorLog',
      );
    } catch (e) {
      throw Exception('공원 정보 페이지($pageNo) 로딩 중 알 수 없는 오류: $e');
    }
  }

  Future<List<ParkInfo>> fetchAllParks() async {
    List<ParkInfo> allParksRaw = [];
    int currentPage = 1;
    final int rowsPerPage = 100;
    bool moreDataExists = true;
    int? totalItemsFromApi;
    int maxPageRequests = 200;
    int requestCount = 0;

    while (moreDataExists && requestCount < maxPageRequests) {
      requestCount++;
      try {
        final jsonData = await _fetchSinglePage(currentPage, rowsPerPage);

        if (jsonData['response'] != null &&
            jsonData['response']['body'] != null &&
            jsonData['response']['header'] != null) {
          final responseBody = jsonData['response']['body'];
          final responseHeader = jsonData['response']['header'];
          String resultCode =
              responseHeader['resultCode']?.toString() ?? 'UNKNOWN_CODE';

          if (resultCode == '03' || resultCode == 'INFO-200') {
            moreDataExists = false;
            continue;
          } else if (resultCode != '00' && resultCode != 'INFO-000') {
            throw Exception(
              'API Error [Code: $resultCode]: ${responseHeader['resultMsg']}',
            );
          }

          if (responseBody['totalCount'] != null && totalItemsFromApi == null) {
            if (responseBody['totalCount'] is String) {
              totalItemsFromApi = int.tryParse(responseBody['totalCount']);
            } else if (responseBody['totalCount'] is int) {
              totalItemsFromApi = responseBody['totalCount'] as int;
            }
          }

          if (responseBody['items'] != null && responseBody['items'] is List) {
            List<dynamic> parkItemsJson = responseBody['items'];
            if (parkItemsJson.isEmpty) {
              moreDataExists = false;
            } else {
              List<ParkInfo> parksInPage =
                  parkItemsJson
                      .map((item) {
                        try {
                          return ParkInfo.fromJson(
                            item as Map<String, dynamic>,
                          );
                        } catch (e) {
                          return null;
                        }
                      })
                      .where((park) => park != null)
                      .cast<ParkInfo>()
                      .toList();

              allParksRaw.addAll(parksInPage);
              currentPage++;

              if (totalItemsFromApi != null &&
                  allParksRaw.length >= totalItemsFromApi) {
                moreDataExists = false;
              } else if (parksInPage.length < rowsPerPage) {
                moreDataExists = false;
              }
            }
          } else {
            moreDataExists = false;
          }
        } else {
          moreDataExists = false;
        }
      } catch (e) {
        moreDataExists = false;
        if (allParksRaw.isEmpty && requestCount <= 1) {
          throw Exception(
            'Failed to fetch any park data on the first attempt: $e',
          );
        }
      }
      if (moreDataExists) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    if (allParksRaw.isEmpty && requestCount > 0) {
      return [];
    }

    final Map<String, ParkInfo> uniqueParksMap = {};
    for (var park in allParksRaw) {
      String addressToUse = park.address;
      String uniqueKey;
      if (addressToUse != '주소 정보 없음' && addressToUse.isNotEmpty) {
        uniqueKey = "${park.name}_$addressToUse";
      } else if (park.latitude != null &&
          park.longitude != null &&
          park.latitude!.isNotEmpty &&
          park.longitude!.isNotEmpty) {
        uniqueKey = "${park.name}_${park.latitude}_${park.longitude}";
      } else {
        uniqueKey = "${park.name}_id_${park.id}";
      }
      uniqueParksMap.putIfAbsent(uniqueKey, () => park);
    }
    List<ParkInfo> uniqueParksList = uniqueParksMap.values.toList();
    return uniqueParksList;
  }
}
