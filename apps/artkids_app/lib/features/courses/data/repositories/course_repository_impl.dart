import '../../domain/entities/course.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl(this.remote);
  final CourseRemoteDataSource remote;
  @override
  Future<List<Course>> getCourses() => remote.getCourses();
  @override
  Future<List<Lesson>> getLessons(String courseId) =>
      remote.getLessons(courseId);
  @override
  Future<void> updateProgress({
    required String childId,
    required String lessonId,
    required int percent,
  }) => remote.updateProgress(
    childId: childId,
    lessonId: lessonId,
    percent: percent,
  );
}
