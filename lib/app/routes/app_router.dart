import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wajd/features/login/loading_screen.dart';
import '../../features/admin/home/admin_layout.dart';
import '../../features/admin/staff/staff_management_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/login/sign_up_screen.dart';
import '../../features/login/signin_error_screen.dart';
import '../../features/parent/children/add_new_child_screen.dart';
import '../../features/parent/children/childern_list_screen.dart';
import '../../features/parent/home/parent_layout.dart';
import '../../features/parent/report/presentation/report_other_child_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/staff/home/staff_home_screen.dart';
import '../../features/staff/reports/reports_screen.dart';
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
    initialLocation: '/splash',
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

          // Admin routes
          GoRoute(
            path: '/admin_home', 
            builder: (context, state) => const AdminLayout(),
            routes: [
              GoRoute(
                path: 'reports',
                builder: (context, state) => const ReportsScreen(),
              ),
              GoRoute(
                path: 'staff',
                builder: (context, state) => const StaffManagementScreen(),
              ),
            ],
          ),
          
          // Parent routes
          GoRoute(path: '/parent_home', builder: (context, state) => const ParentLayout()),
          
          // Staff routes
          GoRoute(path: '/staff_home', builder: (context, state) => const StaffHomeScreen()),
          GoRoute(path: '/report_other_child', builder: (context, state) => const ReportOtherChildScreen()),

          // Common routes
          GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
          GoRoute(path: '/children-list', builder: (context, state) => const ChildrenListScreen()),
          GoRoute(path: '/add-child', builder: (context, state) => const AddNewChildScreen()),
          GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen(),
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const EditProfileScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          ),
        ],
      ),
    ],
  );
});
