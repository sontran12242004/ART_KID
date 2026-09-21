import 'package:equatable/equatable.dart';

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.priceMonthly = 199000,
    this.priceVnd = 199000,
    this.durationMonths = 1,
    this.features = const [
      'Toàn bộ video bài giảng theo độ tuổi',
      'Không giới hạn AI sinh mô hình hoạt hình 2D/3D',
      'Bộ sưu tập huy hiệu & phòng trưng bày của bé',
    ],
    this.includesKit = false,
    this.kitDeliveryIncluded = false,
  });

  final String id;
  final String name;
  final double priceMonthly;
  final int priceVnd;
  final int durationMonths;
  final List<String> features;
  final bool includesKit;
  final bool kitDeliveryIncluded;

  @override
  List<Object?> get props => [
        id,
        name,
        priceMonthly,
        priceVnd,
        durationMonths,
        features,
        includesKit,
        kitDeliveryIncluded,
      ];
}
