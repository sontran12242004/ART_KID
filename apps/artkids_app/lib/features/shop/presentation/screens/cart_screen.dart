import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_paths.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';

/// Màn hình giỏ hàng học cụ
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static const int _freeShippingThreshold = 300000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final totalCount = ref.watch(cartTotalCountProvider);
    final subtotal = ref.watch(cartSubtotalVndProvider);
    ref.listen(cartSyncErrorProvider, (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2C3E50),
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Giỏ hàng ($totalCount)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearCart(context, ref),
              icon: const Icon(
                Icons.delete_sweep_outlined,
                size: 18,
                color: Color(0xFFE74C3C),
              ),
              label: const Text(
                'Xóa tất cả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE74C3C),
                ),
              ),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Thanh thông báo miễn phí vận chuyển
                _buildShippingProgressBanner(subtotal),

                // Danh sách sản phẩm
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return CartItemTile(cartItem: cartItems[index]);
                    },
                  ),
                ),

                // Sticky footer thanh toán
                _buildCheckoutFooter(context, totalCount, subtotal),
              ],
            ),
    );
  }

  /// Banner tiến độ đạt điều kiện miễn phí vận chuyển
  Widget _buildShippingProgressBanner(int subtotal) {
    final isFreeShipping = subtotal >= _freeShippingThreshold;
    final remaining = _freeShippingThreshold - subtotal;
    final progress = (subtotal / _freeShippingThreshold).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isFreeShipping ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFreeShipping
                    ? Icons.local_shipping_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: isFreeShipping
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE65100),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFreeShipping
                      ? 'Đơn hàng đủ điều kiện Miễn phí vận chuyển toàn quốc!'
                      : 'Mua thêm ${_currencyFormat.format(remaining)} để được Miễn phí giao hàng (đơn từ 300.000 đ)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFreeShipping
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFBF360C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isFreeShipping
                  ? const Color(0xFFC8E6C9)
                  : const Color(0xFFFFE0B2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFreeShipping
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Khung hiển thị khi giỏ hàng rỗng
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 52,
                color: Color(0xFF1687A7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Giỏ hàng của bạn đang trống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khám phá các bộ kit học cụ chất lượng cao được tuyển chọn để đồng hành cùng các khóa học của bé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7F8C8D),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go(RoutePaths.parentShop);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text(
                'Khám phá Cửa hàng',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3B46),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Footer cố định: Tạm tính & Nút Tiến hành thanh toán
  Widget _buildCheckoutFooter(
    BuildContext context,
    int totalCount,
    int subtotal,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE8ECEF))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tạm tính',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6B7C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _currencyFormat.format(subtotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F3B46),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.push(RoutePaths.parentShopCheckout);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3B46),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tiến hành thanh toán ($totalCount món)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Xóa toàn bộ giỏ hàng?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Tất cả sản phẩm học cụ trong giỏ sẽ bị xóa bỏ. Bạn có chắc chắn không?',
          style: TextStyle(fontSize: 13, color: Color(0xFF5A6B7C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF7F8C8D)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(cartProvider.notifier).clearRemote();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }
}
