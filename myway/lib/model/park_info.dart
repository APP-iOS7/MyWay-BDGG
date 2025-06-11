import 'package:geolocator/geolocator.dart';

class ParkInfo {
  final String id;
  final String name;
  final String type;
  final String address;
  final String? latitude;
  final String? longitude;
  final String mainEquip;
  final String mainPlant;
  final String guidance;
  final String visitRoad;
  final String useRefer;
  final String parkImage;
  final String updatedDate;
  final double regionArea;
  final String admZone;
  final String wifi;
  final bool hasToilet;
  final bool hasParking;
  final String templateUrl;

  double distanceKm;
  bool isSelected;
  bool isExpanded;

  ParkInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.latitude,
    this.longitude,
    this.mainEquip = "",
    this.mainPlant = "",
    this.guidance = "",
    this.visitRoad = "",
    this.useRefer = "",
    this.parkImage = "",
    this.updatedDate = "",
    this.regionArea = 0.0,
    this.admZone = "",
    this.wifi = "N",
    this.hasToilet = false,
    this.hasParking = false,
    this.templateUrl = "",
    this.distanceKm = 99999.0,
    this.isSelected = false,
    this.isExpanded = false,
  });

  factory ParkInfo.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ParkInfo(
      id:
          json['manageNo']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['parkNm'] ?? '이름 없음',
      type: json['parkSe'] ?? '정보 없음',
      address: json['lnmadr'] ?? json['rdnmadr'] ?? '주소 정보 없음',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      mainEquip: json['mvmFclty'] ?? '',
      mainPlant: json['amsmtFclty'] ?? '',
      guidance: json['cnvnncFclty'] ?? '',
      visitRoad: json['cltrFclty'] ?? '',
      useRefer: json['etcFclty'] ?? '',
      parkImage: json['P_IMG'] ?? '',
      updatedDate: json['referenceDate'] ?? json['appnNtfcDate'] ?? '',
      regionArea: parseDouble(json['parkAr']),
      admZone: json['insttNm'] ?? '',
      wifi: json['WIFI_SERVICE'] ?? 'N',
      hasToilet: (json['cnvnncFclty']?.toString().contains('화장실') ?? false),
      hasParking: (json['cnvnncFclty']?.toString().contains('주차장') ?? false),
      templateUrl: json['TEMPLATE_URL'] ?? '',
    );
  }

  Future<void> calculateDistance(Position currentPosition) async {
    if (latitude != null &&
        longitude != null &&
        latitude!.isNotEmpty &&
        longitude!.isNotEmpty) {
      try {
        double parkLat = double.parse(latitude!);
        double parkLon = double.parse(longitude!);
        // Geolocator를 사용하여 현재 위치와 공원 간의 거리 계산
        distanceKm =
            Geolocator.distanceBetween(
              currentPosition.latitude,
              currentPosition.longitude,
              parkLat,
              parkLon,
            ) /
            1000;
      } catch (e) {
        distanceKm = 99999.0;
      }
    } else {
      distanceKm = 99999.0;
    }
  }

  factory ParkInfo.fromCsvRow(List<dynamic> row) {
    String getStr(dynamic value) => value?.toString() ?? '';

    return ParkInfo(
      id: getStr(row[0]),
      name: getStr(row[1]),
      address: getStr(row[2]),
      latitude: getStr(row[3]),
      longitude: getStr(row[4]),

      // 나머지는 기본값 그대로 두기
      type: '',
      mainEquip: '',
      mainPlant: '',
      guidance: '',
      visitRoad: '',
      useRefer: '',
      parkImage: '',
      updatedDate: '',
      regionArea: 0.0,
      admZone: '',
      wifi: 'N',
      hasToilet: false,
      hasParking: false,
      templateUrl: '',
    );
  }
}
