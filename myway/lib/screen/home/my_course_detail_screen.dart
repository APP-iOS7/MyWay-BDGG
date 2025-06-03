import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../const/colors.dart';

class MyCourseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const MyCourseDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['이미지 Url'] ?? '';
    final courseName = data['코스이름'] ?? '이름 없음';
    final stopTime = data['종료시간'] ?? '';
    final distance = data['거리'] ?? '';
    final steps = data['걸음수'] ?? '';
    final duration = data['소요시간'] ?? '';
    final List<LatLng> route =
        (data['경로'] as List<dynamic>?)
            ?.whereType<GeoPoint>()
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList() ??
        [];
    return Scaffold(
      backgroundColor: WHITE,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: Text(
          courseName,
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WHITE,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            Column(
              spacing: 10,
              children: [
                _buildDataList(title: '공원 이름', content: "parkName"),
                _buildDataList(title: '거리', content: distance),
                _buildDataList(title: '걸음수', content: steps.toString()),
                _buildDataList(title: '소요 시간', content: duration),
                _buildDataList(title: '종료시간', content: stopTime),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataList({required String title, required String content}) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            title,
            style: TextStyle(
              color: GRAYSCALE_LABEL_950,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            content,
            style: TextStyle(color: GRAYSCALE_LABEL_900, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
