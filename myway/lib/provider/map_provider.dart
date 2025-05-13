import 'package:flutter/widgets.dart';

class MapProvider with ChangeNotifier {
  bool _isCourseRecommendBottomSheetVisible = true;
  bool _isStartTrackingBottomSheetVisible = false;
  bool _isTracking = false;

  bool get isCourseRecommendBottomSheetVisible =>
      _isCourseRecommendBottomSheetVisible;
  bool get isStartTrackingBottomSheetVisible =>
      _isStartTrackingBottomSheetVisible;
  bool get isTracking => _isTracking;

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
}
