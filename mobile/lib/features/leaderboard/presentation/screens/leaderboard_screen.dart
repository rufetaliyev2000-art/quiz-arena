import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/providers/user_provider.dart';
import '../../data/leaderboard_repository.dart';
import '../../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(leaderboardProvider);
    final myId = ref.watch(userProfileProvider).valueOrNull?.id;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(l10n.leaderboardError, style: AppTextStyles.bodyMedium),
            ),
            data: (players) {
              if (players.isEmpty) return _buildEmpty(l10n);
              return _buildLoaded(l10n, players, myId);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(l10n.leaderboardTitle, style: AppTextStyles.headlineLarge).animate().fadeIn(),
          const Spacer(),
          const Icon(Icons.emoji_events_outlined, size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(l10n.leaderboardEmpty, style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(l10n.leaderboardEmptyHint, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          const Spacer(),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildLoaded(AppLocalizations l10n, List<LeaderboardEntry> players, String? myId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(l10n.leaderboardTitle, style: AppTextStyles.headlineLarge).animate().fadeIn(),
              const SizedBox(height: 20),
              if (players.length >= 3)
                _buildTopThree(players.take(3).toList())
              else
                _buildShortTop(players),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: players.length > 3 ? players.length - 3 : 0,
            itemBuilder: (_, i) {
              final p = players[i + 3];
              final isMe = p.id == myId;
              return _buildRow(l10n, '${i + 4}', p, isMe, i);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShortTop(List<LeaderboardEntry> players) {
    return Column(
      children: players.asMap().entries.map((e) {
        final medal = e.key == 0 ? '🥇' : (e.key == 1 ? '🥈' : '🥉');
        final color = e.key == 0
            ? AppColors.rankGold
            : (e.key == 1 ? AppColors.rankSilver : AppColors.rankBronze);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(medal, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value.username, style: AppTextStyles.titleMedium.copyWith(color: color))),
              Text('${e.value.elo}', style: AppTextStyles.labelLarge.copyWith(color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopThree(List<LeaderboardEntry> players) {
    return SizedBox(
      height: 160,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodium(players[1].username, players[1].elo, '🥈', 110, AppColors.rankSilver),
          const SizedBox(width: 8),
          _buildPodium(players[0].username, players[0].elo, '🥇', 150, AppColors.rankGold),
          const SizedBox(width: 8),
          _buildPodium(players[2].username, players[2].elo, '🥉', 90, AppColors.rankBronze),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildPodium(String name, int elo, String medal, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(name, style: AppTextStyles.bodySmall.copyWith(color: color), overflow: TextOverflow.ellipsis),
        Text('$elo', style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height * 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.2)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(AppLocalizations l10n, String rank, LeaderboardEntry p, bool isMe, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withValues(alpha: 0.15) : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? AppColors.primary : const Color(0xFF2A2A40)),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text(rank, style: AppTextStyles.titleMedium, textAlign: TextAlign.center)),
          const SizedBox(width: 12),
          CircleAvatar(radius: 18, backgroundColor: AppColors.surfaceLight, child: Text(p.username[0], style: const TextStyle(color: AppColors.textPrimary))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.username}${isMe ? ' ${l10n.youInParens}' : ''}', style: AppTextStyles.titleMedium.copyWith(color: isMe ? AppColors.primaryLight : AppColors.textPrimary)),
                Text(l10n.winsText(p.wins), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.military_tech, color: AppColors.rankGold, size: 16),
              const SizedBox(width: 4),
              Text('${p.elo}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.rankGold)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 80)).slideX(begin: 0.1);
  }
}
