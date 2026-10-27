import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../domain/enums/product_category.dart';

/// Provider lưu giữ danh mục sản phẩm đang được lọc
final selectedProductCategoryProvider = StateProvider<ProductCategory>((ref) {
  return ProductCategory.all;
});

/// Provider lưu từ khóa tìm kiếm sản phẩm
final productSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Provider danh sách sản phẩm theo bộ lọc category và từ khóa tìm kiếm
final shopCatalogProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  final repository = ref.watch(productRepositoryProvider);
  final category = ref.watch(selectedProductCategoryProvider);
  final query = ref.watch(productSearchQueryProvider);

  return repository.getProducts(category: category, searchQuery: query);
});

/// Provider chi tiết 1 sản phẩm theo ID
final productDetailProvider = FutureProvider.autoDispose
    .family<Product, String>((ref, productId) async {
      final repository = ref.watch(productRepositoryProvider);
      return repository.getProductById(productId);
    });
