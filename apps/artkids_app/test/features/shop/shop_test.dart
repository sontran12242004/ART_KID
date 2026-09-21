import 'package:artkids_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:artkids_app/features/orders/data/models/order.dart';
import 'package:artkids_app/features/orders/data/models/shipping_info.dart';
import 'package:artkids_app/features/orders/data/repositories/order_repository.dart';
import 'package:artkids_app/features/orders/domain/entities/order_entity.dart';
import 'package:artkids_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:artkids_app/features/orders/domain/entities/shipping_info_entity.dart';
import 'package:artkids_app/features/orders/domain/enums/order_status.dart';
import 'package:artkids_app/features/orders/domain/enums/order_type.dart';
import 'package:artkids_app/features/orders/domain/enums/payment_status.dart';
import 'package:artkids_app/features/shop/data/models/product.dart';
import 'package:artkids_app/features/shop/data/repositories/product_repository.dart';
import 'package:artkids_app/features/shop/domain/enums/product_category.dart';
import 'package:artkids_app/features/shop/presentation/providers/cart_provider.dart';
import 'package:dio/dio.dart';
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
  }) async =>
      [];
}

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput:
          'ENABLE_MOCK_ORDERS=true\nENABLE_MOCK_SHOP=true\nAPI_BASE_URL=http://10.0.2.2:3000/api\n',
    );
  });

  group('OrderType Enums & Model tests', () {
    test('OrderType labels and properties are correct', () {
      expect(OrderType.subscription.label, equals('Gói đăng ký'));
      expect(OrderType.oneTimePurchase.label, equals('Mua lẻ'));
      expect(OrderType.fromString('subscription'), equals(OrderType.subscription));
      expect(OrderType.fromString('one_time_purchase'),
          equals(OrderType.oneTimePurchase));
      expect(OrderType.fromString('unknown'), equals(OrderType.oneTimePurchase));
    });

    test('OrderModel serializes and deserializes order_type', () {
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
          }
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
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial cart is empty', () {
      expect(container.read(cartProvider), isEmpty);
      expect(container.read(cartTotalCountProvider), equals(0));
      expect(container.read(cartSubtotalVndProvider), equals(0));
    });

    test('Add item to cart and calculate totals', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(testProductA, quantity: 1);

      var items = container.read(cartProvider);
      expect(items.length, equals(1));
      expect(items.first.quantity, equals(1));
      expect(container.read(cartTotalCountProvider), equals(1));
      expect(container.read(cartSubtotalVndProvider), equals(120000));

      // Thêm tiếp sản phẩm A (tăng số lượng)
      notifier.addToCart(testProductA, quantity: 2);
      items = container.read(cartProvider);
      expect(items.length, equals(1));
      expect(items.first.quantity, equals(3));
      expect(container.read(cartTotalCountProvider), equals(3));
      expect(container.read(cartSubtotalVndProvider), equals(360000));

      // Thêm sản phẩm B
      notifier.addToCart(testProductB, quantity: 1);
      items = container.read(cartProvider);
      expect(items.length, equals(2));
      expect(container.read(cartTotalCountProvider), equals(4));
      expect(container.read(cartSubtotalVndProvider), equals(360000 + 280000));
    });

    test('Increment, decrement, and remove item', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(testProductA, quantity: 2);

      notifier.incrementQuantity('prod_a');
      expect(container.read(cartProvider).first.quantity, equals(3));

      notifier.decrementQuantity('prod_a');
      expect(container.read(cartProvider).first.quantity, equals(2));

      // Decrement về 0 -> tự động xóa khỏi giỏ
      notifier.decrementQuantity('prod_a');
      notifier.decrementQuantity('prod_a');
      expect(container.read(cartProvider), isEmpty);

      // Thêm lại rồi xóa hẳn
      notifier.addToCart(testProductA, quantity: 5);
      notifier.removeFromCart('prod_a');
      expect(container.read(cartProvider), isEmpty);
    });

    test('Clear cart', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(testProductA, quantity: 2);
      notifier.addToCart(testProductB, quantity: 3);

      expect(container.read(cartProvider).length, equals(2));
      notifier.clearCart();
      expect(container.read(cartProvider), isEmpty);
      expect(container.read(cartTotalCountProvider), equals(0));
      expect(container.read(cartSubtotalVndProvider), equals(0));
    });
  });

  group('ProductRepository tests', () {
    late ProductRepository repository;

    setUp(() {
      repository = ProductRepositoryImpl(Dio());
    });

    test('getProducts returns 10 mock products by default', () async {
      final products = await repository.getProducts();
      expect(products.length, equals(10));
    });

    test('Filter products by category', () async {
      final courseKits =
          await repository.getProducts(category: ProductCategory.courseKit);
      expect(courseKits.every((p) => p.category == ProductCategory.courseKit),
          isTrue);

      final tools =
          await repository.getProducts(category: ProductCategory.individualTool);
      expect(tools.every((p) => p.category == ProductCategory.individualTool),
          isTrue);
      expect(tools.isNotEmpty, isTrue);
    });

    test('Search products by keyword', () async {
      final results = await repository.getProducts(searchQuery: 'màu nước');
      expect(results.isNotEmpty, isTrue);
      expect(
        results.any((p) =>
            p.name.toLowerCase().contains('màu nước') ||
            p.description.toLowerCase().contains('màu nước')),
        isTrue,
      );
    });

    test('getProductById returns product with cross-sell information', () async {
      final product =
          await repository.getProductById('prod_kit_animal_watercolor');
      expect(product.name, contains('Động Vật'));
      expect(product.courseId, equals('course_wild_animals'));
      expect(product.recommendedSubscriptionPlanId, equals('plan_pro_kit'));
      expect(product.kitItems.isNotEmpty, isTrue);
    });
  });

  group('Shared Order Infrastructure Integration', () {
    test('Create oneTimePurchase order from shop cart', () async {
      final repo = OrderRepositoryImpl(MockRemoteDataSource());

      final order = OrderEntity(
        id: 'ord_shop_test_123',
        orderCode: 'ORD-2026-7777',
        createdAt: DateTime.now(),
        status: OrderStatus.pendingConfirmation,
        orderType: OrderType.oneTimePurchase,
        paymentStatus: PaymentStatus.paid,
        paymentMethodName: 'Chuyển khoản VietQR',
        items: const [
          OrderItemEntity(
            id: 'prod_kit_animal_watercolor',
            kitName: 'Kit Vẽ Động Vật Màu Nước',
            thumbnailUrl: 'https://example.com/thumb.jpg',
            quantity: 1,
            unitPriceVnd: 285000,
            courseId: 'course-animal-watercolor',
            courseTitle: 'Vẽ Động Vật Bằng Màu Nước',
            kitItems: ['Giấy vẽ A4 300gsm', 'Cọ vẽ tròn số 4 & số 8'],
          ),
        ],
        shippingInfo: const ShippingInfoEntity(
          recipientName: 'Trần Thị Thu',
          phoneNumber: '0987654321',
          fullAddress: 'Căn hộ 12B, Masteri Thảo Điền, Quận 2, TP.HCM',
        ),
        subtotalVnd: 285000,
        shippingFeeVnd: 25000,
        discountVnd: 0,
        totalAmountVnd: 310000,
      );

      final created = await repo.createOrder(order);
      expect(created.id, equals('ord_shop_test_123'));
      expect(created.orderType, equals(OrderType.oneTimePurchase));

      // Kiểm tra lấy lại qua getOrderById
      final fetched = await repo.getOrderById('ord_shop_test_123');
      expect(fetched.orderCode, equals('ORD-2026-7777'));
      expect(fetched.orderType, equals(OrderType.oneTimePurchase));
      expect(fetched.items.first.kitItems.length, equals(2));
    });
  });
}
