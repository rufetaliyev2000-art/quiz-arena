import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/profile_customization.dart';

class ProfileCustomizationNotifier extends StateNotifier<ProfileCustomization> {
  ProfileCustomizationNotifier() : super(const ProfileCustomization()) {
    _load();
  }

  static const _keyAvatar = 'profile_avatar_emoji';
  static const _keyFrame = 'profile_frame_id';
  static const _keyColor = 'profile_color_id';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = ProfileCustomization(
      avatarEmoji: p.getString(_keyAvatar),
      frameId: p.getString(_keyFrame) ?? 'default',
      colorId: p.getString(_keyColor) ?? 'purple',
    );
  }

  Future<void> setAvatar(String? emoji) async {
    state = ProfileCustomization(
      avatarEmoji: emoji,
      frameId: state.frameId,
      colorId: state.colorId,
    );
    final p = await SharedPreferences.getInstance();
    if (emoji == null) {
      await p.remove(_keyAvatar);
    } else {
      await p.setString(_keyAvatar, emoji);
    }
  }

  Future<void> setFrame(String id) async {
    state = ProfileCustomization(
      avatarEmoji: state.avatarEmoji,
      frameId: id,
      colorId: state.colorId,
    );
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyFrame, id);
  }

  Future<void> setColor(String id) async {
    state = ProfileCustomization(
      avatarEmoji: state.avatarEmoji,
      frameId: state.frameId,
      colorId: id,
    );
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyColor, id);
  }
}

final profileCustomizationProvider =
    StateNotifierProvider<ProfileCustomizationNotifier, ProfileCustomization>(
        (ref) => ProfileCustomizationNotifier());
