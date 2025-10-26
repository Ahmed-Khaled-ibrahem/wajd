import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/login/controller/auth_controller.dart';
import '../../models/auth_state.dart';
import '../../models/user_profile.dart';
import '../providers/all_app_provider.dart';

class AuthenticatedWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AuthenticatedWrapper({super.key, required this.child});

  @override
  ConsumerState<AuthenticatedWrapper> createState() =>
      _AuthenticatedWrapperState();
}

class _AuthenticatedWrapperState extends ConsumerState<AuthenticatedWrapper> {
  bool _listenerSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_listenerSet) return;
    _listenerSet = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalContainer.listen<AuthState>(authControllerProvider, (
        previous,
        next,
      ) {
        final router = GoRouter.of(context);
        final currentLocation = router.state.uri.toString();
        String? targetRoute;

        switch (next) {
          case AuthInitial():
          case AuthLoading():
            targetRoute = '/loading';
            break;

          case AuthAuthenticated():
            if (next.profile.role == UserRole.admin) {
              targetRoute = '/admin_home';
            } else if (next.profile.role == UserRole.staff) {
              targetRoute = '/staff_home';
            } else {
              targetRoute = '/parent_home';
            }
            break;

          case AuthUnauthenticated():
            targetRoute = '/login';
            break;

          case AuthError():
            targetRoute = '/error';
            break;
        }

        if (targetRoute != null && currentLocation != targetRoute) {
          router.go(targetRoute);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
