import 'dart:convert';
import 'dart:typed_data';
import 'package:artkids_app/core/network/dio_client.dart';
import 'package:artkids_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:artkids_app/features/connected/data/connected_api.dart';
import 'package:artkids_app/features/connected/presentation/course_product_screens.dart';
import 'package:artkids_app/features/connected/presentation/marketplace_screens.dart';
import 'package:artkids_app/features/connected/presentation/seller_order_screens.dart';
import 'package:artkids_app/features/shop/data/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/http_fixture.dart';

const product = <String, dynamic>{
  'id': 'seller-product',
  'name': 'Teacher brushes',
  'priceVnd': 125000,
  'description': 'Four brushes.',
  'courseId': null,
  'thumbnailUrl': '/api/v1/media/products/image-1',
  'isAvailable': true,
  'approvalStatus': 'rejected',
  'rejectionReason': 'Describe the brushes',
  'revision': 3,
  'createdBy': 'teacher-1',
  'fulfillmentMode': 'seller',
};

void main() {
  test('seller order thumbnails resolve against the API origin', () async {
    final dio = fixtureDio(
      (_) => jsonResponse({
        'order': {'id': 'order-1'},
        'items': [
          {
            'id': 'line-1',
            'title': 'Teacher brushes',
            'thumbnailUrl': '/api/v1/media/products/image-1',
          },
        ],
      }),
    );
    final order = await OrderRemoteDataSourceImpl(dio).getOrderById('order-1');
    expect(
      order.items.single.thumbnailUrl,
      'http://test.local/api/v1/media/products/image-1',
    );
  });
  testWidgets('reuses form, shows rejection and resubmits binary availability', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? submitted;
    final dio = fixtureDio((request) {
      if (request.method == 'PUT') {
        submitted = Map<String, dynamic>.from(request.data as Map);
      }
      return jsonResponse(product);
    });
    var saved = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          apiDataProvider(
            '/courses?pageSize=100',
          ).overrideWith((ref) async => {'items': []}),
          mediaBytesProvider('/media/image-1').overrideWith(
            (ref) async => Uint8List.fromList(
              base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aGnUAAAAASUVORK5CYII=',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: CourseProductPublishScreen(
            product: product,
            onSaved: () => saved = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Trạng thái: Bị từ chối'), findsOneWidget);
    expect(find.text('Lý do từ chối: Describe the brushes'), findsOneWidget);
    expect(find.text('Số lượng có sẵn'), findsNothing);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gửi duyệt lại'));
    await tester.tap(find.text('Gửi duyệt lại'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect(submitted, containsPair('isAvailable', false));
    expect(submitted, containsPair('expectedRevision', 3));
    expect(submitted, containsPair('courseId', null));
    expect(submitted!.containsKey('quantityAvailable'), isFalse);
  });

  testWidgets('admin rejection requires a reason before posting', (
    tester,
  ) async {
    final requests = <Map<String, dynamic>>[];
    final dio = fixtureDio((request) {
      if (request.method == 'POST') {
        requests.add(Map<String, dynamic>.from(request.data as Map));
      }
      return jsonResponse(product);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          apiDataProvider('/marketplace/reviews/seller-product').overrideWith(
            (ref) async => {...product, 'approvalStatus': 'pending'},
          ),
          mediaBytesProvider('/media/image-1').overrideWith(
            (ref) async => Uint8List.fromList(
              base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aGnUAAAAASUVORK5CYII=',
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MarketplaceListingDetail(id: 'seller-product', review: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Từ chối và gửi lý do'));
    await tester.tap(find.text('Từ chối và gửi lý do'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    await tester.enterText(
      find.byType(TextFormField),
      'Add safety information',
    );
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(requests.single, containsPair('status', 'rejected'));
    expect(requests.single, containsPair('reason', 'Add safety information'));
    expect(requests.single, containsPair('expectedRevision', 3));
  });

  testWidgets('seller shipping records carrier through marketplace API', (
    tester,
  ) async {
    final dio = fixtureDio((request) => jsonResponse({'status': 'preparing'}));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const MaterialApp(
          home: Scaffold(body: SellerShippingForm(orderId: 'order-1')),
        ),
      ),
    );
    await tester.tap(find.text('Lưu đơn vị vận chuyển'));
    await tester.pumpAndSettle();
    final request = (dio.httpClientAdapter as FixtureAdapter).requests.single;
    expect(request.path, '/marketplace/orders/order-1/fulfillment');
    expect(request.data, {
      'carrier': 'GHN',
      'trackingNumber': null,
      'status': 'preparing',
    });
  });

  test('catalog parser preserves binary out-of-stock status', () async {
    final dio = fixtureDio(
      (_) => jsonResponse({'product': product, 'inStock': false}),
    );
    final result = await ProductRepositoryImpl(
      dio,
    ).getProductById('seller-product');
    expect(result.inStock, isFalse);
    expect(result.priceVnd, 125000);
  });
}
