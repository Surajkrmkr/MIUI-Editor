import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

// ── Shared theme ──────────────────────────────────────────────────────────────
import 'core/theme/app_theme.dart';

// ── Theme Editor imports ──────────────────────────────────────────────────────
import 'theme_editor/core/services/window_service.dart';
import 'theme_editor/presentation/features/splash/user_profile_screen.dart';
import 'theme_editor/presentation/providers/service_providers.dart';

// ── Image Utility imports ─────────────────────────────────────────────────────
import 'image_utility/core/utils/windows.dart';
import 'image_utility/core/router/app_router.dart';

// ── Theme Deployment imports ──────────────────────────────────────────────────
import 'theme_deployment/presentation/pages/deployment_page.dart';

// =============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await WindowService.init();
    await startUpWindowsUtils();
  }

  // Android permissions
  if (Platform.isAndroid) {
    await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
  }

  // Video player
  VideoPlayerMediaKit.ensureInitialized(
    android: true,
    iOS: true,
    macOS: true,
    windows: true,
  );

  // Global error widget
  ErrorWidget.builder = (details) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          details.exceptionAsString(),
          textAlign: TextAlign.center,
        ),
      );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const RootApp(),
    ),
  );
}

// =============================================================================
// Root app — shows the launcher, hosts both sub-apps via Navigator
// =============================================================================

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MIUI Tools',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const AppLauncherScreen(),
      );
}

// =============================================================================
// Launcher — add new apps here forever, no other file needs to change
// =============================================================================

class _AppEntry {
  const _AppEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Returns the root widget of the sub-app.
  /// Each sub-app is fully self-contained — its own MaterialApp / router.
  final Widget Function() builder;
}

// ── Register apps here ────────────────────────────────────────────────────────

final List<_AppEntry> _apps = [
  _AppEntry(
    title: 'Theme Editor',
    subtitle: 'Lockscreen · Icons · Module · MTZ',
    icon: Icons.layers_rounded,
    color: const Color(0xFFD27685),
    builder: () => const _ThemeEditorApp(),
  ),
  _AppEntry(
    title: 'Image Utility',
    subtitle: 'Resize · Crop · Convert · Export',
    icon: Icons.image_rounded,
    color: const Color(0xFF6C8EBF),
    builder: () => const _ImageUtilityApp(),
  ),
  _AppEntry(
    title: 'Themes Deployment',
    subtitle: 'Upload · Designer Portal · Automation',
    icon: Icons.rocket_launch,
    color: const Color(0xFF7DAF7A),
    builder: () => const _ThemeDeploymentApp(),
  ),
  // ── Add more apps below — no other code changes needed ────────────────────
  // _AppEntry(
  //   title:   'New Tool',
  //   subtitle: 'Description',
  //   icon:    Icons.build_rounded,
  //   color:   Color(0xFF7DAF7A),
  //   builder: () => const NewToolApp(),
  // ),
];

// ─────────────────────────────────────────────────────────────────────────────

class AppLauncherScreen extends StatelessWidget {
  const AppLauncherScreen({super.key});

  void _launch(BuildContext context, _AppEntry app) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => app.builder(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 20),
              Text(
                'MIUI Tools',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a tool to get started',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 48),
              // App grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _apps.length,
                  itemBuilder: (context, i) => _AppCard(
                      app: _apps[i], onTap: () => _launch(context, _apps[i])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AppCard extends StatefulWidget {
  const _AppCard({required this.app, required this.onTap});
  final _AppEntry app;
  final VoidCallback onTap;

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _hovering
                ? widget.app.color.withAlpha(40)
                : Colors.white.withAlpha(8),
            border: Border.all(
              color: _hovering
                  ? widget.app.color.withAlpha(180)
                  : Colors.white.withAlpha(20),
              width: _hovering ? 1.5 : 1,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: widget.app.color.withAlpha(60),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(widget.app.icon, color: widget.app.color, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.app.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.app.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sub-app wrappers — each is a full MaterialApp / router in its own scope
// =============================================================================

// ── Theme Editor ──────────────────────────────────────────────────────────────

class _ThemeEditorApp extends ConsumerWidget {
  const _ThemeEditorApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
        title: 'MIUI Theme Editor',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const UserProfileScreen(),
        // Back button on AppBar automatically pops back to launcher
        // because this MaterialApp is pushed onto the root Navigator.
      );
}

// ── Image Utility ─────────────────────────────────────────────────────────────

class _ImageUtilityApp extends ConsumerWidget {
  const _ImageUtilityApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Image Utility',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

// ── Themes Deployment ─────────────────────────────────────────────────────────

class _ThemeDeploymentApp extends StatelessWidget {
  const _ThemeDeploymentApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Themes Deployment',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const DeploymentPage(),
      );
}
