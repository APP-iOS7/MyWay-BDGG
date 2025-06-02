import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:myway/model/park_course_info.dart';

class MapProvider with ChangeNotifier {
  bool _isCourseRecommendBottomSheetVisible = true;
  bool _isStartTrackingBottomSheetVisible = false;
  bool _isTracking = false;
  ParkCourseInfo? _selectedCourse;
  Uint8List? _courseImage;
  bool _isMapLoading = true;
  bool _disposed = false; // dispose 상태 추적

  bool get isCourseRecommendBottomSheetVisible =>
      _isCourseRecommendBottomSheetVisible;
  bool get isStartTrackingBottomSheetVisible =>
      _isStartTrackingBottomSheetVisible;
  bool get isTracking => _isTracking;
  ParkCourseInfo? get selectedCourse => _selectedCourse;
  Uint8List? get courseImage => _courseImage;
  bool get isMapLoading => _isMapLoading;

  void resetState() {
    if (_disposed) return; // dispose된 경우 early return

    _isCourseRecommendBottomSheetVisible = true;
    _isStartTrackingBottomSheetVisible = false;
    _isTracking = false;
    _selectedCourse = null;
    _courseImage = null;
    _isMapLoading = true;
    print('MapProvider state reset');

    // 안전하게 notifyListeners 호출
    _safeNotifyListeners();
  }

  void showCourseRecommendBottomSheet() {
    if (_disposed) return;

    _isCourseRecommendBottomSheetVisible = true;
    _isStartTrackingBottomSheetVisible = false;
    _isTracking = false;
    _safeNotifyListeners();
  }

  void showStartTrackingBottomSheet() {
    if (_disposed) return;

    _isCourseRecommendBottomSheetVisible = false;
    _isStartTrackingBottomSheetVisible = true;
    _isTracking = true;
    _safeNotifyListeners();
  }

  void setTracking(bool value) {
    if (_disposed) return;

    _isTracking = value;
    _safeNotifyListeners();
  }

  void setMapLoading(bool value) {
    if (_disposed) return;

    _isMapLoading = value;
    _safeNotifyListeners();
  }

  void selectCourse(ParkCourseInfo? course) {
    if (_disposed) return;

    if (course != null) {
      _selectedCourse = course;
      print('title: ${course.details.courseName}');
    }
    if (course == null) {
      print('null');
      _selectedCourse = null;
    }
    print('course in pro: $course');

    _safeNotifyListeners();
  }

  void saveImage(Uint8List img) {
    if (_disposed) return;

    _courseImage = img;
    _safeNotifyListeners();
  }

  void courseClear() {
    if (_disposed) return;

    _courseImage = null;
    _safeNotifyListeners();
  }

  // 안전한 notifyListeners 호출
  void _safeNotifyListeners() {
    if (_disposed) return;

    try {
      notifyListeners();
    } catch (e) {
      print('MapProvider: notifyListeners 호출 중 오류 발생: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true; // dispose 상태 설정
    super.dispose();
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
