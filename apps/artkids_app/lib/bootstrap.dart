import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/env_config.dart';
import 'core/storage/hive_boxes.dart';
import 'features/matching_game/domain/completed_picture.dart';
import 'features/matching_game/domain/matching_game_progress.dart';

/// Khởi tạo các dependency toàn cục trước khi runApp.
Future<void> bootstrap() async {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  await dotenv.load(fileName: 'env/$flavor.env');

  await Hive.initFlutter();
  Hive.registerAdapter(MatchingGameProgressAdapter());
  Hive.registerAdapter(CompletedPictureAdapter());

  await Hive.openBox(HiveBoxes.settings);
  await Hive.openBox(HiveBoxes.lessonCache);
  await Hive.openBox<MatchingGameProgress>(HiveBoxes.matchingProgress);
  await Hive.openBox<CompletedPicture>(HiveBoxes.completedPictures);

  final enableFirebase =
      dotenv.env['ENABLE_FIREBASE']?.toLowerCase() != 'false';
  if (enableFirebase) {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[bootstrap] Firebase chưa cấu hình — bỏ qua FCM: $e');
    }
  } else {
    debugPrint('[bootstrap] ENABLE_FIREBASE=false — bỏ qua Firebase.');
  }

  EnvConfig.validate();
}
