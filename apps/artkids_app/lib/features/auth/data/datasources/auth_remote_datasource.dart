import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiConstants.authLogin,
      data: {'email': email, 'password': password},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> verifyKidPin(String pin) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiConstants.authKidPinVerify,
      data: {'pin': pin},
    );
    return res.data!;
  }
}

typedef AuthRemoteDataSourceImpl = AuthRemoteDataSource;
