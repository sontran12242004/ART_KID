import '../../domain/entities/child_profile.dart';
import '../../domain/entities/parent_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<ParentUser> login({required String email, required String password}) async {
    final data = await _remote.login(email, password);
    return ParentUser(
      id: data['id'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
    );
  }

  @override
  Future<ParentUser> register({required String email, required String password, required String displayName}) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordParentalConsent() => throw UnimplementedError();

  @override
  Future<List<ChildProfile>> getChildren() => throw UnimplementedError();

  @override
  Future<ChildProfile> createChild({required String nickname, required int birthYear}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyKidPin(String pin) async {
    final data = await _remote.verifyKidPin(pin);
    return data['valid'] as bool? ?? false;
  }
}
