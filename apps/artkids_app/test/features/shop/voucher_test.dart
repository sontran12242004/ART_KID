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
import 'package:artkids_app/features/shop/data/models/voucher.dart';
import 'package:artkids_app/features/shop/data/repositories/voucher_repository.dart';
import 'package:artkids_app/features/shop/domain/enums/discount_type.dart';
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

  group('Voucher Model & Discount Calculation', () {
    test('Calculate percentage discount with maximum cap', () {
      final voucher = Voucher(
        code: 'ARTKIDS10',
        title: 'Giảm 10% đơn từ 200k',
        discountType: DiscountType.percentage,
        discountValue: 10,
        minOrderAmount: 200000,
        maxDiscountAmount: 50000,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );

      // Đơn 300.000 đ -> 10% = 30.000 đ (< 50.000 đ)
      expect(voucher.calculateDiscount(300000), equals(30000));

      // Đơn 800.000 đ -> 10% = 80.000 đ (> 50.000 đ) -> chạm trần 50.000 đ
      expect(voucher.calculateDiscount(800000), equals(50000));

      // Đơn 150.000 đ (< 200.000 đ) -> không đủ điều kiện -> 0 đ
      expect(voucher.calculateDiscount(150000), equals(0));
    });

    test('Calculate fixed amount discount', () {
      final voucher = Voucher(
        code: 'KID30K',
        title: 'Giảm 30k',
        discountType: DiscountType.fixedAmount,
        discountValue: 30000,
        minOrderAmount: 150000,
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      );

      // Đơn 200.000 đ -> giảm 30.000 đ
      expect(voucher.calculateDiscount(200000), equals(30000));

      // Đơn 100.000 đ (< 150.000 đ) -> 0 đ
      expect(voucher.calculateDiscount(100000), equals(0));
    });

    test('Fixed discount does not exceed subtotal', () {
      final voucher = Voucher(
        code: 'BIGDISCOUNT',
        title: 'Giảm 100k',
        discountType: DiscountType.fixedAmount,
        discountValue: 100000,
        minOrderAmount: 50000,
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      );

      // Đơn 80.000 đ -> giảm tối đa 80.000 đ (không bị âm tiền)
      expect(voucher.calculateDiscount(80000), equals(80000));
    });

    test('isExpired returns correct status', () {
      final validVoucher = Voucher(
        code: 'VALID',
        title: 'Voucher còn hạn',
        discountType: DiscountType.percentage,
        discountValue: 10,
        expiryDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(validVoucher.isExpired, isFalse);

      final expiredVoucher = Voucher(
        code: 'EXPIRED',
        title: 'Voucher hết hạn',
        discountType: DiscountType.percentage,
        discountValue: 10,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredVoucher.isExpired, isTrue);
    });
  });

  group('VoucherRepository & Validation Tests', () {
    late VoucherRepository repository;

    setUp(() {
      repository = VoucherRepositoryImpl(Dio());
    });

    test('getAvailableVouchers returns 5 mock vouchers', () async {
      final vouchers = await repository.getAvailableVouchers();
      expect(vouchers.length, equals(5));
      expect(vouchers.any((v) => v.code == 'ARTKIDS10'), isTrue);
      expect(vouchers.any((v) => v.code == 'KID30K'), isTrue);
      expect(vouchers.any((v) => v.code == 'VIP500K'), isTrue);
      expect(vouchers.any((v) => v.code == 'EXPIRED20'), isTrue);
      expect(vouchers.any((v) => v.code == 'SOLDOUT'), isTrue);
    });

    test('Validate valid voucher ARTKIDS10', () async {
      final result = await repository.validateVoucher(
        code: 'ARTKIDS10',
        orderSubtotalVnd: 250000,
      );

      expect(result.isValid, isTrue);
      expect(result.voucher, isNotNull);
      expect(result.voucher!.code, equals('ARTKIDS10'));
      expect(result.discountAmountVnd, equals(25000)); // 10% của 250k
      expect(result.errorCode, equals(VoucherErrorCode.none));
    });

    test('Validate voucher case insensitively (artkids10)', () async {
      final result = await repository.validateVoucher(
        code: '  artkids10  ',
        orderSubtotalVnd: 300000,
      );

      expect(result.isValid, isTrue);
      expect(result.discountAmountVnd, equals(30000));
    });

    test('Validate non-existent voucher code returns notFound error', () async {
      final result = await repository.validateVoucher(
        code: 'KHONGTONTAI',
        orderSubtotalVnd: 300000,
      );

      expect(result.isValid, isFalse);
      expect(result.errorCode, equals(VoucherErrorCode.notFound));
      expect(result.errorMessage, contains('không tồn tại'));
    });

    test('Validate expired voucher returns expired error', () async {
      final result = await repository.validateVoucher(
        code: 'EXPIRED20',
        orderSubtotalVnd: 300000,
      );

      expect(result.isValid, isFalse);
      expect(result.errorCode, equals(VoucherErrorCode.expired));
      expect(result.errorMessage, contains('hết hạn sử dụng'));
    });

    test('Validate voucher not meeting minOrderAmount returns minOrderNotMet with missing amount', () async {
      // VIP500K yêu cầu tối thiểu 500.000 đ, đơn hiện tại là 350.000 đ (thiếu 150.000 đ)
      final result = await repository.validateVoucher(
        code: 'VIP500K',
        orderSubtotalVnd: 350000,
      );

      expect(result.isValid, isFalse);
      expect(result.errorCode, equals(VoucherErrorCode.minOrderNotMet));
      expect(result.errorMessage, contains('chưa đạt giá trị tối thiểu 500.000'));
      expect(result.errorMessage, contains('150.000'));
    });

    test('Validate voucher with out of usage limit returns outOfUsage error', () async {
      final result = await repository.validateVoucher(
        code: 'SOLDOUT',
        orderSubtotalVnd: 200000,
      );

      expect(result.isValid, isFalse);
      expect(result.errorCode, equals(VoucherErrorCode.outOfUsage));
      expect(result.errorMessage, contains('hết số lượt sử dụng'));
    });
  });

  group('Cart & Voucher State Management (Riverpod)', () {
    late ProviderContainer container;

    final testProduct = Product(
      id: 'prod_paint',
      name: 'Hộp Màu Nước Cao Cấp',
      priceVnd: 100000,
      thumbnailUrl: 'https://example.com/img.jpg',
      description: 'Màu nước chuẩn an toàn',
      category: ProductCategory.individualTool,
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Cart price calculation updates reactively when voucher applied', () {
      final cartNotifier = container.read(cartProvider.notifier);

      // Thêm 2 sản phẩm: subtotal = 200.000 đ (< 300k -> phí ship = 25.000 đ)
      cartNotifier.addToCart(testProduct, quantity: 2);
      expect(container.read(cartSubtotalVndProvider), equals(200000));
      expect(container.read(cartShippingFeeVndProvider), equals(25000));
      expect(container.read(cartDiscountVndProvider), equals(0));
      expect(container.read(cartFinalTotalVndProvider), equals(225000));

      // Áp dụng voucher ARTKIDS10 (10% của 200.000 đ = 20.000 đ)
      final voucher = Voucher(
        code: 'ARTKIDS10',
        title: 'Giảm 10% đơn từ 200k',
        discountType: DiscountType.percentage,
        discountValue: 10,
        minOrderAmount: 200000,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );

      container.read(appliedVoucherProvider.notifier).state = voucher;

      expect(container.read(cartDiscountVndProvider), equals(20000));
      // Tổng mới = 200.000 + 25.000 - 20.000 = 205.000 đ
      expect(container.read(cartFinalTotalVndProvider), equals(205000));

      // Tăng thêm 1 sản phẩm: subtotal = 300.000 đ (đạt ngưỡng freeship -> ship = 0 đ)
      cartNotifier.addToCart(testProduct, quantity: 1);
      expect(container.read(cartSubtotalVndProvider), equals(300000));
      expect(container.read(cartShippingFeeVndProvider), equals(0));
      // Giảm 10% của 300.000 = 30.000 đ
      expect(container.read(cartDiscountVndProvider), equals(30000));
      // Tổng mới = 300.000 + 0 - 30.000 = 270.000 đ
      expect(container.read(cartFinalTotalVndProvider), equals(270000));

      // Giảm số lượng xuống 1 món: subtotal = 100.000 đ (< minOrderAmount 200.000 đ)
      cartNotifier.updateQuantity('prod_paint', 1);
      expect(container.read(cartSubtotalVndProvider), equals(100000));
      // Voucher tự động không giảm (discount = 0 đ) vì chưa đạt mức tối thiểu
      expect(container.read(cartDiscountVndProvider), equals(0));
      expect(container.read(cartShippingFeeVndProvider), equals(25000));
      expect(container.read(cartFinalTotalVndProvider), equals(125000));

      // Gỡ voucher: appliedVoucher = null
      container.read(appliedVoucherProvider.notifier).state = null;
      expect(container.read(cartDiscountVndProvider), equals(0));
    });
  });

  group('Order Integration with Voucher', () {
    test('Create order preserves voucherCode and discountVnd', () async {
      final repo = OrderRepositoryImpl(MockRemoteDataSource());

      final newOrder = OrderEntity(
        id: 'ord_voucher_test_001',
        orderCode: 'ORD-2026-8888',
        createdAt: DateTime.now(),
        status: OrderStatus.pendingConfirmation,
        orderType: OrderType.oneTimePurchase,
        paymentStatus: PaymentStatus.paid,
        paymentMethodName: 'Chuyển khoản VietQR',
        items: const [
          OrderItemEntity(
            id: 'prod_kit_1',
            kitName: 'Kit Học Vẽ Nước',
            thumbnailUrl: 'https://example.com/thumb.jpg',
            quantity: 1,
            unitPriceVnd: 250000,
          ),
        ],
        shippingInfo: const ShippingInfoEntity(
          recipientName: 'Lê Văn An',
          phoneNumber: '0911222333',
          fullAddress: 'Hà Nội',
        ),
        subtotalVnd: 250000,
        shippingFeeVnd: 25000,
        discountVnd: 25000, // Đã giảm 25.000 đ
        voucherCode: 'ARTKIDS10', // Mã voucher
        totalAmountVnd: 250000, // 250k + 25k - 25k = 250k
      );

      final created = await repo.createOrder(newOrder);
      expect(created.voucherCode, equals('ARTKIDS10'));
      expect(created.discountVnd, equals(25000));
      expect(created.totalAmountVnd, equals(250000));

      // Kiểm tra lấy lại qua getOrderById
      final fetched = await repo.getOrderById('ord_voucher_test_001');
      expect(fetched.voucherCode, equals('ARTKIDS10'));
      expect(fetched.discountVnd, equals(25000));
    });

    test('OrderModel serializes and deserializes voucher_code correctly', () {
      final json = {
        'id': 'ord_json_voucher',
        'order_code': 'ORD-2026-7777',
        'created_at': '2026-03-20T10:00:00.000Z',
        'status': 'pending_confirmation',
        'order_type': 'one_time_purchase',
        'payment_status': 'paid',
        'payment_method_name': 'VietQR',
        'items': [],
        'shipping_info': {
          'recipient_name': 'Tester',
          'phone_number': '0901234567',
          'full_address': 'TP.HCM',
        },
        'subtotal_vnd': 300000,
        'shipping_fee_vnd': 0,
        'discount_vnd': 30000,
        'voucher_code': 'ARTKIDS10',
        'total_amount_vnd': 270000,
      };

      final model = OrderModel.fromJson(json);
      expect(model.voucherCode, equals('ARTKIDS10'));
      expect(model.discountVnd, equals(30000));

      final serialized = model.toJson();
      expect(serialized['voucher_code'], equals('ARTKIDS10'));
      expect(serialized['discount_vnd'], equals(30000));
    });
  });
}
