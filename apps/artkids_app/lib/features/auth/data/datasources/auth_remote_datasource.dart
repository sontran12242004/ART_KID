import 'package:dio/dio.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/network/session_store.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this.dio, this.session);
  final Dio dio;
  final SessionStore session;
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = apiMap(
      (await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      )).data,
    );
    session.accept(data);
    return apiMap(data['user']);
  }

  Future<Map<String, dynamic>> verifyKidPin(String pin) async =>
      apiMap((await dio.post('/auth/kid-pin/verify', data: {'pin': pin})).data);
}

typedef AuthRemoteDataSourceImpl = AuthRemoteDataSource;
