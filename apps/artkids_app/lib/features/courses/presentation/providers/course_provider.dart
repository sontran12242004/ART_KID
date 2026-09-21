import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/course_repository.dart';

final courseRemoteDataSourceProvider = Provider<CourseRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return CourseRemoteDataSourceImpl(dio);
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final remote = ref.watch(courseRemoteDataSourceProvider);
  return CourseRepositoryImpl(remote);
});

final coursesFutureProvider = FutureProvider<List<Course>>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getCourses();
});

final lessonsFamilyProvider =
    FutureProvider.family<List<Lesson>, String>((ref, courseId) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getLessons(courseId);
});
