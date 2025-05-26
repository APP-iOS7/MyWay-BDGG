import 'dart:convert';
import 'dart:io'; // For SocketException
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;
import 'package:myway/model/park_info.dart';

class ParkApiService {
  final String _apiKeyOriginal = "N/UtwxZeXvM3HH2BDttOtVdYbgRKV4f8KdtTrvNgLBcioy57fv+2/WW6P5H5mWnCZYXnPi+6r70r9IWZRxLiCA==";
  final String _fullBaseUrl = "http://api.data.go.kr/openapi/tn_pubr_public_cty_park_info_api";

  Future<List<ParkInfo>> fetchParks({int pageNo = 1, int numOfRows = 100}) async {
    final String encodedApiKey = Uri.encodeComponent(_apiKeyOriginal);
    final String queryParams = "?serviceKey=$encodedApiKey"
        "&pageNo=${pageNo.toString()}"
        "&numOfRows=${numOfRows.toString()}"
        "&type=json";
    final String fullUrl = _fullBaseUrl + queryParams;

    print('==================== PARK API REQUEST ====================');
    print('Requesting Park API URL: $fullUrl');
    print('==========================================================');

    http.Response? response;
    String decodedBodyForErrorLog = "N/A";

    try {
      final uri = Uri.parse(fullUrl);
      response = await http.get(uri).timeout(const Duration(seconds: 20));
      
      final String decodedBody = utf8.decode(response.bodyBytes);
      decodedBodyForErrorLog = decodedBody; // 에러 로깅을 위해 할당

      print('-------------------- PARK API RESPONSE --------------------');
      print('API Response Status Code: ${response.statusCode}');
      
      // --- 전체 응답 본문 (JSON 문자열) 출력 ---
      // 데이터가 매우 길 경우 콘솔에서 잘릴 수 있습니다.
      // 디버거를 사용하거나, 아래 prettyPrintedJson을 확인하는 것이 더 좋습니다.
      print('API Response Body (Raw JSON String - Full):');
      print(decodedBody); 
      print('--- End of Raw JSON String ---');
      // ------------------------------------------
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(decodedBody);

        // --- 파싱된 전체 JSON 객체 (Map/List) 예쁘게 출력 ---
        // 이 부분에 중단점(breakpoint)을 설정하고 디버거로 jsonData를 확인하는 것이 가장 좋습니다.
        JsonEncoder encoder = new JsonEncoder.withIndent('  '); // 2칸 공백으로 들여쓰기
        String prettyPrintedJson = encoder.convert(jsonData);
        print('Parsed JSON Data (Pretty Printed - Full Structure):');
        print(prettyPrintedJson);
        print('--- End of Parsed JSON Data ---');
        // --------------------------------------------------

        if (jsonData['response'] != null &&
            jsonData['response']['body'] != null &&
            jsonData['response']['body']['items'] != null &&
            jsonData['response']['body']['items'] is List) {
          List<dynamic> parkItems = jsonData['response']['body']['items'];
          
          if (jsonData['response']['header'] != null && jsonData['response']['header']['resultCode'] != null) {
            String resultCode = jsonData['response']['header']['resultCode'];
            String resultMsg = jsonData['response']['header']['resultMsg'] ?? 'Unknown API error';

            if (resultCode == '03') {
              print('API returned no data (03): $resultMsg');
              return [];
            } else if (resultCode != '00' && resultCode != 'INFO-000') {
              print('API Error [$resultCode]: $resultMsg. URL: $fullUrl');
              throw Exception('API Error [$resultCode]: $resultMsg');
            }
          }
          
          if (parkItems.isEmpty) {
             print('No park items found (items array is empty), but API call was successful.');
             return [];
          }
          print('Mapping ${parkItems.length} park items...'); // 몇 개의 아이템을 매핑하는지 로그
          return parkItems.map((item) {
            // 개별 아이템 파싱 전 로그 (필요시 주석 해제)
            // print('Parsing individual item: $item');
            return ParkInfo.fromJson(item);
          }).toList();

        } else if (jsonData['response'] != null && jsonData['response']['header'] != null && 
                   (jsonData['response']['header']['resultCode'] != '00' && jsonData['response']['header']['resultCode'] != 'INFO-000')) {
          print('API Error (no items or body, header error). URL: $fullUrl. Parsed JSON: $jsonData');
          throw Exception('API Error [${jsonData['response']['header']['resultCode']}]: ${jsonData['response']['header']['resultMsg']}');
        }
        else if (jsonData['response'] != null && jsonData['response']['body'] != null && jsonData['response']['body']['items'] == null && 
                 (jsonData['response']['header']['resultCode'] == '00' || jsonData['response']['header']['resultCode'] == 'INFO-000')){
          print('API returned success but no items array. URL: $fullUrl');
          return [];
        }
        else {
          print('Unexpected API response structure. URL: $fullUrl. Raw Body: $decodedBody');
          return [];
        }
      } else {
        String responseBodyPreview = decodedBody.length > 500 ? decodedBody.substring(0, 500) : decodedBody;
        print('API call failed. Status Code: ${response.statusCode}. URL: $fullUrl. Response (Preview): $responseBodyPreview...');
        throw Exception('API 호출 실패 (상태 코드: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      print("ParkApiService fetchParks SocketException: $e. URL: $fullUrl");
      throw Exception('네트워크 연결을 확인해주세요.');
    } on TimeoutException catch (e) {
      print("ParkApiService fetchParks TimeoutException: $e. URL: $fullUrl");
      throw Exception('API 요청 시간이 초과되었습니다.');
    } on FormatException catch (e) {
       print("ParkApiService fetchParks FormatException (JSON Parsing Error): $e. URL: $fullUrl. Body that caused error: $decodedBodyForErrorLog");
       throw Exception('API 응답 데이터 처리 중 오류가 발생했습니다.');
    }
    catch (e) {
      print("ParkApiService fetchParks 알 수 없는 에러: $e. URL: $fullUrl");
      throw Exception('공원 정보 로딩 중 알 수 없는 오류가 발생했습니다.');
    }
  }
}