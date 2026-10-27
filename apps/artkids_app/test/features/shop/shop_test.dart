import 'package:artkids_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:artkids_app/features/orders/data/models/order.dart';
import 'package:artkids_app/features/orders/data/models/shipping_info.dart';
import 'package:artkids_app/features/orders/domain/enums/order_status.dart';
import 'package:artkids_app/features/orders/domain/enums/order_type.dart';
import 'package:artkids_app/features/orders/domain/enums/payment_status.dart';
import 'package:artkids_app/features/shop/data/models/product.dart';
import 'package:artkids_app/features/shop/domain/enums/product_category.dart';
import 'package:artkids_app/features/shop/presentation/providers/cart_provider.dart';
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
      orderType: OrderType.oneTimePurchase,
      paymentStatus: PaymentStatus.pending,
      items: const [],
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
  }) async => [];
}

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput:
          'ENABLE_MOCK_ORDERS=true\nENABLE_MOCK_SHOP=true\nAPI_BASE_URL=http://10.0.2.2:3000/api\n',
    );
  });

  group('OrderType Enums & Model tests', () {
    test('OrderType labels and properties are correct', () async {
      expect(OrderType.subscription.label, equals('Gói đăng ký'));
      expect(OrderType.oneTimePurchase.label, equals('Mua lẻ'));
      expect(
        OrderType.fromString('subscription'),
        equals(OrderType.subscription),
      );
      expect(
        OrderType.fromString('one_time_purchase'),
        equals(OrderType.oneTimePurchase),
      );
      expect(
        OrderType.fromString('unknown'),
        equals(OrderType.oneTimePurchase),
      );
    });

    test('OrderModel serializes and deserializes order_type', () async {
      final json = {
        'id': 'ord_test_shop_1',
        'order_code': 'ORD-2026-9999',
        'created_at': '2026-03-20T10:00:00.000Z',
        'status': 'pending_confirmation',
        'order_type': 'oneTimePurchase',
        'payment_status': 'paid',
        'payment_method_name': 'Chuyển khoản VietQR',
        'items': [
          {
            'id': 'prod_kit_1',
            'kit_name': 'Kit Màu Nước',
            'thumbnail_url': 'https://example.com/img.jpg',
            'quantity': 2,
            'unit_price_vnd': 150000,
            'kit_items': ['Bút chì 2B', 'Cọ vẽ'],
          },
        ],
        'shipping_info': {
          'recipient_name': 'Nguyễn Văn Minh',
          'phone_number': '0912345678',
          'full_address': 'Quận 7, TP.HCM',
          'carrier_name': 'GHN',
        },
        'subtotal_vnd': 300000,
        'shipping_fee_vnd': 0,
        'discount_vnd': 0,
        'total_amount_vnd': 300000,
      };

      final model = OrderModel.fromJson(json);
      expect(model.orderType, equals(OrderType.oneTimePurchase));
      expect(model.items.first.kitItems.length, equals(2));
      expect(model.toJson()['order_type'], equals('one_time_purchase'));
    });
  });

  group('CartNotifier & Cart Providers', () {
    late ProviderContainer container;

    final testProductA = Product(
      id: 'prod_a',
      name: 'Hộp Màu Nước 24 Màu',
      priceVnd: 120000,
      originalPriceVnd: 150000,
      thumbnailUrl: 'https://example.com/a.jpg',
      description: 'Hộp màu nước cao cấp',
      category: ProductCategory.individualTool,
    );

    final testProductB = Product(
      id: 'prod_b',
      name: 'Bộ Kit Vẽ Động Vật',
      priceVnd: 280000,
      thumbnailUrl: 'https://example.com/b.jpg',
      description: 'Kit học cụ đầy đủ',
      category: ProductCategory.courseKit,
    );

    setUp(() {
      container = ProviderContainer(
        overrides: [cartProvider.overrideWith((ref) => CartNotifier())],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial cart is empty', () async {
      expect(container.read(cartProvider), isEmpty);
      expect(container.read(cartTotalCountProvider), equals(0));
      expect(container.read(cartSubtotalVndProvider), equals(0));
    });

    test('Add item to cart and calculate totals', () async {
      final notifier = container.read(cartProvider.notifier);
      await notifier.addToCart(testProductA, quantity: 1);

      var items = container.read(cartProvider);
      expect(items.length, equals(1));
      expect(items.first.quantity, equals(1));
      expect(container.read(cartTotalCountProvider), equals(1));
      expect(container.read(cartSubtotalVndProvider), equals(120000));

      // Thêm tiếp sản phẩm A (tăng số lượng)
      await notifier.addToCart(testProductA, quantity: 2);
      items = container.read(cartProvider);
      expect(items.length, equals(1));
      expect(items.first.quantity, equals(3));
      expect(container.read(cartTotalCountProvider), equals(3));
      expect(container.read(cartSubtotalVndProvider), equals(360000));

      // Thêm sản phẩm B
      await notifier.addToCart(testProductB, quantity: 1);
      items = container.read(cartProvider);
      expect(items.length, equals(2));
      expect(container.read(cartTotalCountProvider), equals(4));
      expect(container.read(cartSubtotalVndProvider), equals(360000 + 280000));
    });

    test('Increment, decrement, and remove item', () async {
      final notifier = container.read(cartProvider.notifier);
      await notifier.addToCart(testProductA, quantity: 2);

      await notifier.incrementQuantity('prod_a');
      expect(container.read(cartProvider).first.quantity, equals(3));

      await notifier.decrementQuantity('prod_a');
      expect(container.read(cartProvider).first.quantity, equals(2));

      // Decrement về 0 -> tự động xóa khỏi giỏ
      await notifier.decrementQuantity('prod_a');
      await notifier.decrementQuantity('prod_a');
      expect(container.read(cartProvider), isEmpty);

      // Thêm lại rồi xóa hẳn
      await notifier.addToCart(testProductA, quantity: 5);
      await notifier.removeFromCart('prod_a');
      expect(container.read(cartProvider), isEmpty);
    });

    test('Clear cart', () async {
      final notifier = container.read(cartProvider.notifier);
      await notifier.addToCart(testProductA, quantity: 2);
      await notifier.addToCart(testProductB, quantity: 3);

      expect(container.read(cartProvider).length, equals(2));
      notifier.clearCart();
      expect(container.read(cartProvider), isEmpty);
      expect(container.read(cartTotalCountProvider), equals(0));
      expect(container.read(cartSubtotalVndProvider), equals(0));
    });
  });
}
