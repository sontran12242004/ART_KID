import '../../domain/entities/order_entity.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/order_type.dart';
import '../../domain/enums/payment_status.dart';
import 'order_item.dart';
import 'order_tracking_event.dart';
import 'shipping_info.dart';

/// Model API cho Đơn hàng
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderCode,
    required super.createdAt,
    required super.status,
    super.orderType,
    required super.paymentStatus,
    super.paymentMethodName,
    required super.items,
    required super.shippingInfo,
    required super.subtotalVnd,
    super.shippingFeeVnd,
    super.discountVnd,
    super.voucherCode,
    required super.totalAmountVnd,
    super.trackingEvents,
    super.cancelReason,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawShipping = json['shipping_info'] as Map<String, dynamic>? ??
        json['shippingInfo'] as Map<String, dynamic>? ??
        {};
    final shippingInfo = ShippingInfoModel.fromJson(rawShipping);

    final rawTracking = json['tracking_events'] as List<dynamic>? ??
        json['trackingEvents'] as List<dynamic>? ??
        [];
    final trackingEvents = rawTracking
        .map((e) => OrderTrackingEventModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'] as String? ?? '',
      orderCode: json['order_code'] as String? ??
          json['orderCode'] as String? ??
          json['code'] as String? ??
          '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: OrderStatus.fromString(json['status'] as String?),
      orderType: OrderType.fromString(
          json['order_type'] as String? ?? json['orderType'] as String?),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] as String?),
      paymentMethodName: json['payment_method_name'] as String? ??
          json['paymentMethodName'] as String? ??
          'Chuyển khoản VietQR',
      items: items,
      shippingInfo: shippingInfo,
      subtotalVnd: (json['subtotal_vnd'] as num?)?.toInt() ??
          (json['subtotal'] as num?)?.toInt() ??
          0,
      shippingFeeVnd: (json['shipping_fee_vnd'] as num?)?.toInt() ??
          (json['shippingFee'] as num?)?.toInt() ??
          0,
      discountVnd: (json['discount_vnd'] as num?)?.toInt() ??
          (json['discount'] as num?)?.toInt() ??
          0,
      voucherCode: json['voucher_code'] as String? ?? json['voucherCode'] as String?,
      totalAmountVnd: (json['total_amount_vnd'] as num?)?.toInt() ??
          (json['total'] as num?)?.toInt() ??
          0,
      trackingEvents: trackingEvents,
      cancelReason: json['cancel_reason'] as String? ?? json['cancelReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'created_at': createdAt.toIso8601String(),
      'status': status.value,
      'order_type': orderType.value,
      'payment_status': paymentStatus.value,
      'payment_method_name': paymentMethodName,
      'items': items
          .map((e) => (e is OrderItemModel ? e : OrderItemModel(
                id: e.id,
                kitName: e.kitName,
                thumbnailUrl: e.thumbnailUrl,
                quantity: e.quantity,
                unitPriceVnd: e.unitPriceVnd,
                courseId: e.courseId,
                courseTitle: e.courseTitle,
                kitItems: e.kitItems,
              )).toJson())
          .toList(),
      'shipping_info': (shippingInfo is ShippingInfoModel
              ? shippingInfo as ShippingInfoModel
              : ShippingInfoModel(
                  recipientName: shippingInfo.recipientName,
                  phoneNumber: shippingInfo.phoneNumber,
                  fullAddress: shippingInfo.fullAddress,
                  carrierName: shippingInfo.carrierName,
                  trackingNumber: shippingInfo.trackingNumber,
                  trackingUrl: shippingInfo.trackingUrl,
                  estimatedDeliveryDate: shippingInfo.estimatedDeliveryDate,
                ))
          .toJson(),
      'subtotal_vnd': subtotalVnd,
      'shipping_fee_vnd': shippingFeeVnd,
      'discount_vnd': discountVnd,
      if (voucherCode != null) 'voucher_code': voucherCode,
      'total_amount_vnd': totalAmountVnd,
      'tracking_events': trackingEvents
          .map((e) => (e is OrderTrackingEventModel
                  ? e
                  : OrderTrackingEventModel(
                      id: e.id,
                      title: e.title,
                      description: e.description,
                      timestamp: e.timestamp,
                      isPassed: e.isPassed,
                      isCurrent: e.isCurrent,
                      cancelReason: e.cancelReason,
                    ))
              .toJson())
          .toList(),
      if (cancelReason != null) 'cancel_reason': cancelReason,
    };
  }
}
