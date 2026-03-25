import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/pages/home_page.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/pages/settings_page.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/pages/wallpaper_detail_page.dart';
import 'package:miui_icon_generator/image_utility/features/image_generation/presentation/pages/image_generation_page.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/pages/bulk_download_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/generate',
        builder: (context, state) => const ImageGenerationPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/bulk-download',
        builder: (context, state) => const BulkDownloadPage(),
      ),
      GoRoute(
        path: '/wallpaper/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final source = state.uri.queryParameters['source'] ?? '';
          return WallpaperDetailPageEnhanced(
            wallpaperId: id,
            source: source,
          );
        },
      ),
    ],
  );
});
