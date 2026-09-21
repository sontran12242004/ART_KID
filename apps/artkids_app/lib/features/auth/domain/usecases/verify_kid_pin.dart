import '../repositories/auth_repository.dart';

class VerifyKidPinUseCase {
  const VerifyKidPinUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call({required String pin}) {
    return _repository.verifyKidPin(pin);
  }
}
