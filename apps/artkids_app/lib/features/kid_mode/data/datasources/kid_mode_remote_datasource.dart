import 'package:dio/dio.dart';
import '../models/kid_reward_model.dart';

abstract class KidModeRemoteDataSource {
  Future<List<KidRewardModel>> getRewards(String childId);
  Future<int> getTotalPoints(String childId);
}

class KidModeRemoteDataSourceImpl implements KidModeRemoteDataSource {
  KidModeRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<KidRewardModel>> getRewards(String childId) async {
    final response = await _dio.get<List<dynamic>>(
      '/kid/rewards',
      queryParameters: {'child_id': childId},
    );
    return (response.data ?? [])
        .map((item) => KidRewardModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getTotalPoints(String childId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/kid/points',
      queryParameters: {'child_id': childId},
    );
    return response.data?['total_points'] as int? ?? 0;
  }
}
