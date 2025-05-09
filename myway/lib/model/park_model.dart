class Park {
  final String name;
  final String address;
  final String kind;
  final double latitude;
  final double longitude;
  final String imageUrl;

  Park({
    required this.name,
    required this.address,
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });

  factory Park.fromJson(Map<String, dynamic> json) {
    return Park(
      name: json['name'] as String,
      address: json['address'] as String,
      kind: json['kind'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      imageUrl: json['imageUrl'] as String,
    );
  }
}
