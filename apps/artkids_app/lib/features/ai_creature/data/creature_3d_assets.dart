/// Mapping animalType (từ Gemini) → 3D model GLB URL + metadata
///
/// Sử dụng model GLB miễn phí từ các nguồn public:
/// - modelviewer.dev shared assets
/// - poly.pizza (CC-BY licensed)
///
/// Nếu animalType không khớp → fallback sang animated 2D widget.
class Creature3dAssets {
  Creature3dAssets._();

  /// Thông tin asset cho mỗi loại con vật
  static const Map<String, CreatureAssetInfo> _assets = {
    // Có model 3D thật
    'horse': CreatureAssetInfo(
      glbUrl: 'https://modelviewer.dev/shared-assets/models/Horse.glb',
      emoji: '🐴',
      color: 0xFF8B4513,
      nameVi: 'Ngựa',
    ),
    'astronaut': CreatureAssetInfo(
      glbUrl:
          'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      emoji: '🧑‍🚀',
      color: 0xFFE0E0E0,
      nameVi: 'Phi Hành Gia',
    ),
    // Fallback 2D cho các con vật phổ biến khác
    'cat': CreatureAssetInfo(
      emoji: '🐱',
      color: 0xFFFF9800,
      nameVi: 'Mèo',
    ),
    'dog': CreatureAssetInfo(
      emoji: '🐶',
      color: 0xFF795548,
      nameVi: 'Chó',
    ),
    'lion': CreatureAssetInfo(
      emoji: '🦁',
      color: 0xFFFF8F00,
      nameVi: 'Sư Tử',
    ),
    'bird': CreatureAssetInfo(
      emoji: '🐦',
      color: 0xFF2196F3,
      nameVi: 'Chim',
    ),
    'elephant': CreatureAssetInfo(
      emoji: '🐘',
      color: 0xFF9E9E9E,
      nameVi: 'Voi',
    ),
    'fish': CreatureAssetInfo(
      emoji: '🐟',
      color: 0xFF03A9F4,
      nameVi: 'Cá',
    ),
    'rabbit': CreatureAssetInfo(
      emoji: '🐰',
      color: 0xFFE8D5B7,
      nameVi: 'Thỏ',
    ),
    'dolphin': CreatureAssetInfo(
      emoji: '🐬',
      color: 0xFF0288D1,
      nameVi: 'Cá Heo',
    ),
    'butterfly': CreatureAssetInfo(
      emoji: '🦋',
      color: 0xFF9C27B0,
      nameVi: 'Bướm',
    ),
    'dinosaur': CreatureAssetInfo(
      emoji: '🦕',
      color: 0xFF4CAF50,
      nameVi: 'Khủng Long',
    ),
    'penguin': CreatureAssetInfo(
      emoji: '🐧',
      color: 0xFF37474F,
      nameVi: 'Chim Cánh Cụt',
    ),
    'owl': CreatureAssetInfo(
      emoji: '🦉',
      color: 0xFF6D4C41,
      nameVi: 'Cú',
    ),
    'fox': CreatureAssetInfo(
      emoji: '🦊',
      color: 0xFFFF5722,
      nameVi: 'Cáo',
    ),
    'bear': CreatureAssetInfo(
      emoji: '🐻',
      color: 0xFF5D4037,
      nameVi: 'Gấu',
    ),
    'whale': CreatureAssetInfo(
      emoji: '🐋',
      color: 0xFF1565C0,
      nameVi: 'Cá Voi',
    ),
    'tiger': CreatureAssetInfo(
      emoji: '🐯',
      color: 0xFFEF6C00,
      nameVi: 'Hổ',
    ),
    'giraffe': CreatureAssetInfo(
      emoji: '🦒',
      color: 0xFFFFC107,
      nameVi: 'Hươu Cao Cổ',
    ),
    'monkey': CreatureAssetInfo(
      emoji: '🐒',
      color: 0xFF795548,
      nameVi: 'Khỉ',
    ),
    'turtle': CreatureAssetInfo(
      emoji: '🐢',
      color: 0xFF388E3C,
      nameVi: 'Rùa',
    ),
    'snake': CreatureAssetInfo(
      emoji: '🐍',
      color: 0xFF2E7D32,
      nameVi: 'Rắn',
    ),
    'frog': CreatureAssetInfo(
      emoji: '🐸',
      color: 0xFF66BB6A,
      nameVi: 'Ếch',
    ),
    'pig': CreatureAssetInfo(
      emoji: '🐷',
      color: 0xFFF48FB1,
      nameVi: 'Heo',
    ),
    'cow': CreatureAssetInfo(
      emoji: '🐮',
      color: 0xFF8D6E63,
      nameVi: 'Bò',
    ),
    'chicken': CreatureAssetInfo(
      emoji: '🐔',
      color: 0xFFFFB300,
      nameVi: 'Gà',
    ),
  };

