import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/parent_dashboard_provider.dart';
import '../widgets/kit_delivery_tracker.dart';

/// Màn hình Theo dõi Đơn hàng & Giao nhận Học cụ vật lý — Parent Mode
class KitTrackingScreen extends ConsumerWidget {
  const KitTrackingScreen({
    super.key,
    this.parentId = 'current-parent',
  });

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(kitDeliveriesProvider(parentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: const Text(
          'Theo Dõi Học Cụ Giao Tận Nhà',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F3B46),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F3B46)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(kitDeliveriesProvider(parentId));
        },
        child: deliveriesAsync.when(
          data: (deliveries) {
            if (deliveries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa có gói học cụ nào đang vận chuyển.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF546E7A)),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deliveries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return KitDeliveryTracker(delivery: deliveries[index]);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1687A7)),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFE53935)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể kết nối máy chủ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F3B46)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng kiểm tra lại kết nối mạng của thiết bị.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1687A7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => ref.invalidate(kitDeliveriesProvider(parentId)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
