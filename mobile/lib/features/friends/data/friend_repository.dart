import 'package:supabase_flutter/supabase_flutter.dart';

class FriendSummary {
  final String friendshipId;
  final String userId;
  final String username;
  final String friendCode;
  final String? avatar;
  final int level;
  final int elo;

  const FriendSummary({
    required this.friendshipId,
    required this.userId,
    required this.username,
    required this.friendCode,
    this.avatar,
    required this.level,
    required this.elo,
  });

  /// RPC row-larında `friendship_id` snake_case; lookup-da yalnız user
  /// sahələri qaytarılır (friendship_id olmaya bilər).
  factory FriendSummary.fromRow(Map<String, dynamic> j) => FriendSummary(
        friendshipId: (j['friendship_id'] as String?) ?? '',
        userId: j['id'] as String,
        username: j['username'] as String,
        friendCode: (j['friend_code'] as String?) ?? '',
        avatar: j['avatar'] as String?,
        level: (j['level'] as num?)?.toInt() ?? 1,
        elo: (j['elo'] as num?)?.toInt() ?? 1000,
      );
}

class PendingRequests {
  final List<FriendSummary> incoming;
  final List<FriendSummary> outgoing;
  const PendingRequests({required this.incoming, required this.outgoing});
}

class FriendRepository {
  final SupabaseClient _client;
  const FriendRepository(this._client);

  Future<FriendSummary> lookupByCode(String code) async {
    final response = await _client.rpc('find_user_by_code', params: {'p_code': code});
    final list = response as List<dynamic>;
    if (list.isEmpty) {
      throw const FriendNotFoundException();
    }
    return FriendSummary.fromRow(list.first as Map<String, dynamic>);
  }

  Future<List<FriendSummary>> listFriends() async {
    final response = await _client.rpc('list_friends');
    final list = response as List<dynamic>;
    return list.map((e) => FriendSummary.fromRow(e as Map<String, dynamic>)).toList();
  }

  Future<PendingRequests> listPending() async {
    final response = await _client.rpc('list_pending_requests');
    final list = response as List<dynamic>;
    final all = list.map((e) => (e as Map<String, dynamic>)).toList();
    return PendingRequests(
      incoming: all.where((r) => r['direction'] == 'incoming').map(FriendSummary.fromRow).toList(),
      outgoing: all.where((r) => r['direction'] == 'outgoing').map(FriendSummary.fromRow).toList(),
    );
  }

  Future<List<FriendSummary>> listBlocked() async {
    final response = await _client.rpc('list_blocked');
    final list = response as List<dynamic>;
    return list.map((e) => FriendSummary.fromRow(e as Map<String, dynamic>)).toList();
  }

  /// `already_friends`, `already_pending`, `blocked`, `user_not_found`,
  /// `invalid_code_format` Supabase exception kimi qayıtsa kommunikasiya kodu
  /// `message`-də olur — caller `e.message.contains(...)` ilə yoxlasın.
  Future<({String id, String status})> sendRequest(String code) async {
    final response = await _client.rpc('send_friend_request', params: {'p_code': code});
    final list = response as List<dynamic>;
    final row = list.first as Map<String, dynamic>;
    return (id: row['id'] as String, status: row['status'] as String);
  }

  Future<void> accept(String friendshipId) async {
    await _client.rpc('accept_friend_request', params: {'p_friendship_id': friendshipId});
  }

  Future<void> removeOrDecline(String friendshipId) async {
    await _client.rpc('remove_friendship', params: {'p_friendship_id': friendshipId});
  }

  Future<void> block(String code) async {
    await _client.rpc('block_user', params: {'p_code': code});
  }

  Future<void> unblock(String friendshipId) async {
    await _client.rpc('unblock_user', params: {'p_friendship_id': friendshipId});
  }
}

class FriendNotFoundException implements Exception {
  const FriendNotFoundException();
}
