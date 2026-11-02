import 'package:artkids_app/core/network/api_json.dart';
import 'package:artkids_app/features/orders/data/models/order.dart';
import 'package:artkids_app/features/orders/presentation/providers/order_detail_provider.dart';
import 'package:artkids_app/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:artkids_app/features/orders/presentation/widgets/order_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

Map<String, dynamic> response({bool complete = false}) => {
  'order': {
    'id': 'order-1',
    'orderCode': 'AK-1',
    'createdAt': '2026-10-29T07:00:00Z',
    'status': complete ? 'delivered' : 'shipping',
    'paymentStatus': 'cod',
    'canCancel': false,
    'subtotalVnd': 250000,
    'totalAmountVnd': 250000,
  },
  'items': [],
  'shippingInfo': {
    'recipientName': 'Phụ huynh',
    'phoneNumber': '0901234567',
    'fullAddress': 'Địa chỉ thử nghiệm',
  },
  'trackingEvents': [
    {
      'id': 'placed',
      'title': 'Đã đặt hàng',
      'description': 'Đơn COD đã được tạo.',
      'isPassed': true,
      'isCurrent': false,
    },
    {
      'id': 'seller-shipping',
      'title': 'Giảng viên báo đã gửi hàng',
      'description': 'Thông tin chưa được hãng vận chuyển xác minh.',
      'isPassed': false,
      'isCurrent': true,
    },
  ],
  'sellerProgress': [
    {
      'sellerId': 'teacher-1',
      'sellerName': 'Cô Minh',
      'status': 'delivered',
      'itemTitles': ['Bộ cọ Minh'],
      'carrier': 'GHN',
      'trackingNumber': 'GV-CUNG-CAP',
      'deliveredAt': '2026-10-29T07:00:00Z',
    },
    {
      'sellerId': 'teacher-2',
      'sellerName': 'Cô Lan',
      'status': complete ? 'delivered' : 'preparing',
      'itemTitles': ['Giấy Lan'],
    },
  ],
};

void main() {
  test(
    'parent model preserves progress for each seller through round trip and copy',
    () {
      final order = OrderModel.fromJson(apiOrder(response()));
      expect(order.toJson()['seller_progress'], hasLength(2));
      expect(
        OrderModel.fromJson(order.toJson()).sellerProgress,
        order.sellerProgress,
      );
      expect(order.copyWith().sellerProgress, order.sellerProgress);
      expect(
        OrderModel.fromJson({'id': 'legacy-order'}).sellerProgress,
        isEmpty,
      );
    },
  );

  testWidgets(
    'parent shows separate seller progress and unverified delivery notice',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderDetailProvider('order-1').overrideWith(
              (ref) async => OrderModel.fromJson(apiOrder(response())),
            ),
          ],
          child: const MaterialApp(home: OrderDetailScreen(orderId: 'order-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tiến độ từng người bán'), findsOneWidget);
      expect(find.text('Cô Minh'), findsOneWidget);
      expect(find.text('Cô Lan'), findsOneWidget);
      expect(find.text('Bộ cọ Minh'), findsOneWidget);
      expect(find.text('Giấy Lan'), findsOneWidget);
      expect(find.text('Giảng viên báo đã giao'), findsOneWidget);
      expect(find.text('Đang chuẩn bị học cụ'), findsOneWidget);
      expect(
        find.textContaining('không xác nhận đã thu tiền COD'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Đơn vị giảng viên chọn: GHN'),
        findsOneWidget,
      );
      expect(find.textContaining('GV-CUNG-CAP'), findsOneWidget);
      expect(find.text('Xem tiến độ người bán'), findsOneWidget);
      final localTime = DateFormat('dd/MM/yyyy • HH:mm').format(
        DateTime.parse('2026-10-29T07:00:00Z').toLocal(),
      );
      expect(find.text('Đặt ngày: $localTime'), findsOneWidget);
      expect(find.text('Giảng viên báo giao lúc: $localTime'), findsOneWidget);
    },
  );

  testWidgets('parent can refresh seller progress without navigating away', (
    tester,
  ) async {
    var complete = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderDetailProvider('order-1').overrideWith(
            (ref) async =>
                OrderModel.fromJson(apiOrder(response(complete: complete))),
          ),
        ],
        child: const MaterialApp(home: OrderDetailScreen(orderId: 'order-1')),
      ),
    );
    await tester.pumpAndSettle();
    complete = true;
    await tester.tap(find.byTooltip('Cập nhật tiến độ'));
    await tester.pumpAndSettle();
    expect(find.text('Giảng viên báo đã giao'), findsNWidgets(2));
    expect(find.text('Đang chuẩn bị học cụ'), findsNothing);
    expect(
      find.textContaining('Trạng thái giao học cụ do giảng viên báo'),
      findsOneWidget,
    );
  });

  testWidgets(
    'seller tracking fallback never invents a GHN shipment or uses the order code',
    (tester) async {
      final order = OrderModel.fromJson(apiOrder(response()));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderActionButtons(order: order, onCancelOrder: (_) async {}),
          ),
        ),
      );
      await tester.tap(find.text('Xem tiến độ người bán'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Chưa có đường dẫn tra cứu được xác minh'),
        findsOneWidget,
      );
      expect(find.textContaining('Mã vận đơn AK-1'), findsNothing);
      expect(find.textContaining('Giao Hàng Nhanh (GHN)'), findsNothing);
    },
  );
}
