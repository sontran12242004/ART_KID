import '../../domain/entities/order_item_entity.dart';

/// Model API cho từng sản phẩm / kit trong đơn hàng
class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.id,
    required super.kitName,
    required super.thumbnailUrl,
    required super.quantity,
    required super.unitPriceVnd,
    super.courseId,
    super.courseTitle,
    super.kitItems,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? '',
      kitName: json['kit_name'] as String? ?? json['kitName'] as String? ?? '',
      thumbnailUrl:
          json['thumbnail_url'] as String? ??
          json['thumbnailUrl'] as String? ??
          '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceVnd:
          (json['unit_price_vnd'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      courseId: json['course_id'] as String? ?? json['courseId'] as String?,
      courseTitle:
          json['course_title'] as String? ?? json['courseTitle'] as String?,
      kitItems:
          (json['kit_items'] as List<dynamic>? ??
                  json['kitItems'] as List<dynamic>? ??
                  [])
              .map((e) => e.toString())
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kit_name': kitName,
      'thumbnail_url': thumbnailUrl,
      'quantity': quantity,
      'unit_price_vnd': unitPriceVnd,
      if (courseId != null) 'course_id': courseId,
      if (courseTitle != null) 'course_title': courseTitle,
      'kit_items': kitItems,
    };
  }
}
