import 'package:equatable/equatable.dart';

class ChildProgressReport extends Equatable {
  const ChildProgressReport({
    required this.childId,
    required this.completedLessonsCount,
    required this.totalArtworksCount,
    required this.totalBadgesCount,
    required this.learningMinutesThisWeek,
  });

  final String childId;
  final int completedLessonsCount;
  final int totalArtworksCount;
  final int totalBadgesCount;
  final int learningMinutesThisWeek;
  @override
  List<Object?> get props => [
    childId,
    completedLessonsCount,
    totalArtworksCount,
    totalBadgesCount,
    learningMinutesThisWeek,
  ];
}
