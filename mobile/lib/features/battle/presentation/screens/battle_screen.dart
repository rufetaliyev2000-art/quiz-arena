import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gguiz_battle/app_localizations.dart';
import '../../../../core/providers/local_game_stats_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/data/user_repository.dart';
import '../../../home/providers/user_provider.dart';
import '../../../profile/data/profile_customization.dart';
import '../../../profile/providers/profile_customization_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/battle_socket_service.dart';
import 'battle_match_screen.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  late final BattleSocketService _socket = BattleSocketService(ref.read(supabaseClientProvider));
  bool _searching = false;
  bool _searchTooLong = false;
  String? _errorMessage;
  Timer? _searchTimeout;

  @override
  void dispose() {
    _searchTimeout?.cancel();
    if (_searching) {
      _socket.cancelQueue();
    }
    _socket.clearListeners();
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _startSearch() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    if (profile == null) {
      setState(() => _errorMessage = l10n.profileLoadFailed);
      return;
    }

    setState(() {
      _searching = true;
      _searchTooLong = false;
      _errorMessage = null;
    });

    _searchTimeout?.cancel();
    _searchTimeout = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      if (_searching) setState(() => _searchTooLong = true);
    });

    // Bağlantı qurulduqdan SONRA listener-ləri qoş və queue-ya qoşul.
    // Əgər listener-lər `connect`-dən əvvəl qoyulsa, `_socket` hələ null
    // olduğu üçün null-safe call sayəsində heç bir handler qoşulmur.
    _socket.connect(
      whenConnected: () {
        if (!mounted || !_searching) return;
        _socket.onWaiting(() {});
        _socket.onMatchStart((data) => _handleMatchStart(profile, data));
        _socket.onError((data) => _handleError(l10n, data));
        final customization = ref.read(profileCustomizationProvider);
        _socket.joinQueue(
          userId: profile.id,
          username: profile.username,
          elo: profile.elo,
          friendCode: profile.friendCode,
          customization: customization.toJson(),
        );
      },
      onConnectError: (_) {
        if (!mounted) return;
        _searchTimeout?.cancel();
        setState(() {
          _searching = false;
          _searchTooLong = false;
          _errorMessage = l10n.errorNetwork;
        });
      },
    );
  }

  void _handleMatchStart(UserProfile profile, Map<String, dynamic> data) {
    if (!mounted) return;
    final indices = (data['questionIndices'] as List).map((e) => e as int).toList();
    final opponents = data['opponents'] as Map?;
    final opponentInfo = opponents?[profile.id] as Map?;
    final opponentName = opponentInfo?['username'] as String? ?? '???';
    final opponentElo = (opponentInfo?['elo'] as num?)?.toInt() ?? 1000;
    final opponentUserId = opponentInfo?['userId'] as String? ?? '';
    final opponentFriendCode = opponentInfo?['friendCode'] as String? ?? '';
    final opponentCustomizationRaw = opponentInfo?['customization'] as Map?;
    final opponentCustomization = ProfileCustomization.fromJson(
      opponentCustomizationRaw == null
          ? null
          : Map<String, dynamic>.from(opponentCustomizationRaw),
    );

    _searchTimeout?.cancel();
    _socket.clearListeners();
    setState(() {
      _searching = false;
      _searchTooLong = false;
    });

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BattleMatchScreen(
        args: BattleMatchArgs(
          matchId: data['matchId'] as String,
          userId: profile.id,
          username: profile.username,
          questionIndices: indices,
          opponentName: opponentName,
          opponentElo: opponentElo,
          opponentUserId: opponentUserId,
          opponentFriendCode: opponentFriendCode,
          opponentCustomization: opponentCustomization,
          socket: _socket,
        ),
      ),
    )).then((_) {
      if (mounted) setState(() => _searching = false);
    });
  }

  void _handleError(AppLocalizations l10n, Map<String, dynamic> data) {
    if (!mounted) return;
    _searchTimeout?.cancel();
    final code = data['message'] as String?;
    final message = code == 'ALREADY_IN_MATCH' ? l10n.alreadyInMatchMessage : l10n.errorGeneric;
    setState(() {
      _searching = false;
      _searchTooLong = false;
      _errorMessage = message;
    });
  }

  void _cancelSearch() {
    _searchTimeout?.cancel();
    _socket.cancelQueue();
    _socket.clearListeners();
    _socket.disconnect();
    setState(() {
      _searching = false;
      _searchTooLong = false;
    });
  }

  void _switchToBot() {
    _searchTimeout?.cancel();
    _socket.cancelQueue();
    _socket.clearListeners();
    _socket.disconnect();
    setState(() {
      _searching = false;
      _searchTooLong = false;
    });
    context.pushReplacement('/bot-battle');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);
    final localStats = ref.watch(localGameStatsProvider);
    final customization = ref.watch(profileCustomizationProvider);
    final profile = profileAsync.valueOrNull;
    final myElo = profile?.elo ?? 1000;
    final wins = (profile?.wins ?? 0) + localStats.extraWins;
    final losses = (profile?.losses ?? 0) + localStats.extraLosses;
    final total = wins + losses;
    final winRate = total == 0 ? 0 : ((wins / total) * 100).round();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_searching) _cancelSearch();
                        context.pop();
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.oneVsOneBattle, style: AppTextStyles.headlineLarge),
                  ],
                ).animate().fadeIn(),
                const SizedBox(height: 40),
                _buildArenaCard(l10n, profile?.username ?? '...', myElo, customization),
                const SizedBox(height: 32),
                if (_searching) _buildSearching(l10n) else _buildPlayButton(l10n),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: 32),
                _buildStats(l10n, wins, losses, winRate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArenaCard(AppLocalizations l10n, String myName, int myElo, ProfileCustomization customization) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 30)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMyPlayerCard(myName, myElo, customization),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentOrange),
                ),
                child: Text('VS', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.accentOrange)),
              ),
              _buildUnknownPlayerCard(),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.military_tech, color: AppColors.rankGold, size: 16),
                const SizedBox(width: 6),
                Text(l10n.eloRankedMatch, style: AppTextStyles.bodySmall.copyWith(color: AppColors.rankGold)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildMyPlayerCard(String name, int elo, ProfileCustomization customization) {
    return Column(
      children: [
        ProfileAvatar(
          username: name,
          customization: customization,
          size: 64,
        ),
        const SizedBox(height: 8),
        Text(name, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('$elo ELO', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
      ],
    );
  }

  Widget _buildUnknownPlayerCard() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textMuted, width: 2),
          ),
          child: const Icon(Icons.help_outline_rounded, size: 32, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Text('???', style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildSearching(AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
        ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1.seconds),
        const SizedBox(height: 16),
        Text(l10n.findingOpponent, style: AppTextStyles.titleMedium)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 800.ms),
        const SizedBox(height: 8),
        Text(l10n.matchingSimilarElo, style: AppTextStyles.bodySmall),
        const SizedBox(height: 24),
        if (_searchTooLong) ...[
          Text(
            l10n.noOpponentFoundYet,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentOrange),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _switchToBot,
            icon: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.black),
            label: Text(
              l10n.playWithBotInstead,
              style: AppTextStyles.labelLarge.copyWith(color: Colors.black, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextButton.icon(
          onPressed: _cancelSearch,
          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
          label: Text(l10n.cancelSearch, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            backgroundColor: AppColors.error.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startSearch,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports_rounded, color: Colors.black, size: 24),
                const SizedBox(width: 8),
                Text(l10n.findMatchButton, style: AppTextStyles.labelLarge.copyWith(color: Colors.black, fontSize: 16, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildStats(AppLocalizations l10n, int wins, int losses, int winRate) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('$wins', l10n.winsLabel, Icons.emoji_events, AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('$losses', l10n.lossesLabel, Icons.close, AppColors.error)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('$winRate%', l10n.winRateLabel, Icons.trending_up, AppColors.primary)),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.titleMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
