import '../../domain/entities/order_tracking_event_entity.dart';

/// Model API cho mốc sự kiện theo dõi đơn hàng
class OrderTrackingEventModel extends OrderTrackingEventEntity {
  const OrderTrackingEventModel({
    required super.id,
    required super.title,
    required super.description,
    super.timestamp,
    super.isPassed,
    super.isCurrent,
    super.cancelReason,
  });

  factory OrderTrackingEventModel.fromJson(Map<String, dynamic> json) {
    return OrderTrackingEventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      isPassed: json['is_passed'] as bool? ?? json['isPassed'] as bool? ?? false,
      isCurrent: json['is_current'] as bool? ?? json['isCurrent'] as bool? ?? false,
      cancelReason: json['cancel_reason'] as String? ?? json['cancelReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp?.toIso8601String(),
      'is_passed': isPassed,
      'is_current': isCurrent,
      if (cancelReason != null) 'cancel_reason': cancelReason,
    };
  }
}
