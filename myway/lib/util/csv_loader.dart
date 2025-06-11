import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:myway/model/park_info.dart';

Future<List<ParkInfo>> loadParksFromCSV() async {
  try {
    // assets 폴더에서 CSV 파일 읽기
    final rawData = await rootBundle.loadString('assets/data/park_data.csv');

    // CSV 파싱
    final List<List<dynamic>> csvData = const CsvToListConverter().convert(
      rawData,
      eol: '\n',
    );
    print('CSV 데이터 로드 완료: ${csvData.length}행');

    // 첫 줄은 헤더이므로 skip(1)
    return csvData.skip(1).map((row) => ParkInfo.fromCsvRow(row)).toList();
  } catch (e) {
    print('CSV 로딩 중 오류 발생: $e');
    return [];
  }
}
