import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../connected/presentation/widgets.dart';

class KidPinGateScreen extends ConsumerWidget {
  const KidPinGateScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Xác nhận mã PIN')),
    body: Center(
      child: ActionButton(
        label: 'Nhập PIN để vào học',
        action: (r) async {
          final values = await askFields(context, 'Mã PIN phụ huynh', [
            const EntryField('pin', 'PIN', secret: true),
          ]);
          if (values == null) return false;
          final valid = await r
              .read(authRepositoryProvider)
              .verifyKidPin(values['pin']!);
          if (!valid) throw Exception('Mã PIN không đúng.');
          return true;
        },
        onSuccess: (valid) {
          if (valid == true) context.go('/kid');
        },
      ),
    ),
  );
}
