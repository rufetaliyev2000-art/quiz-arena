import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gguiz_battle/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/local_game_stats_provider.dart';
import '../../../leaderboard/data/leaderboard_repository.dart';
import '../../../leaderboard/providers/leaderboard_provider.dart';
import '../../../missions/data/daily_mission.dart';
import '../../../missions/providers/daily_missions_provider.dart';
import '../../data/user_repository.dart';
import '../../providers/user_provider.dart';
import '../../../profile/providers/profile_customization_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  Duration _remaining = const Duration(hours: 2, minutes: 45, seconds: 12);
  final List<dynamic> _notifications = const [];
  bool get _hasUnreadNotifications => _notifications.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');


  @override
  Widget build(BuildContext context) {
    // Profil yüklənən kimi və ya səviyyə dəyişəndə missionları yenilə.
    // Əgər istifadəçi hələ username seçməyibsə setup ekranına yönləndir.
    ref.listen(userProfileProvider, (_, next) {
      next.whenData((profile) {
        if (!profile.usernameSet) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/setup-username');
          });
          return;
        }
        ref.read(dailyMissionsProvider.notifier).ensureFresh(profile.level);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildCurrencyRow(),
              _buildTournamentBanner(context),
              _buildPlayModes(context),
              _buildDailyMissions(context),
              _buildLeaderboard(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final profileAsync = ref.watch(userProfileProvider);
    final localStats = ref.watch(localGameStatsProvider);
    final customization = ref.watch(profileCustomizationProvider);

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: ProfileAvatar(
                    username: profile.username,
                    customization: customization,
                    size: 52,
                  ),
                ),
                Positioned(
                  bottom: -4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${UserProfile.levelFromXp(profile.xp + localStats.bonusXp)}',
                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.username, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: UserProfile.progressForXp(profile.xp + localStats.bonusXp),
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Builder(builder: (_) {
                    final totalXp = profile.xp + localStats.bonusXp;
                    final lvl = UserProfile.levelFromXp(totalXp);
                    String fmt(int n) => n.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (m) => '${m[1]},',
                        );
                    if (lvl >= UserProfile.maxLevel) {
                      return Text(
                        '${fmt(totalXp)} XP • ${AppLocalizations.of(context)!.maxLevelBadge}',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.gold),
                      );
                    }
                    final xpInLvl = UserProfile.xpInLevel(totalXp);
                    final xpNeeded = UserProfile.xpToAdvance(lvl);
                    return Text(
                      '${fmt(xpInLvl)} / ${fmt(xpNeeded)} XP',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _showNotificationsSheet(AppLocalizations.of(context)!),
              child: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 22),
                  ),
                  if (_hasUnreadNotifications)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildCurrencyRow() {
    final profileAsync = ref.watch(userProfileProvider);
    final localStats = ref.watch(localGameStatsProvider);
    final l10n = AppLocalizations.of(context)!;
    final coins = (profileAsync.valueOrNull?.coins ?? 0) + localStats.bonusCoins;
    final xp = (profileAsync.valueOrNull?.xp ?? 0) + localStats.bonusXp;
    final coinsText = coins.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    final xpText = xp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _buildCurrencyBadge(
            icon: Icons.monetization_on,
            amount: coinsText,
            color: AppColors.gold,
            onTapBadge: () => _showBalanceSheet(
              icon: Icons.monetization_on,
              title: l10n.coinBalanceTitle,
              amount: coinsText,
              color: AppColors.gold,
              l10n: l10n,
            ),
            onTapPlus: () => context.go('/shop'),
          ),
          const SizedBox(width: 10),
          _buildCurrencyBadge(
            icon: Icons.star,
            amount: xpText,
            color: AppColors.accent,
            onTapBadge: () => _showBalanceSheet(
              icon: Icons.star,
              title: l10n.xpBalanceTitle,
              amount: xpText,
              color: AppColors.accent,
              l10n: l10n,
            ),
            onTapPlus: () => context.go('/shop'),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/shop'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 150.ms),
    );
  }

  void _showNotificationsSheet(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(l10n.notificationsTitle, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.noNotifications,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(sheetCtx).pop(),
              child: Text(
                l10n.closeAction,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBalanceSheet({
    required IconData icon,
    required String title,
    required String amount,
    required Color color,
    required AppLocalizations l10n,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              amount,
              style: AppTextStyles.headlineLarge.copyWith(color: color, fontSize: 36),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  context.go('/shop');
                },
                icon: const Icon(Icons.storefront_rounded, size: 20),
                label: Text(l10n.goToShop, style: AppTextStyles.labelLarge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetCtx).pop(),
              child: Text(
                l10n.closeAction,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBadge({
    required IconData icon,
    required String amount,
    required Color color,
    required VoidCallback onTapBadge,
    required VoidCallback onTapPlus,
  }) {
    return GestureDetector(
      onTap: onTapBadge,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 4),
            Text(amount, style: AppTextStyles.labelLarge.copyWith(color: color, fontSize: 13)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTapPlus,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: color, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          gradient: AppColors.gradientTournament,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amber)
                  .animate()
                  .scale(delay: 400.ms, duration: 600.ms, curve: Curves.elasticOut),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.daily, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70, letterSpacing: 2, fontSize: 11)),
                  Text(l10n.tournament, style: AppTextStyles.headlineLarge.copyWith(color: Colors.white, fontSize: 22, height: 1.1)),
                  Text(l10n.winBigRewards, style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.startsIn, style: AppTextStyles.bodySmall.copyWith(color: Colors.white54, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              '${_pad(_remaining.inHours)}:${_pad(_remaining.inMinutes % 60)}:${_pad(_remaining.inSeconds % 60)}',
                              style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.go('/tournaments'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(l10n.joinNow, style: AppTextStyles.labelLarge.copyWith(color: Colors.black, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildPlayModes(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _buildSectionHeader(l10n.playModes, l10n.seeAll, () {}),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  title: '1v1',
                  subtitle: l10n.quickBattle,
                  icon: Icons.flash_on_rounded,
                  gradient: AppColors.gradientPrimary,
                  onTap: () => context.push('/battle'),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModeCard(
                  title: l10n.botBattle,
                  subtitle: l10n.botBattleSubtitle,
                  icon: Icons.smart_toy_rounded,
                  gradient: AppColors.gradientCyan,
                  onTap: () => context.push('/bot-battle'),
                ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  title: l10n.soloPlay,
                  subtitle: l10n.soloSubtitle,
                  icon: Icons.psychology_rounded,
                  gradient: AppColors.gradientBattle,
                  onTap: () => context.push('/quiz'),
                ).animate().fadeIn(delay: 420.ms).slideX(begin: -0.2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModeCard(
                  title: l10n.battleRoyaleTitle,
                  subtitle: l10n.lastOneWins,
                  icon: Icons.workspace_premium_rounded,
                  gradient: AppColors.gradientBattleRoyale,
                  onTap: () => context.go('/tournaments'),
                ).animate().fadeIn(delay: 480.ms).slideX(begin: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: gradient.colors.first.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 12, height: 1.2),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMissions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final missionsState = ref.watch(dailyMissionsProvider);
    final missions = missionsState.missions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.dailyMissions,
                  style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.missionRefreshIn(_formatRefreshCountdown(missionsState.timeUntilRefresh(DateTime.now()))),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (missions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            ...missions.asMap().entries.map((e) {
              return _buildMissionRow(l10n, e.value, e.key)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 300 + e.key * 100))
                  .slideX(begin: 0.1);
            }),
        ],
      ),
    );
  }

  String _formatRefreshCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  ({IconData icon, Color color, String label}) _missionVisuals(AppLocalizations l10n, DailyMission m) {
    return switch (m.type) {
      MissionType.playMatch =>
        (icon: Icons.sports_esports_rounded, color: AppColors.cyan, label: l10n.missionPlayMatch(m.target)),
      MissionType.winMatch =>
        (icon: Icons.emoji_events_rounded, color: AppColors.success, label: l10n.missionWinMatch(m.target)),
      MissionType.answerCorrect =>
        (icon: Icons.psychology_rounded, color: AppColors.pink, label: l10n.missionAnswerCorrect(m.target)),
      MissionType.fastAnswer =>
        (icon: Icons.bolt, color: AppColors.accent, label: l10n.missionFastAnswer(m.target)),
      MissionType.winStreak =>
        (icon: Icons.local_fire_department_rounded, color: AppColors.error, label: l10n.missionWinStreak(m.target)),
    };
  }

  Widget _buildMissionRow(AppLocalizations l10n, DailyMission m, int index) {
    final v = _missionVisuals(l10n, m);
    final color = v.color;
    final rewardText = m.reward == MissionReward.xp
        ? l10n.missionRewardXp(m.rewardAmount)
        : l10n.missionRewardCoins(m.rewardAmount);
    final rewardColor = m.reward == MissionReward.xp ? AppColors.accent : AppColors.gold;
    final rewardIcon = m.reward == MissionReward.xp ? Icons.star_rounded : Icons.monetization_on;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A50)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(v.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontSize: 13)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: m.target == 0 ? 0 : (m.progress / m.target).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 3),
                Text('${m.progress} / ${m.target}', style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Row(
                children: [
                  Icon(rewardIcon, color: rewardColor, size: 14),
                  const SizedBox(width: 3),
                  Text(rewardText, style: AppTextStyles.bodySmall.copyWith(color: rewardColor, fontWeight: FontWeight.w600, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              _buildMissionCtaButton(l10n, m),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCtaButton(AppLocalizations l10n, DailyMission m) {
    if (m.claimed) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }
    if (m.isCompleted) {
      return GestureDetector(
        onTap: () => _claimMission(m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(l10n.missionClaim, style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textMuted, width: 1.5),
      ),
    );
  }

  Future<void> _claimMission(DailyMission m) async {
    final result = await ref.read(dailyMissionsProvider.notifier).claim(m.id);
    if (result == null || !mounted) return;
    final (reward, amount) = result;
    await ref.read(localGameStatsProvider.notifier).addReward(
          xp: reward == MissionReward.xp ? amount : 0,
          coins: reward == MissionReward.coins ? amount : 0,
        );
  }

  Widget _buildLeaderboard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(leaderboardProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.leaderboard.toUpperCase(),
                  style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.go('/leaderboard'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(l10n.view, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.topPlayers, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          entriesAsync.when(
            loading: () => const SizedBox(
              height: 110,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => _buildLeaderboardEmpty(l10n),
            data: (players) {
              if (players.isEmpty) return _buildLeaderboardEmpty(l10n);
              final top = players.take(4).toList();
              return Row(
                children: top.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: e.key < top.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2A50)),
                      ),
                      child: _buildLeaderboardCell(e.value, rank),
                    ).animate().fadeIn(delay: Duration(milliseconds: 400 + e.key * 80)).slideY(begin: 0.2),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCell(LeaderboardEntry p, int rank) {
    final medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.textMuted;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surfaceLight,
              child: Text(p.username[0], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Positioned(
              bottom: -6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: medalColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(p.username, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.military_tech, color: AppColors.rankGold, size: 11),
            const SizedBox(width: 2),
            Text('${p.elo}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.rankGold, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaderboardEmpty(AppLocalizations l10n) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A50)),
      ),
      child: Center(
        child: Text(l10n.leaderboardEmpty, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAction,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(actionText, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, color: AppColors.primaryLight, size: 10),
            ],
          ),
        ),
      ],
    );
  }
}
