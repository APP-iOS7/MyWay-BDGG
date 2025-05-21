import 'package:flutter/material.dart';
import 'package:myway/util/permission_util.dart';
import 'package:pedometer/pedometer.dart';

class StepProvider extends ChangeNotifier {
  int _steps = 0;
  String _status = 'Unknown';

  int get steps => _steps;
  String get status => _status;

  late Stream<StepCount> _stepSteream;
  late Stream<PedestrianStatus> _statusStream;

  Future<void> init() async {
    final granted = await requestMotionPermission();

    if (!granted) {
      _status = '권한 거부됨';
      notifyListeners();
      return;
    }

    _stepSteream = Pedometer.stepCountStream;
    _statusStream = Pedometer.pedestrianStatusStream;

    _stepSteream.listen(_onStepCount, onError: _onStepError);
    _statusStream.listen(_onStatusChanged, onError: _onStatusError);
  }

  void _onStepCount(StepCount event) {
    print(event);
    _steps = event.steps;
    notifyListeners();
  }

  void _onStatusChanged(PedestrianStatus event) {
    print(event);
    _status = event.status;
    notifyListeners();
  }

  void _onStepError(error) {
    _steps = 0;
    notifyListeners();
  }

  void _onStatusError(error) {
    _status = '오류발생';
    notifyListeners();
  }

  void reset() {
    _steps = 0;
    _status = 'Unknown';
    notifyListeners();
  }
}
