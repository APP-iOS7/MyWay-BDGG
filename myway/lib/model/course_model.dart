import 'package:google_maps_flutter/google_maps_flutter.dart';

class Course {
  final String title; // 제목
  final String park; // 공원
  final DateTime date; // 날짜
  final double distance; // 거리 (km)
  final String duration; // 시간 (예: '30분')
  final int steps; // 걸음수
  final String imageUrl; // 이미지 URL
  final List<LatLng> route; // 경로 (LatLng 리스트)

  Course({
    required this.title,
    required this.park,
    required this.date,
    required this.distance,
    required this.duration,
    required this.steps,
    required this.imageUrl,
    required this.route,
  });
}
