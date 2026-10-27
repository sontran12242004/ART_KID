import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/session_store.dart';
import '../../../../core/network/api_json.dart';
import '../../domain/entities/order_entity.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order.dart';

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>(
  (ref) => OrderRemoteDataSourceImpl(ref.watch(dioProvider)),
);
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  ref.watch(sessionStoreProvider.select((s) => s.userId));
  return OrderRepositoryImpl(ref.watch(orderRemoteDataSourceProvider));
});

abstract class OrderRepository {
  Future<List<OrderEntity>> getOrders({
    String? status,
    int page = 1,
    int limit = 10,
  });
  Future<OrderEntity> getOrderById(String orderId);
  Future<void> cancelOrder(String orderId, {String? reason});
  Future<OrderEntity> createOrder(OrderEntity order);
}

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this.remote);
  final OrderRemoteDataSource remote;
  @override
  Future<List<OrderEntity>> getOrders({
    String? status,
    int page = 1,
    int limit = 10,
  }) => remote.getOrders(status: status, page: page, limit: limit);
  @override
  Future<OrderEntity> getOrderById(String orderId) =>
      remote.getOrderById(orderId);
  @override
  Future<void> cancelOrder(String orderId, {String? reason}) =>
      remote.cancelOrder(orderId, reason: reason);
  @override
  Future<OrderEntity> createOrder(OrderEntity order) async {
    if (remote is! OrderRemoteDataSourceImpl) {
      throw StateError('Checkout requires a remote API.');
    }
    final result = await (remote as OrderRemoteDataSourceImpl).dio.post(
      '/commerce/checkout',
      data: {
        'idempotencyKey': order.id,
        'items': order.items
            .map(
              (i) => {
                'itemType': 'kit',
                'itemId': i.id,
                'quantity': i.quantity,
              },
            )
            .toList(),
        'voucherCode': order.voucherCode,
        'paymentMethod': order.paymentMethodName.toLowerCase().contains('cod')
            ? 'cod'
            : 'manual_transfer',
        'shipping': {
          'recipientName': order.shippingInfo.recipientName,
          'phoneNumber': order.shippingInfo.phoneNumber,
          'fullAddress': order.shippingInfo.fullAddress,
        },
      },
    );
    return OrderModel.fromJson(apiOrder(result.data));
  }
}
