import 'package:equatable/equatable.dart';

class ParkCourseInfo extends Equatable {
  final String id; // 이 ID는 전체 앱에서 고유해야 함
  final String parkId;
  final String? parkName;
  final String title;
  final String details;
  final String imagePath;
  final bool isSelected;
  bool isFavorite; // isFavorite는 Provider가 관리하는 상태를 반영 (non-final)

  ParkCourseInfo({
    // isFavorite가 non-final이므로 생성자는 const가 아님
    required this.id,
    required this.parkId,
    this.parkName,
    required this.title,
    required this.details,
    required this.imagePath,
    this.isSelected = false,
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [
    id,
    parkId,
    parkName,
    title,
    details,
    imagePath,
    isSelected,
    isFavorite,
  ];

  ParkCourseInfo copyWith({
    String? id,
    String? parkId,
    String? parkName,
    String? title,
    String? details,
    String? imagePath,
    bool? isSelected,
    bool? isFavorite,
  }) {
    return ParkCourseInfo(
      id: id ?? this.id,
      parkId: parkId ?? this.parkId,
      parkName: parkName ?? this.parkName,
      title: title ?? this.title,
      details: details ?? this.details,
      imagePath: imagePath ?? this.imagePath,
      isSelected: isSelected ?? this.isSelected,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
