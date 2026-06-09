import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';
import '../../application/providers/buffy_cms_provider.dart';
import '../../application/providers/buffy_settings_provider.dart';
import '../../application/providers/buffy_analytics_provider.dart';
import '../../domain/models/buffy_wallpaper.dart';
import '../widgets/buffy_wallpaper_form.dart';
import '../widgets/buffy_settings_dialog.dart';
import '../widgets/buffy_git_panel.dart';
import '../widgets/buffy_sidebar.dart';
import '../widgets/buffy_batch_add_dialog.dart';

class BuffyDashboardScreen extends ConsumerStatefulWidget {
  const BuffyDashboardScreen({super.key});

  @override
  ConsumerState<BuffyDashboardScreen> createState() => _BuffyDashboardScreenState();
}

class _BuffyDashboardScreenState extends ConsumerState<BuffyDashboardScreen> {
  bool _showGitPanel = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cmsState = ref.watch(buffyCmsProvider);
    final settings = ref.watch(buffySettingsProvider);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 88,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBackButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
            Builder(
              builder: (ctx) => _AppBarBtn(
                icon: Icons.menu_rounded,
                tooltip: 'Navigation Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ],
        ),
        title: Text(settings.jsonFilePath.isNotEmpty
            ? 'Dashboard - ${settings.jsonFilePath.split('\\').last.split('/').last}'
            : 'Dashboard'),
        actions: [
          _AppBarBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: () {
              if (settings.jsonFilePath.isNotEmpty) {
                ref.read(buffyCmsProvider.notifier).loadFile(settings.jsonFilePath);
                ref.read(buffyAnalyticsStateProvider.notifier).refresh();
              }
            },
          ),
          _AppBarBtn(
            icon: _showGitPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
            tooltip: 'Toggle Source Control',
            isActive: _showGitPanel,
            onPressed: () => setState(() => _showGitPanel = !_showGitPanel),
          ),
          if (settings.jsonFilePath.isNotEmpty) ...[
            const _AppBarDivider(),
            _AppBarBtn(
              icon: Icons.add_photo_alternate_rounded,
              tooltip: 'Batch Add',
              onPressed: () => _showBatchAddDialog(context, cmsState),
            ),
            _AppBarBtn(
              icon: Icons.add_circle_outline_rounded,
              tooltip: 'Add Wallpaper',
              onPressed: () => _showAddDialog(context, cmsState),
            ),
            _AppBarBtn(
              icon: Icons.save_rounded,
              tooltip: 'Save & Backup',
              onPressed: () => _showSaveDialog(context),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      drawer: const BuffySidebar(),
      body: Row(
        children: [
          Expanded(
            child: cmsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : settings.jsonFilePath.isEmpty
                    ? _buildSetupView(context)
                    : _buildMainContent(context, cmsState, ref),
          ),
          if (_showGitPanel) 
            const BuffyGitPanel(),
        ],
      ),
      floatingActionButton: settings.jsonFilePath.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(context, cmsState),
              tooltip: 'Quick Add Single',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSetupView(BuildContext context) {
    final colors = context.appColors;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colors.bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 80, color: colors.textDisabled),
            const SizedBox(height: 24),
            Text(
              'No JSON file loaded',
              style: TextStyle(
                fontSize: 22,
                color: colors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: InkWell(
                    onTap: () => showDialog(context: context, builder: (_) => const BuffySettingsDialog()),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 180,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.border,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 32,
                              color: colors.border,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Empty Slot',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textDisabled,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const BuffySettingsDialog()),
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Configure JSON Path'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
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

  Widget _buildMainContent(BuildContext context, BuffyCmsState state, WidgetRef ref) {
    final analyticsState = ref.watch(buffyAnalyticsStateProvider);
    final filteredWalls = state.wallpapers.where((w) {
      final query = _searchQuery.toLowerCase();
      return w.name.toLowerCase().contains(query) || 
             w.category.toLowerCase().contains(query) ||
             w.id.toString().contains(query);
    }).toList();

    return CustomScrollView(
      slivers: [
        analyticsState.when(
          data: (analytics) {
            if (analytics == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
            final admob = analytics.admob;
            final play  = analytics.play;
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Yesterday AdMob Earnings (Buffy)',
                        value: admob == null
                            ? '—'
                            : '\$${admob.earnings.toStringAsFixed(2)}',
                        icon: Icons.monetization_on,
                        color: context.appColors.primary,
                        metrics: admob == null ? [] : [
                          ('Impressions', '${admob.impressions}'),
                          ('Requests',    '${admob.requests}'),
                          ('Match Rate',  '${(admob.matchRate * 100).toStringAsFixed(1)}%'),
                          ('eCPM',        '\$${admob.ecpm.toStringAsFixed(3)}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Play Console (Buffy)',
                        value: play == null ? '—' : 'Active',
                        icon: Icons.android_rounded,
                        color: Colors.greenAccent.shade400,
                        metrics: play == null ? [] : [
                          ('Crash Rate', '${(play.crashRate * 100).toStringAsFixed(2)}%'),
                          ('ANR Rate',   '${(play.anrRate * 100).toStringAsFixed(2)}%'),
                          ('Active Devices', '${play.activeDevices}'),
                          ('Revenue',    'GCS export only'),
                        ],
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
                _StatCard(
                  title: 'Total Wallpapers',
                  value: state.wallpapers.length.toString(),
                  icon: Icons.image,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Categories',
                  value: state.wallpapers.map((w) => w.category).toSet().length.toString(),
                  icon: Icons.category,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Premium',
                  value: state.wallpapers.where((w) => w.isPremium).length.toString(),
                  icon: Icons.star,
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Hot',
                  value: state.wallpapers.where((w) => w.isHot).length.toString(),
                  icon: Icons.whatshot_rounded,
                  color: Colors.redAccent,
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
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, category or ID...',
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
                final wall = filteredWalls[index];
                return _WallpaperCard(
                  wall: wall,
                  onEdit: () => _showEditDialog(context, state, wall),
                  onDelete: () => _confirmDelete(context, wall.id),
                );
              },
              childCount: filteredWalls.length,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, BuffyCmsState state) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: BuffyWallpaperForm(
          existingTags: state.wallpapers.expand((w) => w.tags).toSet().toList()..sort(),
          existingColors: state.wallpapers.expand((w) => w.colors).toSet().toList()..sort(),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, BuffyCmsState state, BuffyWallpaper w) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: BuffyWallpaperForm(
          initialWallpaper: w,
          existingTags: state.wallpapers.expand((w) => w.tags).toSet().toList()..sort(),
          existingColors: state.wallpapers.expand((w) => w.colors).toSet().toList()..sort(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Wallpaper?'),
        content: Text('Are you sure you want to delete wallpaper ID #$id?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(buffyCmsProvider.notifier).deleteWallpaper(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will update the local JSON file. You will still need to push changes to Git.'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Describe changes (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(buffyCmsProvider.notifier).saveFile();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBatchAddDialog(BuildContext context, BuffyCmsState state) {
    showDialog(
      context: context,
      builder: (context) => BuffyBatchAddDialog(
        existingCategories: state.wallpapers.map((w) => w.category).toSet().toList()..sort(),
        existingTags: state.wallpapers.expand((w) => w.tags).toSet().toList()..sort(),
        existingColors: state.wallpapers.expand((w) => w.colors).toSet().toList()..sort(),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<(String, String)> metrics;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.metrics = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
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
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: metrics.map((m) => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${m.$1}  ',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: m.$2,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppBarBtn extends StatelessWidget {
  const _AppBarBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive ? colors.primarySelection : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(
                  icon,
                  size: 17,
                  color: isActive ? colors.primary : colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarDivider extends StatelessWidget {
  const _AppBarDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      child: VerticalDivider(
        width: 1,
        color: context.appColors.borderSubtle,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
  final BuffyWallpaper wall;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  child: Image.network(
                    wall.compressUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 16, color: Theme.of(context).colorScheme.error),
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
          if (wall.isHot && !wall.isPremium)
            const Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.redAccent,
                radius: 12,
                child: Icon(Icons.whatshot_rounded, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
