import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String id;
  final String fromUserId;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.fromUserId,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        fromUserId: j['fromUserId'] as String,
        text: j['text'] as String,
        sentAt: DateTime.fromMillisecondsSinceEpoch((j['sentAt'] as num).toInt()),
      );
}

/// Ephemeral 1:1 chat — Supabase Realtime broadcast üzərində qurulub.
/// Heç bir mesaj DB-də saxlanılmır; channel-də session-ı olan istifadəçilər
/// real-time görüşür. Sıralanmış peer pair-ə görə channel adı: `chat:<a>:<b>`.
class ChatSocketService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _chatId;
  String? _myUserId;
  // mesajları lokal cache-də saxla (peer joined olduqda göndərə bilək)
  final List<ChatMessage> _localCache = [];

  ChatSocketService(this._client);

  bool get isConnected => _channel != null;
  String? get chatId => _chatId;

  /// Realtime SDK öz idarə edir — connect əsasən noop.
  void connect({void Function()? onConnected, void Function(Object)? onError}) {
    onConnected?.call();
  }

  void open({
    required String userId,
    required String peerId,
    required void Function(String chatId, List<ChatMessage> initialMessages, bool peerOnline) onOpened,
    required void Function(ChatMessage) onMessage,
    required void Function() onPeerJoined,
    required void Function() onPeerLeft,
    required void Function(bool isTyping) onTyping,
    required void Function(String code) onError,
  }) {
    _myUserId = userId;
    final sorted = [userId, peerId]..sort();
    final cid = 'chat:${sorted[0]}:${sorted[1]}';
    _chatId = cid;

    _channel?.unsubscribe();
    _channel = _client.channel(cid, opts: const RealtimeChannelConfig(self: false))
      ..onBroadcast(
        event: 'message',
        callback: (payload) {
          try {
            onMessage(ChatMessage.fromJson(Map<String, dynamic>.from(payload)));
          } catch (e) {
            debugPrint('[chat-rt] message parse error: $e');
          }
        },
      )
      ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          if (payload['userId'] == userId) return; // öz event-ini iqnor et
          onTyping(payload['isTyping'] == true);
        },
      )
      ..onPresenceSync((_) {
        // Presence sinxronlaşması — peer-in olub-olmadığını yoxla
        final state = _channel?.presenceState() ?? const [];
        final hasPeer = state.any((p) =>
            p.presences.any((pr) => pr.payload['userId'] == peerId));
        if (hasPeer) onPeerJoined();
      })
      ..onPresenceJoin((payload) {
        if (payload.newPresences.any((p) => p.payload['userId'] == peerId)) {
          onPeerJoined();
        }
      })
      ..onPresenceLeave((payload) {
        if (payload.leftPresences.any((p) => p.payload['userId'] == peerId)) {
          onPeerLeft();
        }
      })
      ..subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _channel?.track({'userId': userId});
          onOpened(cid, List.unmodifiable(_localCache), false);
        } else if (status == RealtimeSubscribeStatus.channelError) {
          onError(error?.toString() ?? 'channel_error');
        }
      });
  }

  void send(String text) {
    final channel = _channel;
    final myId = _myUserId;
    if (channel == null || myId == null) return;
    final msg = ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      fromUserId: myId,
      text: text,
      sentAt: DateTime.now(),
    );
    _localCache.add(msg);
    channel.sendBroadcastMessage(event: 'message', payload: {
      'id': msg.id,
      'fromUserId': myId,
      'text': text,
      'sentAt': msg.sentAt.millisecondsSinceEpoch,
    });
  }

  void setTyping(bool isTyping) {
    final channel = _channel;
    final myId = _myUserId;
    if (channel == null || myId == null) return;
    channel.sendBroadcastMessage(event: 'typing', payload: {
      'userId': myId,
      'isTyping': isTyping,
    });
  }

  void close() {
    _channel?.untrack();
    _channel?.unsubscribe();
    _channel = null;
    _chatId = null;
    _myUserId = null;
    _localCache.clear();
  }

  void disconnect() => close();
}
