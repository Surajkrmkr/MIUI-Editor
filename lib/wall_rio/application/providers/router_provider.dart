import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/git_control_screen.dart';

// Renamed from routerProvider to avoid conflict with image_utility's routerProvider
final wallRioRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/git',
        builder: (context, state) => const GitControlScreen(),
      ),
    ],
  );
});
