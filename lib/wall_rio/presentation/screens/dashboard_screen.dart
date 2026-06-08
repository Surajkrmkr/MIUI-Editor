import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../application/providers/cms_provider.dart';
import '../../application/providers/settings_provider.dart';
import '../../application/providers/analytics_provider.dart';
import '../../domain/models/wallpaper.dart';
import '../widgets/batch_add_dialog.dart';
import '../widgets/sidebar.dart';
import '../widgets/stat_card.dart';
import '../widgets/wallpaper_form.dart';
import '../widgets/git_panel.dart';
import 'package:path/path.dart' as p;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showGitPanel = false;

  @override
  Widget build(BuildContext context) {
    final cmsState = ref.watch(cmsProvider);
    final currentPath = ref.watch(currentFilePathProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPath != null 
            ? 'Dashboard - ${currentPath.split('\\').last.split('/').last}'
            : 'Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analytics',
            onPressed: () => ref.read(analyticsStateProvider.notifier).refresh(),
          ),
          IconButton(
            icon: Icon(_showGitPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined),
            tooltip: 'Toggle Source Control',
            onPressed: () => setState(() => _showGitPanel = !_showGitPanel),
          ),
          if (currentPath != null) ...[
            IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              tooltip: 'Batch Add',
              onPressed: () => _showBatchAddDialog(context, cmsState.value!),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Single Add',
              onPressed: () => _showAddWallpaperDialog(context, cmsState.value!),
            ),
            const VerticalDivider(width: 20, indent: 10, endIndent: 10),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save & Backup',
              onPressed: () => _showSaveDialog(context, ref, currentPath),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Open JSON',
            onPressed: () => _openFile(context, ref),
          ),
        ],
      ),
      drawer: const Sidebar(),
      body: Row(
        children: [
          Expanded(
            child: cmsState.when(
              data: (data) {
                if (data == null) {
                  return _buildProjectSelection(context, ref);
                }
                return _buildDashboardContent(context, data, ref);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final path = ref.read(currentFilePathProvider);
                        if (path != null) {
                          ref.read(cmsProvider.notifier).loadFile(path);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(currentFilePathProvider.notifier).set(null);
                        ref.read(cmsProvider.notifier).updateData(null as dynamic);
                      },
                      child: const Text('Back to Project Selection'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showGitPanel) const GitPanel(),
        ],
      ),
      floatingActionButton: currentPath != null
          ? FloatingActionButton(
              onPressed: () => _showAddWallpaperDialog(context, cmsState.value!),
              tooltip: 'Quick Add Single',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProjectSelection(BuildContext context, WidgetRef ref) {
    final savedPathsState = ref.watch(savedPathsProvider);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0A0A0A), // Very dark background
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            const Text(
              'No JSON file loaded',
              style: TextStyle(
                fontSize: 22, 
                color: Colors.white54,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 64),
            savedPathsState.when(
              data: (paths) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final p = index < paths.length ? paths[index] : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _ProjectSlot(
                        index: index,
                        label: p?.label,
                        path: p?.path,
                        onSelect: p != null ? () {
                          ref.read(currentFilePathProvider.notifier).set(p.path);
                          ref.read(cmsProvider.notifier).loadFile(p.path);
                        } : null,
                        onConfigure: () => context.go('/settings'),
                      ),
                    );
                  }),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 80),
            ElevatedButton.icon(
              onPressed: () => _openFile(context, ref),
              icon: const Icon(Icons.file_open_rounded),
              label: const Text('Open WallRio JSON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: const Color(0xFFA182FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, RioData data, WidgetRef ref) {
    final walls = data.walls;
    final categories = walls.map((w) => w.category).toSet().toList();
    final premium = walls.where((w) => w.isPremium).length;
    final analyticsState = ref.watch(analyticsStateProvider);

    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return CustomScrollView(
      slivers: [
        analyticsState.when(
          data: (analytics) {
            if (analytics == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Yesterday AdMob Earnings',
                        value: currencyFormat.format(analytics.admob?.earnings ?? 0),
                        subtitle: 'Impressions: ${analytics.admob?.impressions ?? 0}',
                        icon: Icons.monetization_on,
                        color: Colors.purpleAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Yesterday Play Revenue',
                        value: currencyFormat.format(analytics.play?.revenue ?? 0),
                        subtitle: 'Installs: ${analytics.play?.installs ?? 0}',
                        icon: Icons.trending_up,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: LinearProgressIndicator()),
          error: (err, _) => SliverToBoxAdapter(child: Center(child: Text('Analytics Error: $err', style: const TextStyle(color: Colors.red, fontSize: 10)))),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                StatCard(
                  title: 'Total Wallpapers',
                  value: walls.length.toString(),
                  icon: Icons.image,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: 'Categories',
                  value: categories.length.toString(),
                  icon: Icons.category,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: 'Premium',
                  value: premium.toString(),
                  icon: Icons.star,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wallpapers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search wallpapers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final wall = walls[index];
                return _WallpaperCard(
                  wall: wall,
                  onEdit: () => _showEditWallpaperDialog(context, data, wall),
                  onDelete: () => _showDeleteDialog(context, ref, wall),
                );
              },
              childCount: walls.length,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddWallpaperDialog(BuildContext context, RioData data) {
    showDialog(
      context: context,
      builder: (context) => WallpaperForm(
        existingCategories: data.walls.map((w) => w.category).toSet().toList()..sort(),
        existingTags: data.walls.expand((w) => w.tags).toSet().toList()..sort(),
        existingColors: data.walls.expand((w) => w.color).toSet().toList()..sort(),
      ),
    );
  }

  void _showEditWallpaperDialog(BuildContext context, RioData data, Wallpaper wall) {
    showDialog(
      context: context,
      builder: (context) => WallpaperForm(
        initialWallpaper: wall,
        existingCategories: data.walls.map((w) => w.category).toSet().toList()..sort(),
        existingTags: data.walls.expand((w) => w.tags).toSet().toList()..sort(),
        existingColors: data.walls.expand((w) => w.color).toSet().toList()..sort(),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref, Wallpaper wall) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallpaper'),
        content: Text('Are you sure you want to delete "${wall.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(cmsProvider.notifier).deleteWallpaper(wall.id);
    }
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      ref.read(currentFilePathProvider.notifier).set(path);
      await ref.read(cmsProvider.notifier).loadFile(path);
      
      // Save to shared prefs for next time
      await ref.read(jsonPathProvider.notifier).setPath(path);
    }
  }

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref, String path) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a commit message for this version:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Added new wallpapers to abstract category',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save & Backup'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      await ref.read(cmsProvider.notifier).saveFile(path, controller.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved and backup created!')),
        );
      }
    }
  }

  void _showBatchAddDialog(BuildContext context, RioData data) {
    showDialog(
      context: context,
      builder: (context) => BatchAddDialog(
        existingCategories: data.walls.map((w) => w.category).toSet().toList()..sort(),
        existingTags: data.walls.expand((w) => w.tags).toSet().toList()..sort(),
        existingColors: data.walls.expand((w) => w.color).toSet().toList()..sort(),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSlot extends StatelessWidget {
  final int index;
  final String? label;
  final String? path;
  final VoidCallback? onSelect;
  final VoidCallback onConfigure;

  const _ProjectSlot({
    required this.index,
    this.label,
    this.path,
    this.onSelect,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = label == null;

    return InkWell(
      onTap: onSelect ?? onConfigure,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: onSelect != null ? Colors.deepPurple.withValues(alpha: 0.3) : Colors.white10,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            if (!isEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Slot ${index + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.deepPurpleAccent),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEmpty ? Icons.add_circle_outline : Icons.insert_drive_file_outlined,
                    size: 32,
                    color: isEmpty ? Colors.white10 : Colors.deepPurpleAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEmpty ? 'Empty Slot' : label!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isEmpty ? Colors.white24 : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                      child: Text(
                        path!.split('\\').last.split('/').last,
                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperCard extends StatelessWidget {
  final Wallpaper wall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WallpaperCard({
    required this.wall,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  child: Image.network(
                    wall.thumbnail,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wall.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          wall.category,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (wall.isPremium)
            const Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.orange,
                radius: 12,
                child: Icon(Icons.star, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
