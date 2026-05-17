import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../providers/app_providers.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/friends/providers/friend_provider.dart';
import '../../features/home/providers/user_provider.dart';

/// İstifadəçi auth-da olduqda Supabase Realtime-ə qoşulub `friendships`
/// cədvəlində öz user-iylə bağlı dəyişiklikləri izləyir. Hər INSERT/UPDATE/
/// DELETE event-i FriendsProvider-i refresh edir.
class RealtimeService {
  final Ref _ref;
  RealtimeChannel? _channel;
  String? _currentUserId;

  RealtimeService(this._ref);

  void connectFor(String userId) {
    if (_currentUserId == userId && _channel != null) return;
    disconnect();
    _currentUserId = userId;
    debugPrint('[rt] subscribe friendships for user=${userId.substring(0, 8)}');

    final client = _ref.read(supabaseClientProvider);
    _channel = client.channel('friendships:$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'friendships',
        callback: (payload) {
          // RLS yalnız öz user-ə aid row-ları görür → əlavə filter lazım deyil.
          debugPrint('[rt] ← friendships ${payload.eventType.name}');
          try {
            _ref.read(friendsProvider.notifier).refresh();
          } catch (e) {
            debugPrint('[rt] friends refresh failed: $e');
          }
        },
      )
      ..subscribe();
  }

  void disconnect() {
    _channel?.unsubscribe();
    _channel = null;
    _currentUserId = null;
  }
}

/// Provider — auth dəyişəndə avtomatik connect/disconnect edir.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref);
  ref.onDispose(service.disconnect);
  ref.listen<AsyncValue<AuthState>>(authProvider, (prev, next) {
    next.whenData((s) {
      if (s.status == AuthStatus.authenticated) {
        final profile = ref.read(userProfileProvider).valueOrNull;
        if (profile != null) service.connectFor(profile.id);
      } else {
        service.disconnect();
      }
    });
  });
  ref.listen<AsyncValue>(userProfileProvider, (prev, next) {
    next.whenData((p) {
      if (p?.id != null) service.connectFor(p.id as String);
    });
  });
  return service;
});
