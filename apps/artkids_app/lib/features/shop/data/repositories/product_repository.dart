import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_json.dart';
import '../../domain/enums/product_category.dart';
import '../models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(ref.watch(dioProvider)),
);

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    ProductCategory? category,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  });
  Future<Product> getProductById(String id);
}

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this.dio);
  final Dio dio;
  Product _product(dynamic value) {
    return Product.fromJson(apiProduct(value, baseUrl: dio.options.baseUrl));
  }

  @override
  Future<List<Product>> getProducts({
    ProductCategory? category,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get(
      '/shop/products',
      queryParameters: {
        'page': page,
        'pageSize': limit,
        if (category != null && category != ProductCategory.all)
          'category': category.value,
        if (searchQuery?.isNotEmpty == true) 'search': searchQuery,
      },
    );
    return apiList(response.data).map(_product).toList();
  }

  @override
  Future<Product> getProductById(String id) async =>
      _product((await dio.get('/shop/products/$id')).data);
}
