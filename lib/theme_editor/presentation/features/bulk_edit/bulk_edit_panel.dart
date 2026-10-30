import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme_core/theme_core.dart'
    show
        ThemeSpec,
        exportedIconForLockscreenPath,
        lockscreenViewHeight,
        lockscreenViewWidth;
import 'package:theme_raster_flutter/theme_raster_flutter.dart'
    show LockscreenCanvas;

import '../../../../../core/theme/theme_extensions.dart';
import '../../../core/constants/path_constants.dart';
import '../../../domain/entities/element_widget.dart';
import '../../../domain/entities/lock_element_spec_bridge.dart';
import '../../providers/element_provider.dart';
import '../../providers/spec_loader.dart';
import '../../providers/wallpaper_provider.dart';
import '../../providers/workspace_provider.dart';

const _gap = 16.0;
const _padding = 24.0;
const _labelHeight = 44.0;

/// Lockscreen previews of every theme in the open week, to pick one to edit.
class BulkEditPanel extends ConsumerStatefulWidget {
  const BulkEditPanel({super.key});

  @override
  ConsumerState<BulkEditPanel> createState() => _BulkEditPanelState();
}

class _BulkEditPanelState extends ConsumerState<BulkEditPanel> {
  /// Bumped to make every tile read its saved design again.
  int _revision = 0;

  Future<void> _open(int index) async {
    final wall = ref.read(wallpaperProvider.notifier);
    ref.read(workspaceProvider.notifier).setPage(WorkspacePage.lockscreen);
    if (ref.read(wallpaperProvider).index != index) await wall.setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ws = ref.watch(wallpaperProvider);
    final paths = ws.paths;

    return ColoredBox(
      color: colors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_padding, 16, _padding, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Bulk Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                if (ws.weekNum != null)
                  Text(
                    'Week ${ws.weekNum} · ${paths.length} themes',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Reload designs',
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _revision++),
                ),
              ],
            ),
          ),
          Expanded(
            child: paths.isEmpty
                ? Center(
                    child: Text(
                      'No themes loaded for this week',
                      style: TextStyle(color: colors.textDisabled),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth - _padding * 2;
                      final columns = math.max(2, (width / 190).floor());
                      final tileWidth =
                          (width - _gap * (columns - 1)) / columns;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          _padding,
                          8,
                          _padding,
                          _padding,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: _gap,
                          mainAxisSpacing: _gap,
                          mainAxisExtent:
                              tileWidth *
                                  lockscreenViewHeight /
                                  lockscreenViewWidth +
                              _labelHeight,
                        ),
                        itemCount: paths.length,
                        itemBuilder: (_, i) => _ThemeTile(
                          key: ValueKey(paths[i]),
                          path: paths[i],
                          index: i,
                          revision: _revision,
                          onOpen: () => _open(i),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends ConsumerStatefulWidget {
  const _ThemeTile({
    super.key,
    required this.path,
    required this.index,
    required this.revision,
    required this.onOpen,
  });

  final String path;
  final int index;
  final int revision;
  final VoidCallback onOpen;

  @override
  ConsumerState<_ThemeTile> createState() => _ThemeTileState();
}

class _ThemeTileState extends ConsumerState<_ThemeTile> {
  late Future<ThemeSpec?> _saved;

  String get _name =>
      widget.path.split(Platform.isWindows ? r'\' : '/').last.split('.').first;

  String get _week => ref.read(wallpaperProvider).weekNum ?? '1';

  @override
  void initState() {
    super.initState();
    _saved = readSavedDesign(_week, _name);
  }

  @override
  void didUpdateWidget(_ThemeTile old) {
    super.didUpdateWidget(old);
    if (old.revision != widget.revision) {
      _saved = readSavedDesign(_week, _name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCurrent = ref.watch(
      wallpaperProvider.select((s) => s.index == widget.index),
    );
    // The open theme's edits may not be on disk yet, so read them live.
    final live = isCurrent ? ref.watch(elementProvider) : null;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onOpen,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? colors.primary : colors.border,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<ThemeSpec?>(
                  future: _saved,
                  builder: (context, snapshot) {
                    final spec = snapshot.data;
                    final List<LockElement>? elements = live != null
                        ? live.elements
                        : spec == null
                        ? null
                        : [
                            for (final e in spec.lockscreen.elements)
                              e.toLockElement(),
                          ];
                    final bgAlpha = live?.bgAlpha ?? spec?.lockscreen.bgAlpha;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _Preview(
                          path: widget.path,
                          week: _week,
                          name: _name,
                          elements: elements ?? const [],
                          dimming: bgAlpha ?? 0,
                        ),
                        if (elements == null &&
                            snapshot.connectionState == ConnectionState.done)
                          const _Badge(label: 'Not designed', bottom: true),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: _Badge(label: '${widget.index + 1}'),
                        ),
                        if (isCurrent)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: _Badge(label: 'Editing', primary: true),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                height: _labelHeight,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.path,
    required this.week,
    required this.name,
    required this.elements,
    required this.dimming,
  });

  final String path;
  final String week;
  final String name;
  final List<LockElement> elements;
  final double dimming;

  @override
  Widget build(BuildContext context) {
    final themePath = PathConstants.themePath(week, name);
    final lockscreenPath = PathConstants.lockscreenAdvance(themePath);
    final background = File(PathConstants.p('${lockscreenPath}bg.png'));
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: MediaQuery.withNoTextScaling(
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Roboto'),
            child: LockscreenCanvas(
              elements: elements,
              wallpaper: ResizeImage(FileImage(File(path)), width: 400),
              bgImage: background.existsSync()
                  ? ResizeImage(FileImage(background), width: 400)
                  : null,
              dimming: dimming,
              resolveImage: (relative) {
                final file = File(
                  PathConstants.p('$lockscreenPath$relative.png'),
                );
                if (file.existsSync()) return file;
                final icon = exportedIconForLockscreenPath(relative);
                if (icon == null) return null;
                final exported = File(
                  PathConstants.p(
                    '${PathConstants.iconsXxhdpi(themePath)}$icon.png',
                  ),
                );
                return exported.existsSync() ? exported : null;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.primary = false,
    this.bottom = false,
  });

  final String label;
  final bool primary;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary ? colors.primary : Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: primary ? colors.onPrimary : Colors.white,
        ),
      ),
    );
    return bottom
        ? Align(
            alignment: Alignment.bottomCenter,
            child: Padding(padding: const EdgeInsets.all(8), child: chip),
          )
        : chip;
  }
}
