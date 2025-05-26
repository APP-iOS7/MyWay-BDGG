class RecommendedCourseInfo {
  final String id;
  final String parkId; // 이 코스가 속한 공원의 ID
  final String title;
  final String details;
  final String imagePath;
  bool isFavorite;
  bool isSelected;

  RecommendedCourseInfo({
    required this.id,
    required this.parkId,
    required this.title,
    required this.details,
    required this.imagePath,
    this.isFavorite = false,
    this.isSelected = false,
  });
}