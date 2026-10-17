import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/lock_element_spec_bridge.dart';
import 'package:theme_core/theme_core.dart';

import 'fixtures/lock_elements.dart';

List<LockElement> _samples() => [
  kitchenSink,
  for (final t in ElementType.values) LockElement(type: t),
  for (final t in [ElementType.slideToUnlock, ElementType.dragToUnlock])
    LockElement(
      type: t,
      width: 300,
      height: 140,
      unlockIcon: UnlockIcon.automatic,
    ),
  const LockElement(
    type: ElementType.calendarGrid,
    calendarRows: 1,
    colorSecondary: Color(0xFFFFFFFF),
  ),
];

void main() {
  test('spec and LockElement produce identical JSON', () {
    for (final e in _samples()) {
      final json = jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>;
      final spec = e.toSpec();
      expect(spec.toJson(), json, reason: e.name);
      expect(spec.toLockElement().toJson(), json, reason: e.name);
    }
  });

  test('derived values match between the two models', () {
    final now = DateTime(2026, 10, 17);
    for (final e in _samples()) {
      final s = e.toSpec();
      expect(s.name, e.name);
      expect(s.label, e.label);
      expect(s.isBold, e.isBold, reason: e.name);
      expect(s.effectiveProgressSource, e.effectiveProgressSource);
      expect(s.effectiveUnlockIcon, e.effectiveUnlockIcon);
      expect(s.unlockHeight, e.unlockHeight);
      expect(s.effectiveUnlockCornerRadius, e.effectiveUnlockCornerRadius);
      expect(s.unlockTextFontSize, e.unlockTextFontSize);
      expect(s.arcTrackColor.argb, e.arcTrackColor.toARGB32(), reason: e.name);
      expect(s.calendarWeekRows, e.calendarWeekRows);
      expect(s.calendarDisplayRows, e.calendarDisplayRows);
      expect(s.calendarDates(now), e.calendarDates(now));
      expect(
        s.activeAnimations.map((a) => a.toJson()).toList(),
        e.activeAnimations.map((a) => a.toJson()).toList(),
        reason: e.name,
      );
    }
  });

  group('spec-only input forms', () {
    test('accepts hex colors, [x, y] alignments and numeric font weights', () {
      final s = LockElementSpec.fromJson({
        'type': 'hourClock',
        'color': '#80FF0000',
        'strokeColor': '00FF00',
        'align': [-1, 0.5],
        'fontWeight': 700,
      });
      expect(s.color, const Rgba(0x80FF0000));
      expect(s.strokeColor, const Rgba(0xFF00FF00));
      expect(s.align, const Alignment2(-1, 0.5));
      expect(s.fontWeight, 700);
      expect(s.isBold, isTrue);
    });

    test('invalid values fall back to the app defaults', () {
      final s = LockElementSpec.fromJson({
        'type': 'nope',
        'color': 'not-a-color',
        'fontWeight': 'FontWeight.w450',
        'animationDuration': 5,
        'notificationLimit': 99,
      });
      expect(s.type, ElementType.swipeUpUnlock);
      expect(s.color, const Rgba(0xFFFFFFFF));
      expect(s.fontWeight, 400);
      expect(s.animationDuration, 100);
      expect(s.notificationLimit, 10);
    });
  });
}
