import '../../../../core/network/api_json.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/entities/parent_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

ParentUser parentFromApi(dynamic value) {
  final v = apiMap(value);
  return ParentUser(
    id: v['id'],
    email: v['email'],
    fullName: v['full_name'] ?? '',
    displayName: v['display_name'] ?? v['full_name'] ?? '',
    role: v['role'] ?? 'parent',
    phoneNumber: v['phone_number'],
    hasCompletedCoppaConsent: v['has_completed_coppa_consent'] ?? false,
  );
}

ChildProfile childFromApi(dynamic value) {
  final v = apiMap(value);
  final year = v['birth_year'] as int;
  return ChildProfile(
    id: v['id'],
    parentId: v['parent_id'],
    nickname: v['nickname'],
    birthYear: year,
    age: DateTime.now().year - year,
    avatarUrl: v['avatar_url'],
    totalPoints: v['total_points'] ?? 0,
  );
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remote);
  final AuthRemoteDataSource remote;
  @override
  Future<ParentUser> login({
    required String email,
    required String password,
  }) async => parentFromApi(await remote.login(email, password));
  @override
  Future<ParentUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async => parentFromApi(
    (await remote.dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'fullName': displayName},
    )).data,
  );
  @override
  Future<List<ChildProfile>> getChildren() async => apiList(
    (await remote.dio.get('/children')).data,
  ).map(childFromApi).toList();
  @override
  Future<ChildProfile> createChild({
    required String nickname,
    required int birthYear,
  }) async => childFromApi(
    (await remote.dio.post(
      '/children',
      data: {'nickname': nickname, 'birthYear': birthYear},
    )).data,
  );
  @override
  Future<void> recordParentalConsent() async {
    for (final child in await getChildren()) {
      await remote.dio.post(
        '/auth/consent',
        data: {
          'childId': child.id,
          'purpose': 'data_processing',
          'policyVersion': '1',
        },
      );
    }
  }

  @override
  Future<bool> verifyKidPin(String pin) async =>
      (await remote.verifyKidPin(pin))['valid'] == true;
}