  /// Lấy thông tin asset cho loài vật, fallback nếu không có trong map
  static CreatureAssetInfo getAsset(String animalType) {
    final key = animalType.toLowerCase().trim();
    if (_assets.containsKey(key)) return _assets[key]!;

    // Fuzzy matching cho các tên tiếng Việt / tiếng Anh thường gặp
    if (key.contains('pig') || key.contains('heo') || key.contains('lợn') || key.contains('ỉn')) {
      return _assets['pig']!;
    }
    if (key.contains('cat') || key.contains('mèo')) {
      return _assets['cat']!;
    }
    if (key.contains('dog') || key.contains('chó') || key.contains('cún')) {
      return _assets['dog']!;
    }
    if (key.contains('horse') || key.contains('ngựa')) {
      return _assets['horse']!;
    }
    if (key.contains('lion') || key.contains('sư tử')) {
      return _assets['lion']!;
    }
    if (key.contains('bird') || key.contains('chim')) {
      return _assets['bird']!;
    }
    if (key.contains('bear') || key.contains('gấu')) {
      return _assets['bear']!;
    }
    if (key.contains('fish') || key.contains('cá')) {
      return _assets['fish']!;
    }
    if (key.contains('rabbit') || key.contains('thỏ')) {
      return _assets['rabbit']!;
    }
    if (key.contains('dinosaur') || key.contains('khủng long')) {
      return _assets['dinosaur']!;
    }
    if (key.contains('elephant') || key.contains('voi')) {
      return _assets['elephant']!;
    }
    if (key.contains('tiger') || key.contains('hổ') || key.contains('cọp')) {
      return _assets['tiger']!;
    }
    if (key.contains('chicken') || key.contains('gà')) {
      return _assets['chicken']!;
    }
    if (key.contains('frog') || key.contains('ếch')) {
      return _assets['frog']!;
    }
    if (key.contains('turtle') || key.contains('rùa')) {
      return _assets['turtle']!;
    }
    if (key.contains('monkey') || key.contains('khỉ')) {
      return _assets['monkey']!;
    }

    return _defaultAsset;
  }

  /// Kiểm tra xem có model 3D cho loài vật không
  static bool has3dModel(String animalType) {
    return getAsset(animalType).has3d;
  }

  static const CreatureAssetInfo _defaultAsset = CreatureAssetInfo(
    emoji: '🐾',
    color: 0xFFFF6B6B,
    nameVi: 'Con Vật',
  );
}

/// Thông tin asset cho một loại con vật
class CreatureAssetInfo {
  const CreatureAssetInfo({
    this.glbUrl,
    required this.emoji,
    required this.color,
    required this.nameVi,
  });

  /// URL model 3D GLB — null nếu chỉ có fallback 2D
  final String? glbUrl;

  /// Emoji đại diện
  final String emoji;

  /// Màu chủ đạo (dùng cho background gradient, particles)
  final int color;

  /// Tên tiếng Việt
  final String nameVi;

  /// Có model 3D không
  bool get has3d => glbUrl != null;
}
