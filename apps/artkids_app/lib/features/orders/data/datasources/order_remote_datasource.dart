import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/order.dart';

/// Datasource gọi API từ commerce-service / fulfillment-service qua Dio
abstract class OrderRemoteDataSource {
  /// Lấy danh sách đơn hàng có phân trang và lọc theo trạng thái
  Future<List<OrderModel>> getOrders({
    String? status,
    int page = 1,
    int limit = 10,
  });

  /// Lấy thông tin chi tiết của 1 đơn hàng theo ID
  Future<OrderModel> getOrderById(String orderId);

  /// Hủy 1 đơn hàng (khi đơn còn ở trạng thái chờ xác nhận)
  Future<void> cancelOrder(String orderId, {String? reason});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<OrderModel>> getOrders({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    // TODO: Xác nhận endpoint thật và cấu trúc response (phân trang meta) với backend commerce-service
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _dio.get<dynamic>(
      ApiConstants.orders,
      queryParameters: queryParams,
    );

    final data = response.data;
    List<dynamic> listData = [];

    if (data is List) {
      listData = data;
    } else if (data is Map<String, dynamic>) {
      // Một số backend bọc trong { "data": [...], "meta": {...} }
      listData = (data['data'] as List<dynamic>?) ??
          (data['orders'] as List<dynamic>?) ??
          [];
    }

    return listData
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    // TODO: Xác nhận endpoint thật với backend fulfillment-service
    final endpoint = ApiConstants.orderDetail.replaceAll('{id}', orderId);
    final response = await _dio.get<dynamic>(endpoint);

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final orderJson = (data['data'] as Map<String, dynamic>?) ?? data;
      return OrderModel.fromJson(orderJson);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Định dạng dữ liệu đơn hàng không hợp lệ từ máy chủ.',
    );
  }

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    // TODO: Xác nhận endpoint và body request thật khi hủy đơn
    final endpoint = ApiConstants.orderCancel.replaceAll('{id}', orderId);
    await _dio.post(
      endpoint,
      data: {
        'order_id': orderId,
        'reason': ?reason,
      },
    );
  }
}
