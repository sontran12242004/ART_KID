import 'package:equatable/equatable.dart';

class KitDelivery extends Equatable {
  const KitDelivery({
    required this.id,
    required this.orderId,
    required this.kitName,
    required this.trackingNumber,
    required this.status, // ordered, packed, shipping, delivered
    this.estimatedDeliveryDate,
    this.carrier,
  });

  final String id;
  final String orderId;
  final String kitName;
  final String trackingNumber;
  final String status;
  final String? estimatedDeliveryDate;
  final String? carrier;

  @override
  List<Object?> get props => [
    id,
    orderId,
    kitName,
    trackingNumber,
    status,
    estimatedDeliveryDate,
    carrier,
  ];
}
