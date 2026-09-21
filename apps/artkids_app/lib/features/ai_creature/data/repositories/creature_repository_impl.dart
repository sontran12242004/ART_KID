import '../../domain/entities/ai_creature.dart';
import '../../domain/repositories/creature_repository.dart';
import '../datasources/creature_remote_datasource.dart';

class CreatureRepositoryImpl implements CreatureRepository {
  CreatureRepositoryImpl(this._remoteDataSource);

  final CreatureRemoteDataSource _remoteDataSource;

  @override
  Future<AiCreature> getCreatureById(String creatureId) =>
      _remoteDataSource.getCreatureById(creatureId);

  @override
  Future<List<AiCreature>> getCreaturesByChildId(String childId) =>
      _remoteDataSource.getCreaturesByChildId(childId);

  @override
  Future<String> checkJobStatus(String submissionId) =>
      _remoteDataSource.checkJobStatus(submissionId);
}
