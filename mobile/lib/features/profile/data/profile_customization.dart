import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// İstifadəçinin lokal profil görkəmi: emoji avatar, çərçivə, rəng.
/// Backend-də saxlanmır — yalnız SharedPreferences-də.
class ProfileCustomization {
  final String? avatarEmoji; // null olarsa username-in ilk hərfi göstərilir
  final String frameId;
  final String colorId;

  const ProfileCustomization({
    this.avatarEmoji,
    this.frameId = 'default',
    this.colorId = 'purple',
  });

  FrameOption get frame => availableFrames.firstWhere(
        (f) => f.id == frameId,
        orElse: () => availableFrames.first,
      );
  ColorOption get color => availableColors.firstWhere(
        (c) => c.id == colorId,
        orElse: () => availableColors.first,
      );

  static const List<String> availableAvatars = [
    '🦊', '🦁', '🐯', '🐺', '🦉', '🦅', '🐲', '🐼',
    '⚡', '🔥', '👑', '💎', '🎮', '🏆', '🚀', '🦄',
  ];

  static const List<FrameOption> availableFrames = [
    FrameOption(id: 'default', color: AppColors.primary, glow: AppColors.primary),
    FrameOption(id: 'gold', color: AppColors.gold, glow: AppColors.gold),
    FrameOption(id: 'neon', color: AppColors.cyan, glow: AppColors.cyan),
    FrameOption(id: 'pink', color: AppColors.pink, glow: AppColors.pink),
    FrameOption(id: 'fire', color: AppColors.accentOrange, glow: AppColors.error),
    FrameOption(id: 'jade', color: AppColors.success, glow: AppColors.success),
    FrameOption(id: 'silver', color: Color(0xFFC0C0C0), glow: Color(0xFFC0C0C0)),
    FrameOption(id: 'bronze', color: Color(0xFFCD7F32), glow: Color(0xFFCD7F32)),
    FrameOption(id: 'midnight', color: Color(0xFF1A1A2E), glow: Color(0xFF7B5CFF)),
    FrameOption(id: 'shadow', color: Color(0xFF2A2A2A), glow: Color(0xFF6B7090)),
    FrameOption(id: 'ruby', color: Color(0xFFE0115F), glow: Color(0xFFE0115F)),
    FrameOption(id: 'royal', color: Color(0xFF4169E1), glow: Color(0xFF4169E1)),
  ];

  static const List<ColorOption> availableColors = [
    ColorOption(id: 'purple', start: Color(0xFF7B5CFF), end: Color(0xFF4A2ADB)),
    ColorOption(id: 'cyan', start: Color(0xFF00E5FF), end: Color(0xFF0099AA)),
    ColorOption(id: 'pink', start: Color(0xFFFF3ED1), end: Color(0xFFAA0088)),
    ColorOption(id: 'gold', start: Color(0xFFFFD400), end: Color(0xFFCC8800)),
    ColorOption(id: 'green', start: Color(0xFF00E096), end: Color(0xFF008060)),
    ColorOption(id: 'blue', start: Color(0xFF2196F3), end: Color(0xFF0D47A1)),
    ColorOption(id: 'black', start: Color(0xFF2A2A2A), end: Color(0xFF0A0A0A)),
    ColorOption(id: 'gray', start: Color(0xFF8E8E93), end: Color(0xFF4A4A4F)),
    ColorOption(id: 'silver', start: Color(0xFFE0E0E0), end: Color(0xFFA0A0A0)),
    ColorOption(id: 'crimson', start: Color(0xFFFF4560), end: Color(0xFF8B0000)),
    ColorOption(id: 'sunset', start: Color(0xFFFF8C00), end: Color(0xFFFF3ED1)),
    ColorOption(id: 'ocean', start: Color(0xFF00E5FF), end: Color(0xFF0D47A1)),
    ColorOption(id: 'forest', start: Color(0xFF00E096), end: Color(0xFF1B5E20)),
    ColorOption(id: 'royal', start: Color(0xFF4169E1), end: Color(0xFF1A237E)),
  ];

  /// WS payload-da rəqibə göndərmək üçün JSON formatı.
  Map<String, dynamic> toJson() => {
        'avatarEmoji': avatarEmoji,
        'frameId': frameId,
        'colorId': colorId,
      };

  /// Rəqibdən gələn payload-dan oxu.
  factory ProfileCustomization.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ProfileCustomization();
    return ProfileCustomization(
      avatarEmoji: j['avatarEmoji'] as String?,
      frameId: j['frameId'] as String? ?? 'default',
      colorId: j['colorId'] as String? ?? 'purple',
    );
  }
}

class FrameOption {
  final String id;
  final Color color;
  final Color glow;
  const FrameOption({required this.id, required this.color, required this.glow});
}

class ColorOption {
  final String id;
  final Color start;
  final Color end;
  const ColorOption({required this.id, required this.start, required this.end});

  LinearGradient toGradient() => LinearGradient(
        colors: [start, end],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
