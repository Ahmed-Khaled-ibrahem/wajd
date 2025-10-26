import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wajd/features/login/loading_screen.dart';
import '../../features/admin/home/admin_home_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/login/sign_up_screen.dart';
import '../../features/login/signin_error_screen.dart';
import '../../features/parent/home/parent_home_Screen.dart';
import '../../features/staff/home/staff_home_screen.dart';
import '../wrapper/app_wrapper.dart';

final _rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final GlobalKey<NavigatorState> rootKey = ref.watch(
    _rootNavigatorKeyProvider,
  );

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/login',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AuthenticatedWrapper(child: child);
        },
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
          GoRoute(path: '/loading', builder: (context, state) => const LoadingScreen()),
          GoRoute(path: '/error', builder: (context, state) => const SignInErrorScreen()),
          GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),

          GoRoute(path: '/admin_home', builder: (context, state) => const AdminHomeScreen()),
          GoRoute(path: '/parent_home', builder: (context, state) => const ParentHomeScreen()),
          GoRoute(path: '/staff_home', builder: (context, state) => const StaffHomeScreen()),
        ],
      ),
    ],
  );
});
