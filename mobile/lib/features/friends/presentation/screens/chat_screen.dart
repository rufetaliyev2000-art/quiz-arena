import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../home/providers/user_provider.dart';
import '../../data/chat_socket_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String peerId;
  final String peerUsername;
  const ChatScreen({super.key, required this.peerId, required this.peerUsername});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final ChatSocketService _socket = ChatSocketService(ref.read(supabaseClientProvider));
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _peerOnline = false;
  bool _peerTyping = false;
  String? _myId;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    final me = ref.read(userProfileProvider).valueOrNull;
    _myId = me?.id;
    if (_myId == null) return;
    _socket.connect(onConnected: _onConnected);
  }

  void _onConnected() {
    _socket.open(
      userId: _myId!,
      peerId: widget.peerId,
      onOpened: (chatId, initial, peerOnline) {
        if (!mounted) return;
        setState(() {
          _messages
            ..clear()
            ..addAll(initial);
          _peerOnline = peerOnline;
        });
        _scrollToBottom();
      },
      onMessage: (msg) {
        if (!mounted) return;
        setState(() => _messages.add(msg));
        _scrollToBottom();
      },
      onPeerJoined: () {
        if (!mounted) return;
        setState(() => _peerOnline = true);
      },
      onPeerLeft: () {
        if (!mounted) return;
        setState(() => _peerOnline = false);
      },
      onTyping: (t) {
        if (!mounted) return;
        setState(() => _peerTyping = t);
      },
      onError: (code) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final msg = code == 'not_friends' ? l10n.chatNotFriends : l10n.errorGeneric;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
        Navigator.of(context).pop();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _socket.send(text);
    _ctrl.clear();
    _socket.setTyping(false);
  }

  void _onChanged(String _) {
    _socket.setTyping(true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () => _socket.setTyping(false));
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _socket.disconnect();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerUsername, style: AppTextStyles.titleMedium),
            Text(
              _peerTyping
                  ? l10n.chatPeerTyping
                  : (_peerOnline ? l10n.onlineStatus : l10n.offlineStatus),
              style: AppTextStyles.bodySmall.copyWith(
                color: _peerOnline ? AppColors.success : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.accent.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.chatEphemeralNotice,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(l10n.chatNoMessages,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final isMe = m.fromUserId == _myId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : AppColors.surfaceLight,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Text(m.text, style: AppTextStyles.bodyMedium),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(top: BorderSide(color: Color(0xFF2A2A50))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: _onChanged,
                      maxLines: null,
                      maxLength: 1000,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText: l10n.chatInputHint,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
