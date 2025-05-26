// myway/model/park_info.dart

class ParkInfo {
  final String id;
  final String name;
  final String type;
  final String address;
  final String? latitude;    
  final String? longitude;   
  bool isSelected;
  bool isExpanded; 
  double distanceKm;

  ParkInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.latitude,
    this.longitude,
    this.isSelected = false,
    this.isExpanded = false,
    this.distanceKm = 99999.0, 
  });

  factory ParkInfo.fromJson(Map<String, dynamic> json) {
    String tempId = (json['parkNm']?.toString() ?? 'unknown_name') + "_" + (json['rdnmadr']?.toString() ?? json['lnmadr']?.toString() ?? 'unknown_address');
    
    return ParkInfo(
      id: json['manageNo']?.toString() ?? json['관리번호']?.toString() ?? tempId, 
      name: json['parkNm']?.toString() ?? '정보 없음',
      type: json['parkSe']?.toString() ?? '정보 없음',
      address: json['rdnmadr']?.toString() ?? json['lnmadr']?.toString() ?? '주소 정보 없음',
      latitude: json['latitude']?.toString() ?? json['prkplceLat']?.toString() ?? json['위도']?.toString(),
      longitude: json['longitude']?.toString() ?? json['prkplceLot']?.toString() ?? json['경도']?.toString(),
    );
  }

  @override
  String toString() {
    return 'ParkInfo(id: $id, name: $name, address: $address, lat: $latitude, lon: $longitude, distance: ${distanceKm.toStringAsFixed(1)} km)';
  }
}