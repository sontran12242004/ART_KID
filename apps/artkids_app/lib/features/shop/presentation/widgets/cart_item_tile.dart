import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/cart_item.dart';
import '../providers/cart_provider.dart';

/// 1 dòng sản phẩm trong giỏ hàng (ảnh, tên, đơn giá, số lượng, nút xóa)
class CartItemTile extends ConsumerWidget {
  const CartItemTile({
    super.key,
    required this.cartItem,
  });

  final CartItem cartItem;

  static final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = cartItem.product;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 64,
              height: 64,
              color: const Color(0xFFF8FAFB),
              child: CachedNetworkImage(
                imageUrl: product.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: const Color(0xFFECEFF1),
                  child: const Icon(Icons.image_outlined, color: Colors.black26),
                ),
                errorWidget: (_, _, _) => Container(
                  color: const Color(0xFFECEFF1),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Color(0xFF1687A7)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tên + Đơn giá
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 6),
                Text(
                  _currencyFormat.format(product.priceVnd),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F3B46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Bộ chọn số lượng & nút xóa
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Nút xóa (thùng rác)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE74C3C),
                  size: 20,
                ),
                tooltip: 'Xóa khỏi giỏ',
                onPressed: () {
                  ref.read(cartProvider.notifier).removeFromCart(product.id);
                },
              ),
              const SizedBox(height: 10),

              // [- | N | +]
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStepperBtn(
                      icon: Icons.remove,
                      onTap: () {
                        ref
                            .read(cartProvider.notifier)
                            .decrementQuantity(product.id);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${cartItem.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    _buildStepperBtn(
                      icon: Icons.add,
                      onTap: () {
                        ref
                            .read(cartProvider.notifier)
                            .incrementQuantity(product.id);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 16, color: const Color(0xFF2C3E50)),
      ),
    );
  }
}
