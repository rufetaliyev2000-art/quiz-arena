import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gguiz_battle/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 100 səviyyə 7 tier-ə bölünür: hər tier 15 səviyyədir, sonuncu tier 91-100.
/// Tier artdıqca dizayn daha zəngin olur (rənglər, emoji, animasiya).
class LevelTier {
  final int index; // 1..7
  final String emoji;
  final List<Color> colors;
  final int particleCount;
  final double particleVelocity;
  final List<String> titleLabelKey;
  const LevelTier({
    required this.index,
    required this.emoji,
    required this.colors,
    required this.particleCount,
    required this.particleVelocity,
    required this.titleLabelKey,
  });
}

LevelTier tierForLevel(int level) {
  // 1-15 → 1, 16-30 → 2, ..., 91-100 → 7
  final t = ((level - 1) ~/ 15) + 1;
  final clamped = t > 7 ? 7 : (t < 1 ? 1 : t);
  switch (clamped) {
    case 1:
      return const LevelTier(
        index: 1,
        emoji: '⭐',
        colors: [Color(0xFF7B5CFF), Color(0xFF9B82FF)],
        particleCount: 20,
        particleVelocity: 0.25,
        titleLabelKey: [],
      );
    case 2:
      return const LevelTier(
        index: 2,
        emoji: '🌟',
        colors: [Color(0xFF00E5FF), Color(0xFF7B5CFF)],
        particleCount: 30,
        particleVelocity: 0.3,
        titleLabelKey: [],
      );
    case 3:
      return const LevelTier(
        index: 3,
        emoji: '💎',
        colors: [Color(0xFF00E096), Color(0xFF00E5FF)],
        particleCount: 40,
        particleVelocity: 0.35,
        titleLabelKey: [],
      );
    case 4:
      return const LevelTier(
        index: 4,
        emoji: '🔥',
        colors: [Color(0xFFFF8C00), Color(0xFFFFD400)],
        particleCount: 50,
        particleVelocity: 0.4,
        titleLabelKey: [],
      );
    case 5:
      return const LevelTier(
        index: 5,
        emoji: '⚡',
        colors: [Color(0xFFFF3ED1), Color(0xFFFF4560)],
        particleCount: 60,
        particleVelocity: 0.45,
        titleLabelKey: [],
      );
    case 6:
      return const LevelTier(
        index: 6,
        emoji: '👑',
        colors: [Color(0xFFFFD400), Color(0xFFFF8C00)],
        particleCount: 75,
        particleVelocity: 0.5,
        titleLabelKey: [],
      );
    case 7:
    default:
      return const LevelTier(
        index: 7,
        emoji: '🏆',
        colors: [Color(0xFFFFD400), Color(0xFFFF3ED1), Color(0xFF00E5FF)],
        particleCount: 100,
        particleVelocity: 0.6,
        titleLabelKey: [],
      );
  }
}

String _tierTitle(AppLocalizations l10n, int tierIndex) {
  switch (tierIndex) {
    case 1: return l10n.levelTier1;
    case 2: return l10n.levelTier2;
    case 3: return l10n.levelTier3;
    case 4: return l10n.levelTier4;
    case 5: return l10n.levelTier5;
    case 6: return l10n.levelTier6;
    case 7:
    default: return l10n.levelTier7;
  }
}

/// Level-up təbrik ekranını açır. Maksimum səviyyəyə çatdıqda da göstərə bilər.
Future<void> showLevelUpOverlay(
  BuildContext context, {
  required int oldLevel,
  required int newLevel,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    barrierLabel: 'level-up',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, __) => LevelUpScreen(oldLevel: oldLevel, newLevel: newLevel),
    transitionBuilder: (_, anim, __, child) {
      return FadeTransition(opacity: anim, child: child);
    },
  );
}

class LevelUpScreen extends StatefulWidget {
  final int oldLevel;
  final int newLevel;
  const LevelUpScreen({super.key, required this.oldLevel, required this.newLevel});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> with TickerProviderStateMixin {
  late final ConfettiController _confettiTop;
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;

  @override
  void initState() {
    super.initState();
    final tier = tierForLevel(widget.newLevel);
    _confettiTop = ConfettiController(duration: const Duration(seconds: 4));
    _confettiLeft = ConfettiController(duration: const Duration(seconds: 3));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 3));
    Future.microtask(() {
      _confettiTop.play();
      if (tier.index >= 4) _confettiLeft.play();
      if (tier.index >= 4) _confettiRight.play();
    });
  }

  @override
  void dispose() {
    _confettiTop.dispose();
    _confettiLeft.dispose();
    _confettiRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tier = tierForLevel(widget.newLevel);
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  tier.colors.first.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.92),
                ],
                radius: 1.2,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiTop,
              blastDirection: math.pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: tier.particleCount,
              maxBlastForce: 30 * tier.particleVelocity * 2,
              minBlastForce: 10 * tier.particleVelocity * 2,
              emissionFrequency: 0.04,
              gravity: 0.25,
              colors: tier.colors,
            ),
          ),
          if (tier.index >= 4) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: ConfettiWidget(
                confettiController: _confettiLeft,
                blastDirection: 0,
                numberOfParticles: tier.particleCount ~/ 2,
                maxBlastForce: 25,
                emissionFrequency: 0.05,
                gravity: 0.2,
                colors: tier.colors,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ConfettiWidget(
                confettiController: _confettiRight,
                blastDirection: math.pi,
                numberOfParticles: tier.particleCount ~/ 2,
                maxBlastForce: 25,
                emissionFrequency: 0.05,
                gravity: 0.2,
                colors: tier.colors,
              ),
            ),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tier.emoji,
                    style: const TextStyle(fontSize: 80),
                  ).animate().scale(
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.2, 0.2),
                      ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.levelUpTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: tier.colors.first,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 32,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),
                  const SizedBox(height: 20),
                  Container(
                    width: media.size.width * 0.6,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tier.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: tier.colors.first.withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Lv.',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.black.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${widget.newLevel}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _tierTitle(l10n, tier.index),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(
                        delay: 300.ms,
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.3, 0.3),
                      ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.levelUpSubtitle(widget.newLevel),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 220,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: tier.colors),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            l10n.continueButton,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
