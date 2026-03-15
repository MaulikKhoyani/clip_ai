import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/presentation/splash/splash_screen.dart';
import 'package:clip_ai/presentation/onboarding/onboarding_screen.dart';
import 'package:clip_ai/presentation/auth/auth_screen.dart';
import 'package:clip_ai/presentation/home/home_screen.dart';
import 'package:clip_ai/presentation/editor/editor_screen.dart';
import 'package:clip_ai/presentation/settings/settings_screen.dart';
import 'package:clip_ai/presentation/paywall/paywall_screen.dart';
import 'package:clip_ai/presentation/projects/projects_screen.dart';
import 'package:clip_ai/presentation/export/export_screen.dart';
import 'package:clip_ai/presentation/notifications/notification_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

bool get _isLoggedIn => Supabase.instance.client.auth.currentUser != null;

bool get _hasSeenOnboarding {
  final box = Hive.box('settings');
  return box.get('onboarding_completed', defaultValue: false) as bool;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final path = state.matchedLocation;
    final isOnSplash = path == '/';
    final isOnAuthRoute = path == '/auth' || path == '/onboarding';

    if (isOnSplash) return null;

    if (!_hasSeenOnboarding && path != '/onboarding') {
      return '/onboarding';
    }

    if (!_isLoggedIn && !isOnAuthRoute) {
      return '/auth';
    }

    if (_isLoggedIn && isOnAuthRoute) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/projects',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProjectsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/editor',
      builder: (context, state) => const EditorScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/export',
      builder: (context, state) => ExportScreen(
        projectId: state.uri.queryParameters['projectId'],
        videoPath: state.uri.queryParameters['videoPath'],
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/notification-settings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = ['/home', '/projects', '/settings'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.textTertiary, width: 0.2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (index) => context.go(_tabs[index]),
          backgroundColor: AppColors.backgroundDark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder_rounded),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

