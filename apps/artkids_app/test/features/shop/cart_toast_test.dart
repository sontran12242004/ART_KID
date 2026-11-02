import 'dart:async';

import 'package:artkids_app/features/shop/data/models/product.dart';
import 'package:artkids_app/features/shop/domain/enums/product_category.dart';
import 'package:artkids_app/features/shop/presentation/providers/cart_provider.dart';
import 'package:artkids_app/features/shop/presentation/providers/shop_catalog_provider.dart';
import 'package:artkids_app/features/shop/presentation/screens/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const product = Product(
  id: 'brushes',
  name: 'Bộ cọ thử nghiệm',
  priceVnd: 100000,
  thumbnailUrl: '',
  description: 'Bộ cọ cho bé',
  category: ProductCategory.individualTool,
);

class PendingCart extends CartNotifier {
  final result = Completer<bool>();
  int? requestedQuantity;
  @override
  Future<bool> addToCart(Product product, {int quantity = 1}) {
    requestedQuantity = quantity;
    return result.future;
  }
}

Future<void> pumpProduct(
  WidgetTester tester, {
  CartNotifier? cart,
  String? error,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const ProductDetailScreen(productId: 'brushes'),
      ),
      GoRoute(
        path: '/parent/shop/cart',
        builder: (_, _) => const Scaffold(body: Text('Cart destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productDetailProvider('brushes').overrideWith((ref) async => product),
        cartProvider.overrideWith((ref) => cart ?? CartNotifier()),
        cartSyncErrorProvider.overrideWith((ref) => error),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('toast reports the quantity sent, not a later selection', (
    tester,
  ) async {
    final cart = PendingCart();
    await pumpProduct(tester, cart: cart);
    await tester.tap(find.text('Thêm Vào Giỏ Hàng'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(cart.requestedQuantity, 1);
    cart.result.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Đã thêm 1 món vào giỏ hàng!'), findsOneWidget);
    expect(find.text('Đã thêm 2 món vào giỏ hàng!'), findsNothing);
  });

  testWidgets('failed add shows the error once without a success toast', (
    tester,
  ) async {
    final cart = PendingCart();
    await pumpProduct(tester, cart: cart, error: 'Học cụ vừa hết hàng.');
    await tester.tap(find.text('Thêm Vào Giỏ Hàng'));
    await tester.pump();
    cart.result.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Học cụ vừa hết hàng.'), findsOneWidget);
    expect(find.textContaining('Đã thêm'), findsNothing);
    expect(find.text('XEM GIỎ'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'add-to-cart toast expires even though it has a View Cart action',
    (tester) async {
      await pumpProduct(tester);
      await tester.tap(find.text('Thêm Vào Giỏ Hàng'));
      await tester.pumpAndSettle();
      expect(find.text('Đã thêm 1 món vào giỏ hàng!'), findsOneWidget);
      expect(find.text('XEM GIỎ'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('View Cart toast action still opens the actual cart route', (
    tester,
  ) async {
    await pumpProduct(tester);
    await tester.tap(find.text('Thêm Vào Giỏ Hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XEM GIỎ'));
    await tester.pumpAndSettle();
    expect(find.text('Cart destination'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
