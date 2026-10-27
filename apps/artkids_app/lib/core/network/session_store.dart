import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'session_storage_stub.dart'
    if (dart.library.js_interop) 'session_storage_web.dart'
    as storage;

class ApiSession {
  const ApiSession({this.accessToken, this.refreshToken, this.userId});
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
}

/// Retains the web session within its browser tab, including across reloads.
class SessionStore extends StateNotifier<ApiSession> {
  SessionStore() : super(const ApiSession()) {
    try {
      final raw = storage.readSession();
      if (raw != null) {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        state = ApiSession(
          accessToken: saved['accessToken'] as String,
          refreshToken: saved['refreshToken'] as String,
          userId: saved['userId'] as String,
        );
        selectedChildId = saved['selectedChildId'] as String?;
      }
    } catch (_) {
      clear();
    }
  }
  String? selectedChildId;

  void _persist() => storage.writeSession(
    jsonEncode({
      'accessToken': state.accessToken,
      'refreshToken': state.refreshToken,
      'userId': state.userId,
      'selectedChildId': selectedChildId,
    }),
  );

  void selectChild(String? id) {
    selectedChildId = id;
    _persist();
  }

  void accept(Map<String, dynamic> json) {
    final userId = (json['user'] as Map<String, dynamic>)['id'] as String;
    if (state.userId != userId) selectedChildId = null;
    state = ApiSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: (json['user'] as Map<String, dynamic>)['id'] as String,
    );
    _persist();
  }

  void clear() {
    selectedChildId = null;
    state = const ApiSession();
    storage.writeSession(null);
  }
}

final sessionStoreProvider = StateNotifierProvider<SessionStore, ApiSession>(
  (ref) => SessionStore(),
);
