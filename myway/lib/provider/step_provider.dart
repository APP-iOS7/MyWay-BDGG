import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

enum TrackingStatus { running, paused }

class StepProvider extends ChangeNotifier {
  int _baseSteps = 0;
  int _currentSteps = 0;
  int get steps => _currentSteps;

  // 평균 보폭 기준으로 칼로리 계산 (고정 값)
  final double _strideLengthCm = 70.0; // 평균보폭
  final double _caloriesPerStep = 0.04; // 1보당 소모 칼로리

  String get distanceKm =>
      (_currentSteps * _strideLengthCm / 100000).toStringAsFixed(2);
  String get calories => (_currentSteps * _caloriesPerStep).toStringAsFixed(1);

  // 시간
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  String get formattedElapsed => _formatDuration(_elapsed);

  late Stream<StepCount> _stepStream;
  StreamSubscription<StepCount>? _subscription;

  TrackingStatus _status = TrackingStatus.running;
  TrackingStatus get status => _status;

  void startTracking() {
    _baseSteps = 0;
    _currentSteps = 0;
    _elapsed = Duration.zero;
    _startTime = DateTime.now();

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _elapsed = DateTime.now().difference(_startTime!);
      notifyListeners();
    });

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

  void toggle() {
    if (_status == TrackingStatus.running) {
      pause();
    } else {
      resume();
    }
  }

  void pause() {
    _subscription?.cancel();
    _timer?.cancel();
    _status = TrackingStatus.paused;
    notifyListeners();
  }

  void resume() {
    _startTime = DateTime.now().subtract(_elapsed);
    _status = TrackingStatus.running;

    _stepStream = Pedometer.stepCountStream;
    _subscription = _stepStream.listen((event) {
      _currentSteps = event.steps - _baseSteps;
      notifyListeners();
    });

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _elapsed = DateTime.now().difference(_startTime!);
      notifyListeners();
    });

    notifyListeners();
  }

  void stopTracking() {
    _subscription?.cancel();
    _timer?.cancel();
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$h:$m:$s';
  }
}
