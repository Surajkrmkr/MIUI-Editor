import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/wall_rio/presentation/widgets/stat_card.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';
import '../../application/providers/buffy_cms_provider.dart';
import '../../application/providers/buffy_analytics_provider.dart';
import '../../domain/models/buffy_wallpaper.dart';
import '../widgets/buffy_catalog_fields_view.dart';
import '../widgets/buffy_publish_dialog.dart';
import '../widgets/buffy_push_banner_view.dart';
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

enum _BuffyView {
  wallpapers('Wallpapers', Icons.wallpaper_rounded),
  fields('Catalog Fields', Icons.data_object_rounded),
  push('Push Banners', Icons.notifications_active_outlined);

  const _BuffyView(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _BuffyDashboardScreenState extends ConsumerState<BuffyDashboardScreen> {
  bool _showGitPanel = false;
  String _searchQuery = '';
  String? _category;
  _BuffyView _view = _BuffyView.wallpapers;

  @override
  Widget build(BuildContext context) {
    final cmsState = ref.watch(buffyCmsProvider);
    final isLoaded = cmsState.generation != null;
    final showWalls = isLoaded && _view == _BuffyView.wallpapers;

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
        title: isLoaded
            ? SegmentedButton<_BuffyView>(
                showSelectedIcon: false,
                segments: [
                  for (final v in _BuffyView.values)
                    ButtonSegment(value: v, label: Text(v.label), icon: Icon(v.icon, size: 16)),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              )
            : const Text('BuffyWalls CMS'),
        actions: [
          _AppBarBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Reload from Firebase',
            onPressed: () => _reload(context),
          ),
          _AppBarBtn(
            icon: _showGitPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
            tooltip: 'Toggle Source Control',
            isActive: _showGitPanel,
            onPressed: () => setState(() => _showGitPanel = !_showGitPanel),
          ),
          if (showWalls) ...[
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
          ],
          if (isLoaded) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: cmsState.isDirty ? 'Unpublished changes' : 'No unpublished changes',
              child: FilledButton.tonalIcon(
                onPressed: () => showBuffyPublishDialog(context),
                icon: Badge(
                  isLabelVisible: cmsState.isDirty,
                  smallSize: 8,
                  child: const Icon(Icons.cloud_upload_rounded, size: 18),
                ),
                label: const Text('Publish'),
              ),
            ),
          ],
          const SizedBox(width: 12),
        ],
      ),
      drawer: const BuffySidebar(),
      body: Row(
        children: [
          Expanded(
            child: cmsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : !isLoaded
                    ? _buildSetupView(context, cmsState.error)
                    : switch (_view) {
                        _BuffyView.wallpapers => _buildMainContent(context, cmsState, ref),
                        _BuffyView.fields => const BuffyCatalogFieldsView(),
                        _BuffyView.push => const BuffyPushBannerView(),
                      },
          ),
          if (_showGitPanel) 
            const BuffyGitPanel(),
        ],
      ),
      floatingActionButton: showWalls
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context, cmsState),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }

  Widget _buildSetupView(BuildContext context, String? error) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colors.bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: colors.textDisabled),
            const SizedBox(height: 24),
            Text(
              'Catalog not loaded',
              style: TextStyle(
                fontSize: 22,
                color: colors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SelectableText(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const BuffySettingsDialog()),
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open Settings'),
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
    final colors = context.appColors;
    final analyticsState = ref.watch(buffyAnalyticsStateProvider);
    final categories = state.wallpapers.map((w) => w.category).toSet().toList()..sort();
    final category = categories.contains(_category) ? _category : null;
    final query = _searchQuery.toLowerCase();
    final filteredWalls = state.wallpapers.where((w) {
      if (category != null && w.category != category) return false;
      if (query.isEmpty) return true;
      return '${w.id} ${w.name} ${w.category} ${w.designer} ${w.tags.join(' ')}'
          .toLowerCase()
          .contains(query);
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
                StatCard(
                  title: 'Wallpapers',
                  value: '${state.wallpapers.length}',
                  icon: Icons.image,
                  color: colors.primary,
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: 'Categories',
                  value: '${categories.length}',
                  icon: Icons.category,
                  color: colors.success,
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: 'Premium',
                  value: '${state.wallpapers.where((w) => w.isPremium).length}',
                  icon: Icons.star,
                  color: colors.warning,
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: 'Hot',
                  value: '${state.wallpapers.where((w) => w.isHot).length}',
                  icon: Icons.whatshot_rounded,
                  color: colors.error,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  'buffy.json',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(width: 12),
                Text('${filteredWalls.length} shown', style: TextStyle(color: colors.textSecondary)),
                const Spacer(),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('category-$category'),
                    initialValue: category,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      for (final c in categories)
                        DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 280,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search name, ID, tags…',
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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.5,
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

  Future<void> _reload(BuildContext context) async {
    if (ref.read(buffyCmsProvider).isDirty) {
      final confirmed = await _confirm(
        context,
        title: 'Discard unpublished changes?',
        message: 'Reloading replaces your edits with the live catalog.',
        action: 'Discard',
      );
      if (!confirmed) return;
    }
    ref.read(buffyCmsProvider.notifier).load();
    ref.read(buffyAnalyticsStateProvider.notifier).refresh();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return confirmed == true;
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
    final colors = context.appColors;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.network(
                    wall.compressUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    gaplessPlayback: true,
                    frameBuilder: (_, child, frame, sync) => sync || frame != null
                        ? child
                        : ColoredBox(color: colors.bgSubtle),
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: colors.bgSubtle,
                      child: Center(child: Icon(Icons.broken_image_outlined, color: colors.textDisabled)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wall.name,
                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '#${wall.id} · ${wall.category} · ${wall.designer}',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.delete_outline, size: 16, color: colors.textDisabled),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (wall.isHot)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.whatshot_rounded, size: 14, color: colors.error),
                      Text('HOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    ],
                  ),
                ),
              ),
            if (wall.isPremium)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: colors.warning,
                  radius: 12,
                  child: Icon(Icons.star, size: 16, color: colors.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
