import 'package:hiddify/features/auth/data/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<bool> build() async {
    return ref.watch(authRepositoryProvider).isAuthenticated();
  }

  Future<void> login(String username, String password) async {
    final authRepo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await authRepo.login(username, password);
      return true;
    });
  }

  Future<void> logout() async {
    final authRepo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await authRepo.logout();
      return false;
    });
  }
}
