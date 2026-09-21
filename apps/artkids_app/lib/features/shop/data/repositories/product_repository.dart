import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/enums/product_category.dart';
import '../models/product.dart';

/// Provider cung cấp ProductRepository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProductRepositoryImpl(dio);
});

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    ProductCategory? category,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  });

  Future<Product> getProductById(String id);
}

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Product>> getProducts({
    ProductCategory? category,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    if (EnvConfig.enableMockShop) {
      debugPrint('[ProductRepository] Sử dụng Mock Data Shop (ENABLE_MOCK_SHOP=true)');
      return _filterMockProducts(category: category, searchQuery: searchQuery);
    }

    try {
      // TODO: Xác nhận query parameters và format response với backend commerce-service
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (category != null && category != ProductCategory.all)
          'category': category.value,
        if (searchQuery != null && searchQuery.trim().isNotEmpty)
          'q': searchQuery.trim(),
      };

      final response = await _dio.get<dynamic>(
        ApiConstants.shopProducts,
        queryParameters: queryParams,
      );

      final data = response.data;
      List<dynamic> listData = [];
      if (data is List) {
        listData = data;
      } else if (data is Map<String, dynamic>) {
        listData = (data['data'] as List<dynamic>?) ??
            (data['products'] as List<dynamic>?) ??
            [];
      }

      return listData
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductRepository] Lỗi API getProducts ($e). Fallback sang Mock Data.');
      return _filterMockProducts(category: category, searchQuery: searchQuery);
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    if (EnvConfig.enableMockShop) {
      return _findMockProduct(id);
    }

    try {
      // TODO: Xác nhận endpoint chi tiết sản phẩm với backend
      final endpoint = ApiConstants.shopProductDetail.replaceAll('{id}', id);
      final response = await _dio.get<dynamic>(endpoint);

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final productJson = (data['data'] as Map<String, dynamic>?) ?? data;
        return Product.fromJson(productJson);
      }
      throw Exception('Dữ liệu sản phẩm không hợp lệ từ máy chủ.');
    } catch (e) {
      debugPrint('[ProductRepository] Lỗi API getProductById ($e). Fallback sang Mock Data.');
      return _findMockProduct(id);
    }
  }

  // ==================== MOCK DATA ====================

  static List<Product> _filterMockProducts({
    ProductCategory? category,
    String? searchQuery,
  }) {
    List<Product> list = List.of(_mockProducts);

    if (category != null && category != ProductCategory.all) {
      list = list.where((p) => p.category == category).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final courseMatch = p.courseTitle?.toLowerCase().contains(query) ?? false;
        final descMatch = p.description.toLowerCase().contains(query);
        return nameMatch || courseMatch || descMatch;
      }).toList();
    }

    return list;
  }

  static Product _findMockProduct(String id) {
    try {
      return _mockProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return _mockProducts.first;
    }
  }

  static const List<Product> _mockProducts = [
    // 1. Kit theo khóa học: Rừng Xanh
    Product(
      id: 'prod_kit_animal',
      name: 'Hộp Học Cụ: Vẽ Động Vật Rừng Xanh & Hoang Dã',
      priceVnd: 389000,
      originalPriceVnd: 450000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1580493113063-e380f3391b10?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Trọn bộ học cụ tiêu chuẩn được thiết kế đồng bộ cho khóa học "Vẽ động vật bằng màu nước". Giúp bé tiếp cận các kỹ thuật loang màu nước tự nhiên, tạo vân lông thú và hoàn thiện tranh sinh động.',
      category: ProductCategory.courseKit,
      courseId: 'course_wild_animals',
      courseTitle: 'Vẽ động vật bằng màu nước',
      recommendedSubscriptionPlanId: 'plan_pro_kit',
      recommendedSubscriptionPlanName: 'Gói Họa Sĩ Nhí Toàn Năng',
      kitItems: [
        'Hộp màu nước khô 24 màu Kuretake Nhật Bản không độc hại',
        'Bút lông ngậm nước Waterbrush tiện lợi cho trẻ em',
        'Tập giấy vẽ màu nước Fabriano 300gsm định lượng chuẩn (15 tờ)',
        'Khay pha màu hoa cúc nhựa ABS cao cấp chống dính',
        'Cuộn băng dính giấy washi tape cố định viền tranh không rách giấy',
      ],
      rating: 4.9,
      soldCount: 142,
    ),

    // 2. Kit theo khóa học: Acrylic
    Product(
      id: 'prod_kit_acrylic',
      name: 'Hộp Họa Cụ Nhí: Sáng Tạo Màu Acrylic Trên Canvas',
      priceVnd: 420000,
      originalPriceVnd: 490000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Bộ kit màu Acrylic chuyên sâu giúp bé làm quen với chất liệu sơn dầu và acrylic. Màu có độ che phủ hoàn hảo, nhanh khô và bền màu theo thời gian trên vải bố canvas.',
      category: ProductCategory.courseKit,
      courseId: 'course_acrylic_kids',
      courseTitle: 'Vẽ Acrylic cho bé 6–10 tuổi',
      recommendedSubscriptionPlanId: 'plan_pro_kit',
      recommendedSubscriptionPlanName: 'Gói Họa Sĩ Nhí Toàn Năng',
      kitItems: [
        'Hộp 12 tuýp màu Acrylic Pebeo Studio 20ml pigment đậm đặc',
        'Bộ 5 cọ đầu dẹt & cọ tỉa nét sợi mảnh cán gỗ tự nhiên',
        '3 khung tranh canvas căng sẵn trên sườn gỗ thông (20x20cm)',
        'Khay pha màu hoa cúc chống dính dễ rửa sạch',
        'Tạp dề chống bám bẩn in logo họa sĩ nhí ArtKids',
      ],
      rating: 4.8,
      soldCount: 98,
    ),

    // 3. Kit theo khóa học: Cổ Tích
    Product(
      id: 'prod_kit_fairytale',
      name: 'Hộp Học Cụ: Hội Họa Cổ Tích & Lâu Đài Mộng Mơ',
      priceVnd: 320000,
      originalPriceVnd: 360000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Dành riêng cho các bé yêu thích thế giới cổ tích, công chúa và lâu đài mộng mơ. Sử dụng màu sáp dầu cao cấp tạo hiệu ứng tranh nổi và màu sắc rực rỡ.',
      category: ProductCategory.courseKit,
      courseId: 'course_fairy_tales',
      courseTitle: 'Hội họa cổ tích và thế giới kỳ diệu',
      recommendedSubscriptionPlanId: 'plan_vip_year',
      recommendedSubscriptionPlanName: 'Gói Hội Họa VIP 1 Năm',
      kitItems: [
        'Bộ sáp dầu mỹ thuật Mungyo Gallery 36 màu sắc nét',
        'Tập giấy sáp đen & trắng A4 (20 tờ dày dặn)',
        'Cây tán chì và que gạt sáp dầu tạo hiệu ứng 3D',
        'Gọt bút chì 2 nấc chuyên nghiệp',
      ],
      rating: 4.9,
      soldCount: 115,
    ),

    // 4. Kit theo khóa học: Đất Nặn 3D
    Product(
      id: 'prod_kit_clay',
      name: 'Bộ Đất Nặn Điêu Khắc Mô Hình 3D Đa Sắc Siêu Nhẹ',
      priceVnd: 280000,
      originalPriceVnd: 320000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1560421683-6856ea585c78?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1560421683-6856ea585c78?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Bộ đất nặn tự khô công nghệ bọt khí siêu nhẹ, không dính tay và không bám mùi. Giúp bé rèn luyện tư duy không gian 3 chiều và biến các nhân vật hoạt hình thành mô hình thực tế.',
      category: ProductCategory.courseKit,
      courseId: 'course_clay_modeling',
      courseTitle: 'Nặn tượng 3D & Sáng tạo sinh vật kỳ thú',
      recommendedSubscriptionPlanId: 'plan_vip_year',
      recommendedSubscriptionPlanName: 'Gói Hội Họa VIP 1 Năm',
      kitItems: [
        'Hộp 18 màu đất sét tự khô siêu nhẹ chuẩn Nhật Bản',
        'Bộ 4 dao tạo hình chi tiết bằng gỗ mài mịn an toàn',
        'Khung kẽm định hình bộ xương chuyển động',
        'Lọ sơn bóng bảo vệ bề mặt thành phẩm bền màu',
      ],
      rating: 4.7,
      soldCount: 89,
    ),

    // 5. Dụng cụ lẻ: Cọ Vẽ 12 Cây
    Product(
      id: 'prod_tool_brushes',
      name: 'Bộ Cọ Vẽ Lông Mềm Nghệ Thuật 12 Cây Cao Cấp',
      priceVnd: 185000,
      originalPriceVnd: 220000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Bộ cọ vẽ sợi nylon tổng hợp cao cấp cán gỗ sơn phủ bóng, gồm đầy đủ cọ bản to, cọ quạt, cọ tròn và cọ tỉa siêu mảnh. Độ đàn hồi tuyệt hảo, không bị xơ rụng sau nhiều lần sử dụng.',
      category: ProductCategory.individualTool,
      kitItems: [
        '12 cây cọ các kích cỡ từ số 1 đến 12',
        'Túi cuộn bảo vệ cọ vải canvas phong cách tối giản',
        'Khăn vải thấm nước chuyên dụng',
      ],
      rating: 4.9,
      soldCount: 230,
    ),

    // 6. Dụng cụ lẻ: Màu Nước Kuretake
    Product(
      id: 'prod_tool_kuretake',
      name: 'Hộp Màu Nước Nén 24 Màu Kuretake Nhật Bản',
      priceVnd: 260000,
      originalPriceVnd: 295000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1580493113063-e380f3391b10?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1580493113063-e380f3391b10?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Dòng màu nước nén bánh khô cao cấp từ thương hiệu Kuretake Nhật Bản. Màu sắc tươi sáng, trong trẻo, khả năng hòa tan nhanh và cực kỳ kinh tế cho các bé mới bắt đầu tập vẽ.',
      category: ProductCategory.individualTool,
      kitItems: [
        'Hộp kim loại 24 pan màu nén nắp làm khay pha',
        '1 bút lông ngậm nước Waterbrush size M',
      ],
      rating: 5.0,
      soldCount: 310,
    ),

    // 7. Dụng cụ lẻ: Giấy Vẽ Fabriano A4
    Product(
      id: 'prod_tool_paper_a4',
      name: 'Tập Giấy Vẽ Màu Nước Fabriano A4 300gsm (20 tờ)',
      priceVnd: 95000,
      originalPriceVnd: 110000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Giấy màu nước định lượng 300gsm vân Cold Pressed nhập khẩu từ Ý. Giấy ngậm nước tốt, chịu được nhiều lớp màu mà không bị cong vênh hay tróc mủn.',
      category: ProductCategory.individualTool,
      rating: 4.8,
      soldCount: 420,
    ),

    // 8. Dụng cụ lẻ: Sáp Dầu Mungyo 48 Màu
    Product(
      id: 'prod_tool_oil_pastel',
      name: 'Hộp Màu Sáp Dầu Mungyo Gallery 48 Màu Chuyên Nghiệp',
      priceVnd: 195000,
      originalPriceVnd: 240000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Sáp dầu chuẩn họa sĩ với bảng màu phong phú 48 sắc độ. Chất sáp mềm mượt dễ dàng pha trộn, miết loang và tạo hiệu ứng đắp nổi ấn tượng.',
      category: ProductCategory.individualTool,
      rating: 4.9,
      soldCount: 180,
    ),

    // 9. Combo tiết kiệm: Starter Kit
    Product(
      id: 'prod_combo_starter',
      name: 'Combo Khởi Đầu Hội Họa: Màu Nước + Cọ Vẽ + Giấy 300gsm',
      priceVnd: 469000,
      originalPriceVnd: 540000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Combo trọn gói tiết kiệm 15% so với mua lẻ từng món. Đầy đủ dụng cụ cơ bản nhất để bé bắt đầu các bài vẽ màu nước đầu tiên trong đời mà không cần sắm thêm gì khác.',
      category: ProductCategory.comboSaver,
      recommendedSubscriptionPlanId: 'plan_pro_kit',
      recommendedSubscriptionPlanName: 'Gói Họa Sĩ Nhí Toàn Năng',
      kitItems: [
        'Hộp màu nước khô Kuretake 24 màu',
        'Bộ 6 cọ vẽ lông mềm đa năng',
        'Tập giấy vẽ Fabriano A4 300gsm (20 tờ)',
        'Khay pha màu hoa cúc chống dính',
        'Băng dính giấy chặn viền và khăn lau cọ chuyên dụng',
      ],
      rating: 5.0,
      soldCount: 260,
    ),

    // 10. Combo tiết kiệm: Master Kit
    Product(
      id: 'prod_combo_master',
      name: 'Combo Họa Sĩ Nhí Master: Trọn Bộ Họa Cụ Đa Chất Liệu',
      priceVnd: 850000,
      originalPriceVnd: 1050000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
      images: [
        'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1560421683-6856ea585c78?w=600&auto=format&fit=crop&q=80',
      ],
      description:
          'Bộ họa cụ cao cấp và toàn diện nhất dành cho các tài năng hội họa nhí. Kết hợp cả màu nước, acrylic, sáp dầu và đất nặn 3D cùng giá vẽ gỗ để bàn sang trọng.',
      category: ProductCategory.comboSaver,
      recommendedSubscriptionPlanId: 'plan_vip_year',
      recommendedSubscriptionPlanName: 'Gói Hội Họa VIP 1 Năm',
      kitItems: [
        'Hộp 12 tuýp màu Acrylic Pebeo Studio 20ml',
        'Hộp màu nước khô 24 màu Kuretake Nhật Bản',
        'Hộp màu sáp dầu Mungyo Gallery 36 màu',
        'Bộ đất nặn 18 màu tự khô siêu nhẹ',
        'Bộ cọ nghệ thuật 12 cây cao cấp kèm túi cuộn',
        '3 khung tranh canvas vải bố cỡ 20x20cm',
        'Giá vẽ gỗ thông mini để bàn tiện lợi',
      ],
      rating: 5.0,
      soldCount: 75,
    ),
  ];
}
