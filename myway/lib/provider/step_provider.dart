import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class StepProvider extends ChangeNotifier {
  int _baseSteps = 0;
  int _currentSteps = 0;
  int get steps => _currentSteps;

  late Stream<StepCount> _stepStream;
  StreamSubscription<StepCount>? _subscription;

  void startTracking() {
    _baseSteps = 0;
    _currentSteps = 0;
    _subscription?.cancel();

    _stepStream = Pedometer.stepCountStream;
    _subscription = _stepStream.listen(
      (event) {
        if (_baseSteps == 0) {
          _baseSteps = event.steps;
        }

        _currentSteps = event.steps - _baseSteps;
        notifyListeners();
      },
      onError: (e) {
        print("걸음 수 오류: $e");
      },
    );
  }

  void stopTracking() {
    _subscription?.cancel();
  }
}
