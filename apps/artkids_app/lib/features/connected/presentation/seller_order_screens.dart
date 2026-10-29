import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import 'widgets.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});
  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersState();
}

class _SellerOrdersState extends State<SellerOrdersScreen> {
  int _page = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đơn học cụ của tôi')),
    body: ApiView(
      path: '/marketplace/orders?page=$_page&pageSize=20',
      builder: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((data['items'] as List).isEmpty)
            const ListTile(title: Text('Chưa có đơn học cụ.')),
          for (final o in data['items'])
            Card(
              child: ListTile(
                title: Text(o['orderCode']),
                subtitle: Text(
                  '${statusLabel(o['status'])} · Học cụ của bạn: ${money(o['subtotalVnd'])}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/staff/marketplace/orders/${o['id']}'),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Trang trước',
                onPressed: _page > 1 ? () => setState(() => _page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Trang $_page'),
              IconButton(
                tooltip: 'Trang sau',
                onPressed: _page * 20 < (data['total'] as int)
                    ? () => setState(() => _page++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class SellerOrderDetailScreen extends StatelessWidget {
  const SellerOrderDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết đơn học cụ')),
    body: ApiView(
      path: '/marketplace/orders/$id',
      builder: (data) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            data['orderCode'],
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(statusLabel(data['status'])),
          for (final i in data['items'])
            ListTile(
              title: Text(i['title']),
              subtitle: Text('${i['quantity']} × ${money(i['unitPriceVnd'])}'),
            ),
          Text('Tiền học cụ của bạn: ${money(data['subtotalVnd'])}'),
          const Divider(),
          if (data['shippingInfo'] != null) ...[
            Text('Người nhận: ${data['shippingInfo']['recipientName']}'),
            Text('Điện thoại: ${data['shippingInfo']['phoneNumber']}'),
            Text('Địa chỉ: ${data['shippingInfo']['fullAddress']}'),
          ],
          const SizedBox(height: 20),
          if (data['status'] == 'pending_confirmation')
            const Text('Chờ quản trị viên xác nhận đơn trước khi giao hàng.'),
          if (['preparing', 'shipping', 'delivered'].contains(data['status']))
            SellerShippingForm(
              key: ValueKey('${data['fulfillment']}'),
              orderId: id,
              fulfillment: data['fulfillment'] == null
                  ? null
                  : Map<String, dynamic>.from(data['fulfillment']),
            ),
        ],
      ),
    ),
  );
}

class SellerShippingForm extends ConsumerStatefulWidget {
  const SellerShippingForm({
    super.key,
    required this.orderId,
    this.fulfillment,
  });
  final String orderId;
  final Map<String, dynamic>? fulfillment;
  @override
  ConsumerState<SellerShippingForm> createState() => _ShippingState();
}

class _ShippingState extends ConsumerState<SellerShippingForm> {
  late String _carrier;
  late TextEditingController _tracking;
  String get _status => widget.fulfillment?['status'] as String? ?? 'preparing';
  @override
  void initState() {
    super.initState();
    _carrier = widget.fulfillment?['carrier'] as String? ?? 'GHN';
    _tracking = TextEditingController(
      text: widget.fulfillment?['trackingNumber'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Bạn tự liên hệ đơn vị vận chuyển. Thông tin dưới đây chỉ ghi nhận giao hàng do bạn sắp xếp.',
      ),
      DropdownButtonFormField<String>(
        initialValue: _carrier,
        decoration: const InputDecoration(labelText: 'Đơn vị vận chuyển'),
        items: [
          for (final carrier in ['GHN', 'VNPost', 'GHTK'])
            DropdownMenuItem(value: carrier, child: Text(carrier)),
        ],
        onChanged: _status == 'preparing'
            ? (v) => setState(() => _carrier = v!)
            : null,
      ),
      TextField(
        controller: _tracking,
        enabled: _status == 'preparing',
        maxLength: 100,
        decoration: const InputDecoration(labelText: 'Mã vận đơn (nếu có)'),
      ),
      Text('Giao hàng của bạn: ${statusLabel(_status)}'),
      if (_status == 'preparing')
        ActionButton(
          label: 'Lưu đơn vị vận chuyển',
          action: (r) => _save(r, 'preparing'),
        ),
      const SizedBox(height: 12),
      if (_status != 'delivered')
        ActionButton(
          label: _status == 'shipping'
              ? 'Xác nhận đã giao'
              : 'Ghi nhận đã gửi hàng',
          action: (r) =>
              _save(r, _status == 'shipping' ? 'delivered' : 'shipping'),
        ),
    ],
  );
  Future<dynamic> _save(WidgetRef ref, String status) => ref
      .read(dioProvider)
      .put(
        '/marketplace/orders/${widget.orderId}/fulfillment',
        data: {
          'carrier': _carrier,
          'trackingNumber': _tracking.text.trim().isEmpty
              ? null
              : _tracking.text.trim(),
          'status': status,
        },
      );
}
