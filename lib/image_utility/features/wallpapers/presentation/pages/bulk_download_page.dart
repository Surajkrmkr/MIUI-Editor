import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/bulk_download_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';

class BulkDownloadPage extends ConsumerStatefulWidget {
  const BulkDownloadPage({super.key});

  @override
  ConsumerState<BulkDownloadPage> createState() => _BulkDownloadPageState();
}

class _BulkDownloadPageState extends ConsumerState<BulkDownloadPage> {
  static const _orientations = ['portrait', 'landscape', 'square'];
  static const _colors = [
    'red', 'orange', 'yellow', 'green', 'turquoise', 'blue',
    'violet', 'pink', 'brown', 'black', 'gray', 'white',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCriteriaDialog());
  }

  Future<void> _showCriteriaDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _CriteriaDialog(
        orientations: _orientations,
        colors: _colors,
      ),
    );
    if (!mounted) return;
    // If user dismissed without fetching, go back
    if (ref.read(bulkDownloadProvider).step == BulkDownloadStep.criteria) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkDownloadProvider);

    return PopScope(
      canPop: state.step == BulkDownloadStep.criteria ||
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
          leading: IconButton(
            icon: const Icon(Icons.close),
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
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
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
        // Criteria is shown as a dialog via initState / _handleBack
        return const SizedBox.shrink();
      case BulkDownloadStep.selection:
        return _SelectionStep(
          wallpapers: state.wallpapers,
          replacingIndices: state.replacingIndices,
          onReplace: (i) =>
              ref.read(bulkDownloadProvider.notifier).replaceWallpaper(i),
          onProceed: () =>
              ref.read(bulkDownloadProvider.notifier).startProcessing(),
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

  const _CriteriaDialog({
    required this.orientations,
    required this.colors,
  });

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
    await ref.read(bulkDownloadProvider.notifier).fetchWallpapers(
          query: _queryController.text.trim().isEmpty
              ? null
              : _queryController.text.trim(),
          sourceId: _selectedSource,
          orientation: _selectedOrientation,
          color: _selectedColor,
        );
    // Close dialog once step has moved past criteria
    if (mounted &&
        ref.read(bulkDownloadProvider).step != BulkDownloadStep.criteria) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, ) {
    final state = ref.watch(bulkDownloadProvider);
    final sourcesAsync = ref.watch(availableSourcesProvider);
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
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.collections_bookmark,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Download',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        Text(
                          'Set criteria to fetch wallpapers',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.7),
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

            // ── Form body ────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Count picker
                    Row(
                      children: [
                        Text(
                          'Wallpaper Count',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
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
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
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
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All fields are optional',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Query
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

                    // Source
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
                              value: null, child: Text('All sources')),
                          ...sources.map(
                            (s) => DropdownMenuItem(
                              value: s.sourceId,
                              child: Text(s.sourceId.toUpperCase()),
                            ),
                          ),
                        ],
                        onChanged:
                            isFetching ? null : (v) => setState(() => _selectedSource = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),

                    // Orientation
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOrientation,
                      decoration: const InputDecoration(
                        labelText: 'Orientation',
                        prefixIcon: Icon(Icons.screen_rotation),
                      ),
                      hint: const Text('Any orientation'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Any orientation')),
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

                    // Color
                    DropdownButtonFormField<String>(
                      initialValue: _selectedColor,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        prefixIcon: Icon(Icons.palette),
                      ),
                      hint: const Text('Any color'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Any color')),
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

                    if (fetchError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(fetchError,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Action button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isFetching ? null : _onFetch,
                  icon: isFetching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
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
// Step 2: Selection Grid
// ─────────────────────────────────────────────

class _SelectionStep extends StatelessWidget {
  final List<Wallpaper> wallpapers;
  final Set<int> replacingIndices;
  final ValueChanged<int> onReplace;
  final VoidCallback onProceed;

  const _SelectionStep({
    required this.wallpapers,
    required this.replacingIndices,
    required this.onReplace,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap a wallpaper to replace it with a new random one.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                '${wallpapers.length}/25',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 6 / 13,
            ),
            itemCount: wallpapers.length,
            itemBuilder: (context, index) {
              final wallpaper = wallpapers[index];
              final isReplacing = replacingIndices.contains(index);
              return _WallpaperSelectionCard(
                wallpaper: wallpaper,
                isReplacing: isReplacing,
                index: index,
                onReplace: onReplace,
              );
            },
          ),
        ),

        // Proceed button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: replacingIndices.isEmpty && wallpapers.isNotEmpty
                  ? onProceed
                  : null,
              icon: const Icon(Icons.rocket_launch),
              label: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Start Bulk Download (${wallpapers.length} wallpapers)',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WallpaperSelectionCard extends StatelessWidget {
  final Wallpaper wallpaper;
  final bool isReplacing;
  final int index;
  final ValueChanged<int> onReplace;

  const _WallpaperSelectionCard({
    required this.wallpaper,
    required this.isReplacing,
    required this.index,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isReplacing ? null : () => onReplace(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: wallpaper.smallUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey[300],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            ),

            // Replace spinner overlay
            if (isReplacing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              // Hover/tap indicator overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white70,
                  size: 16,
                ),
              ),

            // Index badge
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
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
// Step 3: Processing
// ─────────────────────────────────────────────

class _ProcessingStep extends StatelessWidget {
  final BulkDownloadState state;

  const _ProcessingStep({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.wallpapers.length;
    final done = state.results.length;
    final progress = total > 0 ? done / total : 0.0;
    final current = state.currentWallpaper;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Progress ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$done',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'of $total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status text
          if (state.processingStatus != null)
            Text(
              state.processingStatus!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 32),

          // Current wallpaper thumbnail
          if (current != null) ...[
            Text(
              'Current wallpaper',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 200,
                child: CachedNetworkImage(
                  imageUrl: current.smallUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              current.photographer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          const SizedBox(height: 32),

          // Results so far
          if (state.results.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  label: '${state.results.where((r) => r.success).length} done',
                ),
                _StatChip(
                  icon: Icons.error_outline,
                  color: Colors.red,
                  label:
                      '${state.results.where((r) => !r.success).length} failed',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step 4: Complete
// ─────────────────────────────────────────────

class _CompleteStep extends StatelessWidget {
  final BulkDownloadState state;
  final VoidCallback onDone;
  final VoidCallback? onRetryFailed;
  final Future<void> Function(int index, String newName) onRename;

  const _CompleteStep({
    required this.state,
    required this.onDone,
    required this.onRetryFailed,
    required this.onRename,
  });

  void _showRenameDialog(BuildContext context, int index, String currentName) {
    showDialog<void>(
      context: context,
      builder: (_) => _RenameDialog(
        initialName: currentName,
        onConfirm: (newName) => onRename(index, newName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final success = state.results.where((r) => r.success).length;
    final failed = state.results.where((r) => !r.success).length;

    return Column(
      children: [
        // Summary header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: success > 0
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          child: Column(
            children: [
              Icon(
                success > 0 ? Icons.check_circle : Icons.error,
                size: 56,
                color: success > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                'Bulk Download Complete',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    label: '$success downloaded',
                  ),
                  if (failed > 0) ...[
                    const SizedBox(width: 16),
                    _StatChip(
                      icon: Icons.error_outline,
                      color: Colors.red,
                      label: '$failed failed',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final result = state.results[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 40,
                      height: 80,
                      child: CachedNetworkImage(
                        imageUrl: result.wallpaper.smallUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(
                    result.success
                        ? result.downloadResult?.aiName ?? 'Unknown'
                        : result.wallpaper.photographer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: result.success
                      ? Text(
                          result.downloadResult?.tags.take(3).join(', ') ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        )
                      : Text(
                          result.error ?? 'Failed',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 11),
                        ),
                  trailing: result.success
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Rename',
                              onPressed: () => _showRenameDialog(
                                context,
                                index,
                                result.downloadResult!.aiName,
                              ),
                            ),
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                          ],
                        )
                      : const Icon(Icons.error, color: Colors.red),
                ),
              );
            },
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              if (onRetryFailed != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRetryFailed,
                    icon: const Icon(Icons.refresh),
                    label: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Retry ${state.failedCount} Failed',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              if (onRetryFailed != null) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Done', style: TextStyle(fontSize: 16)),
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
// Rename Dialog
// ─────────────────────────────────────────────

class _RenameDialog extends StatefulWidget {
  final String initialName;
  final Future<void> Function(String newName) onConfirm;

  const _RenameDialog({required this.initialName, required this.onConfirm});

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
    return AlertDialog(
      title: const Text('Rename Wallpaper'),
      content: TextField(
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
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
