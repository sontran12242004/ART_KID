import 'package:equatable/equatable.dart';

import 'seller_delivery_progress.dart';
import '../enums/order_status.dart';
import '../enums/order_type.dart';
import '../enums/payment_status.dart';
import 'order_item_entity.dart';
import 'order_tracking_event_entity.dart';
import 'shipping_info_entity.dart';

/// Thực thể thuần đại diện cho một Đơn Hàng trong ArtKids
class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.orderCode,
    required this.createdAt,
    required this.status,
    this.orderType = OrderType.oneTimePurchase,
    required this.paymentStatus,
    this.paymentMethodName = 'Chuyển khoản VietQR',
    required this.items,
    required this.shippingInfo,
    required this.subtotalVnd,
    this.shippingFeeVnd = 0,
    this.discountVnd = 0,
    this.voucherCode,
    required this.totalAmountVnd,
    this.trackingEvents = const [],
    this.sellerProgress = const [],
    this.cancelReason,
    this.cancellationAllowed,
    this.awaitingMarketplacePayment = false,
  });

  /// ID hệ thống của đơn hàng
  final String id;

  /// Mã đơn hàng hiển thị (VD: "ORD-2026-8891")
  final String orderCode;

  /// Ngày giờ đặt hàng
  final DateTime createdAt;

  /// Trạng thái đơn hàng
  final OrderStatus status;

  /// Loại đơn hàng (Gói đăng ký hoặc Mua lẻ)
  final OrderType orderType;

  /// Trạng thái thanh toán
  final PaymentStatus paymentStatus;

  /// Tên phương thức thanh toán
  final String paymentMethodName;

  /// Danh sách sản phẩm trong đơn
  final List<OrderItemEntity> items;

  /// Thông tin vận chuyển
  final ShippingInfoEntity shippingInfo;

  /// Tiền tạm tính
  final int subtotalVnd;

  /// Phí vận chuyển
  final int shippingFeeVnd;

  /// Giảm giá (voucher, ưu đãi gói học cụ...)
  final int discountVnd;

  /// Mã voucher đã áp dụng (nếu có)
  final String? voucherCode;

  /// Tổng tiền thanh toán cuối cùng
  final int totalAmountVnd;

  /// Timeline các mốc theo dõi
  final List<OrderTrackingEventEntity> trackingEvents;
  final List<SellerDeliveryProgress> sellerProgress;

  /// Lý do hủy đơn (nếu có)
  final String? cancelReason;
  final bool? cancellationAllowed;
  final bool awaitingMarketplacePayment;
  bool get canCancel =>
      status != OrderStatus.cancelled &&
      status != OrderStatus.shipping &&
      status != OrderStatus.delivered &&
      (cancellationAllowed ?? status == OrderStatus.pendingConfirmation);

  /// Tổng số món kit trong đơn
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Sao chép đơn hàng với các trường cập nhật (dùng khi hủy đơn hoặc update trạng thái)
  OrderEntity copyWith({
    String? id,
    String? orderCode,
    DateTime? createdAt,
    OrderStatus? status,
    OrderType? orderType,
    PaymentStatus? paymentStatus,
    String? paymentMethodName,
    List<OrderItemEntity>? items,
    ShippingInfoEntity? shippingInfo,
    int? subtotalVnd,
    int? shippingFeeVnd,
    int? discountVnd,
    String? voucherCode,
    int? totalAmountVnd,
    List<OrderTrackingEventEntity>? trackingEvents,
    String? cancelReason,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      items: items ?? this.items,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      subtotalVnd: subtotalVnd ?? this.subtotalVnd,
      shippingFeeVnd: shippingFeeVnd ?? this.shippingFeeVnd,
      discountVnd: discountVnd ?? this.discountVnd,
      voucherCode: voucherCode ?? this.voucherCode,
      totalAmountVnd: totalAmountVnd ?? this.totalAmountVnd,
      trackingEvents: trackingEvents ?? this.trackingEvents,
      sellerProgress: sellerProgress,
      cancelReason: cancelReason ?? this.cancelReason,
      cancellationAllowed: cancellationAllowed,
      awaitingMarketplacePayment: awaitingMarketplacePayment,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderCode,
    createdAt,
    status,
    orderType,
    paymentStatus,
    paymentMethodName,
    items,
    shippingInfo,
    subtotalVnd,
    shippingFeeVnd,
    discountVnd,
    voucherCode,
    totalAmountVnd,
    trackingEvents,
    sellerProgress,
    cancelReason,
    cancellationAllowed,
    awaitingMarketplacePayment,
  ];
}
