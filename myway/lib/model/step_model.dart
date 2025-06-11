import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StepModel {
  final String id;
  final int steps;
  final String duration;
  final double distance;
  final String stopTime;
  final String courseName;
  final String imageUrl;
  final String? parkId;
  final List<LatLng> route; // 경로 (LatLng 리스트)
  final String? parkName;

  StepModel({
    required this.id,
    required this.steps,
    required this.duration,
    required this.distance,
    required this.stopTime,
    required this.courseName,
    required this.imageUrl,
    this.parkId,
    required this.route,
    this.parkName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '걸음수': steps,
      '소요시간': duration,
      '거리': distance,
      '종료시간': stopTime,
      '코스이름': courseName,
      '이미지 Url': imageUrl,
      '공원 ID': parkId,

      '경로':
          route
              .map((latLng) => GeoPoint(latLng.latitude, latLng.longitude))
              .toList(),
      if (parkName != null) '공원명': parkName,
    };
  }

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      id: json['id'] ?? '',
      steps: json['걸음수'],
      duration: json['소요시간'],
      distance:
          (json['거리'] is int)
              ? (json['거리'] as int).toDouble()
              : (json['거리'] as double),
      stopTime: json['종료시간'],
      courseName: json['코스이름'],
      imageUrl: json['이미지 Url'],
      parkId: json['공원 ID'],
      route:
          (json['경로'] as List<dynamic>).map((point) {
            final geo = point as GeoPoint;
            return LatLng(geo.latitude, geo.longitude);
          }).toList(),

      parkName: json['공원명'],
    );
  }
}
