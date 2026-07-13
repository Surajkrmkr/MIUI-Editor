import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/bulk_download_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';

class BulkDownloadPage extends ConsumerStatefulWidget {
  const BulkDownloadPage({super.key});

  @override
  ConsumerState<BulkDownloadPage> createState() => _BulkDownloadPageState();
}

class _BulkDownloadPageState extends ConsumerState<BulkDownloadPage> {
  static const _orientations = ['portrait', 'landscape', 'square'];
  static const _colors = [
    'red',
    'orange',
    'yellow',
    'green',
    'turquoise',
    'blue',
    'violet',
    'pink',
    'brown',
    'black',
    'gray',
    'white',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only show criteria dialog when there is no cached selection to restore.
      if (ref.read(bulkDownloadProvider).step == BulkDownloadStep.criteria) {
        _showCriteriaDialog();
      }
    });
  }

  Future<void> _showCriteriaDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          const _CriteriaDialog(orientations: _orientations, colors: _colors),
    );
    if (!mounted) return;
    if (ref.read(bulkDownloadProvider).step == BulkDownloadStep.criteria) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkDownloadProvider);

    return PopScope(
      canPop:
          state.step == BulkDownloadStep.criteria ||
          state.step == BulkDownloadStep.complete,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop &&
            (state.step == BulkDownloadStep.selection ||
                state.step == BulkDownloadStep.processing)) {
          _confirmExit(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleForStep(state.step)),
          leading: AppBackButton.close(
            onPressed: () => _handleBack(context, state.step),
          ),
        ),
        body: _bodyForStep(context, state),
      ),
    );
  }

  String _titleForStep(BulkDownloadStep step) {
    switch (step) {
      case BulkDownloadStep.criteria:
        return 'Bulk Download';
      case BulkDownloadStep.selection:
        return 'Select Wallpapers';
      case BulkDownloadStep.processing:
        return 'Processing...';
      case BulkDownloadStep.complete:
        return 'Download Complete';
    }
  }

  void _handleBack(BuildContext context, BulkDownloadStep step) {
    if (step == BulkDownloadStep.processing) {
      _confirmExit(context);
    } else if (step == BulkDownloadStep.selection) {
      ref.read(bulkDownloadProvider.notifier).reset();
      _showCriteriaDialog();
    } else {
      context.pop();
    }
  }

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Bulk Download?'),
        content: const Text('This will cancel the current operation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Exit',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(bulkDownloadProvider.notifier).reset();
      context.pop();
    }
  }

  Widget _bodyForStep(BuildContext context, BulkDownloadState state) {
    switch (state.step) {
      case BulkDownloadStep.criteria:
        return const SizedBox.shrink();
      case BulkDownloadStep.selection:
        return _SelectionStep(
          wallpapers: state.wallpapers,
          selectedWallpaperIds: state.selectedWallpaperIds,
          isLoadingMore: state.isLoadingMore,
          hasMorePages: state.hasMorePages,
          onToggle: (id) =>
              ref.read(bulkDownloadProvider.notifier).toggleSelection(id),
          onProceed: () =>
              ref.read(bulkDownloadProvider.notifier).startProcessing(),
          onLoadMore: () =>
              ref.read(bulkDownloadProvider.notifier).loadMoreWallpapers(),
        );
      case BulkDownloadStep.processing:
        return _ProcessingStep(state: state);
      case BulkDownloadStep.complete:
        return _CompleteStep(
          state: state,
          onRetryFailed: state.failedCount > 0
              ? () => ref.read(bulkDownloadProvider.notifier).retryFailed()
              : null,
          onRename: (index, newName) => ref
              .read(bulkDownloadProvider.notifier)
              .renameResult(index, newName),
          onBulkRename: (baseName) =>
              ref.read(bulkDownloadProvider.notifier).bulkRename(baseName),
          onDone: () {
            ref.read(bulkDownloadProvider.notifier).reset();
            context.pop();
          },
        );
    }
  }
}

// ─────────────────────────────────────────────
// Step 1: Search Criteria (shown as a Dialog)
// ─────────────────────────────────────────────

class _CriteriaDialog extends ConsumerStatefulWidget {
  final List<String> orientations;
  final List<String> colors;

