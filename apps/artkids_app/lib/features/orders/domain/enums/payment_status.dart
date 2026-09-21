import 'package:flutter/material.dart';

/// Enum biểu diễn trạng thái thanh toán của đơn hàng
enum PaymentStatus {
  /// Đã thanh toán qua cổng trực tuyến (VietQR, Thẻ, Ví...)
  paid(
    value: 'paid',
    label: 'Đã thanh toán',
    color: Color(0xFF27AE60),
    backgroundColor: Color(0xFFE8F8F5),
    icon: Icons.check_circle_rounded,
  ),

  /// Chờ người dùng thanh toán trực tuyến
  pending(
    value: 'pending',
    label: 'Chờ thanh toán',
    color: Color(0xFFE67E22),
    backgroundColor: Color(0xFFFDF2E9),
    icon: Icons.schedule_rounded,
  ),

  /// Thanh toán khi nhận hàng (Cash on Delivery)
  cod(
    value: 'cod',
    label: 'Thanh toán khi nhận hàng (COD)',
    color: Color(0xFF2980B9),
    backgroundColor: Color(0xFFEBF5FB),
    icon: Icons.payments_outlined,
  );

  const PaymentStatus({
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

  static PaymentStatus fromString(String? val) {
    if (val == null) return PaymentStatus.pending;
    final normalized = val.toLowerCase().trim();
    switch (normalized) {
      case 'paid':
      case 'success':
      case 'completed':
        return PaymentStatus.paid;
      case 'cod':
      case 'cash_on_delivery':
        return PaymentStatus.cod;
      case 'pending':
      case 'unpaid':
      default:
        return PaymentStatus.pending;
    }
  }
}
