import 'package:google_maps_flutter/google_maps_flutter.dart';

import '/model/course_model.dart';

class CourseData {
  static List<Course> getCourses() {
    return courses;
  }
}

List<Course> courses = [
  Course(
    title: '코스1',
    park: '공원1',
    date: DateTime.now(),
    distance: 2.0,
    duration: '30분',
    steps: 3000,
    imageUrl: 'https://picsum.photos/250?image=9',
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
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',

    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(37.4002, 126.9362),
      LatLng(37.40046, 126.936581),
      LatLng(37.40124, 126.9365),
      LatLng(37.40194, 126.93660),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',
    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',

    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',
    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',

    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',

    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',

    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',

    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',

    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
  Course(
    title: '코스2',
    park: '공원2',
    date: DateTime.now(),
    distance: 3.5,
    duration: '45분',

    steps: 4000,
    imageUrl: 'https://picsum.photos/250?image=9',
    route: [
      LatLng(35.1694, 129.0877),
      LatLng(35.1695, 129.0878),
      LatLng(35.1696, 129.0879),
    ],
  ),
];
