import 'package:equatable/equatable.dart';

/// Thực thể thông tin nhận hàng và vận chuyển
class ShippingInfoEntity extends Equatable {
  const ShippingInfoEntity({
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    this.carrierName = 'Giao Hàng Nhanh (GHN)',
    this.trackingNumber,
    this.trackingUrl,
    this.estimatedDeliveryDate,
  });

  /// Họ tên người nhận (thường là tên phụ huynh)
  final String recipientName;

  /// Số điện thoại liên hệ nhận hàng
  final String phoneNumber;

  /// Địa chỉ giao hàng đầy đủ (Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành)
  final String fullAddress;

  /// Đơn vị vận chuyển (GHN, Viettel Post, GHTK...)
  final String carrierName;

  /// Mã vận đơn để tra cứu
  final String? trackingNumber;

  /// Đường dẫn web tra cứu vận đơn trực tiếp của hãng vận chuyển
  final String? trackingUrl;

  /// Thời gian dự kiến giao hàng
  final DateTime? estimatedDeliveryDate;

  @override
  List<Object?> get props => [
        recipientName,
        phoneNumber,
        fullAddress,
        carrierName,
        trackingNumber,
        trackingUrl,
        estimatedDeliveryDate,
      ];
}
