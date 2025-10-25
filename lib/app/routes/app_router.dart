import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/login/login_screen.dart';
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
        ],
      ),
    ],
  );
});
