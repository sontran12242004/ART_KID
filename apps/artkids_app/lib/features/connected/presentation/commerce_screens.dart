import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../shop/presentation/providers/cart_provider.dart';
import 'widgets.dart';

class ConnectedCheckout extends ConsumerStatefulWidget {
  const ConnectedCheckout({super.key, this.type, this.id});
  final String? type, id;
  @override
  ConsumerState<ConnectedCheckout> createState() => _ConnectedCheckoutState();
}

class _ConnectedCheckoutState extends ConsumerState<ConnectedCheckout> {
  final name = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      voucher = TextEditingController();
  final key = 'checkout-${DateTime.now().microsecondsSinceEpoch}';
  String method = 'manual_transfer';
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    voucher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final single = widget.id != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt hàng')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (single)
            ApiView(
              path: widget.type == 'course'
                  ? '/courses/${widget.id}'
                  : '/commerce/plans',
              builder: (data) {
                final item = widget.type == 'course'
                    ? data
                    : (data as List).firstWhere((p) => p['id'] == widget.id);
                return ListTile(
                  title: Text(item['title'] ?? item['name']),
                  subtitle: Text(money(item['priceVnd'])),
                );
              },
            )
          else ...[
            for (final i in cart)
              ListTile(
                title: Text(i.product.name),
                subtitle: Text('${i.quantity} × ${money(i.product.priceVnd)}'),
              ),
            Text('Tạm tính: ${money(ref.watch(cartSubtotalVndProvider))}'),
          ],
          const Text(
            'Giá, phí giao hàng và mã giảm giá được máy chủ kiểm tra khi đặt hàng.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Tên người nhận'),
          ),
          TextField(
            controller: phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại'),
          ),
          TextField(
            controller: address,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ nhận học cụ (bắt buộc khi có bộ kit)',
            ),
          ),
          TextField(
            controller: voucher,
            decoration: const InputDecoration(labelText: 'Mã giảm giá'),
          ),
          DropdownButtonFormField<String>(
            initialValue: method,
            items: [
              const DropdownMenuItem(
                value: 'manual_transfer',
                child: Text('Chuyển khoản · chờ quản trị xác nhận'),
              ),
              if (!single)
                const DropdownMenuItem(
                  value: 'cod',
                  child: Text('Thanh toán khi nhận hàng'),
                ),
            ],
            onChanged: (v) => setState(() => method = v!),
            decoration: const InputDecoration(labelText: 'Thanh toán'),
          ),
          const SizedBox(height: 20),
          ActionButton(
            label: 'Đặt hàng',
            action: (r) async {
              final items = single
                  ? [
                      {
                        'itemType': widget.type,
                        'itemId': widget.id,
                        'quantity': 1,
                      },
                    ]
                  : [
                      for (final i in cart)
                        {
                          'itemType': 'kit',
                          'itemId': i.product.id,
                          'quantity': i.quantity,
                        },
                    ];
              final result = await r
                  .read(dioProvider)
                  .post(
                    '/commerce/checkout',
                    data: {
                      'idempotencyKey': key,
                      'items': items,
                      'childId': r.read(authProvider).selectedChild?.id,
                      'paymentMethod': method,
                      if (voucher.text.trim().isNotEmpty)
                        'voucherCode': voucher.text.trim(),
                      if (address.text.trim().isNotEmpty)
                        'shipping': {
                          'recipientName': name.text.trim(),
                          'phoneNumber': phone.text.trim(),
                          'fullAddress': address.text.trim(),
                        },
                    },
                  );
              if (!single) await r.read(cartProvider.notifier).load();
              return result.data;
            },
            onSuccess: (data) {
              toast(context, 'Đã tạo đơn. Thanh toán đang chờ xác nhận.');
              context.go('/parent/orders/${data['order']['id']}');
            },
          ),
        ],
      ),
    );
  }
}

class ConnectedPlans extends StatelessWidget {
  const ConnectedPlans({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gói học')),
    body: ApiView(
      path: '/commerce/plans',
      builder: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in data)
            Card(
              child: ListTile(
                title: Text(p['name']),
                subtitle: Text(
                  '${money(p['priceVnd'])} · ${p['durationMonths']} tháng',
                ),
                trailing: FilledButton(
                  onPressed: () => context.push(
                    '/parent/shop/checkout?type=subscription&id=${p['id']}',
                  ),
                  child: const Text('Đăng ký'),
                ),
              ),
            ),
          const Divider(),
          const Text('Gói đã đăng ký'),
          ApiView(
            path: '/commerce/subscriptions',
            builder: (subs) => Column(
              children: [
                for (final s in subs)
                  ListTile(
                    title: Text(statusLabel(s['status'])),
                    subtitle: Text('Hết hạn: ${dateLabel(s['endsAt'])}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
