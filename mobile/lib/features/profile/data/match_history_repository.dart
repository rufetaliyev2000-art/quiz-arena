import 'package:dio/dio.dart';

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

  factory MatchOpponent.fromJson(Map<String, dynamic> j) => MatchOpponent(
        userId: j['userId'] as String,
        username: j['username'] as String,
        score: (j['score'] as num).toInt(),
        correctAnswers: (j['correctAnswers'] as num).toInt(),
      );
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

  factory MatchHistoryEntry.fromJson(Map<String, dynamic> j) => MatchHistoryEntry(
        matchId: j['matchId'] as String,
        type: j['type'] as String,
        status: j['status'] as String,
        startedAt: j['startedAt'] != null ? DateTime.tryParse(j['startedAt'] as String) : null,
        endedAt: j['endedAt'] != null ? DateTime.tryParse(j['endedAt'] as String) : null,
        outcome: _parseOutcome(j['outcome'] as String?),
        myScore: (j['myScore'] as num).toInt(),
        myCorrect: (j['myCorrect'] as num).toInt(),
        opponent: j['opponent'] == null
            ? null
            : MatchOpponent.fromJson(j['opponent'] as Map<String, dynamic>),
      );
}

class MatchHistoryRepository {
  final Dio _dio;
  const MatchHistoryRepository(this._dio);

  Future<List<MatchHistoryEntry>> getHistory() async {
    try {
      final response = await _dio.get('/matches/history');
      final list = response.data as List;
      return list
          .map((e) => MatchHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return const [];
    }
  }
}
