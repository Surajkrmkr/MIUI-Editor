import 'dart:math';

import 'element_enums.dart';
import 'geometry.dart';
import 'lock_element_spec.dart';
import 'shortcut_app.dart';

bool isDockStyle(ShortcutStyle s) =>
    s == ShortcutStyle.glossDock ||
    s == ShortcutStyle.darkDock ||
    s == ShortcutStyle.pastelDock ||
    s == ShortcutStyle.neonCapsule ||
    s == ShortcutStyle.candyCapsule;

bool isCapsuleStyle(ShortcutStyle s) =>
    s == ShortcutStyle.neonCapsule || s == ShortcutStyle.candyCapsule;

/// Dock styles whose panel can sit on the left, right or away from the edge.
bool supportsShortcutEdge(ShortcutStyle s) =>
    isDockStyle(s) && !isCapsuleStyle(s);

ShortcutEdge shortcutEdgeOf(LockElementSpec el) =>
    supportsShortcutEdge(el.shortcutStyle)
    ? el.shortcutEdge
    : ShortcutEdge.floating;

/// Space the exported panel PNG adds around [panel].
double shortcutPanelInset(Rect2 panel) => panel.width * .25;

/// Space the exported tile PNG adds around [tile], for its shadow.
double shortcutTileExportInset(Rect2 tile) => tile.width * .2;

/// Geometry in theme pixels (before `scale`), shared by preview and export.
class ShortcutSetLayout {
  const ShortcutSetLayout._(this.size, this.tiles, this.panel);

  factory ShortcutSetLayout.of(LockElementSpec el) {
    final n = ShortcutApp.parse(el.shortcutApps).length;
    final w = el.width;
    switch (el.shortcutStyle) {
      case ShortcutStyle.socialRow:
      case ShortcutStyle.softRow:
      case ShortcutStyle.glossOrbs:
        final tile = w / (n + max(0, n - 1) * .18 + .5);
        final pad = tile * .25;
        final h = tile + pad * 2;
        return ShortcutSetLayout._(Size2(w, h), [
          for (var i = 0; i < n; i++)
            Rect2.fromLTWH(pad + i * tile * 1.18, pad, tile, tile),
        ], Rect2.fromLTWH(0, 0, w, h));
      case ShortcutStyle.hexGrid:
        final gap = w * .045;
        final tile = (w - gap * 1.5) / 2.5;
        final rows = (n + 1) ~/ 2;
        return ShortcutSetLayout._(
          Size2(w, max(1, tile + max(0, rows - 1) * tile * .9)),
          [
            for (var i = 0; i < n; i++)
              Rect2.fromLTWH(
                (i % 2) * (tile + gap) +
                    ((i ~/ 2).isOdd ? (tile + gap) / 2 : 0),
                (i ~/ 2) * tile * .9,
                tile,
                tile,
              ),
          ],
          null,
        );
      default:
    }
    if (el.shortcutStyle == ShortcutStyle.socialCards) {
      final h = w * .4;
      final gap = w * .07;
      return ShortcutSetLayout._(
        Size2(w, max(1, n * h + max(0, n - 1) * gap)),
        [for (var i = 0; i < n; i++) Rect2.fromLTWH(0, i * (h + gap), w, h)],
        null,
      );
    }
    if (isDockStyle(el.shortcutStyle)) {
      final neon = isCapsuleStyle(el.shortcutStyle);
      final tile = w * (neon ? .62 : .64);
      final gap = tile * (neon ? .3 : .12);
      final top = tile * (neon ? .6 : .55);
      final h = top * 2 + n * tile + max(0, n - 1) * gap;
      final x = switch (shortcutEdgeOf(el)) {
        ShortcutEdge.right => w * .13,
        ShortcutEdge.left => w - w * .13 - tile,
        ShortcutEdge.floating => (w - tile) / 2,
      };
      return ShortcutSetLayout._(Size2(w, h), [
        for (var i = 0; i < n; i++)
          Rect2.fromLTWH(x, top + i * (tile + gap), tile, tile),
      ], Rect2.fromLTWH(0, 0, w, h));
    }
    final gap = w * .07;
    final tile = (w - gap) / 2;
    final rows = (n + 1) ~/ 2;
    return ShortcutSetLayout._(
      Size2(w, max(1, rows * tile + max(0, rows - 1) * gap)),
      [
        for (var i = 0; i < n; i++)
          Rect2.fromLTWH(
            (i % 2) * (tile + gap),
            (i ~/ 2) * (tile + gap),
            tile,
            tile,
          ),
      ],
      null,
    );
  }

  final Size2 size;
  final List<Rect2> tiles;
  final Rect2? panel;
}
