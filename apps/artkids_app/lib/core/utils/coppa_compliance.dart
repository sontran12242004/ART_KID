/// Tuân thủ COPPA (Children's Online Privacy Protection Act) & GDPR-K:
/// 1. Không thu thập thông tin định danh cá nhân (PII) của trẻ (không hỏi họ tên thật, số điện thoại, địa chỉ trường học).
/// 2. Chỉ lưu trữ nickname và độ tuổi (để gợi ý bài học phù hợp).
/// 3. Ảnh bài vẽ trước khi gửi lên AI pipeline cần xác nhận từ phụ huynh (Parental Gate).
/// 4. Không gửi dữ liệu khuôn mặt / sinh trắc học.
/// 5. Không chia sẻ dữ liệu trẻ em cho bên thứ 3 quảng cáo / analytics định danh.
class CoppaCompliance {
  CoppaCompliance._();

  static bool isValidChildNickname(String nickname) {
    // Không chứa ký tự đặc biệt hoặc định dạng email/số điện thoại
    final phonePattern = RegExp(r'\d{8,}');
    final emailPattern = RegExp(r'@');
    if (phonePattern.hasMatch(nickname) || emailPattern.hasMatch(nickname)) {
      return false;
    }
    return nickname.trim().length >= 2 && nickname.trim().length <= 20;
  }

  static bool isAgeEligibleForKidMode(int age) {
    return age >= 4 && age <= 12;
  }
}
