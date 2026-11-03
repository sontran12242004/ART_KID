import '../../../core/routing/app_back_button.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_interceptor.dart';
import '../../../core/network/dio_client.dart';
import '../../orders/presentation/providers/order_detail_provider.dart';
import '../../orders/presentation/providers/orders_list_provider.dart';
import 'widgets.dart';

class VnpayPaymentScreen extends ConsumerStatefulWidget {
  const VnpayPaymentScreen({
    super.key,
    required this.orderId,
    this.autoStart = false,
    this.result,
  });
  final String orderId;
  final bool autoStart;
  final String? result;

  @override
  ConsumerState<VnpayPaymentScreen> createState() => _VnpayPaymentScreenState();
}

class _VnpayPaymentScreenState extends ConsumerState<VnpayPaymentScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  bool redirecting = false;
  Timer? timer;
  int polls = 0;

  @override
  void initState() {
    super.initState();
    redirecting = widget.autoStart && widget.orderId.isNotEmpty;
    if (widget.orderId.isNotEmpty) {
      Future.microtask(() async {
        await _load();
        if (mounted && widget.autoStart && data?['canPay'] == true) {
          await _pay();
        } else if (mounted) {
          setState(() => redirecting = false);
        }
      });
      timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (++polls >= 20) timer?.cancel();
        _load();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await ref
          .read(dioProvider)
          .get('/payments/vnpay/orders/${widget.orderId}');
      if (!mounted) return;
      setState(() {
        data = Map<String, dynamic>.from(response.data);
        error = null;
      });
      if (data?['paymentStatus'] == 'paid' || data?['status'] == 'cancelled') {
        timer?.cancel();
        ref.invalidate(orderDetailProvider(widget.orderId));
        ref.invalidate(ordersListProvider);
      }
    } catch (exception) {
      if (mounted) setState(() => error = apiError(exception));
    }
  }

  Future<void> _pay() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await ref
          .read(dioProvider)
          .post('/payments/vnpay/orders/${widget.orderId}/url');
      if (!mounted) return;
      final url = Uri.parse(response.data['paymentUrl'] as String);
      if (url.scheme != 'https' || url.host != 'sandbox.vnpayment.vn') {
        throw StateError('Địa chỉ thanh toán không hợp lệ.');
      }
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      )) {
        throw StateError('Không mở được VNPay. Vui lòng thử lại.');
      }
      if (mounted && !kIsWeb) setState(() => redirecting = false);
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = apiError(exception);
          redirecting = false;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (redirecting) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang chuyển đến VNPay…'),
            ],
          ),
        ),
      );
    }
    final paid = data?['paymentStatus'] == 'paid';
    final awaitingConfirmation = !paid && widget.result == 'pending';
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Thanh toán VNPay Sandbox'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                paid
                    ? Icons.check_circle
                    : Icons.account_balance_wallet_outlined,
                size: 64,
                color: paid
                    ? Colors.teal
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              if (paid && data?['status'] != 'cancelled') ...[
                Text(
                  'Thanh toán thành công!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (awaitingConfirmation) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                const Text(
                  'VNPay đã trả về kết quả thành công. Đang chờ xác nhận giao dịch; bạn không cần thanh toán lại.',
                ),
                const SizedBox(height: 16),
              ],
              if (widget.orderId.isEmpty)
                const Text(
                  'Không xác minh được kết quả thanh toán. Vui lòng kiểm tra trong Đơn hàng của tôi.',
                ),
              if (data != null) ...[
                Text(
                  'Đơn hàng ${data!['orderCode']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(money(data!['totalAmountVnd'])),
                const SizedBox(height: 12),
                Text(
                  paid
                      ? data!['status'] == 'cancelled'
                            ? 'Đã nhận thanh toán cho đơn đã hủy. Vui lòng liên hệ hỗ trợ để đối soát hoàn tiền.'
                            : 'Thanh toán thành công! Hệ thống đã nhận xác nhận từ VNPay.'
                      : widget.result == 'failed'
                      ? 'Thanh toán chưa thành công hoặc đã bị hủy. Bạn có thể thử lại.'
                      : widget.result == 'invalid'
                      ? 'Kết quả trả về không hợp lệ. Trạng thái dưới đây được kiểm tra trực tiếp từ hệ thống.'
                      : 'Đơn hàng chưa được xác nhận thanh toán. Nếu bạn vừa thanh toán, vui lòng đợi hệ thống nhận thông báo từ VNPay.',
                ),
                const SizedBox(height: 16),
                if (!paid &&
                    !awaitingConfirmation &&
                    data!['canPay'] == true) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    onPressed: busy ? null : _pay,
                    icon: const Icon(Icons.payment),
                    label: Text(
                      busy ? 'Đang mở VNPay…' : 'Thanh toán qua VNPay',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra trạng thái'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () =>
                      context.go('/parent/orders/${widget.orderId}'),
                  child: const Text('Xem đơn hàng'),
                ),
              ] else if (widget.orderId.isNotEmpty && error == null)
                const Center(child: CircularProgressIndicator()),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => context.go('/parent/orders'),
                child: const Text('Đơn hàng của tôi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
