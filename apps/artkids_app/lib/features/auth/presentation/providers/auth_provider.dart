import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/entities/parent_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_parent.dart';
import '../../domain/usecases/verify_kid_pin.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/session_store.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSourceImpl(dio, ref.read(sessionStoreProvider.notifier));
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
  AuthNotifier(this._loginUseCase, this._repository, [this._session])
    : super(const AuthState());
  final SessionStore? _session;

  Future<void> restore(Dio dio) async {
    if (_session?.state.accessToken == null) return;
    final user = parentFromApi((await dio.get('/auth/me')).data);
    final children = user.role == 'parent'
        ? await _repository.getChildren()
        : <ChildProfile>[];
    final selected =
        children.where((c) => c.id == _session?.selectedChildId).firstOrNull ??
        children.firstOrNull;
    state = AuthState(
      currentUser: user,
      children: children,
      selectedChild: selected,
    );
    _session?.selectChild(selected?.id);
  }

  final LoginParentUseCase _loginUseCase;
  final AuthRepository _repository;

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _loginUseCase(email: email, password: password);
      final children = user.role == 'parent'
          ? await _repository.getChildren()
          : <ChildProfile>[];
      state = state.copyWith(
        currentUser: user,
        children: children,
        selectedChild: children.isNotEmpty ? children.first : null,
        isLoading: false,
      );
      _session?.selectChild(state.selectedChild?.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void selectChild(ChildProfile child) {
    state = state.copyWith(selectedChild: child);
    _session?.selectChild(child.id);
  }

  void logout() {
    state = const AuthState();
  }

  Future<void> reloadChildren() async {
    final children = await _repository.getChildren();
    state = AuthState(
      currentUser: state.currentUser,
      children: children,
      selectedChild:
          children.where((c) => c.id == state.selectedChild?.id).firstOrNull ??
          children.firstOrNull,
    );
  }

  void updateUser(ParentUser user) => state = state.copyWith(currentUser: user);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginParentUseCaseProvider);
  final repo = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(
    loginUseCase,
    repo,
    ref.read(sessionStoreProvider.notifier),
  );
  ref.listen(sessionStoreProvider.select((s) => s.userId), (previous, next) {
    if (previous != null && next == null) notifier.logout();
  });
  return notifier;
});
