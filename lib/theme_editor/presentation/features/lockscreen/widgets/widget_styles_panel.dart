import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../domain/entities/builtin_widget_styles.dart';
import '../../../../domain/entities/element_widget.dart';
import '../../../../domain/entities/widget_style.dart';
import '../../../providers/element_provider.dart';
import '../../../providers/widget_style_provider.dart';
import 'unlock_control_preview.dart';

class WidgetStylesPanel extends ConsumerStatefulWidget {
  const WidgetStylesPanel({super.key, required this.element});
  final LockElement element;
  @override
  ConsumerState<WidgetStylesPanel> createState() => _WidgetStylesPanelState();
}

class _WidgetStylesPanelState extends ConsumerState<WidgetStylesPanel> {
  String? _setId;
  bool _busy = false;

  Future<void> _run(
    Future<Failure?> Function() action, {
    bool reload = false,
  }) async {
    setState(() => _busy = true);
    try {
      final failure = await action();
      if (failure != null) throw Exception(failure.message);
      if (reload && mounted) {
        ref.invalidate(widgetStyleSetsProvider);
        await ref.read(widgetStyleSetsProvider.future);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(List<WidgetStyleSet> sets) async {
    final element = widget.element;
    var styleName = 'My ${element.type.label}';
    var setName =
        sets.where((set) => set.id == _setId).firstOrNull?.name ?? 'Personal';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Style'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: styleName,
                autofocus: true,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Style name'),
                onChanged: (value) => styleName = value,
              ),
              TextFormField(
                initialValue: setName,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Style set'),
                onChanged: (value) => setName = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (styleName.trim().isNotEmpty && setName.trim().isNotEmpty) {
                Navigator.pop(dialogContext, styleName.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    await _run(() async {
      final (set, failure) = await ref
          .read(manageWidgetStylesProvider)
          .saveCurrent(
            element: element,
            name: name,
            setName: setName,
            set: sets
                .where(
                  (set) =>
                      set.name.toLowerCase() == setName.trim().toLowerCase(),
                )
                .firstOrNull,
          );
      if (failure == null && mounted) setState(() => _setId = set!.id);
      return failure;
    }, reload: true);
  }

  Future<void> _import() => _run(() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Import Style Set',
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    final (set, failure) = await ref
        .read(manageWidgetStylesProvider)
        .importSet(path);
    if (failure == null && mounted) setState(() => _setId = set!.id);
    return failure;
  }, reload: true);

  Future<void> _export(WidgetStyleSet set) => _run(() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Style Set',
      fileName: '${set.id}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null) return null;
    return ref
        .read(manageWidgetStylesProvider)
        .exportSet(set, path.endsWith('.json') ? path : '$path.json');
  });

  Future<void> _delete(WidgetStyleSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Style Set?'),
        content: Text(set.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(
        () => ref.read(manageWidgetStylesProvider).delete(set.id),
        reload: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(widgetStyleSetsProvider);
    final saved = library.asData?.value;
    final sets = [builtinUnlockStyles, ...?saved];
    final set =
        sets.where((item) => item.id == _setId).firstOrNull ?? sets.first;
    final styles = set.styles
        .where((style) => style.type == widget.element.type)
        .toList();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(set.id),
          initialValue: set.id,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Style set',
            isDense: true,
          ),
          items: [
            for (final item in sets)
              DropdownMenuItem(
                value: item.id,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _busy ? null : (value) => setState(() => _setId = value),
        ),
        Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: 'Save current style',
              icon: const Icon(Icons.add_box_outlined),
              onPressed: _busy || saved == null ? null : () => _save(saved),
            ),
            IconButton(
              tooltip: 'Import style set',
              icon: const Icon(Icons.file_upload_outlined),
              onPressed: _busy ? null : _import,
            ),
            IconButton(
              tooltip: 'Export style set',
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _busy ? null : () => _export(set),
            ),
            if (set.id != builtinUnlockStyles.id)
              IconButton(
                tooltip: 'Delete style set',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _busy ? null : () => _delete(set),
              ),
          ],
        ),
        if (_busy || library.isLoading)
          const LinearProgressIndicator(minHeight: 2),
        if (library.hasError)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${library.error}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.error, fontSize: 11),
                ),
              ),
              IconButton(
                tooltip: 'Retry loading styles',
                icon: const Icon(Icons.refresh),
                onPressed: _busy
                    ? null
                    : () => ref.invalidate(widgetStyleSetsProvider),
              ),
            ],
          ),
        if (styles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No styles for this widget'),
          ),
        LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: styles.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth >= 360
                  ? 3
                  : constraints.maxWidth >= 220
                  ? 2
                  : 1,
              mainAxisExtent: 104,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final style = styles[index];
              final element = style.applyTo(LockElement(type: style.type));
              final json = widget.element.toJson();
              final selected = style.appearance.entries.every(
                (entry) => json[entry.key] == entry.value,
              );
              return Tooltip(
                message: style.name,
                child: Material(
                  color: selected
                      ? scheme.secondaryContainer
                      : scheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(
                      color: selected ? scheme.primary : scheme.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('style-${style.id}'),
                    onTap: _busy || widget.element.isLocked
                        ? null
                        : () => ref
                              .read(elementProvider.notifier)
                              .applyStyle(style),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: const Color(0xFF34363C),
                            padding: const EdgeInsets.all(8),
                            child: FittedBox(
                              child: _StylePreview(element: element),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            style.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StylePreview extends StatelessWidget {
  const _StylePreview({required this.element});
  final LockElement element;
  @override
  Widget build(BuildContext context) {
    final angle = element.angle * pi / 180;
    final width = element.width / AppConstants.screenRatio;
    final height = element.unlockHeight / AppConstants.screenRatio;
    return SizedBox(
      width: width * cos(angle).abs() + height * sin(angle).abs(),
      height: width * sin(angle).abs() + height * cos(angle).abs(),
      child: OverflowBox(
        minWidth: width,
        maxWidth: width,
        minHeight: height,
        maxHeight: height,
        child: Transform.rotate(
          angle: angle,
          child: UnlockControlPreview(element: element),
        ),
      ),
    );
  }
}
