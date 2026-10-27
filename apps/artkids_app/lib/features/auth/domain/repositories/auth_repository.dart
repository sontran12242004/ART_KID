import '../entities/child_profile.dart';
import '../entities/parent_user.dart';

abstract class AuthRepository {
  Future<ParentUser> login({required String email, required String password});
  Future<ParentUser> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> recordParentalConsent();
  Future<List<ChildProfile>> getChildren();
  Future<ChildProfile> createChild({
    required String nickname,
    required int birthYear,
  });
  Future<bool> verifyKidPin(String pin);
}
