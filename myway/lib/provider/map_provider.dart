import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '/model/course_model.dart';

class MapProvider with ChangeNotifier {
  bool _isCourseRecommendBottomSheetVisible = true;
  bool _isStartTrackingBottomSheetVisible = false;
  bool _isTracking = false;
  Course? _selectedCourse;
  Uint8List? _courseImage;
  bool _isMapLoading = true;

  bool get isCourseRecommendBottomSheetVisible =>
      _isCourseRecommendBottomSheetVisible;
  bool get isStartTrackingBottomSheetVisible =>
      _isStartTrackingBottomSheetVisible;
  bool get isTracking => _isTracking;
  Course? get selectedCourse => _selectedCourse;
  Uint8List? get courseImage => _courseImage;
  bool get isMapLoading => _isMapLoading;

  void showCourseRecommendBottomSheet() {
    _isCourseRecommendBottomSheetVisible = true;
    _isStartTrackingBottomSheetVisible = false;
    _isTracking = false;
    notifyListeners();
  }

  void showStartTrackingBottomSheet() {
    _isCourseRecommendBottomSheetVisible = false;
    _isStartTrackingBottomSheetVisible = true;
    _isTracking = true;
    notifyListeners();
  }

  void setTracking(bool value) {
    _isTracking = value;
    notifyListeners();
  }

  void setMapLoading(bool value) {
    _isMapLoading = value;
    notifyListeners();
  }

  void selectCourse(Course? course) {
    if (course != null) {
      _selectedCourse = course;
      print('title: ${course.title}');
    }
    if (course == null) {
      print('null');
      _selectedCourse = null;
    }
    print('course in pro: $course');

    notifyListeners();
  }

  void saveImage(Uint8List img) {
    _courseImage = img;
    notifyListeners();
  }

  void courseClear() {
    _courseImage = null;
    notifyListeners();
  }

  Future<Uint8List?> captureMap(GlobalKey boundaryKey) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      debugPrint("📍 캡처 성공, 이미지 크기: ${pngBytes?.length} bytes");

      return pngBytes;
    } catch (e) {
      debugPrint("📍 캡처 실패: $e");
      return null;
    }
  }
}
