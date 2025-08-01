import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myway/model/step_model.dart';
import 'package:pedometer/pedometer.dart';
import 'package:uuid/uuid.dart';

enum TrackingStatus { running, paused, stopped }

class StepProvider extends ChangeNotifier {
  final TextEditingController courseName = TextEditingController();
  String? _parkName;
  String? get parkName => _parkName;
  String? _parkId;
  String? get parkId => _parkId;

  int _baseSteps = 0;
  int _currentSteps = 0;
  int get steps => _currentSteps;

  bool _isCourseNameValid = false;
  bool get isCourseNameValid => _isCourseNameValid;

  // 평균 보폭 기준으로 칼로리 계산 (고정 값)
  final double _strideLengthCm = 70.0; // 평균보폭

  String get distanceKm =>
      (_currentSteps * _strideLengthCm / 100000).toStringAsFixed(2);

  // 시간
  DateTime? _startTime;
  DateTime? _stopTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero; // 경과
  String _formattedStopTime = '';
  String get formattedElapsed => _formatDuration(_elapsed);
  String get formattedStopTime => _formattedStopTime;

  late Stream<StepCount> _stepStream;
  StreamSubscription<StepCount>? _subscription;

  TrackingStatus _status = TrackingStatus.running;
  TrackingStatus get status => _status;

  List<LatLng> _route = [];
  List<LatLng> get route => _route;

  // 현재 저장된 데이터를 관리하는 변수
  StepModel? _currentStepModel;
  StepModel? get currentStepModel => _currentStepModel;

  StepProvider() {
    courseName.addListener(_validateCourseName);
  }

  void setParkName(String? parkName) {
    _parkName = parkName;
    notifyListeners();
  }

  void setRoute(List<LatLng>? route) {
    if (route != null) {
      _route = List.from(route);
    } else {
      _route.clear();
    }
    notifyListeners();
  }

  void setParkId(String? parkId) {
    _parkId = parkId;
    notifyListeners();
  }

  void toggle() {
    if (_status == TrackingStatus.running) {
      pause();
    } else {
      resume();
    }
  }

  void startTracking() {
    _baseSteps = 0;
    _currentSteps = 0;
    _elapsed = Duration.zero;
    _startTime = DateTime.now();
    _status = TrackingStatus.running;

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

  // 새로운 메서드: StepModel만 생성하고 상태는 변경하지 않음
  StepModel createStepModel({String imageUrl = ''}) {
    _stopTime = DateTime.now();
    _formattedStopTime = DateFormat('yyyy-MM-dd HH:mm').format(_stopTime!);

    return StepModel(
      id: const Uuid().v4(),
      route: route, // 나중에 설정
      steps: steps,
      duration: formattedElapsed,
      distance: double.parse(distanceKm),
      stopTime: formattedStopTime,
      courseName: courseName.text,
      imageUrl: imageUrl,
      parkName: _parkName,
      parkId: _parkId,
    );
  }

  // 기존 메서드: 내부 상태를 초기화하고 notifyListeners 호출

  void resetTracking() {
    _subscription?.cancel();
    _timer?.cancel();
    _baseSteps = 0;
    courseName.text = '';
    _currentSteps = 0;
    _elapsed = Duration.zero;
    _status = TrackingStatus.stopped;
    _parkName = null;
    _parkId = null;
    _route.clear();
    print('stepProvider state reset');

    notifyListeners();
  }

  void stopTracking() {
    _status = TrackingStatus.stopped;
    _timer?.cancel();
    _timer = null;
    _currentStepModel = createStepModel();
    notifyListeners();
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

  void _validateCourseName() {
    final isValid = courseName.text.trim().isNotEmpty;

    if (_isCourseNameValid != isValid) {
      _isCourseNameValid = isValid;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    courseName.removeListener(_validateCourseName);
    courseName.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$h:$m:$s';
  }
}
