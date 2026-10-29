import 'package:equatable/equatable.dart';

class SellerDeliveryProgress extends Equatable {
  const SellerDeliveryProgress({
    required this.sellerId,
    required this.sellerName,
    required this.status,
    this.itemTitles = const [],
    this.carrier,
    this.trackingNumber,
    this.shippedAt,
    this.deliveredAt,
  });

  final String sellerId;
  final String sellerName;
  final String status;
  final List<String> itemTitles;
  final String? carrier;
  final String? trackingNumber;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  @override
  List<Object?> get props => [
    sellerId,
    sellerName,
    status,
    itemTitles,
    carrier,
    trackingNumber,
    shippedAt,
    deliveredAt,
  ];
}
