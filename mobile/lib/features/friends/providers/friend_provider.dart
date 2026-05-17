import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../data/friend_repository.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(ref.watch(supabaseClientProvider));
});

class FriendsState {
  final List<FriendSummary> friends;
  final List<FriendSummary> incoming;
  final List<FriendSummary> outgoing;
  final List<FriendSummary> blocked;

  const FriendsState({
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
    this.blocked = const [],
  });

  FriendsState copyWith({
    List<FriendSummary>? friends,
    List<FriendSummary>? incoming,
    List<FriendSummary>? outgoing,
    List<FriendSummary>? blocked,
  }) =>
      FriendsState(
        friends: friends ?? this.friends,
        incoming: incoming ?? this.incoming,
        outgoing: outgoing ?? this.outgoing,
        blocked: blocked ?? this.blocked,
      );
}

class FriendsNotifier extends AsyncNotifier<FriendsState> {
  @override
  Future<FriendsState> build() async {
    return _load();
  }

  Future<FriendsState> _load() async {
    final repo = ref.read(friendRepositoryProvider);
    final results = await Future.wait([
      repo.listFriends(),
      repo.listPending(),
      repo.listBlocked(),
    ]);
    return FriendsState(
      friends: results[0] as List<FriendSummary>,
      incoming: (results[1] as PendingRequests).incoming,
      outgoing: (results[1] as PendingRequests).outgoing,
      blocked: results[2] as List<FriendSummary>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> sendRequest(String code) async {
    await ref.read(friendRepositoryProvider).sendRequest(code);
    await refresh();
  }

  Future<void> accept(String friendshipId) async {
    await ref.read(friendRepositoryProvider).accept(friendshipId);
    await refresh();
  }

  Future<void> removeOrDecline(String friendshipId) async {
    await ref.read(friendRepositoryProvider).removeOrDecline(friendshipId);
    await refresh();
  }

  Future<void> block(String code) async {
    await ref.read(friendRepositoryProvider).block(code);
    await refresh();
  }

  Future<void> unblock(String friendshipId) async {
    await ref.read(friendRepositoryProvider).unblock(friendshipId);
    await refresh();
  }
}

final friendsProvider =
    AsyncNotifierProvider<FriendsNotifier, FriendsState>(() => FriendsNotifier());
