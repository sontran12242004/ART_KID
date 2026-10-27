import 'package:equatable/equatable.dart';

class Course extends Equatable {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.ageRange = '4–12 tuổi',
    this.priceVnd = 299000,
    this.includesPhysicalKit = true,
  });

  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String ageRange;
  final int priceVnd;
  final bool includesPhysicalKit;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    thumbnailUrl,
    ageRange,
    priceVnd,
    includesPhysicalKit,
  ];
}
