import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gguiz_logo.dart';
import '../../../../core/widgets/language_selector.dart';
import '../widgets/social_login_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: const LanguageButton(),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 48),
                const Center(
                  child: GguizLogo(size: 120),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 28),
                Text(
                  l10n.welcomeBack,
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                Text(
                  l10n.tagline,
                  style: AppTextStyles.bodySmall.copyWith(
                    letterSpacing: 4,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 64),
                const SocialLoginButtons().animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
