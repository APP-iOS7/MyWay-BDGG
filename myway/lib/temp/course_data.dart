import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myway/model/park_course_info.dart';

import '../model/step_model.dart';

class CourseData {
  static List<ParkCourseInfo> getCourses() {
    return courses;
  }
}

List<ParkCourseInfo> courses = [
  ParkCourseInfo(
    id: 'course1',
    isFavorite: false,
    details: StepModel(
      steps: 100,
      duration: '100',
      distance: '100',
      stopTime: '12:00',
      courseName: 'test',
      imageUrl: 'assets/images/course_placeholder_1.png',
      parkId: 'park1',
      parkName: '공원1',
      route: [
        LatLng(37.40020, 126.93613),
        LatLng(37.400120, 126.93657),
        LatLng(37.39948, 126.93656),
        LatLng(37.39948, 126.93656),
        LatLng(37.399476, 126.937293),

        LatLng(37.39953, 126.93780),
        LatLng(37.400076, 126.938185),
        LatLng(37.400675, 126.93859),
        LatLng(37.40129, 126.93866),
        LatLng(37.401855, 126.938573),
        LatLng(37.40216, 126.93897),
      ],
    ),
  ),
  ParkCourseInfo(
    id: 'course1',
    isFavorite: false,
    details: StepModel(
      steps: 100,
      duration: '100',
      distance: '100',
      stopTime: '12:00',
      courseName: 'test',
      imageUrl: 'assets/images/course_placeholder_1.png',
      parkId: 'park1',
      parkName: '공원1',
      route: [
        LatLng(37.40020, 126.93613),
        LatLng(37.400120, 126.93657),
        LatLng(37.39948, 126.93656),
        LatLng(37.39948, 127.93656),
        LatLng(37.399476, 127.937293),

        LatLng(37.39953, 126.93780),
        LatLng(37.400076, 126.938185),
        LatLng(37.400675, 126.93859),
        LatLng(37.40129, 126.93866),
        LatLng(37.401855, 126.938573),
        LatLng(37.40216, 126.93897),
      ],
    ),
  ),
];
