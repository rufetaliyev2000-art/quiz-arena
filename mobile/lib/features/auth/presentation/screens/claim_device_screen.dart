import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/device_id_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/providers/user_provider.dart';

/// Bu cihaz hesabın active_device_id-si DEYİL. İstifadəçi Supabase Auth OTP
/// keçib `claim_device` RPC ilə bu cihazı yeni "yeganə aktiv cihaz" kimi
/// qeyd edə bilər. Köhnə cihaz növbəti RPC çağırışında check_device()
/// false qaytarır → o da bu ekrana düşür.
class ClaimDeviceScreen extends ConsumerStatefulWidget {
  const ClaimDeviceScreen({super.key});

  @override
  ConsumerState<ClaimDeviceScreen> createState() => _ClaimDeviceScreenState();
}

class _ClaimDeviceScreenState extends ConsumerState<ClaimDeviceScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  bool _claiming = false;
  String? _error;
  String? _info;
  String? _activeLabel;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final deviceId = await ref.read(deviceIdServiceProvider).get();
      final response = await ref.read(supabaseClientProvider)
          .rpc('get_device_status', params: {'p_device_id': deviceId});
      final list = response as List<dynamic>;
      if (mounted && list.isNotEmpty) {
        final row = list.first as Map<String, dynamic>;
        setState(() => _activeLabel = row['active_device_label'] as String?);
      }
    } catch (_) {/* səssiz */}
    if (!mounted) return;
    _sendOtp(initial: true);
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) t.cancel();
    });
  }

  String? _myEmail() => ref.read(supabaseClientProvider).auth.currentUser?.email;

  Future<void> _sendOtp({bool initial = false}) async {
    if (_sending || _cooldown > 0) return;
    final email = _myEmail();
    if (email == null) {
      setState(() => _error = AppLocalizations.of(context)!.errorGeneric);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      if (!initial) _info = null;
    });
    try {
      await ref.read(supabaseClientProvider).auth.signInWithOtp(
            email: email,
            shouldCreateUser: false,
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _sending = false;
        _info = l10n.signupOtpSent;
      });
      _startCooldown();
    } on AuthException catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _sending = false;
        _error = l10n.errorGeneric;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _sending = false;
        _error = l10n.errorGeneric;
      });
    }
  }

  Future<void> _claim() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _ctrl.text.trim();
    final email = _myEmail();
    if (code.length != 6) {
      setState(() => _error = l10n.otpCodeLength);
      return;
    }
    if (email == null) {
      setState(() => _error = l10n.errorGeneric);
      return;
    }
    setState(() {
      _claiming = true;
      _error = null;
      _info = null;
    });
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.verifyOTP(email: email, token: code, type: OtpType.email);
      final deviceId = await ref.read(deviceIdServiceProvider).get();
      await supabase.rpc('claim_device', params: {
        'p_device_id': deviceId,
        'p_device_label': deviceLabel(),
      });
      if (!mounted) return;
      ref.read(authProvider.notifier).clearDeviceMismatch();
      ref.invalidate(userProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.claimDeviceSuccess),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ));
      context.go('/home');
    } on AuthException catch (_) {
      if (!mounted) return;
      setState(() {
        _claiming = false;
        _error = l10n.signupOtpInvalid;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _claiming = false;
        _error = l10n.errorGeneric;
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    ref.read(authProvider.notifier).clearDeviceMismatch();
    if (mounted) context.go('/login');
  }

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
                const SizedBox(height: 32),
                Icon(Icons.devices_other_rounded, size: 64, color: AppColors.accent)
                    .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text(l10n.claimDeviceTitle, style: AppTextStyles.displayMedium, textAlign: TextAlign.center)
                    .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                const SizedBox(height: 10),
                Text(l10n.claimDeviceSubtitle,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center)
                    .animate().fadeIn(delay: 200.ms),
                if (_activeLabel != null && _activeLabel!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.smartphone_rounded, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('${l10n.claimDeviceActiveLabel}: $_activeLabel',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ]),
                  ).animate().fadeIn(delay: 250.ms),
                ],
                const SizedBox(height: 30),
                if (_error != null) ...[
                  _banner(_error!, AppColors.error, Icons.error_outline_rounded),
                  const SizedBox(height: 14),
                ] else if (_info != null) ...[
                  _banner(_info!, AppColors.success, Icons.check_circle_outline_rounded),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _ctrl,
                  style: AppTextStyles.headlineMedium.copyWith(letterSpacing: 8),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '______',
                    hintStyle: AppTextStyles.headlineMedium.copyWith(
                      letterSpacing: 8,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                    counterText: '',
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 26),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _claiming ? null : _claim,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _claiming ? null : AppColors.gradientPrimary,
                        color: _claiming ? AppColors.surfaceLight : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _claiming
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(l10n.claimDeviceContinue,
                                style: AppTextStyles.labelLarge.copyWith(fontSize: 14, letterSpacing: 2)),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: (_cooldown > 0 || _sending) ? null : () => _sendOtp(),
                    child: Text(
                      _cooldown > 0 ? l10n.signupOtpResendIn(_cooldown) : l10n.signupOtpResend,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _cooldown > 0 ? AppColors.textMuted : AppColors.primaryLight,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _claiming ? null : _logout,
                    icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                    label: Text(l10n.claimDeviceLogout,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                  ),
                ).animate().fadeIn(delay: 550.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: color))),
      ]),
    ).animate().fadeIn(duration: 200.ms);
  }
}
