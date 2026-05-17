import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/profile_customization.dart';

/// İstifadəçinin profil avatarını çəkir: customization-a görə emoji və ya
/// username-in ilk hərfi, çərçivə rəngi və daxili gradient rənggi.
class ProfileAvatar extends StatelessWidget {
  final String username;
  final ProfileCustomization customization;
  final double size;
  final bool isMaxLevel;

  const ProfileAvatar({
    super.key,
    required this.username,
    required this.customization,
    this.size = 96,
    this.isMaxLevel = false,
  });

  @override
  Widget build(BuildContext context) {
    final frameColor =
        isMaxLevel ? AppColors.gold : customization.frame.color;
    final glow = isMaxLevel ? AppColors.gold : customization.frame.glow;
    final initial = (username.isEmpty ? '?' : username[0]).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: customization.color.toGradient(),
        shape: BoxShape.circle,
        border: Border.all(color: frameColor, width: 3),
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.4), blurRadius: 20),
        ],
      ),
      child: Center(
        child: customization.avatarEmoji != null
            ? Text(
                customization.avatarEmoji!,
                style: TextStyle(fontSize: size * 0.5),
              )
            : Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
