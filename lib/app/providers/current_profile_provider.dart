import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/auth_state.dart';
import '../../models/user_profile.dart';
import '../../services/auth_controller.dart';

final currentUserProfileProvider = StateProvider<UserProfile?>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState is AuthAuthenticated) {
    return authState.profile;
  }
  return null;
});
