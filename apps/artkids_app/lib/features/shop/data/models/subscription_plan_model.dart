import '../../domain/entities/subscription_plan.dart';

class SubscriptionPlanModel extends SubscriptionPlan {
  const SubscriptionPlanModel({
    required super.id,
    required super.name,
    super.priceMonthly = 199000,
    super.priceVnd = 199000,
    super.durationMonths = 1,
    super.features = const [],
    super.includesKit = false,
    super.kitDeliveryIncluded = false,
    this.description,
  });

  final String? description;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final price =
        (json['price_monthly'] as num?)?.toDouble() ??
        (json['priceMonthly'] as num?)?.toDouble() ??
        199000.0;
    final kit =
        json['includes_kit'] as bool? ?? json['includesKit'] as bool? ?? false;

    return SubscriptionPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      priceMonthly: price,
      priceVnd: (json['price_vnd'] as num?)?.toInt() ?? price.toInt(),
      durationMonths: json['duration_months'] as int? ?? 1,
      includesKit: kit,
      kitDeliveryIncluded: kit,
      description: json['description'] as String?,
      features:
          (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_monthly': priceMonthly,
      'includes_kit': includesKit,
      'description': description,
      'features': features,
    };
  }
}
