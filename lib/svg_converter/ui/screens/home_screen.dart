import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/drop_zone.dart';
import '../widgets/stats_panel.dart';
import '../widgets/wallpaper_carousel.dart';
import '../widgets/glass_card.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
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
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildMainPreview(context, state),
                        ),
                        if (state.selectedFolder != null) ...[
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                const Expanded(child: StatsPanel()),
                                const SizedBox(width: 24),
                                Expanded(child: _ActionPanel(primary: primary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          const Spacer(),
                        ],
                      ],
                    ),
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
              color: primary.withOpacity(0.08),
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
              color: primary.withOpacity(0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Row(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(8),
            borderRadius: 12,
            child: InkWell(
              onTap: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          const _NavIcon(icon: Icons.auto_awesome_mosaic_rounded),
          const SizedBox(width: 16),
          const _NavIcon(icon: Icons.layers_outlined),
          const SizedBox(width: 16),
          const _NavIcon(icon: Icons.search_rounded),
          const Spacer(),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 100,
            child: Row(
              children: [
                const Icon(Icons.history_toggle_off_rounded,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildUserBadge(context),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}';
  }

  Widget _buildUserBadge(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      borderRadius: 100,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: primary),
                const SizedBox(width: 8),
                const Text('READY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person_outline_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 4),
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
          const SizedBox(width: 12),
          const _CategoryChip(label: 'VTracer Tags', count: 4),
          const SizedBox(width: 12),
          const _CategoryChip(label: 'Spline Mode', isDropdown: true),
        ],
      ),
    );
  }

  Widget _buildMainPreview(BuildContext context, AppState state) {
    if (state.selectedFolder == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spatial_audio_off_rounded,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.15)),
            const SizedBox(height: 32),
            const Text(
              'Initialize Spatial Workspace',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Drag folders or click to map source images',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final path =
                    await FilePicker.platform.getDirectoryPath();
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

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: WallpaperCarousel(tasks: state.tasks),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: GlassCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              borderRadius: 100,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_left_rounded,
                      color: Colors.white38),
                  SizedBox(width: 12),
                  Text('SWIPE TO EXPLORE SPATIAL LIBRARY',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  SizedBox(width: 12),
                  Icon(Icons.keyboard_arrow_right_rounded,
                      color: Colors.white38),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  const _NavIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(8),
      borderRadius: 12,
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final bool isDropdown;

  const _CategoryChip({
    required this.label,
    this.count,
    this.isSelected = false,
    this.isDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
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
            isDropdown ? Icons.grid_view_rounded : Icons.folder_rounded,
            size: 14,
            color: isSelected ? primary : Colors.white38,
          ),
          const SizedBox(width: 8),
          Text(
            label + (count != null ? ' ($count)' : ''),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white38,
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isDropdown) ...[
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                size: 14, color: Colors.white38),
          ],
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

    return GlassCard(
      padding: const EdgeInsets.all(20),
      hasGlow: state.isProcessing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spatial Workflow',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Queue: ${state.pendingCount} tasks remaining',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12),
                  ),
                ],
              ),
              const _NavIcon(
                  icon: Icons.settings_input_component_rounded),
            ],
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
              color: state.isVTracerInstalled ? primary : Colors.white24,
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
            color: Colors.white.withOpacity(0.08),
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
    final isPrimary = color == Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isPrimary ? Colors.white : Colors.white70,
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
