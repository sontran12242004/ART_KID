import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/seller_delivery_progress.dart';

class SellerDeliveryProgressCard extends StatelessWidget {
  const SellerDeliveryProgressCard({super.key, required this.progress});
  final List<SellerDeliveryProgress> progress;
  static final _date = DateFormat('dd/MM/yyyy • HH:mm');

  static String _status(String value) =>
      const {
        'preparing': 'Đang chuẩn bị học cụ',
        'shipping': 'Giảng viên báo đã gửi hàng',
        'delivered': 'Giảng viên báo đã giao',
        'pending_payment': 'Chờ xác minh chuyển khoản',
        'cancelled': 'Đã hủy',
      }[value] ??
      'Chờ giảng viên cập nhật';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8ECEF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tiến độ từng người bán',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Thông tin giao hàng do giảng viên cập nhật, chưa được hãng vận chuyển xác minh; không xác nhận đã thu tiền COD.',
        ),
        if (progress.length > 1) ...[
          const SizedBox(height: 8),
          const Text(
            'Mỗi giảng viên xử lý phần học cụ của mình. Đơn chỉ hoàn tất khi tất cả phần hàng đã giao.',
          ),
        ],
        for (final seller in progress) ...[
          const Divider(height: 28),
          Text(
            seller.sellerName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          for (final title in seller.itemTitles) Text(title),
          const SizedBox(height: 6),
          Text(
            _status(seller.status),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (seller.carrier?.isNotEmpty == true)
            Text('Đơn vị giảng viên chọn: ${seller.carrier}'),
          if (seller.trackingNumber?.isNotEmpty == true)
            Text('Mã vận đơn do giảng viên cung cấp: ${seller.trackingNumber}'),
          if (seller.shippedAt != null)
            Text(
              'Giảng viên báo gửi lúc: ${_date.format(seller.shippedAt!.toLocal())}',
            ),
          if (seller.deliveredAt != null)
            Text(
              'Giảng viên báo giao lúc: ${_date.format(seller.deliveredAt!.toLocal())}',
            ),
        ],
      ],
    ),
  );
}
