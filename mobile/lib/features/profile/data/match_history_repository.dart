import 'package:supabase_flutter/supabase_flutter.dart';

enum MatchOutcome { win, loss, draw, solo }

MatchOutcome _parseOutcome(String? raw) => switch (raw) {
      'win' => MatchOutcome.win,
      'loss' => MatchOutcome.loss,
      'draw' => MatchOutcome.draw,
      _ => MatchOutcome.solo,
    };

class MatchOpponent {
  final String userId;
  final String username;
  final int score;
  final int correctAnswers;
  const MatchOpponent({
    required this.userId,
    required this.username,
    required this.score,
    required this.correctAnswers,
  });
}

class MatchHistoryEntry {
  final String matchId;
  final String type; // 'solo' | '1v1' | 'tournament'
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final MatchOutcome outcome;
  final int myScore;
  final int myCorrect;
  final MatchOpponent? opponent;

  const MatchHistoryEntry({
    required this.matchId,
    required this.type,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.outcome,
    required this.myScore,
    required this.myCorrect,
    required this.opponent,
  });

  /// `get_match_history` RPC flat snake_case row qaytarır.
  factory MatchHistoryEntry.fromRow(Map<String, dynamic> j) {
    final oppId = j['opponent_id'] as String?;
    final oppUsername = j['opponent_username'] as String?;
    return MatchHistoryEntry(
      matchId: j['match_id'] as String,
      type: j['type'] as String,
      status: j['status'] as String,
      startedAt: j['started_at'] != null ? DateTime.tryParse(j['started_at'] as String) : null,
      endedAt: j['ended_at'] != null ? DateTime.tryParse(j['ended_at'] as String) : null,
      outcome: _parseOutcome(j['outcome'] as String?),
      myScore: ((j['my_score'] as num?) ?? 0).toInt(),
      myCorrect: ((j['my_correct'] as num?) ?? 0).toInt(),
      opponent: (oppId == null || oppUsername == null)
          ? null
          : MatchOpponent(
              userId: oppId,
              username: oppUsername,
              score: ((j['opponent_score'] as num?) ?? 0).toInt(),
              correctAnswers: ((j['opponent_correct'] as num?) ?? 0).toInt(),
            ),
    );
  }
}

class MatchHistoryRepository {
  final SupabaseClient _client;
  const MatchHistoryRepository(this._client);

  Future<List<MatchHistoryEntry>> getHistory() async {
    try {
      final response = await _client.rpc('get_match_history');
      final list = response as List<dynamic>;
      return list
          .map((e) => MatchHistoryEntry.fromRow(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
