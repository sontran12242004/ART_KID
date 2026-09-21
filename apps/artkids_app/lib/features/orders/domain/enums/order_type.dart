import 'package:flutter/material.dart';

/// Enum phân biệt loại đơn hàng trong ArtKids:
/// - Gói đăng ký định kỳ (subscription)
/// - Mua lẻ học cụ trong Cửa hàng (oneTimePurchase)
enum OrderType {
  /// Đơn hàng tạo ra từ việc đăng ký gói học hội họa (kèm kit định kỳ)
  subscription(
    value: 'subscription',
    label: 'Gói đăng ký',
    color: Color(0xFF6C5CE7), // Tím hiện đại
    backgroundColor: Color(0xFFF3E5F5),
    icon: Icons.card_membership_rounded,
  ),

  /// Đơn hàng tạo ra từ việc mua lẻ từng món/kit học cụ trong Shop
  oneTimePurchase(
    value: 'one_time_purchase',
    label: 'Mua lẻ',
    color: Color(0xFFE67E22), // Cam ấm
    backgroundColor: Color(0xFFFDF2E9),
    icon: Icons.shopping_bag_outlined,
  );

  const OrderType({
    required this.value,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  static OrderType fromString(String? val) {
    if (val == null) return OrderType.oneTimePurchase;
    final normalized = val.toLowerCase().replaceAll('-', '_').trim();
    switch (normalized) {
      case 'subscription':
      case 'sub':
      case 'plan':
        return OrderType.subscription;
      case 'one_time_purchase':
      case 'onetimepurchase':
      case 'retail':
      case 'shop':
      default:
        return OrderType.oneTimePurchase;
    }
  }
}
