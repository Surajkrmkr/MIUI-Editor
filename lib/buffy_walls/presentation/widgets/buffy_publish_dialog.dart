import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../application/providers/buffy_cms_provider.dart';
import '../../application/providers/buffy_storage_provider.dart';
import '../../application/services/buffy_catalog_publisher.dart';
import '../../domain/buffy_catalog_json.dart';
import '../../domain/models/buffy_wallpaper.dart';

Future<void> showBuffyPublishDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _BuffyPublishDialog(),
);

enum _Phase { checking, ready, blocked, publishing, done, failed }

/// Checks the edited catalog, shows what changes, and publishes it.
class _BuffyPublishDialog extends ConsumerStatefulWidget {
  const _BuffyPublishDialog();

  @override
  ConsumerState<_BuffyPublishDialog> createState() =>
      _BuffyPublishDialogState();
}

class _BuffyPublishDialogState extends ConsumerState<_BuffyPublishDialog> {
  _Phase _phase = _Phase.checking;
  String? _localJson;
  BuffyPublishPreview? _preview;
  BuffyCatalogDiff? _diff;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _phase = _Phase.checking;
      _error = null;
    });
    try {
      final state = ref.read(buffyCmsProvider);
      final localJson = await ref
          .read(buffyCmsProvider.notifier)
          .buildCatalogJson();
      final diff = await compute(diffBuffyCatalog, (
        before: state.catalogJson!,
        after: localJson,
      ));
      final publisher = await ref.read(buffyCatalogPublisherProvider.future);
      final preview = await publisher.preview(
        localJson,
        generation: state.generation!,
      );
      if (!mounted) return;
      setState(() {
        _localJson = localJson;
        _diff = diff;
        _preview = preview;
        _phase = preview.problems.isEmpty ? _Phase.ready : _Phase.blocked;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _phase = _Phase.failed;
        });
      }
    }
  }

  Future<void> _publish() async {
    setState(() => _phase = _Phase.publishing);
    try {
      final publisher = await ref.read(buffyCatalogPublisherProvider.future);
      final generation = await publisher.publish(_localJson!, _preview!);
      ref
          .read(buffyCmsProvider.notifier)
          .markPublished(_localJson!, generation);
      if (mounted) setState(() => _phase = _Phase.done);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _phase = _Phase.failed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final busy = _phase == _Phase.checking || _phase == _Phase.publishing;

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload_rounded, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publish buffy.json',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'The live catalog is backed up first. Apps pick it up within ~5 minutes.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (busy)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: _buildBody(context),
              ),
            ),
            Divider(height: 1, color: colors.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    return switch (_phase) {
      _Phase.checking || _Phase.publishing => [
        TextButton(
          onPressed: null,
          child: Text(_phase == _Phase.checking ? 'Checking…' : 'Publishing…'),
        ),
      ],
      _Phase.ready => [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _publish,
          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
          label: const Text('Publish'),
        ),
      ],
      _Phase.blocked || _Phase.failed => [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _check,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Check again'),
        ),
      ],
      _Phase.done => [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    };
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.appColors;
    final preview = _preview;
    final diff = _diff;

    if (_phase == _Phase.checking) {
      return _Message(
        icon: Icons.fact_check_outlined,
        color: colors.primary,
        text: 'Checking the catalog and every media link in it…',
      );
    }
    if (_phase == _Phase.failed) {
      final changed = _error!.contains('changed since it was loaded');
      return _Message(
        icon: Icons.error_outline_rounded,
        color: colors.error,
        text: changed ? _error! : 'Nothing was published.\n\n$_error',
      );
    }
    if (_phase == _Phase.done) {
      return _Message(
        icon: Icons.check_circle_rounded,
        color: colors.success,
        text:
            'Published ${preview!.localCount} wallpapers. '
            'The previous catalog is saved in buffyjson/history/.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Tile(
              'Live now',
              '${preview!.liveCount}',
              Icons.cloud_outlined,
              colors.textSecondary,
            ),
            _Tile(
              'After publish',
              '${preview.localCount}',
              Icons.cloud_done_outlined,
              colors.primary,
            ),
            _Tile(
              'Added',
              '${diff!.added.length}',
              Icons.add_circle_outline,
              colors.success,
            ),
            _Tile(
              'Edited',
              '${diff.edited.length}',
              Icons.edit_outlined,
              colors.warning,
            ),
            _Tile(
              'Removed',
              '${diff.removed.length}',
              Icons.remove_circle_outline,
              colors.error,
            ),
            _Tile(
              'Fields',
              '${diff.fieldsChanged.length}',
              Icons.data_object_rounded,
              colors.primary,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_phase == _Phase.blocked) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.error.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${preview.problems.length} problems — fix these first. Nothing has been changed on Firebase.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: 8),
                for (final p in preview.problems)
                  SelectableText(
                    p,
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (diff.isEmpty)
          Text(
            'No changes from the live catalog.',
            style: TextStyle(color: colors.textSecondary),
          ),
        _ChangeSection('Added', colors.success, diff.added),
        _ChangeSection('Edited', colors.warning, diff.edited),
        _ChangeSection('Removed', colors.error, diff.removed),
        if (diff.fieldsChanged.isNotEmpty) ...[
          _SectionTitle('Changed fields', colors.primary),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in diff.fieldsChanged) Chip(label: Text(f)),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _ChangeSection extends StatelessWidget {
  const _ChangeSection(this.title, this.color, this.walls);

  final String title;
  final Color color;
  final List<BuffyWallpaper> walls;

  @override
  Widget build(BuildContext context) {
    if (walls.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('$title (${walls.length})', color),
        for (final w in walls)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 28,
                    height: 44,
                    child: Image.network(
                      w.compressUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          ColoredBox(color: colors.bgSubtle),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '#${w.id}  ${w.name}',
                    style: TextStyle(color: colors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  w.category,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 16),
        SelectableText(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appColors.textSecondary),
        ),
      ],
    ),
  );
}
