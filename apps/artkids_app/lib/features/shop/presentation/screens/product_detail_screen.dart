import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_paths.dart';
import '../../data/models/product.dart';
import '../../domain/enums/product_category.dart';
import '../providers/cart_provider.dart';
import '../providers/shop_catalog_provider.dart';
import '../widgets/cart_badge_icon.dart';

/// Màn hình Chi tiết Sản phẩm học cụ — Parent Mode
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  int _selectedQuantity = 1;
  final PageController _pageController = PageController();

  static final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F3B46), size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Chi Tiết Học Cụ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F3B46),
          ),
        ),
        actions: const [
          CartBadgeIcon(),
          SizedBox(width: 4),
        ],
      ),
      body: productAsync.when(
        data: (product) => _buildContent(context, product),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1687A7)),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 44, color: Color(0xFFE53935)),
              const SizedBox(height: 12),
              const Text('Không tìm thấy thông tin sản phẩm'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(productDetailProvider(widget.productId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Product product) {
    final images = product.allImages;
    final discount = product.discountPercent;

    return Column(
      children: [
        // Nội dung cuộn được
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PageView Ảnh sản phẩm
                Container(
                  color: Colors.white,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.1,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (idx) {
                            setState(() => _currentImageIndex = idx);
                          },
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: const Color(0xFFECEFF1),
                                child: const Icon(Icons.image_outlined,
                                    color: Colors.black26),
                              ),
                              errorWidget: (_, _, _) => Container(
                                color: const Color(0xFFECEFF1),
                                child: const Icon(Icons.inventory_2_outlined,
                                    color: Color(0xFF1687A7), size: 48),
                              ),
                            );
                          },
                        ),
                      ),
                      // Dot indicators nếu có nhiều hơn 1 ảnh
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (idx) {
                              final isCurrent = idx == _currentImageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: isCurrent ? 20 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFF1687A7)
                                      : Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. Thông tin chính: Giá, Tên, Đánh giá
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Giá tiền & Giảm giá
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _currencyFormat.format(product.priceVnd),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F3B46),
                            ),
                          ),
                          if (product.originalPriceVnd != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              _currencyFormat.format(product.originalPriceVnd),
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF95A5A6),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          if (discount != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEDEC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFFE74C3C)
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '-$discount%',
                                style: const TextStyle(
                                  color: Color(0xFFE74C3C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Tên sản phẩm
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Rating & Đã bán
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 18, color: Color(0xFFF39C12)),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                              width: 3, height: 12, color: const Color(0xFFCBD5E1)),
                          const SizedBox(width: 12),
                          Text(
                            'Đã bán ${product.soldCount} sản phẩm',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Liên kết Khóa Học & Điểm nối Subscription
                if (product.category == ProductCategory.courseKit &&
                    product.courseTitle != null) ...[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dùng cho khóa học
                        InkWell(
                          onTap: () {
                            if (product.courseId != null) {
                              context.push(
                                  '/kid/course/${product.courseId}/lessons');
                            } else {
                              context.push(RoutePaths.parentCourses);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F3F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF1687A7)
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1687A7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.palette_rounded,
                                      size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Kit học cụ thiết kế riêng cho khóa:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF556E74),
                                        ),
                                      ),
                                      Text(
                                        product.courseTitle!,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F3B46),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: Color(0xFF1687A7)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Banner gợi ý Subscription (Tiết kiệm hơn mua lẻ)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFF8E44AD)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7)
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      color: Color(0xFFF1C40F), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tiết kiệm hơn với Gói Đăng Ký',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Đăng ký ${product.recommendedSubscriptionPlanName ?? "Gói Họa Sĩ Nhí Toàn Năng"} để nhận trọn bộ kit học cụ định kỳ gửi về tận nhà + học không giới hạn toàn bộ bài giảng.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF6C5CE7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () => context
                                      .push(RoutePaths.parentSubscriptions),
                                  child: const Text(
                                    'Xem Các Gói Đăng Ký',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 4. Chi tiết các món bên trong kit (ExpansionTile)
                if (product.kitItems.isNotEmpty) ...[
                  Container(
                    color: Colors.white,
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        iconColor: const Color(0xFF1687A7),
                        collapsedIconColor: const Color(0xFF7F8C8D),
                        title: Row(
                          children: [
                            const Icon(Icons.format_list_bulleted_rounded,
                                size: 18, color: Color(0xFF1687A7)),
                            const SizedBox(width: 8),
                            Text(
                              'Các món bên trong kit (${product.kitItems.length} món)',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F3B46),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFECEFF1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: product.kitItems
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final idx = entry.key + 1;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 3.5),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$idx. ',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1687A7),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF34495E),
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 5. Mô tả chi tiết
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mô Tả Sản Phẩm',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F3B46),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.description,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF57606F),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // 6. Thanh cố định ở đáy: Bộ chọn số lượng + Nút Thêm vào giỏ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: Color(0xFFE8ECEF), width: 1.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Bộ chọn số lượng
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _selectedQuantity > 1
                            ? () => setState(() => _selectedQuantity--)
                            : null,
                      ),
                      Text(
                        '$_selectedQuantity',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F3B46),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _selectedQuantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Nút Thêm Vào Giỏ
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1687A7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      ref.read(cartProvider.notifier).addToCart(
                            product,
                            quantity: _selectedQuantity,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Đã thêm $_selectedQuantity món vào giỏ hàng!',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          action: SnackBarAction(
                            label: 'XEM GIỎ',
                            textColor: const Color(0xFFF1C40F),
                            onPressed: () =>
                                context.push(RoutePaths.parentShopCart),
                          ),
                          backgroundColor: const Color(0xFF27AE60),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: const Text(
                      'Thêm Vào Giỏ Hàng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
