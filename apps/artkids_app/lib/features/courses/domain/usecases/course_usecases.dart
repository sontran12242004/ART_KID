import '../entities/course.dart';
import '../entities/lesson.dart';
import '../repositories/course_repository.dart';

class GetCoursesUseCase {
  const GetCoursesUseCase(this._repository);

  final CourseRepository _repository;

  Future<List<Course>> call() => _repository.getCourses();
}

class GetLessonsUseCase {
  const GetLessonsUseCase(this._repository);

  final CourseRepository _repository;

  Future<List<Lesson>> call(String courseId) =>
      _repository.getLessons(courseId);
}

class UpdateProgressUseCase {
  const UpdateProgressUseCase(this._repository);

  final CourseRepository _repository;

  Future<void> call({
    required String childId,
    required String lessonId,
    required int percent,
  }) => _repository.updateProgress(
    childId: childId,
    lessonId: lessonId,
    percent: percent,
  );
}
