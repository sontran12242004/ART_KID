import 'package:artkids_app/features/orders/domain/entities/order_entity.dart';
import 'package:artkids_app/features/orders/domain/entities/shipping_info_entity.dart';
import 'package:artkids_app/features/orders/domain/enums/order_status.dart';
import 'package:artkids_app/features/orders/domain/enums/payment_status.dart';
import 'package:artkids_app/features/orders/presentation/providers/order_detail_provider.dart';
import 'package:artkids_app/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('copy tracking notification wraps within a 320px snackbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final order = OrderEntity(
      id: 'order-1',
      orderCode: 'AK-1',
      createdAt: DateTime(2026, 11, 2),
      status: OrderStatus.shipping,
      paymentStatus: PaymentStatus.cod,
      items: const [],
      shippingInfo: const ShippingInfoEntity(
        recipientName: 'Mai',
        phoneNumber: '0901234567',
        fullAddress: 'Hà Nội',
        carrierName: 'VNPost',
        trackingNumber: 'ACTUAL-REFERENCE',
      ),
      subtotalVnd: 100000,
      totalAmountVnd: 100000,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderDetailProvider('order-1').overrideWith((ref) async => order),
        ],
        child: MaterialApp(
          theme: ThemeData(
            snackBarTheme: const SnackBarThemeData(
              width: 320,
              behavior: SnackBarBehavior.floating,
            ),
          ),
          home: const OrderDetailScreen(orderId: 'order-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sao chép'));
    await tester.tap(find.text('Sao chép'));
    await tester.pumpAndSettle();
    expect(find.text('Đã sao chép mã vận đơn vào bộ nhớ tạm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
