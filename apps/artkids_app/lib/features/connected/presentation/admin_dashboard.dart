import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/connected_api.dart';
import 'widgets.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});
  static const path = '/admin/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Tổng quan hệ thống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F3B46),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cập nhật số liệu',
            onPressed: () => ref.invalidate(apiDataProvider(path)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ApiView(
        path: path,
        builder: (raw) {
          final data = Map<String, dynamic>.from(raw);
          final metrics = [
            (
              'Tổng tiền đã nhận',
              money(data['totalRevenueVnd']),
              'Đơn đã thanh toán, không gồm đơn hủy',
              Icons.account_balance_wallet_outlined,
              const Color(0xFF00897B),
            ),
            (
              'Tiền nhận tháng này',
              money(data['monthRevenueVnd']),
              'Tháng ${data['revenueMonth']} · giờ Việt Nam',
              Icons.trending_up,
              const Color(0xFF1687A7),
            ),
            (
              'Khóa học',
              '${data['courseCount']}',
              '${data['publishedCourseCount']} khóa đang công khai',
              Icons.school_outlined,
              const Color(0xFF6C5CE7),
            ),
            (
              'Đơn đã thanh toán',
              '${data['paidOrderCount']}',
              'Thanh toán đã được hệ thống xác nhận',
              Icons.receipt_long_outlined,
              const Color(0xFF0984E3),
            ),
            (
              'Hồ sơ học viên',
              '${data['childCount']}',
              'Tổng số hồ sơ bé trên hệ thống',
              Icons.child_care,
              const Color(0xFFE76F51),
            ),
            (
              'Học cụ chờ duyệt',
              '${data['pendingProductCount']}',
              'Đề xuất cần quản trị viên kiểm duyệt',
              Icons.fact_check_outlined,
              const Color(0xFFAD6800),
            ),
          ];
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 3
                  : constraints.maxWidth >= 600
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final metric in metrics)
                        SizedBox(
                          width: width,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE8ECEF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(metric.$4, color: metric.$5, size: 28),
                                const SizedBox(height: 14),
                                Text(
                                  metric.$1,
                                  style: const TextStyle(
                                    color: Color(0xFF52656D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  metric.$2,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F3B46),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  metric.$3,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF657780),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${data['pendingOrderCount']} đơn đang chờ thanh toán/xác nhận. Tổng tiền bao gồm phí vận chuyển, sau giảm giá.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF657780),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    ],
  );
}
