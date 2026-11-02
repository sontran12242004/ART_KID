import 'package:artkids_app/core/network/api_json.dart';
import 'package:artkids_app/features/connected/data/connected_api.dart';
import 'package:artkids_app/features/connected/presentation/seller_order_screens.dart';
import 'package:artkids_app/features/connected/presentation/workspace_screens.dart';
import 'package:artkids_app/features/orders/data/models/order.dart';
import 'package:artkids_app/features/orders/domain/enums/order_status.dart';
import 'package:artkids_app/features/orders/presentation/widgets/order_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final ready in [true, false]) {
    testWidgets('seller order exposes shipping only when ready: $ready', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiDataProvider('/marketplace/orders/order-1').overrideWith(
              (ref) async => {
                'orderCode': 'AK-1',
                'status': 'pending_confirmation',
                'sellerStatus': ready ? 'preparing' : 'pending_payment',
                'canFulfill': ready,
                'awaitingPayment': !ready,
                'collectionUnverified': ready,
                'items': [],
                'subtotalVnd': 125000,
                'shippingInfo': null,
                'fulfillment': null,
              },
            ),
          ],
          child: const MaterialApp(
            home: SellerOrderDetailScreen(id: 'order-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Ghi nhận đã gửi hàng'),
        ready ? findsOneWidget : findsNothing,
      );
      expect(
        find.textContaining('Chờ xác minh tiền chuyển khoản'),
        ready ? findsNothing : findsOneWidget,
      );
      expect(
        find.textContaining('Chờ quản trị viên xác nhận đơn'),
        findsNothing,
      );
    });
  }

  for (final kind in ['marketplace', 'transfer', 'legacy', 'mixed']) {
    testWidgets('admin shows only applicable legacy confirmation: $kind', (
      tester,
    ) async {
      final legacyAction = kind == 'legacy' || kind == 'mixed';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiDataProvider('/commerce/orders?pageSize=100').overrideWith(
              (ref) async => [
                {
                  'id': 'order-1',
                  'orderCode': 'AK-1',
                  'status': 'pending_confirmation',
                  'totalAmountVnd': 125000,
                  'hasMarketplaceItems': kind != 'legacy',
                  'requiresLegacyConfirmation': legacyAction,
                  'awaitingMarketplacePayment': kind == 'transfer',
                },
              ],
            ),
          ],
          child: const MaterialApp(home: AdminOrders()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Xác nhận thanh toán'),
        kind == 'legacy' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Xác nhận phần hàng nền tảng'),
        kind == 'mixed' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Xem chi tiết'),
        legacyAction ? findsNothing : findsOneWidget,
      );
    });
  }

  for (final allowed in [true, false]) {
    testWidgets('parent cancel button follows server permission: $allowed', (
      tester,
    ) async {
      final order = OrderModel.fromJson(
        apiOrder({
          'id': 'order-1',
          'status': allowed ? 'preparing' : 'pending_confirmation',
          'canCancel': allowed,
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderActionButtons(order: order, onCancelOrder: (_) async {}),
          ),
        ),
      );
      expect(find.text('Hủy đơn'), allowed ? findsOneWidget : findsNothing);
      expect(order.copyWith(status: OrderStatus.cancelled).canCancel, false);
      expect(OrderModel.fromJson(order.toJson()).canCancel, allowed);
    });
  }
}
