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

Future<void> pumpProduct(WidgetTester tester) async {
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
        cartProvider.overrideWith((ref) => CartNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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
