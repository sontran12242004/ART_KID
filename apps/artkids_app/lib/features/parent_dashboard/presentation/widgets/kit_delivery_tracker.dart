import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/kit_delivery.dart';
import '../providers/parent_dashboard_provider.dart';

/// Widget theo dõi giao hàng kit học cụ — Parent Mode
class KitDeliveryTracker extends ConsumerWidget {
  const KitDeliveryTracker({
    super.key,
    this.parentId = 'current-parent',
    this.delivery,
  });

  final String parentId;
  final KitDelivery? delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (delivery != null) {
      return _buildDeliveryCard(delivery!);
    }

    final deliveriesAsync = ref.watch(kitDeliveriesProvider(parentId));

    return deliveriesAsync.when(
      data: (deliveries) {
        if (deliveries.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Chưa có đơn hàng nào')),
            ),
          );
        }
        return Column(children: deliveries.map(_buildDeliveryCard).toList());
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Lỗi: $error')),
    );
  }

  Widget _buildDeliveryCard(KitDelivery item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor(item.status),
                shape: BoxShape.circle,
              ),
              child: _statusIcon(item.status),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.kitName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã vận đơn: ${item.trackingNumber}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (item.estimatedDeliveryDate != null)
                    Text(
                      'Dự kiến: ${item.estimatedDeliveryDate}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
            Chip(
              label: Text(
                _statusLabel(item.status),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _statusColor(item.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(String status) {
    return switch (status.toLowerCase()) {
      'ordered' => const Icon(Icons.receipt_long, color: Colors.blue),
      'packed' => const Icon(Icons.inventory_2, color: Colors.orange),
      'shipping' ||
      'intransit' => const Icon(Icons.local_shipping, color: Colors.deepPurple),
      'delivered' => const Icon(Icons.check_circle, color: Colors.green),
      _ => const Icon(Icons.local_shipping, color: Colors.deepPurple),
    };
  }

  String _statusLabel(String status) {
    return switch (status.toLowerCase()) {
      'ordered' => 'Đã đặt',
      'packed' => 'Đang gói',
      'shipping' || 'intransit' => 'Đang giao',
      'delivered' => 'Đã nhận',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'ordered' => Colors.blue.shade50,
      'packed' => Colors.orange.shade50,
      'shipping' || 'intransit' => Colors.purple.shade50,
      'delivered' => Colors.green.shade50,
      _ => Colors.grey.shade100,
    };
  }
}
