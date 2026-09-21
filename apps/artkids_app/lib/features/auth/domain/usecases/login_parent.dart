import '../entities/parent_user.dart';
import '../repositories/auth_repository.dart';

class LoginParentUseCase {
  const LoginParentUseCase(this._repository);

  final AuthRepository _repository;

  Future<ParentUser> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
