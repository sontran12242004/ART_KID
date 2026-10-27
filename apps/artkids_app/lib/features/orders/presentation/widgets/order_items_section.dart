import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_paths.dart';
import '../../domain/entities/order_item_entity.dart';

/// Section hiển thị danh sách các kit học cụ trong đơn hàng
class OrderItemsSection extends StatelessWidget {
  const OrderItemsSection({super.key, required this.items});

  final List<OrderItemEntity> items;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECEF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 20,
                  color: Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Danh Sách Học Cụ (${items.length} món)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFFF1F2F6)),
            ),
            itemBuilder: (context, index) {
              return _buildItemRow(context, items[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, OrderItemEntity item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Thumbnail + Thông tin + Giá
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFFF4F6F8),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: const Color(0xFFECEFF1),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Colors.black26,
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: const Color(0xFFECEFF1),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF1687A7),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Thông tin kit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.kitName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Khóa học liên quan (có thể click)
                  if (item.courseTitle != null)
                    InkWell(
                      onTap: () {
                        if (item.courseId != null) {
                          context.push('/kid/course/${item.courseId}/lessons');
                        } else {
                          context.push(RoutePaths.parentCourses);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 13,
                              color: Color(0xFF1687A7),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Thuộc khóa: ${item.courseTitle}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1687A7),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 6),

                  // Giá và số lượng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số lượng: x${item.quantity}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF7F8C8D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(item.unitPriceVnd),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F3B46),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // ExpansionTile: Xem chi tiết bên trong kit (thu gọn mặc định)
        if (item.kitItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
              iconColor: const Color(0xFF1687A7),
              collapsedIconColor: const Color(0xFF7F8C8D),
              title: Row(
                children: [
                  const Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 15,
                    color: Color(0xFF1687A7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Xem chi tiết bên trong kit (${item.kitItems.length} món)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1687A7),
                    ),
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFECEFF1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: item.kitItems.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final desc = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$idx. ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1687A7),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                desc,
                                style: const TextStyle(
                                  fontSize: 12,
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
              ],
            ),
          ),
        ],
      ],
    );
  }
}
