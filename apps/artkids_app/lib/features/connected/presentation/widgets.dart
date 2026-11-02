import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_interceptor.dart';
import '../../../core/network/dio_client.dart';
import '../data/connected_api.dart';

String money(num value) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
).format(value);
String dateLabel(dynamic value) => value == null
    ? 'Chưa có'
    : DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.parse(value as String).toLocal());
String statusLabel(dynamic value) =>
    const {
      'pending_confirmation': 'Chờ xác nhận',
      'preparing': 'Đang chuẩn bị',
      'shipping': 'Đang giao',
      'delivered': 'Đã giao',
      'cancelled': 'Đã hủy',
      'pending': 'Chờ thanh toán',
      'pending_payment': 'Chờ xác minh thanh toán',
      'paid': 'Đã thanh toán',
      'cod': 'Trả khi nhận hàng',
      'pending_review': 'Chờ giáo viên chấm',
      'reviewed': 'Đã nhận xét',
      'scheduled': 'Sắp diễn ra',
      'live': 'Đang diễn ra',
      'completed': 'Hoàn thành',
      'open': 'Đang mở đăng ký',
      'active': 'Đang hoạt động',
      'packed': 'Đã đóng gói',
      'returned': 'Đã hoàn hàng',
      'queued': 'Đang chờ',
      'processing': 'Đang xử lý',
      'failed': 'Không thành công',
    }[value] ??
    value?.toString() ??
    '';
void toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : Colors.teal.shade700,
    ),
  );
}

class ApiView extends ConsumerWidget {
  const ApiView({super.key, required this.path, required this.builder});
  final String path;
  final Widget Function(dynamic data) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(apiDataProvider(path))
      .when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(apiError(e), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(apiDataProvider(path)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: builder,
      );
}

class PrivateImage extends ConsumerWidget {
  const PrivateImage({super.key, required this.assetId, this.height = 220});
  final String assetId;
  final double height;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(mediaBytesProvider('/media/$assetId'))
      .when(
        data: (Uint8List bytes) =>
            Image.memory(bytes, height: height, fit: BoxFit.contain),
        loading: () => SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) =>
            SizedBox(height: 80, child: Center(child: Text(apiError(e)))),
      );
}

class ActionButton extends ConsumerStatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.action,
    this.onSuccess,
    this.enabled = true,
    this.icon = Icons.check_circle_outline,
  });
  final String label;
  final bool enabled;
  final Future<dynamic> Function(WidgetRef ref) action;
  final void Function(dynamic result)? onSuccess;
  final IconData icon;
  @override
  ConsumerState<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends ConsumerState<ActionButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: busy || !widget.enabled
        ? null
        : () async {
            setState(() => busy = true);
            try {
              final result = await widget.action(ref);
              ref.invalidate(apiDataProvider);
              if (context.mounted) {
                widget.onSuccess?.call(result);
                if (widget.onSuccess == null) {
                  toast(context, 'Đã lưu thành công.');
                }
              }
            } catch (e) {
              if (context.mounted) toast(context, apiError(e), error: true);
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
    icon: busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(widget.icon),
    label: Text(widget.label),
  );
}

class EntryField {
  const EntryField(
    this.key,
    this.label, {
    this.value = '',
    this.number = false,
    this.required = true,
    this.secret = false,
  });
  final String key, label, value;
  final bool number, required, secret;
}

Future<Map<String, String>?> askFields(
  BuildContext context,
  String title,
  List<EntryField> fields,
) async {
  final controls = {
    for (final f in fields) f.key: TextEditingController(text: f.value),
  };
  final form = GlobalKey<FormState>();
  try {
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final f in fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: controls[f.key],
                        decoration: InputDecoration(
                          labelText: f.label,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: f.number
                            ? TextInputType.number
                            : TextInputType.text,
                        obscureText: f.secret,
                        validator: (v) =>
                            f.required && (v?.trim().isEmpty ?? true)
                            ? 'Vui lòng nhập ${f.label.toLowerCase()}'
                            : f.number &&
                                  v!.isNotEmpty &&
                                  num.tryParse(v) == null
                            ? 'Vui lòng nhập số hợp lệ'
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, {
                  for (final f in fields) f.key: controls[f.key]!.text.trim(),
                });
              }
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  } finally {
    // The dialog route keeps its children during its reverse animation.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final c in controls.values) {
      c.dispose();
    }
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ??
    false;
Future<bool> mutate(
  BuildContext context,
  WidgetRef ref,
  String path,
  Map<String, dynamic> data, {
  String method = 'POST',
  String success = 'Đã lưu thành công.',
}) async {
  try {
    await ref
        .read(dioProvider)
        .request(
          path,
          data: data,
          options: Options(method: method),
        );
    ref.invalidate(apiDataProvider);
    if (context.mounted) toast(context, success);
    return true;
  } catch (e) {
    if (context.mounted) toast(context, apiError(e), error: true);
    return false;
  }
}
