import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/order_tracking_event_entity.dart';
import '../../domain/enums/order_status.dart';

/// Timeline dọc theo dõi tiến trình giao hàng theo thời gian thực
class OrderTrackingTimeline extends StatelessWidget {
  const OrderTrackingTimeline({
    super.key,
    required this.events,
    required this.orderStatus,
    this.cancelReason,
  });

  final List<OrderTrackingEventEntity> events;
  final OrderStatus orderStatus;
  final String? cancelReason;

  static final _dateFormat = DateFormat('dd/MM/yyyy • HH:mm');

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1687A7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  size: 20,
                  color: Color(0xFF1687A7),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Hành Trình Đơn Hàng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Danh sách các mốc
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              final isCancelledNode =
                  orderStatus == OrderStatus.cancelled &&
                  (event.cancelReason != null || index == events.length - 1);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột trục Icon + Đường nối
                    Column(
                      children: [
                        _buildIndicator(event, isCancelledNode),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2.2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: event.isPassed
                                  ? const Color(0xFF27AE60)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Cột thông tin chi tiết mốc
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight:
                                          (event.isCurrent || event.isPassed)
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isCancelledNode
                                          ? const Color(0xFFE74C3C)
                                          : event.isCurrent
                                          ? const Color(0xFF1687A7)
                                          : event.isPassed
                                          ? const Color(0xFF2C3E50)
                                          : const Color(0xFF95A5A6),
                                    ),
                                  ),
                                ),
                                if (event.timestamp != null)
                                  Text(
                                    _dateFormat.format(
                                      event.timestamp!.toLocal(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF7F8C8D),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.description,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: event.isPassed || event.isCurrent
                                    ? const Color(0xFF57606F)
                                    : const Color(0xFFA4B0BE),
                              ),
                            ),
                            // Nếu có lý do hủy
                            if (isCancelledNode &&
                                (event.cancelReason != null ||
                                    cancelReason != null)) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDEDEC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFE74C3C,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: Color(0xFFE74C3C),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Lý do: ${event.cancelReason ?? cancelReason}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFC0392B),
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(OrderTrackingEventEntity event, bool isCancelledNode) {
    if (isCancelledNode) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFFE74C3C),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
      );
    }

    if (event.isPassed) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF27AE60),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
      );
    }

    if (event.isCurrent) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1687A7), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1687A7).withValues(alpha: 0.3),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF1687A7),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    // Mốc chưa tới
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBDC3C7), width: 1.8),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFBDC3C7),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
