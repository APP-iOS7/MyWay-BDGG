import 'package:equatable/equatable.dart';

import 'step_model.dart';

class ParkCourseInfo extends Equatable {
  final String id; // 이 ID는 전체 앱에서 고유해야 함
  final bool isSelected;
  bool isFavorite; // isFavorite는 Provider가 관리하는 상태를 반영 (non-final)
  final StepModel details;
  ParkCourseInfo({
    // isFavorite가 non-final이므로 생성자는 const가 아님
    required this.id,
    required this.details,
    this.isSelected = false,
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [id, details, isSelected, isFavorite];

  ParkCourseInfo copyWith({
    String? id,
    StepModel? details,
    bool? isSelected,
    bool? isFavorite,
  }) {
    return ParkCourseInfo(
      id: id ?? this.id,
      details: details ?? this.details,
      isSelected: isSelected ?? this.isSelected,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
