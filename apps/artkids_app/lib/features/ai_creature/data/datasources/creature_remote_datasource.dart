import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/ai_creature_model.dart';

abstract class CreatureRemoteDataSource {
  Future<AiCreatureModel> getCreatureById(String creatureId);
  Future<List<AiCreatureModel>> getCreaturesByChildId(String childId);
  Future<String> checkJobStatus(String submissionId);
}

class CreatureRemoteDataSourceImpl implements CreatureRemoteDataSource {
  CreatureRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AiCreatureModel> getCreatureById(String creatureId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.kidCreatures}/$creatureId',
    );
    return AiCreatureModel.fromJson(response.data ?? {});
  }

  @override
  Future<List<AiCreatureModel>> getCreaturesByChildId(String childId) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.kidCreatures,
      queryParameters: {'child_id': childId},
    );
    return (response.data ?? [])
        .map((item) => AiCreatureModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> checkJobStatus(String submissionId) async {
    final endpoint = ApiConstants.kidSubmissionStatus.replaceAll('{id}', submissionId);
    final response = await _dio.get<Map<String, dynamic>>(endpoint);
    return response.data?['status'] as String? ?? 'pending';
  }
}
