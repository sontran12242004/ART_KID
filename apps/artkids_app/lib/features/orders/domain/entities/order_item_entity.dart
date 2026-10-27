import 'package:equatable/equatable.dart';

/// Thực thể biểu diễn 1 sản phẩm / bộ kit học cụ trong đơn hàng
class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.id,
    required this.kitName,
    required this.thumbnailUrl,
    required this.quantity,
    required this.unitPriceVnd,
    this.courseId,
    this.courseTitle,
    this.kitItems = const [],
  });

  /// Mã định danh sản phẩm
  final String id;

  /// Tên kit học cụ (VD: "Hộp Học Cụ Sáng Tạo: Vẽ Động Vật Bằng Màu Nước")
  final String kitName;

  /// Đường dẫn hình ảnh thumbnail
  final String thumbnailUrl;

  /// Số lượng đặt
  final int quantity;

  /// Đơn giá VNĐ
  final int unitPriceVnd;

  /// ID khóa học liên quan nếu kit đi kèm khóa học
  final String? courseId;

  /// Tên khóa học liên quan (VD: "Vẽ động vật bằng màu nước")
  final String? courseTitle;

  /// Chi tiết các món đồ vật lý bên trong kit (hiển thị khi bấm "Xem chi tiết bên trong kit")
  final List<String> kitItems;

  /// Thành tiền
  int get totalPriceVnd => unitPriceVnd * quantity;

  @override
  List<Object?> get props => [
    id,
    kitName,
    thumbnailUrl,
    quantity,
    unitPriceVnd,
    courseId,
    courseTitle,
    kitItems,
  ];
}
