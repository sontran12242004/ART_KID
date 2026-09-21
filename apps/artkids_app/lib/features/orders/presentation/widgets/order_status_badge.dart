import 'package:flutter/material.dart';

import '../../domain/enums/order_status.dart';

enum BadgeSize {
  compact,
  large,
}

/// Badge trạng thái đơn hàng hiển thị nhãn và màu sắc tương ứng
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.compact,
  });

  final OrderStatus status;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final isLarge = size == BadgeSize.large;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 9,
        vertical: isLarge ? 8 : 4.5,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
        border: Border.all(
          color: status.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: isLarge
            ? [
                BoxShadow(
                  color: status.color.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            color: status.color,
            size: isLarge ? 18 : 13.5,
          ),
          SizedBox(width: isLarge ? 7 : 4.5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: isLarge ? 14 : 11.5,
              fontWeight: isLarge ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
