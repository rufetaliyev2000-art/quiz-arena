import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardEntry {
  final String id;
  final String username;
  final String? avatar;
  final int elo;
  final int wins;
  final int losses;
  final int level;

  const LeaderboardEntry({
    required this.id,
    required this.username,
    this.avatar,
    required this.elo,
    required this.wins,
    required this.losses,
    required this.level,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        id: j['id'] as String,
        username: j['username'] as String,
        avatar: j['avatar'] as String?,
        elo: (j['elo'] as num).toInt(),
        wins: (j['wins'] as num).toInt(),
        losses: (j['losses'] as num).toInt(),
        level: (j['level'] as num).toInt(),
      );
}

class LeaderboardRepository {
  final SupabaseClient _client;
  const LeaderboardRepository(this._client);

  Future<List<LeaderboardEntry>> getTop({int limit = 50}) async {
    try {
      final response = await _client.rpc('get_leaderboard', params: {'p_limit': limit});
      final list = response as List<dynamic>;
      return list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
