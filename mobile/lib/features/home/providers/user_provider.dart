import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider), ref.watch(storageProvider));
});

/// Auth status-a abunədir — login/logout dəyişəndə avtomatik yenidən fetch edir.
/// Bu olmasa 401 cache-də qalır və login sonra `/users/me` çağırılmır.
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final auth = ref.watch(authProvider);
  final isAuth = auth.whenOrNull(data: (s) => s.status == AuthStatus.authenticated) ?? false;
  if (!isAuth) {
    throw StateError('not_authenticated');
  }
  return ref.watch(userRepositoryProvider).getMe();
});
