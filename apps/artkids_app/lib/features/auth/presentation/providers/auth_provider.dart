import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/entities/parent_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_parent.dart';
import '../../domain/usecases/verify_kid_pin.dart';
import '../../../../core/network/dio_client.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSourceImpl(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

final loginParentUseCaseProvider = Provider<LoginParentUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginParentUseCase(repository);
});

final verifyKidPinUseCaseProvider = Provider<VerifyKidPinUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyKidPinUseCase(repository);
});

class AuthState {
  const AuthState({
    this.currentUser,
    this.selectedChild,
    this.children = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final ParentUser? currentUser;
  final ChildProfile? selectedChild;
  final List<ChildProfile> children;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    ParentUser? currentUser,
    ChildProfile? selectedChild,
    List<ChildProfile>? children,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      selectedChild: selectedChild ?? this.selectedChild,
      children: children ?? this.children,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._loginUseCase, this._repository) : super(const AuthState());

  final LoginParentUseCase _loginUseCase;
  final AuthRepository _repository;

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _loginUseCase(email: email, password: password);
      final children = await _repository.getChildren();
      state = state.copyWith(
        currentUser: user,
        children: children,
        selectedChild: children.isNotEmpty ? children.first : null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectChild(ChildProfile child) {
    state = state.copyWith(selectedChild: child);
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginParentUseCaseProvider);
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(loginUseCase, repo);
});
