import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/product.dart';
import '../providers/cart_provider.dart';

/// Card sản phẩm dạng lưới (2 cột) trong Cửa hàng học cụ
class ProductGridCard extends ConsumerWidget {
  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  static final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discount = product.discountPercent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh sản phẩm + Badge giảm giá
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(15)),
                    child: AspectRatio(
                      aspectRatio: 1.15,
                      child: Container(
                        color: const Color(0xFFF8FAFB),
                        child: CachedNetworkImage(
                          imageUrl: product.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: const Color(0xFFECEFF1),
                            child: const Icon(Icons.image_outlined,
                                color: Colors.black26),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: const Color(0xFFECEFF1),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF1687A7),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (discount != null && discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Nội dung chi tiết
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên sản phẩm
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Rating & Đã bán
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFF39C12),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${product.rating}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• Đã bán ${product.soldCount}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Hàng giá và nút thêm giỏ (+)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.originalPriceVnd != null)
                                  Text(
                                    _currencyFormat
                                        .format(product.originalPriceVnd),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF95A5A6),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  _currencyFormat.format(product.priceVnd),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F3B46),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Nút thêm nhanh vào giỏ (+)
                          Material(
                            color: const Color(0xFF1687A7),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addToCart(product, quantity: 1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Đã thêm "${product.name}" vào giỏ!',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF27AE60),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
