import '../entities/course.dart';
import '../entities/lesson.dart';

abstract class CourseRepository {
  Future<List<Course>> getCourses();
  Future<List<Lesson>> getLessons(String courseId);
  Future<void> updateProgress({required String childId, required String lessonId, required int percent});
}
