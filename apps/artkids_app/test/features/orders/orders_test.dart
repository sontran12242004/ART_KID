import 'package:artkids_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:artkids_app/features/orders/data/models/order.dart';
import 'package:artkids_app/features/orders/data/models/order_item.dart';
import 'package:artkids_app/features/orders/data/models/shipping_info.dart';
import 'package:artkids_app/features/orders/data/repositories/order_repository.dart';
import 'package:artkids_app/features/orders/domain/enums/order_status.dart';
import 'package:artkids_app/features/orders/domain/enums/payment_status.dart';
import 'package:artkids_app/features/orders/presentation/providers/orders_list_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRemoteDataSource implements OrderRemoteDataSource {
  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {}

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    return OrderModel(
      id: orderId,
      orderCode: 'ORD-TEST-001',
      createdAt: DateTime.now(),
      status: OrderStatus.pendingConfirmation,
      paymentStatus: PaymentStatus.pending,
      items: const [
        OrderItemModel(
          id: 'item-1',
          kitName: 'Kit Test',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          quantity: 1,
          unitPriceVnd: 100000,
        ),
      ],
      shippingInfo: const ShippingInfoModel(
        recipientName: 'Tester',
        phoneNumber: '0901234567',
        fullAddress: 'Hà Nội',
      ),
      subtotalVnd: 100000,
      totalAmountVnd: 100000,
    );
  }

  @override
  Future<List<OrderModel>> getOrders({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    return [];
  }
}

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput:
          'ENABLE_MOCK_ORDERS=true\nAPI_BASE_URL=http://10.0.2.2:3000/api\n',
    );
  });

  group('1. OrderStatus Enum Tests', () {
    test('Kiểm tra nhãn tiếng Việt của các trạng thái', () {
      expect(OrderStatus.pendingConfirmation.label, 'Chờ xác nhận');
      expect(OrderStatus.preparing.label, 'Đang chuẩn bị');
      expect(OrderStatus.shipping.label, 'Đang giao');
      expect(OrderStatus.delivered.label, 'Đã giao');
      expect(OrderStatus.cancelled.label, 'Đã hủy');
    });

    test('Kiểm tra isProcessing', () {
      expect(OrderStatus.pendingConfirmation.isProcessing, isTrue);
      expect(OrderStatus.preparing.isProcessing, isTrue);
      expect(OrderStatus.shipping.isProcessing, isTrue);
      expect(OrderStatus.delivered.isProcessing, isFalse);
      expect(OrderStatus.cancelled.isProcessing, isFalse);
    });

    test('Kiểm tra OrderStatus.fromString', () {
      expect(
        OrderStatus.fromString('pending_confirmation'),
        OrderStatus.pendingConfirmation,
      );
      expect(OrderStatus.fromString('preparing'), OrderStatus.preparing);
      expect(OrderStatus.fromString('shipping'), OrderStatus.shipping);
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);
      expect(
        OrderStatus.fromString('UNKNOWN_STATUS'),
        OrderStatus.pendingConfirmation,
      );
    });
  });

  group('2. PaymentStatus Enum Tests', () {
    test('Kiểm tra nhãn thanh toán', () {
      expect(PaymentStatus.paid.label, 'Đã thanh toán');
      expect(PaymentStatus.pending.label, 'Chờ thanh toán');
      expect(PaymentStatus.cod.label, 'Thanh toán khi nhận hàng (COD)');
    });

    test('Kiểm tra PaymentStatus.fromString', () {
      expect(PaymentStatus.fromString('paid'), PaymentStatus.paid);
      expect(PaymentStatus.fromString('cod'), PaymentStatus.cod);
      expect(PaymentStatus.fromString('pending'), PaymentStatus.pending);
    });
  });

  group('3. OrderModel Serialization Tests', () {
    test('fromJson và toJson hoạt động chính xác', () {
      final json = {
        'id': 'test_ord_1',
        'order_code': 'ORD-2026-9999',
        'created_at': '2026-09-17T10:00:00.000Z',
        'status': 'shipping',
        'payment_status': 'paid',
        'payment_method_name': 'Chuyển khoản VietQR',
        'items': [
          {
            'id': 'item_1',
            'kit_name': 'Hộp Màu Nước',
            'thumbnail_url': 'https://example.com/kit.jpg',
            'quantity': 2,
            'unit_price_vnd': 150000,
            'kit_items': ['Màu', 'Cọ', 'Giấy'],
          },
        ],
        'shipping_info': {
          'recipient_name': 'Nguyễn Văn A',
          'phone_number': '0901234567',
          'full_address': 'Quận 1, TP. HCM',
          'carrier_name': 'GHN',
          'tracking_number': 'GHN12345',
        },
        'subtotal_vnd': 300000,
        'shipping_fee_vnd': 30000,
        'discount_vnd': 30000,
        'total_amount_vnd': 300000,
        'tracking_events': [
          {
            'id': 'evt_1',
            'title': 'Đặt hàng',
            'description': 'Đã đặt',
            'is_passed': true,
            'is_current': false,
          },
        ],
      };

      final model = OrderModel.fromJson(json);
      expect(model.id, 'test_ord_1');
      expect(model.orderCode, 'ORD-2026-9999');
      expect(model.status, OrderStatus.shipping);
      expect(model.paymentStatus, PaymentStatus.paid);
      expect(model.items.length, 1);
      expect(model.items.first.totalPriceVnd, 300000);
      expect(model.shippingInfo.trackingNumber, 'GHN12345');
      expect(model.trackingEvents.length, 1);

      final convertedJson = model.toJson();
      expect(convertedJson['order_code'], 'ORD-2026-9999');
      expect(convertedJson['status'], 'shipping');
    });
  });

  group('5. OrdersListProvider State Tests', () {
    test('Tải danh sách đơn hàng ban đầu', () async {
      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(
            OrderRepositoryImpl(MockRemoteDataSource()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(ordersListProvider, (_, _) {});
      addTearDown(subscription.close);

      // Ban đầu là loading
      expect(subscription.read(), isA<AsyncLoading>());

      // Đợi loadInitial hoàn tất
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = subscription.read();
      expect(state, isA<AsyncData<OrdersListState>>());
      expect(state.value!.orders, isEmpty);
    });

    test('Chuyển đổi bộ lọc cập nhật state provider', () {
      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(
            OrderRepositoryImpl(MockRemoteDataSource()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(selectedOrderFilterProvider), OrderListFilter.all);

      container.read(selectedOrderFilterProvider.notifier).state =
          OrderListFilter.delivered;

      expect(
        container.read(selectedOrderFilterProvider),
        OrderListFilter.delivered,
      );
    });
  });
}
