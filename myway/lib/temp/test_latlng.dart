import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestLatlng {
  List<LatLng> getTestLatlng() {
    final List<LatLng> routeCoordinates = [
      LatLng(37.400469, 126.936431), // 좌표 1 (예시)
      LatLng(37.400509, 126.936510), // 좌표 2
      LatLng(37.400582, 126.936584), // 좌표 3
      LatLng(37.400729, 126.935995), // 좌표 4
      LatLng(37.400523, 126.936572), // 좌표 5
      LatLng(37.400442, 126.936561), // 좌표 5
      LatLng(37.400356, 126.936556), // 좌표 5
      LatLng(37.400271, 126.936556), // 좌표 5
      LatLng(37.4001540, 126.936544), // 좌표 5
      LatLng(37.400050, 126.936533), // 좌표 5
      LatLng(37.399960, 126.936516), // 좌표 5
      LatLng(37.399883, 126.93653), // 좌표 5
      LatLng(37.399766, 126.93652), // 좌표 5
    ];
    return routeCoordinates;
  }
}
