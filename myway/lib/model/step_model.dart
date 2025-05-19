class StepModel {
  final int steps;
  final String duration;
  final String distance;
  final String stopTime;

  StepModel({
    required this.steps,
    required this.duration,
    required this.distance,
    required this.stopTime,
  });

  Map<String, dynamic> toJson() {
    return {'걸음수': steps, '소요시간': duration, '거리': distance, '종료시간': stopTime};
  }

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      steps: json['걸음수'],
      duration: json['소요시간'],
      distance: json['거리'],
      stopTime: json['종료시간'],
    );
  }
}
