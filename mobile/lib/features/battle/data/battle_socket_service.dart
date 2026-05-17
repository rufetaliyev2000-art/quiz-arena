import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Realtime üzərindən 1v1 matchmaking və match yayımları.
///
/// Axın:
///   1. [joinQueue] çağırılır → RPC `join_matchmaking_queue`. Pair dərhal
///      tapılarsa [onMatchStart] callback dərhal çağrılır.
///   2. Tapılmırsa öz `matchmaking_queue` row-una postgres_changes UPDATE
///      subscribe edilir. Backend `try_find_match` çağırılana qədər
///      hər 5 saniyədə re-scan edirik (vaxt keçdikcə ELO toleransı genişlənir).
///   3. Match başladıqda hər iki tərəf eyni `match:<matchId>` broadcast
///      channel-ə qoşulur — cavablar, presence, və match result orada gedir.
///   4. Hər oyunçu öz nəticəsini bilərək [completeMatch] çağırır
///      ([finish_1v1] idempotent-dir; ikinci çağırış mövcud nəticəni qaytarır).
class BattleSocketService {
  final SupabaseClient _client;
  RealtimeChannel? _queueChannel;
  RealtimeChannel? _matchChannel;
  Timer? _rescanTimer;
  String? _currentMatchId;
  // Callback referansları — clearListeners()-də sıfırlamaq üçün.
  void Function()? _onWaiting;
  void Function(Map<String, dynamic>)? _onMatchStart;
  void Function(Map<String, dynamic>)? _onAnswerReceived;
  void Function(Map<String, dynamic>)? _onMatchResult;
  void Function()? _onOpponentDisconnected;
  void Function(Map<String, dynamic>)? _onError;

  BattleSocketService(this._client);

  bool get isConnected => _client.realtime.isConnected;

  /// İcra olunmasına ehtiyac yox — Supabase Realtime SDK öz idarə edir.
  /// API uyğunluğu üçün saxlanılır.
  void connect({void Function()? whenConnected, void Function(Object error)? onConnectError}) {
    debugPrint('[realtime] connect (managed by SDK)');
    whenConnected?.call();
  }

  /// Queue-yə qoşul. RPC dərhal pair tapsa match başladılır;
  /// tapmasa Realtime subscribe edirik.
  Future<void> joinQueue({
    required String userId,
    required String username,
    required int elo,
    String friendCode = '',
    Map<String, dynamic>? customization,
  }) async {
    debugPrint('[realtime] join_matchmaking_queue user=$username elo=$elo');
    try {
      final response = await _client.rpc('join_matchmaking_queue', params: {
        'p_elo': elo,
        'p_username': username,
        'p_friend_code': friendCode,
        'p_customization': customization ?? <String, dynamic>{},
      });
      final list = response as List<dynamic>;
      if (list.isEmpty) {
        _onError?.call({'message': 'JOIN_FAILED'});
        return;
      }
      final row = list.first as Map<String, dynamic>;
      final matchId = row['match_id'] as String?;
      final opponentId = row['opponent_user_id'] as String?;
      if (matchId != null && opponentId != null) {
        // Pair dərhal tapıldı — match başladıldı
        await _onMatchPaired(matchId: matchId, opponentId: opponentId, myUserId: userId);
        return;
      }
      // Queue-də qaldıq → Realtime subscribe + periodic re-scan
      _onWaiting?.call();
      _subscribeToQueue(userId, elo);
    } on PostgrestException catch (e) {
      debugPrint('[realtime] join failed: ${e.code} ${e.message}');
      if (e.message.contains('already_in_match')) {
        _onError?.call({'message': 'ALREADY_IN_MATCH'});
      } else {
        _onError?.call({'message': e.message});
      }
    }
  }

  void _subscribeToQueue(String userId, int elo) {
    _queueChannel?.unsubscribe();
    _queueChannel = _client.channel('queue:$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'matchmaking_queue',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) async {
          final newRecord = payload.newRecord;
          final matchId = newRecord['match_id'] as String?;
          final opponentId = newRecord['matched_with'] as String?;
          if (matchId != null && opponentId != null) {
            await _onMatchPaired(matchId: matchId, opponentId: opponentId, myUserId: userId);
          }
        },
      )
      ..subscribe();

