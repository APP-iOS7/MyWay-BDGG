import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

Future<bool> requestMotionPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  if (Platform.isIOS) {
    final sensorstatus = await Permission.sensors.request();
    print('ios 권한상태: $sensorstatus');
    return sensorstatus.isGranted ||
        sensorstatus.isLimited ||
        sensorstatus.isRestricted;
  }

  return false;
}
