import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AvatarNotifier extends StateNotifier<String?> {
  AvatarNotifier(this.userId) : super(null) {
    _loadAvatar();
  }

  final String userId;
  String get _prefKey => 'user_avatar_path_$userId';

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_prefKey);
  }

  Future<void> setAvatar(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, path);
    state = path;
  }

  Future<void> clearAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    state = null;
  }
}

final avatarProvider = StateNotifierProvider<AvatarNotifier, String?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final userId = user?.id ?? 'default';
  return AvatarNotifier(userId);
});
