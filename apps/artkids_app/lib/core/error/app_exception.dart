sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Lỗi kết nối mạng']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Phiên đăng nhập không hợp lệ']);
}

class AiJobException extends AppException {
  const AiJobException([super.message = 'Không thể tạo con vật AI']);
}

class ParentalConsentRequiredException extends AppException {
  const ParentalConsentRequiredException()
      : super('Cần xác nhận từ phụ huynh trước khi gửi bài vẽ');
}