  const _CriteriaDialog({required this.orientations, required this.colors});

  @override
  ConsumerState<_CriteriaDialog> createState() => _CriteriaDialogState();
}

class _CriteriaDialogState extends ConsumerState<_CriteriaDialog> {
  final _queryController = TextEditingController();
  String? _selectedSource;
  String? _selectedOrientation;
  String? _selectedColor;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _onFetch() async {
    await ref
        .read(bulkDownloadProvider.notifier)
        .fetchWallpapers(
          query: _queryController.text.trim().isEmpty
              ? null
              : _queryController.text.trim(),
          sourceId: _selectedSource,
          orientation: _selectedOrientation,
          color: _selectedColor,
        );
    if (mounted &&
        ref.read(bulkDownloadProvider).step != BulkDownloadStep.criteria) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkDownloadProvider);
    final sourcesAsync = ref.watch(availableSourcesProvider);
    final scheme = Theme.of(context).colorScheme;
    final isFetching = state.isFetching;
    final batchSize = state.batchSize;
    final fetchError = state.fetchError;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.collections_bookmark,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Download',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                        Text(
                          'Set criteria to fetch wallpapers',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onPrimaryContainer.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Wallpaper Count',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton.outlined(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: batchSize > 1
                              ? () => ref
                                    .read(bulkDownloadProvider.notifier)
                                    .setBatchSize(batchSize - 1)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$batchSize',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton.outlined(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: batchSize < 100
                              ? () => ref
                                    .read(bulkDownloadProvider.notifier)
                                    .setBatchSize(batchSize + 1)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Search Criteria',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All fields are optional',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _queryController,
                      enabled: !isFetching,
                      decoration: const InputDecoration(
                        labelText: 'Search Query',
                        hintText: 'e.g. nature, abstract, city...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),

                    sourcesAsync.when(
                      data: (sources) => DropdownButtonFormField<String>(
                        initialValue: _selectedSource,
                        decoration: const InputDecoration(
                          labelText: 'Source',
                          prefixIcon: Icon(Icons.source),
                        ),
                        hint: const Text('All sources'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All sources'),
                          ),
                          ...sources.map(
                            (s) => DropdownMenuItem(
                              value: s.sourceId,
                              child: Text(s.sourceId.toUpperCase()),
                            ),
                          ),
                        ],
                        onChanged: isFetching
                            ? null
                            : (v) => setState(() => _selectedSource = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedOrientation,
                      decoration: const InputDecoration(
                        labelText: 'Orientation',
                        prefixIcon: Icon(Icons.screen_rotation),
                      ),
                      hint: const Text('Any orientation'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Any orientation'),
                        ),
                        ...widget.orientations.map(
                          (o) => DropdownMenuItem(
                            value: o,
                            child: Text(o[0].toUpperCase() + o.substring(1)),
                          ),
                        ),
                      ],
                      onChanged: isFetching
                          ? null
                          : (v) => setState(() => _selectedOrientation = v),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedColor,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        prefixIcon: Icon(Icons.palette),
                      ),
                      hint: const Text('Any color'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Any color'),
                        ),
                        ...widget.colors.map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c[0].toUpperCase() + c.substring(1)),
                          ),
                        ),
                      ],
                      onChanged: isFetching
                          ? null
                          : (v) => setState(() => _selectedColor = v),
                    ),

                    const SizedBox(height: 20),
                    _ToggleCard(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: Colors.amber,
                      title: 'AI Naming',
                      subtitle: 'Use Gemini to generate creative file names',
                      value: state.aiNamingEnabled,
                      enabled: !isFetching,
                      onChanged: (v) => ref
                          .read(bulkDownloadProvider.notifier)
                          .setAiNaming(v),
                    ),
                    const SizedBox(height: 10),
                    _ToggleCard(
                      icon: Icons.replay_rounded,
                      iconColor: scheme.primary,
                      title: 'Auto Retry',
                      subtitle:
                          'Retry failed downloads automatically (up to 3×)',
                      value: state.autoRetryEnabled,
                      enabled: !isFetching,
                      onChanged: (v) => ref
                          .read(bulkDownloadProvider.notifier)
                          .setAutoRetry(v),
                    ),

                    if (fetchError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: scheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: scheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fetchError,
                                style: TextStyle(
                                  color: scheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isFetching ? null : _onFetch,
                  icon: isFetching
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.download_for_offline),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      isFetching
                          ? 'Fetching wallpapers...'
                          : 'Fetch $batchSize Wallpapers',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable toggle card for criteria dialog
// ─────────────────────────────────────────────

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value
            ? iconColor.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? iconColor.withValues(alpha: 0.45)
              : scheme.outlineVariant,
          width: value ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? () => onChanged(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 2: Selection — split panel (grid + right panel)
// ─────────────────────────────────────────────

class _SelectionStep extends StatefulWidget {
  final List<Wallpaper> wallpapers;
  final Set<String> selectedWallpaperIds;
  final bool isLoadingMore;
  final bool hasMorePages;
  final ValueChanged<String> onToggle;
  final VoidCallback onProceed;
  final VoidCallback onLoadMore;

  const _SelectionStep({
    required this.wallpapers,
    required this.selectedWallpaperIds,
    required this.isLoadingMore,
    required this.hasMorePages,
    required this.onToggle,
    required this.onProceed,
    required this.onLoadMore,
  });

  @override
  State<_SelectionStep> createState() => _SelectionStepState();
}

class _SelectionStepState extends State<_SelectionStep> {
  String? _providerFilter;
  String? _orientationFilter; // null | 'portrait' | 'landscape'
  String? _colorFilter;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _colorSwatches = {
    'red': Color(0xFFE53935),
    'orange': Color(0xFFFF7043),
    'yellow': Color(0xFFFFCA28),
    'green': Color(0xFF43A047),
    'turquoise': Color(0xFF00BCD4),
    'blue': Color(0xFF1E88E5),
    'violet': Color(0xFF8E24AA),
    'pink': Color(0xFFE91E63),
    'brown': Color(0xFF6D4C41),
    'black': Color(0xFF212121),
    'gray': Color(0xFF757575),
    'white': Color(0xFFEEEEEE),
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      widget.onLoadMore();
    }
  }

  Set<String> get _availableProviders =>
      widget.wallpapers.map((w) => w.source).toSet();

  List<Wallpaper> get _filtered => widget.wallpapers.where((w) {
    // Provider
    if (_providerFilter != null && w.source != _providerFilter) {
      return false;
    }
    // Orientation
    if (_orientationFilter == 'portrait' && w.width >= w.height) {
      return false;
    }
    if (_orientationFilter == 'landscape' && w.width < w.height) {
      return false;
    }
    // Color — match against tags and description
    if (_colorFilter != null) {
      final haystack = [
        ...(w.tags ?? []),
        w.description ?? '',
      ].join(' ').toLowerCase();
      if (!haystack.contains(_colorFilter!)) return false;
    }
    // Query search — photographer, description, tags
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      final haystack = [
        w.photographer,
        w.description ?? '',
        ...(w.tags ?? []),
      ].join(' ').toLowerCase();
      if (!haystack.contains(query)) return false;
    }
    return true;
  }).toList();

  bool get _hasActiveFilter =>
      _providerFilter != null ||
      _orientationFilter != null ||
      _colorFilter != null ||
      _searchController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final selectedWallpapers = widget.wallpapers
        .where((w) => widget.selectedWallpaperIds.contains(w.id))
        .toList();
    final providers = _availableProviders.toList()..sort();

    return Row(
      children: [
        // ── Left: browse grid ───────────────────────────────────────────
        Expanded(
          flex: 7,
          child: Column(
            children: [
              // ── Filter panel ──────────────────────────────────────────
              Container(
                color: scheme.surface,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search box
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: 'Search by photographer, tag, description…',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => _searchController.clear(),
                                padding: EdgeInsets.zero,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Provider + Orientation row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Provider chips
                          if (providers.length > 1) ...[
                            const _FilterLabel('Provider'),
                            const SizedBox(width: 6),
                            _FilterChip(
                              label: 'All',
                              selected: _providerFilter == null,
                              onTap: () =>
                                  setState(() => _providerFilter = null),
                            ),
                            ...providers.map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _FilterChip(
                                  label: p[0].toUpperCase() + p.substring(1),
                                  selected: _providerFilter == p,
                                  onTap: () =>
                                      setState(() => _providerFilter = p),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const _FilterDivider(),
                            const SizedBox(width: 14),
                          ],
                          // Orientation chips
                          const _FilterLabel('Orientation'),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'All',
                            selected: _orientationFilter == null,
                            onTap: () =>
                                setState(() => _orientationFilter = null),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Portrait',
                            icon: Icons.stay_current_portrait_outlined,
                            selected: _orientationFilter == 'portrait',
                            onTap: () =>
                                setState(() => _orientationFilter = 'portrait'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Landscape',
                            icon: Icons.stay_current_landscape_outlined,
                            selected: _orientationFilter == 'landscape',
                            onTap: () => setState(
                              () => _orientationFilter = 'landscape',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Color swatch row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const _FilterLabel('Color'),
                          const SizedBox(width: 8),
                          // "All" swatch
                          _ColorSwatchChip(
                            colorName: null,
                            color: null,
                            selected: _colorFilter == null,
                            onTap: () => setState(() => _colorFilter = null),
                          ),
                          ..._colorSwatches.entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _ColorSwatchChip(
                                colorName: e.key,
                                color: e.value,
                                selected: _colorFilter == e.key,
                                onTap: () =>
                                    setState(() => _colorFilter = e.key),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Info bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: scheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tap to select · ${filtered.length} of ${widget.wallpapers.length} shown',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_hasActiveFilter)
                      InkWell(
                        onTap: () => setState(() {
                          _providerFilter = null;
                          _orientationFilter = null;
                          _colorFilter = null;
                          _searchController.clear();
                        }),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 14,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Grid
              Expanded(
                child: filtered.isEmpty && !widget.isLoadingMore
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 48,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No wallpapers match the filters',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(12),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 3.0 / 5.0,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final wallpaper = filtered[index];
                                return _WallpaperSelectionCard(
                                  wallpaper: wallpaper,
                                  isSelected: widget.selectedWallpaperIds
                                      .contains(wallpaper.id),
                                  index: index,
                                  onToggle: widget.onToggle,
                                );
                              }, childCount: filtered.length),
                            ),
                          ),
                          // Pagination footer
                          SliverToBoxAdapter(
                            child: widget.isLoadingMore
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : !widget.hasMorePages
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'All ${widget.wallpapers.length} images loaded',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 16),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),

        // ── Divider ─────────────────────────────────────────────────────
        const VerticalDivider(width: 1, thickness: 1),

        // ── Right: selected panel ────────────────────────────────────────
        SizedBox(
          width: 280,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: scheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selectedWallpapers.isNotEmpty
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selectedWallpapers.length}',
                        style: TextStyle(
                          color: selectedWallpapers.isNotEmpty
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Selected list
              Expanded(
                child: selectedWallpapers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 48,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap wallpapers\nto select them',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: selectedWallpapers.length,
                        itemBuilder: (context, index) {
                          final w = selectedWallpapers[index];
                          return _SelectedWallpaperItem(
                            wallpaper: w,
                            onRemove: () => widget.onToggle(w.id),
                          );
                        },
                      ),
              ),

              // Proceed button
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedWallpapers.isNotEmpty
                        ? widget.onProceed
                        : null,
                    icon: const Icon(Icons.rocket_launch, size: 18),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        selectedWallpapers.isEmpty
                            ? 'Select wallpapers'
                            : 'Download (${selectedWallpapers.length})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Filter bar helper widgets
// ─────────────────────────────────────────────

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatchChip extends StatelessWidget {
  final String? colorName;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatchChip({
    required this.colorName,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  // Pick a contrasting icon color for the checkmark.
  Color _checkColor() {
    if (color == null) return Colors.black;
    final luminance = color!.computeLuminance();
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAll = colorName == null;

    return Tooltip(
      message: isAll
          ? 'All colors'
          : colorName![0].toUpperCase() + colorName!.substring(1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAll ? null : color,
            gradient: isAll
                ? const SweepGradient(
                    colors: [
                      Color(0xFFE53935),
                      Color(0xFFFF7043),
                      Color(0xFFFFCA28),
                      Color(0xFF43A047),
                      Color(0xFF1E88E5),
                      Color(0xFF8E24AA),
                      Color(0xFFE53935),
                    ],
                  )
                : null,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 14,
                  color: isAll ? Colors.white : _checkColor(),
                )
              : null,
        ),
      ),
    );
  }
}

class _FilterDivider extends StatelessWidget {
  const _FilterDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Grid card with checkbox overlay (4:3, no iPhone frame)
// ─────────────────────────────────────────────

class _WallpaperSelectionCard extends StatelessWidget {
  final Wallpaper wallpaper;
  final bool isSelected;
  final int index;
  final ValueChanged<String> onToggle;

  const _WallpaperSelectionCard({
    required this.wallpaper,
    required this.isSelected,
    required this.index,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onToggle(wallpaper.id),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _DeferredImage(
                url: wallpaper.mediumUrl.isNotEmpty
                    ? wallpaper.mediumUrl
                    : wallpaper.originalUrl,
                index: index,
              ),
            ),

            // Selection tint overlay
            if (isSelected)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(color: scheme.primary.withValues(alpha: 0.35)),
              ),

            // Check badge (top-right)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check : null,
                  size: 14,
                  color: scheme.onPrimary,
                ),
              ),
            ),

            // Index badge (top-left)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Right-panel selected item row
// ─────────────────────────────────────────────

class _SelectedWallpaperItem extends StatelessWidget {
  final Wallpaper wallpaper;
  final VoidCallback onRemove;

  const _SelectedWallpaperItem({
    required this.wallpaper,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: SizedBox(
        width: 36,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: wallpaper.smallUrl.isNotEmpty
                ? wallpaper.smallUrl
                : wallpaper.mediumUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        wallpaper.photographer,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        wallpaper.source.toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18),
        tooltip: 'Remove',
        onPressed: onRemove,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 3: Processing
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// Step 3: Processing — modern animated layout
// ─────────────────────────────────────────────

class _ProcessingStep extends StatefulWidget {
  final BulkDownloadState state;
  const _ProcessingStep({required this.state});

  @override
  State<_ProcessingStep> createState() => _ProcessingStepState();
}

class _ProcessingStepState extends State<_ProcessingStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = widget.state.results.length;
    final total = widget.state.selectedWallpapers.length;
    final progress = total > 0 ? done / total : 0.0;
    final current = widget.state.currentWallpaper;
    final successCount = widget.state.results.where((r) => r.success).length;
    final failCount = widget.state.results.where((r) => !r.success).length;

    return Row(
      children: [
        // ── Left: progress panel ────────────────────────────────────────
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border(right: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated progress ring
              _PulsingProgressRing(
                progress: progress,
                pulseAnim: _pulseAnim,
                done: done,
                total: total,
              ),

              const SizedBox(height: 28),

              // Animated status text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    widget.state.processingStatus ?? 'Starting…',
                    key: ValueKey(widget.state.processingStatus),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Stats card
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: done == 0
                    ? const SizedBox.shrink()
                    : Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _ProcessingStat(
                              count: successCount,
                              label: 'Done',
                              icon: Icons.check_circle_rounded,
                              color: Colors.green,
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: scheme.outlineVariant,
                            ),
                            _ProcessingStat(
                              count: failCount,
                              label: 'Failed',
                              icon: Icons.cancel_rounded,
                              color: scheme.error,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),

        // ── Right: current item + live feed ────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                color: scheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    _PulsingDot(color: scheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Now Processing',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (done > 0)
                      Text(
                        '$done of $total complete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Current wallpaper — animated on change
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: current != null
                      ? _CurrentWallpaperCard(
                          key: ValueKey(current.id),
                          wallpaper: current,
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // Live results feed
              if (widget.state.results.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Recent',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    reverse: true,
                    itemCount: widget.state.results.length,
                    itemBuilder: (context, index) {
                      final result = widget
                          .state
                          .results[widget.state.results.length - 1 - index];
                      return _ResultFeedItem(
                        result: result,
                        isLatest: index == 0,
                      );
                    },
                  ),
                ),
              ] else
                const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Animated progress ring ─────────────────────────────────────────────

class _PulsingProgressRing extends StatelessWidget {
  final double progress;
  final Animation<double> pulseAnim;
  final int done;
  final int total;

  const _PulsingProgressRing({
    required this.progress,
    required this.pulseAnim,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow halo
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (context, _) => Container(
              width: 170 + pulseAnim.value * 18,
              height: 170 + pulseAnim.value * 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(
                      alpha: pulseAnim.value * 0.22,
                    ),
                    blurRadius: 24 + pulseAnim.value * 16,
                    spreadRadius: pulseAnim.value * 6,
                  ),
                ],
              ),
            ),
          ),

          // Track ring
          SizedBox(
            width: 168,
            height: 168,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 12,
              color: scheme.surfaceContainerHighest,
            ),
          ),

          // Animated progress ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, value, _) => SizedBox(
              width: 168,
              height: 168,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                color: scheme.primary,
              ),
            ),
          ),

          // Center: animated count + percentage
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween(begin: 0.7, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  '$done',
                  key: ValueKey(done),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'of $total',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, value, _) => Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Current wallpaper card ─────────────────────────────────────────────

class _CurrentWallpaperCard extends StatelessWidget {
  final Wallpaper wallpaper;

  const _CurrentWallpaperCard({super.key, required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 108,
            height: 180,
            child: CachedNetworkImage(
              imageUrl: wallpaper.mediumUrl.isNotEmpty
                  ? wallpaper.mediumUrl
                  : wallpaper.originalUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: scheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  wallpaper.source.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                wallpaper.photographer,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (wallpaper.description != null &&
                  wallpaper.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  wallpaper.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              // Processing pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Processing…',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Animated result feed item ──────────────────────────────────────────

class _ResultFeedItem extends StatefulWidget {
  final BulkProcessResult result;
  final bool isLatest;

  const _ResultFeedItem({required this.result, required this.isLatest});

  @override
  State<_ResultFeedItem> createState() => _ResultFeedItemState();
}

class _ResultFeedItemState extends State<_ResultFeedItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success = widget.result.success;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isLatest
                ? (success
                      ? Colors.green.withValues(alpha: 0.08)
                      : scheme.error.withValues(alpha: 0.08))
                : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isLatest
                  ? (success
                        ? Colors.green.withValues(alpha: 0.35)
                        : scheme.error.withValues(alpha: 0.35))
                  : scheme.outlineVariant.withValues(alpha: 0.4),
              width: widget.isLatest ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 36,
                  height: 60,
                  child: CachedNetworkImage(
                    imageUrl: widget.result.wallpaper.smallUrl.isNotEmpty
                        ? widget.result.wallpaper.smallUrl
                        : widget.result.wallpaper.mediumUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      success
                          ? (widget.result.downloadResult?.aiName ??
                                widget.result.wallpaper.photographer)
                          : widget.result.wallpaper.photographer,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!success && widget.result.error != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.result.error!,
                        style: TextStyle(fontSize: 10, color: scheme.error),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: success ? Colors.green : scheme.error,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pulsing status dot ─────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _anim.value * 0.5),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.5),
              blurRadius: 6 + _anim.value * 4,
              spreadRadius: _anim.value * 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats tile ─────────────────────────────────────────────────────────

class _ProcessingStat extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  const _ProcessingStat({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween(begin: 0.6, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  '$count',
                  key: ValueKey(count),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 4: Complete
// ─────────────────────────────────────────────

/// Normalises a tag into a filename-friendly base (lowercase alphanumerics).
String _tagToBaseName(String tag) =>
    tag.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '');

class _CompleteStep extends StatefulWidget {
  final BulkDownloadState state;
  final VoidCallback onDone;
  final VoidCallback? onRetryFailed;
  final Future<void> Function(int index, String newName) onRename;
  final Future<void> Function(String baseName) onBulkRename;

  const _CompleteStep({
    required this.state,
    required this.onDone,
    required this.onRetryFailed,
    required this.onRename,
    required this.onBulkRename,
  });

  @override
  State<_CompleteStep> createState() => _CompleteStepState();
}

class _CompleteStepState extends State<_CompleteStep> {
  final _bulkController = TextEditingController();
  bool _isRenamingAll = false;

  @override
  void dispose() {
    _bulkController.dispose();
    super.dispose();
  }

  /// Most frequent tags across all successful results — used as quick-pick
  /// base names for bulk renaming.
  List<String> get _suggestedBaseNames {
    final counts = <String, int>{};
    for (final r in widget.state.results) {
      if (!r.success) continue;
      final tags = <String>[...?r.wallpaper.tags, ...?r.downloadResult?.tags];
      for (final t in tags) {
        final base = _tagToBaseName(t);
        if (base.isEmpty || base.length < 3) continue;
        counts[base] = (counts[base] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(8).toList();
  }

  Future<void> _applyBulkRename() async {
    final base = _bulkController.text.trim();
    if (base.isEmpty || _isRenamingAll) return;
    setState(() => _isRenamingAll = true);
    try {
      await widget.onBulkRename(base);
      if (mounted) {
        final isList = base.contains(',');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isList
                  ? 'Applied names in order'
                  : 'Renamed all to "${base}_1, ${base}_2, …"',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRenamingAll = false);
    }
  }

  void _showRenameDialog(int index, String currentName, Wallpaper wallpaper) {
    final result = widget.state.results[index];
    showDialog<void>(
      context: context,
      builder: (_) => _RenameDialog(
        initialName: currentName,
        wallpaper: wallpaper,
        suggestions: <String>{
          ...?wallpaper.tags,
          ...?result.downloadResult?.tags,
        }.where((t) => t.trim().isNotEmpty).toList(),
        onConfirm: (newName) => widget.onRename(index, newName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success = widget.state.results.where((r) => r.success).length;
    final failed = widget.state.results.where((r) => !r.success).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: summary, bulk rename & actions ────────────────────────
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        success > 0 ? Icons.check_circle : Icons.error,
                        size: 40,
                        color: success > 0
                            ? context.appColors.success
                            : scheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bulk Download Complete',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _StatChip(
                            icon: Icons.check_circle,
                            color: context.appColors.success,
                            label: '$success downloaded',
                          ),
                          if (failed > 0)
                            _StatChip(
                              icon: Icons.error_outline,
                              color: scheme.error,
                              label: '$failed failed',
                            ),
                        ],
                      ),
                      if (success > 0) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildBulkRenameBar(context),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // ── Bottom actions ──────────────────────────────────────
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (widget.onRetryFailed != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: widget.onRetryFailed,
                            icon: const Icon(Icons.refresh),
                            label: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Retry ${widget.state.failedCount} Failed',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onDone,
                          child: const Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Done', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1, thickness: 1),

        // ── Right: results grid (large, clearly-visible previews) ──────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = (constraints.maxWidth ~/ 200).clamp(2, 6);
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: widget.state.results.length,
                itemBuilder: (context, index) {
                  final result = widget.state.results[index];
                  return _ResultCard(
                    result: result,
                    onRename: result.success
                        ? () => _showRenameDialog(
                            index,
                            result.downloadResult!.aiName,
                            result.wallpaper,
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBulkRenameBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final suggestions = _suggestedBaseNames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.drive_file_rename_outline,
              size: 18,
              color: scheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Bulk rename',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'one name → name_1, name_2 …  ·  comma-separated → one per wall',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bulkController,
          enabled: !_isRenamingAll,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _applyBulkRename(),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Base name, or comma-separated names',
            prefixIcon: const Icon(Icons.label_outline, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isRenamingAll ? null : _applyBulkRename,
            icon: _isRenamingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all, size: 18),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_isRenamingAll ? 'Renaming…' : 'Apply to all'),
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 13,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                'Suggested from tags',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s),
                    labelStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                    onPressed: _isRenamingAll
                        ? null
                        : () => setState(() {
                            _bulkController.text = s;
                            _bulkController.selection = TextSelection.collapsed(
                              offset: s.length,
                            );
                          }),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Complete-step result card (large preview)
// ─────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final BulkProcessResult result;
  final VoidCallback? onRename;

  const _ResultCard({required this.result, required this.onRename});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success = result.success;
    final name = success
        ? (result.downloadResult?.aiName ?? 'Unknown')
        : result.wallpaper.photographer;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: success
              ? scheme.outlineVariant
              : scheme.error.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview image — large and clearly visible.
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: result.wallpaper.mediumUrl.isNotEmpty
                      ? result.wallpaper.mediumUrl
                      : result.wallpaper.originalUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success ? Icons.check_circle : Icons.error,
                      size: 18,
                      color: success ? context.appColors.success : scheme.error,
                    ),
                  ),
                ),
                // Rename affordance
                if (success)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onRename,
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        success
                            ? (result.downloadResult?.tags.take(3).join(', ') ??
                                  '')
                            : (result.error ?? 'Failed'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: success
                              ? scheme.onSurfaceVariant
                              : scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                if (success)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Rename',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: onRename,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Rename Dialog
// ─────────────────────────────────────────────

class _RenameDialog extends StatefulWidget {
  final String initialName;
  final Wallpaper wallpaper;
  final List<String> suggestions;
  final Future<void> Function(String newName) onConfirm;

  const _RenameDialog({
    required this.initialName,
    required this.wallpaper,
    required this.suggestions,
    required this.onConfirm,
  });

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Name cannot be empty');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm(name);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      title: const Text('Rename Wallpaper'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: CachedNetworkImage(
                imageUrl: widget.wallpaper.mediumUrl.isNotEmpty
                    ? widget.wallpaper.mediumUrl
                    : widget.wallpaper.originalUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: colors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(color: colors.surface),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'New name',
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Suggestions from tags',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.suggestions
                  .map(
                    (s) => ActionChip(
                      label: Text(s),
                      labelStyle: const TextStyle(fontSize: 12),
                      visualDensity: VisualDensity.compact,
                      onPressed: _isLoading
                          ? null
                          : () {
                              final base = _tagToBaseName(s);
                              if (base.isEmpty) return;
                              setState(() {
                                _controller.text = base;
                                _controller.selection = TextSelection.collapsed(
                                  offset: base.length,
                                );
                              });
                            },
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Rename'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Staggered image loader (avoids 429 rate limits)
// ─────────────────────────────────────────────

// URLs that have already passed their stagger window — future widget rebuilds
// (e.g. after scroll recycling) skip the delay and show from cache immediately.
final _fetchedUrls = <String>{};

/// Spaces out image loads that mount close together in time so we don't fire
/// a burst of CDN requests at once (which can trigger 429s). Crucially, the
/// delay is relative to *now*, not the grid index — so images on a freshly
/// loaded page never wait longer than [_maxDelay], no matter how far down the
/// list they are.
class _LoadStagger {
  static const _gap = Duration(milliseconds: 120);
  static const _maxDelay = Duration(milliseconds: 1200);
  static DateTime? _nextSlot;

  /// Reserves the next load slot and returns how long the caller should wait.
  static Duration reserve() {
    final now = DateTime.now();
    var slot = (_nextSlot == null || _nextSlot!.isBefore(now))
        ? now
        : _nextSlot!;
    // Never make a just-mounted image wait more than the cap.
    if (slot.difference(now) > _maxDelay) {
      slot = now.add(_maxDelay);
    }
    _nextSlot = slot.add(_gap);
    return slot.difference(now);
  }
}

class _DeferredImage extends StatefulWidget {
  final String url;
  final int index;

  const _DeferredImage({required this.url, required this.index});

  @override
  State<_DeferredImage> createState() => _DeferredImageState();
}

class _DeferredImageState extends State<_DeferredImage> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Already fetched once (e.g. scrolled away and back) — show immediately.
    if (_fetchedUrls.contains(widget.url)) {
      _ready = true;
      return;
    }
    // First time: take a slot in the rolling stagger window.
    final delay = _LoadStagger.reserve();
    if (delay == Duration.zero) {
      _ready = true;
      _fetchedUrls.add(widget.url);
    } else {
      _timer = Timer(delay, () {
        if (mounted) {
          _fetchedUrls.add(widget.url);
          setState(() => _ready = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (!_ready) {
      return Container(
        color: colors.surface,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: colors.surface,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: colors.surface,
        child: const Icon(Icons.broken_image),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
