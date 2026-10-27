import 'package:artkids_app/core/network/api_json.dart';
import 'package:artkids_app/features/orders/data/models/order.dart';
import 'package:artkids_app/features/shop/data/repositories/product_repository.dart';
import 'package:artkids_app/features/shop/data/repositories/voucher_repository.dart';
import 'package:artkids_app/features/shop/presentation/providers/cart_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/http_fixture.dart';

const product = {
  'id': 'prod_kit',
  'name': 'Drawing kit',
  'priceVnd': 180000,
  'description': 'Kit',
  'category': 'course_kit',
  'thumbnailUrl': '',
};
void main() {
  test('uploaded product images resolve against the API origin', () async {
    final image = '/api/v1/media/products/image_1';
    final dio = fixtureDio(
      (_) => jsonResponse({
        'product': {
          ...product,
          'thumbnailUrl': image,
          'images': [image],
        },
        'inStock': true,
      }),
    );
    final result = await ProductRepositoryImpl(dio).getProductById('prod_kit');
    expect(result.thumbnailUrl, 'http://test.local$image');
    expect(result.images, ['http://test.local$image']);
  });
  test(
    'rapid cart increments serialize against the latest server quantity',
    () async {
      var quantity = 1;
      final notifier = CartNotifier(
        fixtureDio((r) {
          if (r.method == 'PUT') quantity = r.data['quantity'] as int;
          return jsonResponse({
            'items': [
              {'id': 'cartrow', 'product': product, 'quantity': quantity},
            ],
          });
        }),
      );
      addTearDown(notifier.dispose);
      await notifier.load();
      await Future.wait([
        notifier.incrementQuantity('prod_kit'),
        notifier.incrementQuantity('prod_kit'),
      ]);
      expect(notifier.state.single.quantity, 3);
    },
  );
  test(
    'catalog unwraps ASP.NET paged product responses and server stock',
    () async {
      final dio = fixtureDio((r) {
        expect(r.queryParameters['pageSize'], 20);
        return jsonResponse({
          'total': 1,
          'items': [
            {'product': product, 'inStock': false},
          ],
        });
      });
      final items = await ProductRepositoryImpl(dio).getProducts();
      expect(items.single.id, 'prod_kit');
      expect(items.single.priceVnd, 180000);
      expect(items.single.inStock, false);
    },
  );
  test(
    'server failure never falls back to fabricated catalog products',
    () async {
      final repo = ProductRepositoryImpl(
        fixtureDio(
          (_) => jsonResponse({'title': 'Service unavailable'}, status: 503),
        ),
      );
      await expectLater(repo.getProducts(), throwsA(isA<DioException>()));
    },
  );
  test(
    'cart uses product ID rather than cart-row ID and preserves accepted state on failure',
    () async {
      var calls = 0;
      String? error;
      final dio = fixtureDio((r) {
        calls++;
        if (calls == 1) {
          return jsonResponse({
            'items': [
              {
                'id': 'cart_row_01',
                'productId': 'prod_kit',
                'quantity': 2,
                'product': product,
              },
            ],
          });
        }
        expect(r.data['productId'], 'prod_kit');
        return jsonResponse({'title': 'Out of stock'}, status: 409);
      });
      final notifier = CartNotifier(dio, (e) => error = e);
      addTearDown(notifier.dispose);
      expect(await notifier.load(), true);
      expect(notifier.state.single.product.id, 'prod_kit');
      expect(notifier.state.single.totalPriceVnd, 360000);
      expect(await notifier.incrementQuantity('prod_kit'), false);
      expect(error, isNotNull);
      expect(notifier.state.single.quantity, 2);
    },
  );
  test(
    'voucher validation sends server subtotal and uses server discount',
    () async {
      final repo = VoucherRepositoryImpl(
        fixtureDio((r) {
          expect(r.data, {'code': 'ARTKIDS10', 'subtotalVnd': 250000});
          return jsonResponse({
            'isValid': true,
            'discountAmountVnd': 25000,
            'voucher': {
              'code': 'ARTKIDS10',
              'title': 'Discount',
              'discountType': 'percentage',
              'discountValue': 10,
              'expiryDate': '2099-01-01T00:00:00Z',
            },
          });
        }),
      );
      final result = await repo.validateVoucher(
        code: ' artkids10 ',
        orderSubtotalVnd: 250000,
      );
      expect(result.isValid, true);
      expect(result.discountAmountVnd, 25000);
    },
  );
  test(
    'order wrapper preserves monetary amounts, item title and UTC timestamps',
    () {
      final model = OrderModel.fromJson(
        apiOrder({
          'order': {
            'id': 'order_1',
            'orderCode': 'AK-1',
            'createdAt': '2026-10-21T08:00:00Z',
            'status': 'pending_confirmation',
            'paymentStatus': 'pending',
            'subtotalVnd': 180000,
            'shippingFeeVnd': 30000,
            'totalAmountVnd': 210000,
          },
          'items': [
            {
              'id': 'item_1',
              'title': 'Drawing kit',
              'quantity': 1,
              'unitPriceVnd': 180000,
            },
          ],
          'shippingInfo': null,
          'trackingEvents': [],
        }),
      );
      expect(model.totalAmountVnd, 210000);
      expect(model.shippingFeeVnd, 30000);
      expect(model.items.single.kitName, 'Drawing kit');
      expect(model.createdAt, DateTime.utc(2026, 10, 21, 8));
    },
  );
}
