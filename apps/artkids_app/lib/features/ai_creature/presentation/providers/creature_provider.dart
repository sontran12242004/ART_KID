import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/creature_remote_datasource.dart';
import '../../data/repositories/creature_repository_impl.dart';
import '../../domain/entities/ai_creature.dart';
import '../../domain/repositories/creature_repository.dart';

final creatureRemoteDataSourceProvider = Provider<CreatureRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return CreatureRemoteDataSourceImpl(dio);
});

final creatureRepositoryProvider = Provider<CreatureRepository>((ref) {
  final remote = ref.watch(creatureRemoteDataSourceProvider);
  return CreatureRepositoryImpl(remote);
});

final creatureDetailProvider =
    FutureProvider.family<AiCreature, String>((ref, creatureId) async {
  final repo = ref.watch(creatureRepositoryProvider);
  return repo.getCreatureById(creatureId);
});

final childCreaturesProvider =
    FutureProvider.family<List<AiCreature>, String>((ref, childId) async {
  final repo = ref.watch(creatureRepositoryProvider);
  return repo.getCreaturesByChildId(childId);
});
