import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gguiz_battle/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournaments = <(String, IconData, String, int, int, LinearGradient, bool)>[
      (l10n.dailyChampionship, Icons.emoji_events_rounded, 'Starts in 02:45', 256, 5000, AppColors.gradientTournament, true),
      (l10n.weekendRoyale, Icons.workspace_premium_rounded, 'Starts in 1d 08h', 512, 15000, AppColors.gradientBattleRoyale, false),
      (l10n.speedQuizBlitz, Icons.flash_on_rounded, l10n.liveFilter, 128, 3000, AppColors.gradientPrimary, true),
      (l10n.knowledgeMasters, Icons.psychology_rounded, 'Starts in 3d 12h', 64, 8000, AppColors.gradientCyan, false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tournamentsTitle, style: AppTextStyles.headlineLarge).animate().fadeIn(),
                  const SizedBox(height: 4),
                  Text(l10n.tournamentSubtitle, style: AppTextStyles.bodyMedium).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [l10n.allFilter, l10n.liveFilter, l10n.upcomingFilter, l10n.myEntriesFilter].asMap().entries.map((e) {
                  final selected = e.key == 0;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : const Color(0xFF2A2A50)),
                    ),
                    alignment: Alignment.center,
                    child: Text(e.value, style: AppTextStyles.bodySmall.copyWith(color: selected ? Colors.white : AppColors.textMuted, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: tournaments.length,
                itemBuilder: (_, i) {
                  final (name, icon, time, players, prize, gradient, live) = tournaments[i];
                  return _buildTournamentCard(l10n, name, icon, time, players, prize, gradient, live, i);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentCard(AppLocalizations l10n, String name, IconData icon, String time, int players, int prize, LinearGradient gradient, bool live, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A50)),
      ),
      child: Column(
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                if (live)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(l10n.liveBadge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                Center(child: Icon(icon, size: 50, color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.textMuted, size: 13),
                          const SizedBox(width: 4),
                          Flexible(child: Text(time, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 12),
                          const Icon(Icons.people_outline, color: AppColors.textMuted, size: 13),
                          const SizedBox(width: 4),
                          Flexible(child: Text(l10n.playersCount(players), style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: AppColors.gold, size: 14),
                          const SizedBox(width: 4),
                          Text(l10n.coinsPrize((prize / 1000).toStringAsFixed(0)), style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(l10n.joinButton, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 100)).slideY(begin: 0.1);
  }
}
