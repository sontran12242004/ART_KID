import '../../domain/entities/shipping_info_entity.dart';

/// Model API cho thông tin giao hàng
class ShippingInfoModel extends ShippingInfoEntity {
  const ShippingInfoModel({
    required super.recipientName,
    required super.phoneNumber,
    required super.fullAddress,
    super.carrierName,
    super.trackingNumber,
    super.trackingUrl,
    super.estimatedDeliveryDate,
  });

  factory ShippingInfoModel.fromJson(Map<String, dynamic> json) {
    return ShippingInfoModel(
      recipientName:
          json['recipient_name'] as String? ??
          json['recipientName'] as String? ??
          '',
      phoneNumber:
          json['phone_number'] as String? ??
          json['phoneNumber'] as String? ??
          '',
      fullAddress:
          json['full_address'] as String? ??
          json['fullAddress'] as String? ??
          '',
      carrierName:
          json['carrier_name'] as String? ??
          json['carrierName'] as String? ??
          'Chưa phân công',
      trackingNumber:
          json['tracking_number'] as String? ??
          json['trackingNumber'] as String?,
      trackingUrl:
          json['tracking_url'] as String? ?? json['trackingUrl'] as String?,
      estimatedDeliveryDate: json['estimated_delivery_date'] != null
          ? DateTime.tryParse(json['estimated_delivery_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient_name': recipientName,
      'phone_number': phoneNumber,
      'full_address': fullAddress,
      'carrier_name': carrierName,
      if (trackingNumber != null) 'tracking_number': trackingNumber,
      if (trackingUrl != null) 'tracking_url': trackingUrl,
      if (estimatedDeliveryDate != null)
        'estimated_delivery_date': estimatedDeliveryDate!.toIso8601String(),
    };
  }
}
