import '../../domain/entities/kit_delivery.dart';

class KitDeliveryModel extends KitDelivery {
  const KitDeliveryModel({
    required super.id,
    required super.orderId,
    required super.kitName,
    required super.trackingNumber,
    required super.status,
    super.estimatedDeliveryDate,
    super.carrier,
  });

  factory KitDeliveryModel.fromJson(Map<String, dynamic> json) {
    return KitDeliveryModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? json['orderId'] as String? ?? '',
      kitName: json['kit_name'] as String? ?? json['kitName'] as String? ?? 'Physical Art Kit',
      trackingNumber: json['tracking_number'] as String? ?? json['trackingNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'ordered',
      estimatedDeliveryDate: json['estimated_delivery_date'] as String? ?? json['estimatedDeliveryDate'] as String?,
      carrier: json['carrier'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'kit_name': kitName,
      'tracking_number': trackingNumber,
      'status': status,
      'estimated_delivery_date': estimatedDeliveryDate,
      'carrier': carrier,
    };
  }
}
