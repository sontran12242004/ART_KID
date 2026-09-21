import 'package:equatable/equatable.dart';

/// Thực thể biểu diễn 1 mốc sự kiện trong hành trình xử lý / vận chuyển đơn hàng
class OrderTrackingEventEntity extends Equatable {
  const OrderTrackingEventEntity({
    required this.id,
    required this.title,
    required this.description,
    this.timestamp,
    this.isPassed = false,
    this.isCurrent = false,
    this.cancelReason,
  });

  /// Mã sự kiện
  final String id;

  /// Tiêu đề mốc (VD: "Đặt hàng", "Xác nhận", "Xuất kho", "Đang giao", "Giao thành công", "Đã hủy")
  final String title;

  /// Mô tả chi tiết mốc
  final String description;

  /// Thời điểm diễn ra mốc này (nếu đã xảy ra)
  final DateTime? timestamp;

  /// Mốc này đã diễn ra trong quá khứ hay chưa
  final bool isPassed;

  /// Mốc này có đang là trạng thái hiện tại hay không
  final bool isCurrent;

  /// Lý do hủy nếu đơn hàng bị hủy tại mốc này
  final String? cancelReason;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        timestamp,
        isPassed,
        isCurrent,
        cancelReason,
      ];
}
