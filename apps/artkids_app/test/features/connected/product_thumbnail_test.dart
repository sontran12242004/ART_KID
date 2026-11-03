import 'dart:convert';
import 'dart:typed_data';

import 'package:artkids_app/features/connected/data/connected_api.dart';
import 'package:artkids_app/features/connected/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Cloudinary URL remains intact and never calls private media API',
    (tester) async {
      const url = 'https://res.cloudinary.com/demo/image/upload/v1/brushes.jpg';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaBytesProvider.overrideWith((ref, path) {
              fail('CDN image must not request private media: $path');
            }),
          ],
          child: const MaterialApp(home: ProductThumbnail(url: url)),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, url);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('legacy product image uses original product media endpoint', (
    tester,
  ) async {
    String? requested;
    final png = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaBytesProvider.overrideWith((ref, path) async {
            requested = path;
            return png;
          }),
        ],
        child: const MaterialApp(
          home: ProductThumbnail(url: '/api/v1/media/products/asset-123'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requested, '/media/products/asset-123');
    expect(tester.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());
  });
}
