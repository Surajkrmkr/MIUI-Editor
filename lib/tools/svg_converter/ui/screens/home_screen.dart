import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/drop_zone.dart';
import '../widgets/stats_panel.dart';
import '../widgets/wallpaper_carousel.dart';
import 'package:miui_icon_generator/widgets/glass_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          _buildBackgroundGlow(context),
          Column(
            children: [
              _buildTopBar(context),
              _buildCategoryBar(context, state),
              Expanded(
                child: FolderDropZone(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: state.selectedFolder != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 320,
                                child: Column(
                                  children: [
                                    const Expanded(child: StatsPanel()),
                                    const SizedBox(height: 16),
                                    Expanded(
                                        child: _ActionPanel(primary: primary)),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildCarousel(context, state),
                              ),
                            ],
                          )
                        : _buildEmptyState(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: isDark ? 0.08 : 0.06),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: isDark ? 0.04 : 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Row(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(8),
            borderRadius: 12,
            child: InkWell(
              onTap: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Icon(Icons.arrow_back_rounded,
                  color: colors.textPrimary, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Row(
        children: [
          _CategoryChip(
            label: 'Library',
            count: state.tasks.length,
            isSelected: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spatial_audio_off_rounded,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.15)),
          const SizedBox(height: 32),
          Text(
            'Initialize Spatial Workspace',
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Drag folders or click to map source images',
            style: TextStyle(color: colors.textDisabled, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final path = await FilePicker.platform.getDirectoryPath();
              if (path != null) {
                ProviderScope.containerOf(context)
                    .read(appStateProvider.notifier)
                    .selectFolder(path);
              }
            },
            child: const Text('Map Source Directory'),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: WallpaperCarousel(tasks: state.tasks),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;

  const _CategoryChip({
    required this.label,
    this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 12,
      glowColor: isSelected ? primary : null,
      hasGlow: isSelected,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_rounded,
            size: 14,
            color: isSelected ? primary : colors.textDisabled,
          ),
          const SizedBox(width: 8),
          Text(
            label + (count != null ? ' ($count)' : ''),
            style: TextStyle(
              color: isSelected ? colors.textPrimary : colors.textDisabled,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends ConsumerWidget {
  final Color primary;
  const _ActionPanel({required this.primary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final colors = context.appColors;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      hasGlow: state.isProcessing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spatial Workflow',
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Queue: ${state.pendingCount} tasks remaining',
            style: TextStyle(color: colors.textDisabled, fontSize: 12),
          ),
          const Spacer(),
          if (state.isProcessing)
            _buildButton(
              context: context,
              label: 'HALT PIPELINE',
              icon: Icons.pause_circle_filled_rounded,
              color: Colors.redAccent,
              onPressed: () =>
                  ref.read(appStateProvider.notifier).cancelProcessing(),
            )
          else
            _buildButton(
              context: context,
              label: 'INITIALIZE CONVERSION',
              icon: Icons.play_circle_filled_rounded,
              color: state.isVTracerInstalled ? primary : colors.textDisabled,
              onPressed: () {
                if (!state.isVTracerInstalled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'vtracer not found. Install it with: pip3 install vtracer',
                      ),
                      duration: Duration(seconds: 5),
                    ),
                  );
                  return;
                }
                if (state.tasks.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No images found. Select a folder containing JPG or PNG files.',
                      ),
                    ),
                  );
                  return;
                }
                ref.read(appStateProvider.notifier).startProcessing();
              },
            ),
          const SizedBox(height: 12),
          _buildButton(
            context: context,
            label: 'VIEW OUTPUT LIBRARY',
            icon: Icons.folder_copy_rounded,
            color: colors.surfaceOverlay,
            onPressed: () {
              if (state.selectedFolder != null) {
                final outDir = p.join(state.selectedFolder!, 'svg');
                launchUrl(Uri.parse('file:$outDir'));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final colors = context.appColors;
    final isPrimary = color == Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isPrimary ? colors.onPrimary : colors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.2)),
      ),
    );
  }
}
