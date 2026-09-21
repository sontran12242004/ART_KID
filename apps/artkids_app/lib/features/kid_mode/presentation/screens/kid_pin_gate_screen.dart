import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/kid_button.dart';

/// Cổng PIN — chỉ phụ huynh biết, ngăn trẻ tự thoát Kid Mode
class KidPinGateScreen extends StatelessWidget {
  const KidPinGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Nhập mã PIN', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              // TODO: PIN pad widget
              KidButton(
                label: 'Vào học',
                icon: Icons.palette,
                onPressed: () => context.go(RoutePaths.kidHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
