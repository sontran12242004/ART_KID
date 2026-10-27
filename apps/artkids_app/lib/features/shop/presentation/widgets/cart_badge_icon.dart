import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../providers/cart_provider.dart';

/// Icon giỏ hàng trên AppBar hiển thị số lượng sản phẩm nổi bật
class CartBadgeIcon extends ConsumerWidget {
  const CartBadgeIcon({super.key, this.color = const Color(0xFF0F3B46)});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCount = ref.watch(cartTotalCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.shopping_bag_outlined, color: color, size: 24),
          tooltip: 'Giỏ hàng học cụ ($totalCount)',
          onPressed: () => context.push(RoutePaths.parentShopCart),
        ),
        if (totalCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE74C3C), // Đỏ nổi bật
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    totalCount > 99 ? '99+' : '$totalCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
