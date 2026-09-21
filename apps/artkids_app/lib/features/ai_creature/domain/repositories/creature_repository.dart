import '../entities/ai_creature.dart';

abstract class CreatureRepository {
  Future<AiCreature> getCreatureById(String creatureId);
  Future<List<AiCreature>> getCreaturesByChildId(String childId);
  Future<String> checkJobStatus(String submissionId);
}
