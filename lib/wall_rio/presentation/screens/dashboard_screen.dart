import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';

import '../../application/providers/analytics_provider.dart';
import '../../application/providers/catalog_provider.dart';
import '../../domain/models/catalog.dart';
import '../../infrastructure/services/storage_client.dart';
import '../widgets/collection_dialog.dart';
import '../widgets/entry_edit_dialog.dart';
import '../widgets/sidebar.dart';
import '../widgets/stat_card.dart';
import '../widgets/storage_image.dart';
import '../widgets/upload_dialog.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final kind = ref.watch(selectedKindProvider);
    final catalog = ref.watch(catalogProvider(kind));
    final doc = catalog.valueOrNull;
    final collectionId = doc == null ? null : _collectionIdFor(doc);
    // Collections: uploading needs a collection to upload into.
    final canUpload = doc != null && (!kind.hasCollections || collectionId != null);

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
        title: SegmentedButton<CatalogKind>(
          showSelectedIcon: false,
          segments: [
            for (final k in CatalogKind.values)
              ButtonSegment(value: k, label: Text(k.label)),
          ],
          selected: {kind},
          onSelectionChanged: (s) {
            setState(() => _category = null);
            ref.read(selectedKindProvider.notifier).select(s.first);
          },
        ),
        actions: [
          _AppBarBtn(
            icon: Icons.insights_rounded,
            tooltip: 'Refresh Analytics',
            onPressed: () => ref.read(analyticsStateProvider.notifier).refresh(),
          ),
          _AppBarBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Reload ${kind.jsonFile}',
            onPressed: () => ref.read(catalogProvider(kind).notifier).reload(),
          ),
          _AppBarBtn(
            icon: Icons.history_rounded,
            tooltip: 'History & Restore',
            onPressed: () => context.go('/history'),
          ),
          const _AppBarDivider(),
          _AppBarBtn(
            icon: Icons.cloud_upload_outlined,
            tooltip: 'Upload Wallpapers',
            onPressed: canUpload
                ? () => showUploadDialog(context, doc, collectionId: collectionId)
                : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const Sidebar(),
      body: catalog.when(
        data: (doc) => _buildContent(context, doc, _collectionIdFor(doc)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _CatalogError(
          error: err,
          onRetry: () => ref.invalidate(catalogProvider(kind)),
        ),
      ),
      floatingActionButton: !canUpload
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showUploadDialog(context, doc, collectionId: collectionId),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload'),
            ),
    );
  }

  /// The selected collection, falling back to the first; null for other kinds.
  String? _collectionIdFor(CatalogDocument doc) {
    if (!doc.kind.hasCollections) return null;
    final selected = ref.watch(selectedCollectionProvider);
    if (doc.collection(selected) != null) return selected;
    final collections = doc.collections;
    return collections.isEmpty ? null : '${collections.first['id']}';
  }

  Future<void> _editCollection(Map<String, dynamic>? existing) async {
    final id = await showCollectionDialog(context, existing: existing);
    if (id == null || !mounted) return;
    setState(() => _category = null);
    ref.read(selectedCollectionProvider.notifier).select(id);
  }

  Widget _buildContent(BuildContext context, CatalogDocument doc, String? collectionId) {
    final colors = context.appColors;
    final collection = doc.kind.hasCollections ? doc.collection(collectionId) : null;
    final walls = doc.kind.hasCollections && collectionId == null
        ? <Map<String, dynamic>>[]
        : doc.wallsOf(collectionId);
    final categories = walls.map((w) => '${w['category'] ?? ''}').where((c) => c.isNotEmpty).toSet().toList()..sort();
    final premium = walls.where((w) => w['isPremium'] == true).length;
    final query = _query.toLowerCase();
    final visible = walls.where((w) {
      if (_category != null && w['category'] != _category) return false;
      if (query.isEmpty) return true;
      return '${w['name']} ${w['author']} ${(w['tags'] as List? ?? const []).join(' ')}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final isDesktop = doc.kind == CatalogKind.desktop;
    final title = collection == null ? doc.kind.jsonFile : '${collection['name']}';

    return CustomScrollView(
      slivers: [
        _buildAnalytics(context),
        if (doc.kind.hasCollections) _buildCollectionBar(context, doc, collection),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                StatCard(title: 'Wallpapers', value: '${walls.length}', icon: Icons.image, color: colors.primary),
                const SizedBox(width: 16),
                StatCard(title: 'Categories', value: '${categories.length}', icon: Icons.category, color: colors.success),
                const SizedBox(width: 16),
                StatCard(title: 'Premium', value: '$premium', icon: Icons.star, color: colors.warning),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(width: 12),
                Text('${visible.length} shown', style: TextStyle(color: colors.textSecondary)),
                const Spacer(),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('${doc.kind}-$collectionId'),
                    initialValue: _category,
                    isDense: true,
                    // Long category names get an ellipsis instead of overflowing.
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
                    decoration: InputDecoration(
                      hintText: 'Search name, author, tags…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isDesktop ? 340 : 200,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.35 : 0.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _WallpaperCard(
                entry: visible[index],
                kind: doc.kind,
                onTap: () => showEntryEditDialog(
                  context,
                  doc,
                  visible[index],
                  collectionId: collectionId,
                ),
              ),
              childCount: visible.length,
            ),
          ),
        ),
      ],
    );
  }

  /// Collection picker plus create / edit, above the stats.
  Widget _buildCollectionBar(
    BuildContext context,
    CatalogDocument doc,
    Map<String, dynamic>? collection,
  ) {
    final colors = context.appColors;
    final collections = doc.collections;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String>(
                key: ValueKey('collection-${collection?['id']}-${collections.length}'),
                initialValue: collection == null ? null : '${collection['id']}',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Collection', isDense: true),
                items: [
                  for (final c in collections)
                    DropdownMenuItem(
                      value: '${c['id']}',
                      child: Text(
                        '${c['name']}  (${(c['walls'] as List? ?? const []).length})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  setState(() => _category = null);
                  ref.read(selectedCollectionProvider.notifier).select(id);
                },
              ),
            ),
            const SizedBox(width: 12),
            if (collection != null) ...[
              Flexible(
                child: Text(
                  '${collection['productId']}'
                  '${collection['hideForIOS'] == true ? '  ·  hidden on iOS' : ''}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Edit collection',
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _editCollection(collection),
              ),
            ],
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _editCollection(null),
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('New collection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context) {
    final colors = context.appColors;
    return ref.watch(analyticsStateProvider).when(
          data: (analytics) {
            if (analytics == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
            final admob = analytics.admob;
            final play = analytics.play;
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Yesterday AdMob Earnings',
                        value: admob == null ? '—' : '\$${admob.earnings.toStringAsFixed(2)}',
                        icon: Icons.monetization_on,
                        color: colors.primary,
                        metrics: admob == null
                            ? []
                            : [
                                ('Impressions', '${admob.impressions}'),
                                ('Requests', '${admob.requests}'),
                                ('Match Rate', '${(admob.matchRate * 100).toStringAsFixed(1)}%'),
                                ('eCPM', '\$${admob.ecpm.toStringAsFixed(3)}'),
                              ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Play Console',
                        value: play == null ? '—' : 'Active',
                        icon: Icons.android_rounded,
                        color: colors.success,
                        metrics: play == null
                            ? []
                            : [
                                ('Crash Rate', '${(play.crashRate * 100).toStringAsFixed(2)}%'),
                                ('ANR Rate', '${(play.anrRate * 100).toStringAsFixed(2)}%'),
                                ('Rating', play.averageRating > 0 ? play.averageRating.toStringAsFixed(1) : '—'),
                                ('Revenue', 'GCS export only'),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: LinearProgressIndicator()),
          error: (err, _) => SliverToBoxAdapter(
            child: Center(
              child: Text('Analytics Error: $err', style: TextStyle(color: colors.error, fontSize: 10)),
            ),
          ),
        );
  }
}

/// Explains why the catalog didn't load, with the most likely fix.
class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final notSignedIn = error is NotSignedInException;
    // Google rejected the saved refresh token (expired or revoked).
    final expired = '$error'.contains('invalid_grant');
    final missingScope = error is StorageException &&
        ((error as StorageException).statusCode == 403 ||
            (error as StorageException).statusCode == 401);
    final needsSignIn = notSignedIn || expired || missingScope;
    final message = notSignedIn
        ? 'Sign in with Google in Settings to load the catalogs.'
        : expired
            ? 'Your Google sign-in has expired. In Settings → Credentials, '
                'click Switch next to Google Cloud and sign in again.'
            : missingScope
            ? 'Your Google sign-in has no Storage access yet. In Settings → '
                'Credentials, click Switch next to Google Cloud and sign in again to grant it.'
            : '$error';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(needsSignIn ? Icons.lock_outline : Icons.error_outline,
                size: 48, color: colors.textDisabled),
            const SizedBox(height: 16),
            SelectableText(message, textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (needsSignIn)
                  FilledButton(
                    onPressed: () => showWallRioSettings(context),
                    child: const Text('Open Settings'),
                  ),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperCard extends StatelessWidget {
  const _WallpaperCard({required this.entry, required this.kind, required this.onTap});

  final Map<String, dynamic> entry;
  final CatalogKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: StorageImage('${entry['thumbnail'] ?? ''}')),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry['name']}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '#${entry['id']} · ${entry['category']} · ${entry['author']}',
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (kind.isVideo)
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
                      Icon(Icons.play_arrow_rounded, size: 14, color: colors.textPrimary),
                      Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    ],
                  ),
                ),
              ),
            if (entry['isPremium'] == true)
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

// =============================================================================
// Modern AppBar toolbar helpers
// =============================================================================

class _AppBarBtn extends StatelessWidget {
  const _AppBarBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

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
                  color: onPressed == null ? colors.textDisabled : colors.textSecondary,
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
