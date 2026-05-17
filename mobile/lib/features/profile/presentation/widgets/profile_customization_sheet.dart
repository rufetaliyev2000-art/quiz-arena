import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/data/user_repository.dart';
import '../../../home/providers/user_provider.dart';
import '../../data/profile_customization.dart';
import '../../providers/profile_customization_provider.dart';
import 'profile_avatar.dart';

Future<void> showProfileCustomizationSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProfileCustomizationSheet(profile: profile),
  );
}

class _ProfileCustomizationSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _ProfileCustomizationSheet({required this.profile});

  @override
  ConsumerState<_ProfileCustomizationSheet> createState() => _ProfileCustomizationSheetState();
}

enum _UsernameStatus { idle, checking, available, taken, invalid }

class _ProfileCustomizationSheetState extends ConsumerState<_ProfileCustomizationSheet> {
  late final TextEditingController _usernameCtrl;
  String? _usernameError;
  bool _saving = false;
  Timer? _checkDebounce;
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;
  String? _checkedReason; // 'taken' | 'format' | 'min_three_chars'

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.profile.username);
  }

  @override
  void dispose() {
    _checkDebounce?.cancel();
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (_usernameError != null) {
      setState(() => _usernameError = null);
    }
    setState(() {});
    final raw = _usernameCtrl.text.trim();
    // Dəyişməyibsə yoxlamağa ehtiyac yoxdur — öz adı.
    if (raw == widget.profile.username) {
      setState(() {
        _usernameStatus = _UsernameStatus.idle;
        _checkedReason = null;
      });
      return;
    }
    if (raw.length < 3) {
      setState(() {
        _usernameStatus = _UsernameStatus.invalid;
        _checkedReason = 'min_three_chars';
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(raw)) {
      setState(() {
        _usernameStatus = _UsernameStatus.invalid;
        _checkedReason = 'format';
      });
      return;
    }
    setState(() {
      _usernameStatus = _UsernameStatus.checking;
      _checkedReason = null;
    });
    _checkDebounce?.cancel();
    _checkDebounce = Timer(const Duration(milliseconds: 500), () => _runAvailabilityCheck(raw));
  }

  Future<void> _runAvailabilityCheck(String name) async {
    try {
      final res = await ref.read(userRepositoryProvider).checkUsernameAvailable(name);
      if (!mounted) return;
      // İstifadəçi araya başqa simvol əlavə etdisə bu yoxlama köhnəlib — atla.
      if (_usernameCtrl.text.trim() != name) return;
      setState(() {
        _usernameStatus = res.available
            ? _UsernameStatus.available
            : (res.reason == 'taken' ? _UsernameStatus.taken : _UsernameStatus.invalid);
        _checkedReason = res.reason;
      });
    } catch (_) {
      // Şəbəkə xətası — idle qaytarırıq ki save zamanı yenidən yoxlansın.
      if (!mounted) return;
      if (_usernameCtrl.text.trim() != name) return;
      setState(() => _usernameStatus = _UsernameStatus.idle);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final newName = _usernameCtrl.text.trim();

    if (newName != widget.profile.username) {
      if (newName.length < 3) {
        setState(() => _usernameError = l10n.usernameSetupErrorMinLen);
        return;
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newName)) {
        setState(() => _usernameError = l10n.usernameSetupErrorFormat);
        return;
      }
      setState(() {
        _saving = true;
        _usernameError = null;
      });
      try {
        await ref.read(userRepositoryProvider).setUsername(newName);
        ref.invalidate(userProfileProvider);
      } on UsernameTakenException {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _usernameError = l10n.usernameSetupErrorTaken;
        });
        return;
      } on UsernameFormatException {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _usernameError = l10n.usernameSetupErrorFormat;
        });
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _usernameError = l10n.usernameSetupSaveFailed;
        });
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.profileUpdated),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customization = ref.watch(profileCustomizationProvider);
    final notifier = ref.read(profileCustomizationProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.editProfileTitle,
                          style: AppTextStyles.titleLarge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    Center(
                      child: ProfileAvatar(
                        username: _usernameCtrl.text.isEmpty
                            ? widget.profile.username
                            : _usernameCtrl.text,
                        customization: customization,
                        size: 100,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.usernameField,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameCtrl,
                      style: AppTextStyles.bodyLarge,
                      onChanged: (_) => _onUsernameChanged(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.alternate_email_rounded,
                            color: AppColors.textMuted, size: 20),
                        suffixIcon: _buildStatusIcon(),
                        errorText: _usernameError ?? _statusError(l10n),
                        helperText: _usernameStatus == _UsernameStatus.available
                            ? l10n.usernameAvailable
                            : null,
                        helperStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.chooseAvatar),
                    const SizedBox(height: 12),
                    _buildAvatarGrid(notifier, customization, l10n),
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.chooseFrame),
                    const SizedBox(height: 12),
                    _buildFrameRow(notifier, customization),
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.chooseColor),
                    const SizedBox(height: 12),
                    _buildColorRow(notifier, customization),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_saving ||
                                _usernameStatus == _UsernameStatus.checking ||
                                _usernameStatus == _UsernameStatus.taken ||
                                _usernameStatus == _UsernameStatus.invalid)
                            ? null
                            : _save,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _saving ? null : AppColors.gradientPrimary,
                            color: _saving ? AppColors.surfaceLight : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    l10n.saveAction,
                                    style: AppTextStyles.labelLarge
                                        .copyWith(fontSize: 14, letterSpacing: 2),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
      );

  Widget? _buildStatusIcon() {
    switch (_usernameStatus) {
      case _UsernameStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
          ),
        );
      case _UsernameStatus.available:
        return const Icon(Icons.check_circle_rounded, color: AppColors.success);
      case _UsernameStatus.taken:
      case _UsernameStatus.invalid:
        return const Icon(Icons.cancel_rounded, color: AppColors.error);
      case _UsernameStatus.idle:
        return null;
    }
  }

  String? _statusError(AppLocalizations l10n) {
    if (_usernameStatus == _UsernameStatus.taken) return l10n.usernameSetupErrorTaken;
    if (_usernameStatus == _UsernameStatus.invalid) {
      if (_checkedReason == 'min_three_chars') return l10n.usernameSetupErrorMinLen;
      return l10n.usernameSetupErrorFormat;
    }
    return null;
  }

  Widget _buildAvatarGrid(
    ProfileCustomizationNotifier notifier,
    ProfileCustomization current,
    AppLocalizations l10n,
  ) {
    final items = <_AvatarItem>[
      _AvatarItem(emoji: null, label: l10n.useInitialLetter),
      ...ProfileCustomization.availableAvatars.map((e) => _AvatarItem(emoji: e)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final selected = current.avatarEmoji == item.emoji;
        return GestureDetector(
          onTap: () => notifier.setAvatar(item.emoji),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : const Color(0xFF2A2A40),
                width: selected ? 2 : 1,
              ),
            ),
            child: Center(
              child: item.emoji != null
                  ? Text(item.emoji!, style: const TextStyle(fontSize: 26))
                  : Icon(Icons.text_fields_rounded,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      size: 22),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrameRow(
      ProfileCustomizationNotifier notifier, ProfileCustomization current) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProfileCustomization.availableFrames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final frame = ProfileCustomization.availableFrames[i];
          final selected = current.frameId == frame.id;
          return GestureDetector(
            onTap: () => notifier.setFrame(frame.id),
            child: Container(
              width: 64,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFF2A2A40),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: current.color.toGradient(),
                    shape: BoxShape.circle,
                    border: Border.all(color: frame.color, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: frame.glow.withValues(alpha: 0.5),
                          blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorRow(
      ProfileCustomizationNotifier notifier, ProfileCustomization current) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProfileCustomization.availableColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final color = ProfileCustomization.availableColors[i];
          final selected = current.colorId == color.id;
          return GestureDetector(
            onTap: () => notifier.setColor(color.id),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: color.toGradient(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                        color: color.start.withValues(alpha: 0.6),
                        blurRadius: 12),
                ],
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 24)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _AvatarItem {
  final String? emoji;
  final String? label;
  _AvatarItem({this.emoji, this.label});
}
