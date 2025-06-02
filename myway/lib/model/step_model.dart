import 'package:google_maps_flutter/google_maps_flutter.dart';

class StepModel {
  final int steps;
  final String duration;
  final String distance;
  final String stopTime;
  final String courseName;
  final String imageUrl;
  final String parkId;
  final String parkName;
  final List<LatLng> route; // 경로 (LatLng 리스트)

  StepModel({
    required this.steps,
    required this.duration,
    required this.distance,
    required this.stopTime,
    required this.courseName,
    required this.imageUrl,
    required this.parkId,
    required this.parkName,
    required this.route,
  });

  Map<String, dynamic> toJson() {
    return {
      '걸음수': steps,
      '소요시간': duration,
      '거리': distance,
      '종료시간': stopTime,
      '코스이름': courseName,
      '이미지 Url': imageUrl,
      '공원 ID': parkId,
      '공원 이름': parkName,
      '경로':
          route
              .map(
                (latLng) => {
                  'latitude': latLng.latitude,
                  'longitude': latLng.longitude,
                },
              )
              .toList(),
    };
  }

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      steps: json['걸음수'],
      duration: json['소요시간'],
      distance: json['거리'],
      stopTime: json['종료시간'],
      courseName: json['코스이름'],
      imageUrl: json['이미지 Url'],
      parkId: json['공원 ID'],
      parkName: json['공원 이름'],
      route:
          (json['경로'] as List)
              .map((latLng) => LatLng(latLng['latitude'], latLng['longitude']))
              .toList(),
    );
  }
}
