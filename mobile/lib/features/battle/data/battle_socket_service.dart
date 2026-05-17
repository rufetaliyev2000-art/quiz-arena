import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/api_constants.dart';

/// Backend WebSocket gateway-i ilə əlaqə.
/// Bağlantı, matchmaking, cavab göndərmə və match nəticəsi.
class BattleSocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// Socket-i qoş və `whenConnected` callback-i tetiklə (zatən qoşuludursa dərhal).
  void connect({void Function()? whenConnected, void Function(Object error)? onConnectError}) {
    if (_socket != null && _socket!.connected) {
      debugPrint('[ws] already connected, sock=${_socket!.id}');
      whenConnected?.call();
      return;
    }
    debugPrint('[ws] connecting to ${ApiConstants.socketUrl}');
    _socket ??= io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket!.onConnect((_) {
      debugPrint('[ws] connected, sock=${_socket!.id}');
      whenConnected?.call();
    });
    _socket!.onDisconnect((_) => debugPrint('[ws] disconnected'));
    if (onConnectError != null) {
      _socket!.onConnectError((err) {
        debugPrint('[ws] connect error: $err');
        onConnectError(err as Object);
      });
      _socket!.onError((err) {
        debugPrint('[ws] error: $err');
        onConnectError(err as Object);
      });
    }
    if (!_socket!.connected) _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void joinQueue({
    required String userId,
    required String username,
    required int elo,
    String friendCode = '',
    Map<String, dynamic>? customization,
  }) {
    debugPrint('[ws] match:join → user=$username (id=${userId.substring(0, 8)}, elo=$elo)');
    _socket?.emit('match:join', {
      'userId': userId,
      'username': username,
      'elo': elo,
      'friendCode': friendCode,
      if (customization != null) 'customization': customization,
    });
  }

  void cancelQueue() {
    _socket?.emit('match:cancel');
  }

  void submitAnswer({
    required String matchId,
    required int questionIndex,
    required String answer,
    required bool isCorrect,
    required int timeMs,
  }) {
    _socket?.emit('answer:submit', {
      'matchId': matchId,
      'questionIndex': questionIndex,
      'answer': answer,
      'isCorrect': isCorrect,
      'timeMs': timeMs,
    });
  }

  void completeMatch({
    required String matchId,
    required String userId,
    required int score,
    required int correctAnswers,
  }) {
    _socket?.emit('match:complete', {
      'matchId': matchId,
      'userId': userId,
      'score': score,
      'correctAnswers': correctAnswers,
    });
  }

  void onWaiting(void Function() callback) {
    _socket?.on('match:waiting', (_) {
      debugPrint('[ws] ← match:waiting (queue-da gözləyirik)');
      callback();
    });
  }

  void onMatchStart(void Function(Map<String, dynamic> data) callback) {
    _socket?.on('match:start', (data) {
      debugPrint('[ws] ← match:start: $data');
      if (data is Map) callback(Map<String, dynamic>.from(data));
    });
  }

  void onAnswerReceived(void Function(Map<String, dynamic> data) callback) {
    _socket?.on('answer:received', (data) {
      if (data is Map) callback(Map<String, dynamic>.from(data));
    });
  }

  void onMatchResult(void Function(Map<String, dynamic> data) callback) {
    _socket?.on('match:result', (data) {
      if (data is Map) callback(Map<String, dynamic>.from(data));
    });
  }

  void onOpponentDisconnected(void Function() callback) {
    _socket?.on('opponent:disconnected', (_) => callback());
  }

  void onError(void Function(Map<String, dynamic> data) callback) {
    _socket?.on('match:error', (data) {
      debugPrint('[ws] ← match:error: $data');
      if (data is Map) callback(Map<String, dynamic>.from(data));
    });
  }

  void clearListeners() {
    _socket?.off('match:waiting');
    _socket?.off('match:start');
    _socket?.off('answer:received');
    _socket?.off('match:result');
    _socket?.off('opponent:disconnected');
    _socket?.off('match:error');
    _socket?.off('connect');
    _socket?.off('connect_error');
  }

  /// Cari socket-in id-si (rəqibin cavabını öz cavabımdan ayırmaq üçün).
  String? get socketId => _socket?.id;
}
