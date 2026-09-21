import 'package:dio/dio.dart';
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
    final response = await _dio.get<List<dynamic>>(ApiConstants.subscriptions);
    return (response.data ?? [])
        .map((item) => SubscriptionPlanModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> checkout({required String planId}) async {
    await _dio.post(ApiConstants.checkout, data: {'plan_id': planId});
  }
}
