/// Enum đại diện cho 3 con vật trong trò chơi vẽ và ghép tranh
enum Animal { cat, dog, bird }

/// Tiện ích bổ sung cho [Animal] hỗ trợ hiển thị UI và đường dẫn tài nguyên
extension AnimalX on Animal {
  /// Tên gọi tiếng Việt thân thiện với trẻ nhỏ
  String get displayName {
    switch (this) {
      case Animal.cat:
        return 'Mèo con';
      case Animal.dog:
        return 'Cún cưng';
      case Animal.bird:
        return 'Chú chim';
    }
  }

  /// Câu gợi ý hướng dẫn bé vẽ
  String get drawingPrompt {
    switch (this) {
      case Animal.cat:
        return 'Bé hãy vẽ một chú mèo đáng yêu nhé! 🐱';
      case Animal.dog:
        return 'Bé hãy vẽ một bạn cún thật ngoan nào! 🐶';
      case Animal.bird:
        return 'Bé hãy vẽ một chú chim đang hót nhé! 🐦';
    }
  }

  /// Đường dẫn asset sticker đã tách nền trong suốt
  String get stickerAssetPath {
    switch (this) {
      case Animal.cat:
        return 'assets/images/matching_game/sticker_cat.png';
      case Animal.dog:
        return 'assets/images/matching_game/sticker_dog.png';
      case Animal.bird:
        return 'assets/images/matching_game/sticker_bird.png';
    }
  }

  /// Thông điệp khen thưởng khi bé vẽ xong
  String get rewardMessage {
    switch (this) {
      case Animal.cat:
        return 'Tuyệt vời! Bé nhận được 1 Sticker Mèo Con!';
      case Animal.dog:
        return 'Hoan hô! Bé nhận được 1 Sticker Cún Cưng!';
      case Animal.bird:
        return 'Xuất sắc! Bé nhận được 1 Sticker Chú Chim!';
    }
  }
}
