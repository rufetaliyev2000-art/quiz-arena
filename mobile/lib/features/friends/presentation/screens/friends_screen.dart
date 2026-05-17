import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/providers/user_provider.dart';
import '../../data/friend_repository.dart';
import '../../providers/friend_provider.dart';
import 'chat_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddDialog(AppLocalizations l10n) async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _AddFriendDialog(),
    );
    if (code == null || code.isEmpty) return;
    try {
      await ref.read(friendsProvider.notifier).sendRequest(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.friendRequestSent), backgroundColor: AppColors.success),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _mapError(l10n, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  String _mapError(AppLocalizations l10n, DioException e) {
    final code = (e.response?.data is Map ? (e.response!.data as Map)['message'] : null) as String?;
    switch (code) {
      case 'user_not_found':
        return l10n.errorUserNotFound;
      case 'cannot_friend_self':
        return l10n.errorCannotFriendSelf;
      case 'already_friends':
        return l10n.errorAlreadyFriends;
      case 'already_pending':
        return l10n.errorAlreadyPending;
      case 'blocked':
        return l10n.errorBlocked;
      case 'invalid_code_format':
        return l10n.errorInvalidCodeFormat;
      default:
        return l10n.errorGeneric;
    }
  }

  Future<void> _copyCode(String code, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.codeCopied), backgroundColor: AppColors.success, duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friendsAsync = ref.watch(friendsProvider);
    final me = ref.watch(userProfileProvider).valueOrNull;
    final myCode = me?.friendCode ?? '------';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.friendsTitle,
                      style: AppTextStyles.headlineLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _openAddDialog(l10n),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(l10n.addButton, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Mənim ID kodum kartı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => _copyCode(myCode, l10n),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.yourFriendCode,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(myCode,
                                style: AppTextStyles.headlineMedium
                                    .copyWith(color: AppColors.primary, letterSpacing: 4)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(l10n.copyCodeAction, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: l10n.friendsTab(friendsAsync.valueOrNull?.friends.length ?? 0)),
                    Tab(text: l10n.requestsTab(friendsAsync.valueOrNull?.incoming.length ?? 0)),
                    Tab(text: l10n.blockedTab(friendsAsync.valueOrNull?.blocked.length ?? 0)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Expanded(
              child: friendsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e', style: AppTextStyles.bodyMedium)),
                data: (state) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsList(l10n, state.friends),
                    _buildRequestsList(l10n, state),
                    _buildBlockedList(l10n, state.blocked),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, [String? hint]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(hint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendsList(AppLocalizations l10n, List<FriendSummary> friends) {
    if (friends.isEmpty) return _emptyState(Icons.people_outline_rounded, l10n.noFriendsYet, l10n.noFriendsHint);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: friends.length,
      itemBuilder: (_, i) {
        final f = friends[i];
        return _FriendCard(
          name: f.username,
          subtitle: '${f.elo} ELO  •  Lv ${f.level}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniAction(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(peerId: f.userId, peerUsername: f.username),
                  ));
                },
              ),
              const SizedBox(width: 8),
              _miniAction(
                icon: Icons.person_remove_rounded,
                color: AppColors.error,
                onTap: () => _confirmRemove(l10n, f),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 60 * i)).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildRequestsList(AppLocalizations l10n, FriendsState state) {
    if (state.incoming.isEmpty && state.outgoing.isEmpty) {
      return _emptyState(Icons.inbox_outlined, l10n.noRequestsYet);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (state.incoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.incomingRequests,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ...state.incoming.map((f) => _FriendCard(
                name: f.username,
                subtitle: '${f.elo} ELO  •  Lv ${f.level}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _miniAction(
                      icon: Icons.close_rounded,
                      color: AppColors.error,
                      onTap: () async {
                        await ref.read(friendsProvider.notifier).removeOrDecline(f.friendshipId);
                      },
                    ),
                    const SizedBox(width: 8),
                    _miniAction(
                      icon: Icons.check_rounded,
                      color: AppColors.success,
                      onTap: () async {
                        await ref.read(friendsProvider.notifier).accept(f.friendshipId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l10n.friendRequestAccepted),
                          backgroundColor: AppColors.success,
                        ));
                      },
                    ),
                  ],
                ),
              )),
        ],
        if (state.outgoing.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.outgoingRequests,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ...state.outgoing.map((f) => _FriendCard(
                name: f.username,
                subtitle: '${f.elo} ELO  •  Lv ${f.level}',
                trailing: _miniAction(
                  icon: Icons.close_rounded,
                  color: AppColors.error,
                  onTap: () async {
                    await ref.read(friendsProvider.notifier).removeOrDecline(f.friendshipId);
                  },
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildBlockedList(AppLocalizations l10n, List<FriendSummary> blocked) {
    if (blocked.isEmpty) return _emptyState(Icons.block_rounded, l10n.noBlockedYet);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: blocked.length,
      itemBuilder: (_, i) {
        final f = blocked[i];
        return _FriendCard(
          name: f.username,
          subtitle: f.friendCode,
          trailing: GestureDetector(
            onTap: () async {
              await ref.read(friendsProvider.notifier).unblock(f.friendshipId);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.friendUnblocked),
                backgroundColor: AppColors.success,
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(l10n.unblockAction, style: AppTextStyles.bodySmall),
            ),
          ),
        );
      },
    );
  }

  Widget _miniAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Future<void> _confirmRemove(AppLocalizations l10n, FriendSummary f) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(f.username, style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_remove_rounded, color: AppColors.error),
              title: Text(l10n.removeFriendAction, style: AppTextStyles.bodyLarge),
              onTap: () => Navigator.of(context).pop('remove'),
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppColors.error),
              title: Text(l10n.blockAction, style: AppTextStyles.bodyLarge),
              onTap: () => Navigator.of(context).pop('block'),
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              title: Text(l10n.cancelAction, style: AppTextStyles.bodyLarge),
              onTap: () => Navigator.of(context).pop(null),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'remove') {
      await ref.read(friendsProvider.notifier).removeOrDecline(f.friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.friendRemoved),
        backgroundColor: AppColors.success,
      ));
    } else if (action == 'block') {
      await ref.read(friendsProvider.notifier).block(f.friendCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.friendBlocked),
        backgroundColor: AppColors.success,
      ));
    }
  }
}

class _FriendCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget trailing;
  const _FriendCard({required this.name, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A50)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _AddFriendDialog extends StatefulWidget {
  const _AddFriendDialog();

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final _ctrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length != 6 || !RegExp(r'^[A-Z2-9]{6}$').hasMatch(code)) {
      setState(() => _err = l10n.friendCodeFormatError);
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.addFriendTitle, style: AppTextStyles.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.addFriendHint, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            textAlign: TextAlign.center,
            maxLength: 6,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z2-9]')),
              UpperCaseTextFormatter(),
            ],
            style: AppTextStyles.headlineMedium.copyWith(letterSpacing: 6, color: AppColors.primary),
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              counterText: '',
              errorText: _err,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _submit(l10n),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancelAction, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => _submit(l10n),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(l10n.addFriendButton),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
