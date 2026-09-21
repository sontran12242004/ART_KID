import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM — nhận push khi AI generate xong, đơn hàng cập nhật, bài học mới
class FcmService {
  FcmService(this._messaging);
  final FirebaseMessaging _messaging;

  Future<void> initialize({
    required void Function(RemoteMessage) onMessage,
    required void Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    await _messaging.requestPermission();
    FirebaseMessaging.onMessage.listen(onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);

    final token = await _messaging.getToken();
    // TODO: gửi token lên notification-service
    assert(token != null || true);
  }

  /// Handler khi app ở background — đăng ký trong main.dart
  static Future<void> backgroundHandler(RemoteMessage message) async {
    // TODO: xử lý notification AI job completed
  }
}
