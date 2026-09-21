import 'package:flutter/material.dart';

/// Enum biểu diễn trạng thái vòng đời của đơn hàng vật lý (Kit học cụ)
enum OrderStatus {
  /// Chờ xác nhận từ hệ thống hoặc trung tâm điều phối
  pendingConfirmation(
    value: 'pending_confirmation',
    label: 'Chờ xác nhận',
    color: Color(0xFFE67E22), // Cam ấm
    backgroundColor: Color(0xFFFDF2E9),
    icon: Icons.hourglass_top_rounded,
  ),

  /// Đang chuẩn bị đóng gói kit học cụ tại kho
  preparing(
    value: 'preparing',
    label: 'Đang chuẩn bị',
    color: Color(0xFF2980B9), // Xanh navy tươi
    backgroundColor: Color(0xFFEBF5FB),
    icon: Icons.inventory_2_outlined,
  ),

  /// Đang trên đường giao tới địa chỉ phụ huynh
  shipping(
    value: 'shipping',
    label: 'Đang giao',
    color: Color(0xFF1687A7), // Xanh Teal chủ đạo của app
    backgroundColor: Color(0xFFE2F3F5),
    icon: Icons.local_shipping_outlined,
  ),

  /// Đã giao hàng thành công tới tay người nhận
  delivered(
    value: 'delivered',
    label: 'Đã giao',
    color: Color(0xFF27AE60), // Xanh lá thành công
    backgroundColor: Color(0xFFE8F8F5),
    icon: Icons.check_circle_outline_rounded,
  ),

  /// Đơn hàng đã bị hủy
  cancelled(
    value: 'cancelled',
    label: 'Đã hủy',
    color: Color(0xFFE74C3C), // Đỏ nhạt / xám
    backgroundColor: Color(0xFFFDEDEC),
    icon: Icons.cancel_outlined,
  );

  const OrderStatus({
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

  /// Đơn hàng có đang trong quá trình xử lý (chưa kết thúc)
  bool get isProcessing =>
      this == OrderStatus.pendingConfirmation ||
      this == OrderStatus.preparing ||
      this == OrderStatus.shipping;

  /// Chuyển đổi từ chuỗi string API
  static OrderStatus fromString(String? val) {
    if (val == null) return OrderStatus.pendingConfirmation;
    final normalized = val.toLowerCase().replaceAll('-', '_').trim();
    switch (normalized) {
      case 'pending':
      case 'pending_confirmation':
      case 'pendingconfirmation':
        return OrderStatus.pendingConfirmation;
      case 'preparing':
      case 'processing':
      case 'packaged':
        return OrderStatus.preparing;
      case 'shipping':
      case 'in_transit':
      case 'delivering':
        return OrderStatus.shipping;
      case 'delivered':
      case 'completed':
      case 'success':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pendingConfirmation;
    }
  }
}
