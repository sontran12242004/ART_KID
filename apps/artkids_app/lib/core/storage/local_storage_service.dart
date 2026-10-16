import 'package:hive_flutter/hive_flutter.dart';

/// Cache offline cho nội dung bài học và cài đặt cục bộ.
class LocalStorageService {
  LocalStorageService(this._box);
  final Box<dynamic> _box;

  Future<void> put(String key, dynamic value) => _box.put(key, value);

  T? get<T>(String key) => _box.get(key) as T?;

  Future<void> delete(String key) => _box.delete(key);
}
