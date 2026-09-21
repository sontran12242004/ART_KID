import '../entities/ai_creature.dart';
import '../repositories/creature_repository.dart';

class GetCreatureByIdUseCase {
  const GetCreatureByIdUseCase(this._repository);

  final CreatureRepository _repository;

  Future<AiCreature> call(String creatureId) =>
      _repository.getCreatureById(creatureId);
}

class GetCreaturesByChildUseCase {
  const GetCreaturesByChildUseCase(this._repository);

  final CreatureRepository _repository;

  Future<List<AiCreature>> call(String childId) =>
      _repository.getCreaturesByChildId(childId);
}

class CheckAiJobStatusUseCase {
  const CheckAiJobStatusUseCase(this._repository);

  final CreatureRepository _repository;

  /// Trả về trạng thái job: pending | processing | done | failed
  Future<String> call(String submissionId) =>
      _repository.checkJobStatus(submissionId);
}
