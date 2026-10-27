import 'package:dio/dio.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/subscription_plan_model.dart';

abstract class ShopRemoteDataSource {
  Future<List<SubscriptionPlanModel>> getPlans();
  Future<void> checkout({required String planId});
}

class ShopRemoteDataSourceImpl implements ShopRemoteDataSource {
  ShopRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    final response = await _dio.get<List<dynamic>>('/commerce/plans');
    return (response.data ?? [])
        .map((item) => SubscriptionPlanModel.fromJson(apiMap(item)))
        .toList();
  }

  @override
  Future<void> checkout({required String planId}) async {
    await _dio.post(
      ApiConstants.checkout,
      data: {
        'idempotencyKey': 'plan-${DateTime.now().microsecondsSinceEpoch}',
        'items': [
          {'itemType': 'subscription', 'itemId': planId, 'quantity': 1},
        ],
      },
    );
  }
}
