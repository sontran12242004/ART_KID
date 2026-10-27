import '../../domain/entities/course.dart';

class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.title,
    required super.description,
    super.thumbnailUrl,
    super.priceVnd,
    super.ageRange,
    super.includesPhysicalKit,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      priceVnd: (json['price_vnd'] as num?)?.toInt() ?? 0,
      ageRange: json['age_range'] as String? ?? '4–12 tuổi',
      includesPhysicalKit: json['includes_physical_kit'] as bool? ?? false,
      thumbnailUrl:
          json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
    };
  }
}
