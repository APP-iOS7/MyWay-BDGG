import 'package:flutter/widgets.dart';

import '../model/course_model.dart';

class MapProvider with ChangeNotifier {
  bool _isCourseRecommendBottomSheetVisible = true;
  bool _isStartTrackingBottomSheetVisible = false;
  bool _isTracking = false;
  Course? _selectedCourse;

  bool get isCourseRecommendBottomSheetVisible =>
      _isCourseRecommendBottomSheetVisible;
  bool get isStartTrackingBottomSheetVisible =>
      _isStartTrackingBottomSheetVisible;
  bool get isTracking => _isTracking;
  Course? get selectedCourse => _selectedCourse;

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
}