    // Vaxt keçdikcə ELO toleransı genişlənir; periodik olaraq try_find_match çağır.
    _rescanTimer?.cancel();
    _rescanTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_currentMatchId != null) return;
      try {
        final response = await _client.rpc('try_find_match');
        final list = response as List<dynamic>;
        if (list.isEmpty) return;
        final row = list.first as Map<String, dynamic>;
        final matchId = row['match_id'] as String?;
        final opponentId = row['opponent_user_id'] as String?;
        if (matchId != null && opponentId != null) {
          await _onMatchPaired(matchId: matchId, opponentId: opponentId, myUserId: userId);
        }
      } catch (e) {
        debugPrint('[realtime] try_find_match error: $e');
      }
    });
  }

  Future<void> _onMatchPaired({
    required String matchId,
    required String opponentId,
    required String myUserId,
  }) async {
    if (_currentMatchId == matchId) return; // idempotent
    _currentMatchId = matchId;
    _rescanTimer?.cancel();
    _queueChannel?.unsubscribe();
    _queueChannel = null;

    // matches cədvəlindən match data al (question_indices, rəqibin queue row-u)
    final match = await _client
        .from('matches')
        .select('id, question_indices')
        .eq('id', matchId)
        .single();
    final indices = (match['question_indices'] as List).cast<int>();

    // Rəqibin queue row-u: username, elo, friend_code, customization
    final opp = await _client
        .from('matchmaking_queue')
        .select('user_id, username, elo, friend_code, customization')
        .eq('user_id', opponentId)
        .maybeSingle();
    final me = await _client
        .from('matchmaking_queue')
        .select('user_id, username, elo, friend_code, customization')
        .eq('user_id', myUserId)
        .maybeSingle();

    // Match broadcast channel-ə qoşul (cavablar üçün)
    _subscribeToMatch(matchId, myUserId, opponentId);

    final oppData = {
      'userId': opp?['user_id'] ?? opponentId,
      'username': opp?['username'] ?? '',
      'elo': opp?['elo'] ?? 1000,
      'friendCode': opp?['friend_code'] ?? '',
      'customization': opp?['customization'] ?? <String, dynamic>{},
    };
    final meData = {
      'userId': me?['user_id'] ?? myUserId,
      'username': me?['username'] ?? '',
      'elo': me?['elo'] ?? 1000,
      'friendCode': me?['friend_code'] ?? '',
      'customization': me?['customization'] ?? <String, dynamic>{},
    };

    _onMatchStart?.call({
      'matchId': matchId,
      'questionIndices': indices,
      'opponents': {
        myUserId: oppData,
        opponentId: meData,
      },
    });
  }

  void _subscribeToMatch(String matchId, String myUserId, String opponentId) {
    _matchChannel?.unsubscribe();
    _matchChannel = _client.channel('match:$matchId', opts: const RealtimeChannelConfig(self: false))
      ..onBroadcast(
        event: 'answer',
        callback: (payload) {
          // Yalnız rəqibin cavabını ötür (öz cavabımızı echo etməyə ehtiyac yox).
          if (payload['userId'] == myUserId) return;
          _onAnswerReceived?.call(Map<String, dynamic>.from(payload));
        },
      )
      ..onPresenceLeave((payload) {
        // Rəqib presence-dən çıxdı → disconnect
        if (payload.leftPresences.any((p) => p.payload['userId'] == opponentId)) {
          _onOpponentDisconnected?.call();
        }
      })
      ..subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _matchChannel?.track({'userId': myUserId});
        }
      });
  }

  Future<void> cancelQueue() async {
    _rescanTimer?.cancel();
    _queueChannel?.unsubscribe();
    _queueChannel = null;
    try {
      await _client.rpc('cancel_matchmaking');
    } catch (e) {
      debugPrint('[realtime] cancel error: $e');
    }
  }

  /// Cavab göndər → broadcast channel-də `answer` event.
  void submitAnswer({
    required String matchId,
    required int questionIndex,
    required String answer,
    required bool isCorrect,
    required int timeMs,
  }) {
    final channel = _matchChannel;
    if (channel == null) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    channel.sendBroadcastMessage(
      event: 'answer',
      payload: {
        'userId': userId,
        'questionIndex': questionIndex,
        'answer': answer,
        'isCorrect': isCorrect,
        'timeMs': timeMs,
      },
    );
  }

  /// Matçı tamamla → finish_1v1 RPC çağrılır. RPC idempotent-dir.
  Future<void> completeMatch({
    required String matchId,
    required String userId,
    required int score,
    required int correctAnswers,
    required String opponentUserId,
    required int opponentScore,
    required int opponentCorrect,
  }) async {
    try {
      final response = await _client.rpc('finish_1v1', params: {
        'p_match_id': matchId,
        'p_my_score': score,
        'p_my_correct': correctAnswers,
        'p_opp_user_id': opponentUserId,
        'p_opp_score': opponentScore,
        'p_opp_correct': opponentCorrect,
      });
      final list = response as List<dynamic>;
      if (list.isEmpty) return;
      final row = list.first as Map<String, dynamic>;
      _onMatchResult?.call({
        'winnerId': row['winner_id'],
        'isDraw': row['is_draw'],
        'eloChange': {
          userId: row['my_elo_delta'],
          opponentUserId: row['opp_elo_delta'],
        },
        'newElo': {
          userId: row['my_new_elo'],
          opponentUserId: row['opp_new_elo'],
        },
        'rewards': {
          userId: {
            'xp': row['my_xp_reward'],
            'coins': row['my_coin_reward'],
          },
        },
        'scores': {
          userId: score,
          opponentUserId: opponentScore,
        },
      });
    } catch (e) {
      debugPrint('[realtime] finish_1v1 failed: $e');
      _onError?.call({'message': 'FINISH_FAILED'});
    }
  }

  void disconnect() {
    _rescanTimer?.cancel();
    _queueChannel?.unsubscribe();
    _matchChannel?.unsubscribe();
    _queueChannel = null;
    _matchChannel = null;
    _currentMatchId = null;
  }

  void onWaiting(void Function() callback) => _onWaiting = callback;
  void onMatchStart(void Function(Map<String, dynamic>) callback) => _onMatchStart = callback;
  void onAnswerReceived(void Function(Map<String, dynamic>) callback) => _onAnswerReceived = callback;
  void onMatchResult(void Function(Map<String, dynamic>) callback) => _onMatchResult = callback;
  void onOpponentDisconnected(void Function() callback) => _onOpponentDisconnected = callback;
  void onError(void Function(Map<String, dynamic>) callback) => _onError = callback;

  void clearListeners() {
    _onWaiting = null;
    _onMatchStart = null;
    _onAnswerReceived = null;
    _onMatchResult = null;
    _onOpponentDisconnected = null;
    _onError = null;
  }

  /// Köhnə API uyğunluğu — Socket.IO `socketId` əvəzinə user id istifadə edirik.
  String? get socketId => _client.auth.currentUser?.id;
}
