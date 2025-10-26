import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wajd/models/user_profile.dart';
import '../../../models/auth_state.dart';
import 'auth_controller.dart';

final currentUserProfileProvider = StateProvider<AppUser?>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState is AuthAuthenticated) {
    return authState.profile;
  }
  return null;
});
