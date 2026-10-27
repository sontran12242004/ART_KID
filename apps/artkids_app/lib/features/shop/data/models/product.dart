import 'package:equatable/equatable.dart';

import '../../domain/enums/product_category.dart';

/// Model đại diện cho 1 sản phẩm bán lẻ trong Cửa hàng học cụ (Shop)
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.priceVnd,
    this.originalPriceVnd,
    required this.thumbnailUrl,
    this.images = const [],
    required this.description,
    required this.category,
    this.courseId,
    this.courseTitle,
    this.recommendedSubscriptionPlanId,
    this.recommendedSubscriptionPlanName,
    this.kitItems = const [],
    this.rating = 0,
    this.soldCount = 0,
    this.inStock = true,
  });

  /// Mã định danh sản phẩm
  final String id;

  /// Tên sản phẩm
  final String name;

  /// Giá bán hiện tại (VNĐ)
  final int priceVnd;

  /// Giá gốc niêm yết trước ưu đãi (nếu có)
  final int? originalPriceVnd;

  /// Ảnh đại diện chính
  final String thumbnailUrl;

  /// Danh sách ảnh chi tiết (dùng cho PageView)
  final List<String> images;

  /// Mô tả chi tiết công dụng, chất liệu, hướng dẫn
  final String description;

  /// Phân loại danh mục
  final ProductCategory category;

  /// ID khóa học liên kết (nếu là Kit theo khóa)
  final String? courseId;

  /// Tên khóa học liên kết
  final String? courseTitle;

  /// ID gói subscription gợi ý nếu muốn tiết kiệm hơn
  final String? recommendedSubscriptionPlanId;

  /// Tên gói subscription gợi ý
  final String? recommendedSubscriptionPlanName;

  /// Chi tiết các món dụng cụ bên trong kit (hiển thị dạng ExpansionTile)
  final List<String> kitItems;

  /// Điểm đánh giá trung bình
  final double rating;

  /// Số lượng đã bán
  final int soldCount;

  /// Còn hàng trong kho hay không
  final bool inStock;

  /// Danh sách ảnh đầy đủ (ưu tiên mảng images, nếu rỗng thì dùng thumbnail)
  List<String> get allImages => images.isNotEmpty ? images : [thumbnailUrl];

  /// Phần trăm giảm giá (nếu có giá gốc lớn hơn giá bán)
  int? get discountPercent {
    if (originalPriceVnd != null && originalPriceVnd! > priceVnd) {
      return (((originalPriceVnd! - priceVnd) / originalPriceVnd!) * 100)
          .round();
    }
    return null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceVnd:
          (json['price_vnd'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      originalPriceVnd:
          (json['original_price_vnd'] as num?)?.toInt() ??
          (json['originalPrice'] as num?)?.toInt(),
      thumbnailUrl:
          json['thumbnail_url'] as String? ??
          json['thumbnailUrl'] as String? ??
          '',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      description: json['description'] as String? ?? '',
      category: ProductCategory.fromString(json['category'] as String?),
      courseId: json['course_id'] as String? ?? json['courseId'] as String?,
      courseTitle:
          json['course_title'] as String? ?? json['courseTitle'] as String?,
      recommendedSubscriptionPlanId:
          json['recommended_subscription_plan_id'] as String? ??
          json['recommendedSubscriptionPlanId'] as String?,
      recommendedSubscriptionPlanName:
          json['recommended_subscription_plan_name'] as String? ??
          json['recommendedSubscriptionPlanName'] as String?,
      kitItems:
          (json['kit_items'] as List<dynamic>? ??
                  json['kitItems'] as List<dynamic>? ??
                  [])
              .map((e) => e.toString())
              .toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
      inStock: json['in_stock'] as bool? ?? json['inStock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_vnd': priceVnd,
      if (originalPriceVnd != null) 'original_price_vnd': originalPriceVnd,
      'thumbnail_url': thumbnailUrl,
      'images': images,
      'description': description,
      'category': category.value,
      if (courseId != null) 'course_id': courseId,
      if (courseTitle != null) 'course_title': courseTitle,
      if (recommendedSubscriptionPlanId != null)
        'recommended_subscription_plan_id': recommendedSubscriptionPlanId,
      if (recommendedSubscriptionPlanName != null)
        'recommended_subscription_plan_name': recommendedSubscriptionPlanName,
      'kit_items': kitItems,
      'rating': rating,
      'sold_count': soldCount,
      'in_stock': inStock,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    priceVnd,
    originalPriceVnd,
    thumbnailUrl,
    images,
    description,
    category,
    courseId,
    courseTitle,
    recommendedSubscriptionPlanId,
    recommendedSubscriptionPlanName,
    kitItems,
    rating,
    soldCount,
    inStock,
  ];
}
