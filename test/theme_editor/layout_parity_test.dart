import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/lock_element_spec_bridge.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/widgets/analog_clock_art.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/widgets/calendar_style_art.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/widgets/shortcut_set_art.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/widgets/unlock_skin_art.dart';
import 'package:theme_core/lockscreen_layout.dart' as core;

/// The painters still use the app's own layout classes; these must stay in
/// lockstep with theme_core's until the painters switch over.
List<double> _r(Rect r) => [r.left, r.top, r.right, r.bottom];
List<double> _r2(core.Rect2 r) => [r.left, r.top, r.right, r.bottom];

void main() {
  test('CalendarLayout matches theme_core', () {
    for (final style in CalendarStyle.values) {
      for (final rows in [1, 2, 6]) {
        for (final month in [true, false]) {
          for (final weekdays in [true, false]) {
            final el = LockElement(
              type: ElementType.calendarGrid,
              calendarStyle: style,
              calendarRows: rows,
              calendarShowMonth: month,
              calendarShowWeekdays: weekdays,
              width: 420,
              height: 330,
              color: const Color(0xFFEEEEEE),
              strokeColor: const Color(0xFFCC3333),
              borderColor: const Color(0xFF112233),
            );
            final a = CalendarLayout.of(el);
            final b = core.CalendarLayout.of(el.toSpec());
            final why = '$style rows=$rows month=$month weekdays=$weekdays';
            expect(_r2(b.inner), _r(a.inner), reason: why);
            expect(b.rowH, a.rowH, reason: why);
            expect(b.colW, a.colW, reason: why);
            expect(b.monthRow, a.monthRow, reason: why);
            expect(b.weekdayRow, a.weekdayRow, reason: why);
            expect(b.firstDateRow, a.firstDateRow, reason: why);
            expect(b.showsDates, a.showsDates, reason: why);
            expect(b.labels, a.labels, reason: why);
            expect(b.panelRadius, a.panelRadius, reason: why);
            expect(b.todayText.argb, a.todayText.toARGB32(), reason: why);
            expect(
              b.exportInset,
              CalendarStyleArt.exportInset(el),
              reason: why,
            );
            for (var col = 0; col < 7; col++) {
              expect(b.labelColor(col).argb, a.labelColor(col).toARGB32());
              for (var row = 0; row < el.calendarDisplayRows; row++) {
                expect(
                  _r2(b.cell(row, col)),
                  _r(a.cell(row, col)),
                  reason: why,
                );
                final ha = a.highlight(row, col), hb = b.highlight(row, col);
                expect(_r2(hb.rect), _r(ha.outerRect), reason: why);
                expect(hb.radius, ha.tlRadiusX, reason: why);
              }
            }
          }
        }
      }
    }
  });

  test('ShortcutSetLayout and ShortcutApp match theme_core', () {
    for (final app in ShortcutApp.values) {
      final c = core.ShortcutApp.values.byName(app.name);
      expect(c.label, app.label);
      expect(c.iconType, app.iconType);
      expect(c.package, app.package);
      expect(c.activity, app.activity);
      expect(c.brandColor.argb, app.brand.toARGB32());
    }
    expect(core.ShortcutApp.values.length, ShortcutApp.values.length);
    expect(
      core.ShortcutApp.parse('camera, nope,phone').map((a) => a.name),
      ShortcutApp.parse('camera, nope,phone').map((a) => a.name),
    );

    for (final style in ShortcutStyle.values) {
      expect(
        core.supportsShortcutEdge(style),
        supportsShortcutEdge(style),
        reason: '$style',
      );
      for (final edge in ShortcutEdge.values) {
        for (final apps in [
          'gallery,camera,music,browser,whatsapp,settings',
          'camera',
          'camera,phone,music,browser,whatsapp,settings,gallery,clock',
          '',
        ]) {
          for (final w in [180.0, 300.0]) {
            final el = LockElement(
              type: ElementType.shortcutSet,
              shortcutStyle: style,
              shortcutEdge: edge,
              shortcutApps: apps,
              width: w,
            );
            final a = ShortcutSetLayout.of(el);
            final b = core.ShortcutSetLayout.of(el.toSpec());
            final why = '$style $edge "$apps" $w';
            expect(
              [b.size.width, b.size.height],
              [a.size.width, a.size.height],
              reason: why,
            );
            expect(
              b.tiles.map(_r2).toList(),
              a.tiles.map(_r).toList(),
              reason: why,
            );
            expect(
              b.panel == null ? null : _r2(b.panel!),
              a.panel == null ? null : _r(a.panel!),
              reason: why,
            );
            if (a.panel case final p?) {
              expect(
                core.shortcutPanelInset(b.panel!),
                ShortcutSetArt.panelInset(p),
              );
            }
            for (var i = 0; i < a.tiles.length; i++) {
              expect(
                core.shortcutTileExportInset(b.tiles[i]),
                ShortcutSetArt.exportInset(a.tiles[i]),
                reason: why,
              );
            }
          }
        }
      }
    }
  });

  test('UnlockSkinLayout matches theme_core', () {
    for (final type in [
      ElementType.tapToUnlock,
      ElementType.slideToUnlock,
      ElementType.dragToUnlock,
      ElementType.swipeUpUnlock,
    ]) {
      for (final skin in UnlockSkin.values) {
        for (final (w, h) in [(360.0, 120.0), (300.0, 60.0), (200.0, 200.0)]) {
          for (final text in ['', 'Slide']) {
            for (final scale in [.6, 1.0]) {
              final el = LockElement(
                type: type,
                unlockSkin: skin,
                width: w,
                height: h,
                unlockText: text,
                unlockIconScale: scale,
              );
              final a = UnlockSkinLayout.of(el);
              final b = core.UnlockSkinLayout.of(el.toSpec());
              final why = '$type $skin $w x $h "$text" $scale';
              expect(
                [
                  b.width,
                  b.height,
                  b.thumbY,
                  b.thumbWidth,
                  b.thumbHeight,
                  b.thumbPaintWidth,
                  b.travel,
                  b.iconCenter.dx,
                  b.iconCenter.dy,
                  b.iconSize,
                ],
                [
                  a.width,
                  a.height,
                  a.thumbY,
                  a.thumbWidth,
                  a.thumbHeight,
                  a.thumbPaintWidth,
                  a.travel,
                  a.iconCenter.dx,
                  a.iconCenter.dy,
                  a.iconSize,
                ],
                reason: why,
              );
              expect(_r2(b.textRect), _r(a.textRect), reason: why);
              expect(
                b.target == null ? null : _r2(b.target!),
                a.target == null ? null : _r(a.target!),
                reason: why,
              );
            }
          }
        }
      }
    }
  });

  test('analog parts and suffixes match theme_core', () {
    for (final type in ElementType.values) {
      expect(
        core.AnalogClockType(type).isAnalog,
        AnalogClockType(type).isAnalog,
      );
      for (final style in AnalogStyle.values) {
        final el = LockElement(type: type, analogStyle: style);
        final spec = el.toSpec();
        final a = analogPartsOf(el).map((p) => p.name).toList();
        final b = core.analogPartsOfSpec(spec).map((p) => p.name).toList();
        expect(b, a, reason: '$type $style');
        for (final p in AnalogPart.values) {
          final cp = core.AnalogPart.values.byName(p.name);
          expect(core.analogPartSuffix(spec, cp), AnalogClockArt.suffix(el, p));
          expect(cp.angleExpression, p.angleExpression);
        }
      }
    }
  });
}
