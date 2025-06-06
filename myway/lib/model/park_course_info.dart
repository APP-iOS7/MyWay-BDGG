import 'package:equatable/equatable.dart';

import 'step_model.dart';

class ParkCourseInfo extends Equatable {
  final String parkId;
  final String? parkName;
  final String title;
  final String park; // 공원
  final DateTime date; // 날짜
  final bool isSelected;
  final bool isFavorite; // isFavorite는 Provider가 관리하는 상태를 반영 (non-final)
  final StepModel details;

  const ParkCourseInfo({
    // isFavorite가 non-final이므로 생성자는 const가 아님
    required this.parkId,
    this.parkName,
    required this.title,
    required this.details,
    required this.park,
    required this.date,

    this.isSelected = false,
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [details, isSelected, isFavorite];

  ParkCourseInfo copyWith({
    String? id,
    String? parkId,
    String? parkName,
    String? title,
    StepModel? details,
    String? park,
    DateTime? date,
    bool? isSelected,
    bool? isFavorite,
  }) {
    return ParkCourseInfo(
      parkId: parkId ?? this.parkId,
      parkName: parkName ?? this.parkName,
      title: title ?? this.title,
      details: details ?? this.details,
      park: park ?? this.park,
      date: date ?? this.date,
      isSelected: isSelected ?? this.isSelected,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
