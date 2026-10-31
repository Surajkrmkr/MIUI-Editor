import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/builtin_widget_styles.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/user_profile.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/widgets/element_info_panel.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/pro_workspace/widgets/layer_manager.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/element_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/lockscreen_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/user_profile_provider.dart';

void main() {
  testWidgets('dot clocks and containers offer wallpaper glass', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(500, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final type in [ElementType.dotClock, ElementType.containerBG1]) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(elementProvider.notifier);
      notifier.add(LockElement(type: type, width: 200, height: 100));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ElementInfoPanel()),
            ),
          ),
        ),
      );
      final label = find.text('Wallpaper Glass');
      expect(label, findsOneWidget, reason: type.name);
      expect(find.text('Edge Light'), findsNothing);
      final toggle = find.descendant(
        of: find.ancestor(of: label, matching: find.byType(Row)).first,
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();
      final glass = container.read(elementProvider).elements.single;
      expect(glass.isWallpaperGlass, isTrue, reason: type.name);
      expect(find.text('Edge Light'), findsOneWidget);
      expect(find.text('Shadow Color'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('gauge has a Scale control beside Font Size', (tester) async {
    tester.view
      ..physicalSize = const Size(500, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(elementProvider.notifier);
    notifier.add(const LockElement(type: ElementType.gaugeSet, width: 600));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ElementInfoPanel()),
          ),
        ),
      ),
    );
    expect(find.text('FONT SIZE'), findsOneWidget);
    final scale = find.descendant(
      of: find.byKey(const ValueKey('gauge-scale')),
      matching: find.byType(Slider),
    );
    await tester.ensureVisible(scale);
    await tester.drag(scale, const Offset(60, 0));
    await tester.pump();
    final gauge = container.read(elementProvider).elements.single;
    expect(gauge.scale, greaterThan(1.5));
    expect(
      gauge.fontSize,
      const LockElement(type: ElementType.gaugeSet).fontSize,
    );
    expect(tester.takeException(), isNull);
  });
  test('wallpaper colors apply to the whole set in one undo step', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(elementProvider.notifier);
    final preset = builtinBatterySets.firstWhere(
      (preset) => preset.id == 'battery-set-annapurna-my-phone',
    );
    notifier.applyElementSet(preset.elements, isBatterySetElement);
    final before = container.read(elementProvider);
    notifier.applyInfoSetColors(
      preset.elements.last,
      text: const Color(0xFFFFFFFF),
      accent: const Color(0xFF009988),
      background: const Color(0xFF202020),
      outline: const Color(0xFFEEDD99),
    );
    final after = container.read(elementProvider);
    expect(after.undoCount, before.undoCount + 1);
    for (var index = 0; index < before.elements.length; index++) {
      final original = before.elements[index];
      final changed = after.elements[index];
      expect(
        changed
            .copyWith(
              color: original.color,
              colorSecondary: original.colorSecondary,
            )
            .toJson(),
        original.toJson(),
      );
      expect(changed.color.a, original.color.a);
      expect(changed.colorSecondary.a, original.colorSecondary.a);
      if (!original.type.isShape) expect(changed.color.toARGB32(), 0xFFFFFFFF);
      if (original.effectiveProgressSource != ArcProgressSource.none) {
        expect(changed.color.toARGB32(), 0xFF009988);
      }
    }
    notifier.undo();
    expect(container.read(elementProvider).elements, before.elements);
    notifier.redo();
    expect(container.read(elementProvider).elements, after.elements);
    notifier.setActive(
      preset.elements.last.type,
      id: preset.elements.last.name,
    );
    notifier.setLocked(preset.elements.last.type, true);
    final locked = container.read(elementProvider);
    notifier.applyInfoSetColors(
      preset.elements.last,
      text: Colors.red,
      accent: Colors.red,
      background: Colors.red,
      outline: Colors.red,
    );
    expect(container.read(elementProvider), same(locked));
  });

  testWidgets('set color swatches match the shared two-column layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(elementProvider.notifier);
    for (final id in [
      'battery-set-annapurna-my-phone',
      'battery-set-annapurna-electric-type',
    ]) {
      final preset = builtinBatterySets.firstWhere((preset) => preset.id == id);
      notifier.applyElementSet(preset.elements, isBatterySetElement);
      notifier.setActive(
        preset.elements.last.type,
        id: preset.elements.last.name,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ElementInfoPanel()),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('COLOR'), findsOneWidget);
      final wallpaperButton = find.widgetWithText(
        OutlinedButton,
        'Use Wallpaper Colors',
      );
      expect(wallpaperButton, findsOneWidget);
      final first = tester.getRect(
        find.byKey(const ValueKey('info-set-color-0')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('info-set-color-1')),
      );
      expect(first.width, greaterThan(100));
      expect(first.width, closeTo(second.width, .01));
      expect(first.height, 46);
      expect(first.top, second.top);
      expect(second.left - first.right, closeTo(10, .01));
      if (id.endsWith('electric-type')) {
        final last = tester.getRect(
          find.byKey(const ValueKey('info-set-color-2')),
        );
        expect(last.width, closeTo(first.width * 2 + 10, .01));
        expect(last.top - first.bottom, closeTo(10, .01));
      }
      final action = tester.getRect(wallpaperButton);
      expect(action.width, closeTo(first.width * 2 + 10, .01));
      notifier.setLocked(preset.elements.last.type, true);
      await tester.pump();
      expect(tester.widget<OutlinedButton>(wallpaperButton).onPressed, isNull);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('battery set exposes working color and text customization', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(elementProvider.notifier);
    final preset = builtinBatterySets.firstWhere(
      (preset) => preset.id == 'battery-set-annapurna-my-phone',
    );
    notifier.applyElementSet(preset.elements, isBatterySetElement);
    final label = preset.elements.firstWhere(
      (member) => member.type.isNormalText,
    );
    notifier.setActive(label.type, id: label.name);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ElementInfoPanel()),
          ),
        ),
      ),
    );
    final swatch = find.byKey(const ValueKey('info-set-color-0'));
    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pumpAndSettle();
    final picker = tester.widget<ColorPicker>(find.byType(ColorPicker));
    picker.onColorChanged(Colors.red);
    await tester.pump();
    picker.onColorChanged(Colors.blue);
    await tester.pump();
    final colorTargets = preset.elements
        .where((member) => member.color == label.color)
        .map((member) => member.name)
        .toSet();
    expect(
      container
          .read(elementProvider)
          .elements
          .where((member) => colorTargets.contains(member.name))
          .every((member) => member.color == Colors.blue),
      isTrue,
    );
    await tester.tapAt(const Offset(790, 10));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byKey(ValueKey('info-set-text-${label.name}')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, 'My Device');
    await tester.pump();
    final edited = container.read(elementProvider);
    expect(
      edited.elements.firstWhere((member) => member.name == label.name).text,
      'My Device',
    );
    final restored = edited.elements
        .map((member) => LockElement.fromJson(member.toJson()))
        .toList();
    final xml = container
        .read(lockscreenProvider.notifier)
        .buildManifest(ElementState(elements: restored))
        .toXmlString();
    expect(xml, contains('My Device'));
    expect(xml, contains('#battery_level'));
    expect(
      restored
          .firstWhere((member) => member.name == label.name)
          .color
          .toARGB32(),
      Colors.blue.toARGB32(),
    );
    notifier.undo();
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, label.text);
    notifier.redo();
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'My Device');
    notifier.setLocked(label.type, true);
    await tester.pump();
    expect(tester.widget<TextField>(field).enabled, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'battery set palette and labels customize together with undo and isolation',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(elementProvider.notifier);
      const personal = LockElement(
        type: ElementType.normalText1,
        text: 'Personal',
      );
      notifier.add(personal);
      notifier.applyElementSet(
        builtinWeatherSets.first.elements,
        isWeatherSetElement,
      );
      for (final preset in builtinBatterySets.where(
        (preset) => preset.user == 'annapurna',
      )) {
        notifier.applyElementSet(preset.elements, isBatterySetElement);
        final before = container.read(elementProvider);
        final selected = preset.elements.last;
        final originalColor = selected.color;
        final foreground = preset.elements
            .where((member) => member.color == originalColor)
            .map((member) => member.name)
            .toSet();
        final fills = preset.elements
            .where((member) => member.colorSecondary == originalColor)
            .map((member) => member.name)
            .toSet();
        for (final color in [Colors.red, Colors.blue]) {
          notifier.setInfoSetColor(
            selected,
            color,
            foregroundIds: foreground,
            fillIds: fills,
          );
        }
        final recolored = container.read(elementProvider);
        for (var index = 0; index < before.elements.length; index++) {
          final original = before.elements[index];
          final changed = recolored.elements[index];
          expect(
            changed.color,
            foreground.contains(original.name) ? Colors.blue : original.color,
          );
          expect(
            changed.colorSecondary,
            fills.contains(original.name)
                ? Colors.blue
                : original.colorSecondary,
          );
          expect(
            changed
                .copyWith(
                  color: original.color,
                  colorSecondary: original.colorSecondary,
                )
                .toJson(),
            original.toJson(),
          );
        }
        notifier.undo();
        expect(
          container
              .read(elementProvider)
              .elements
              .where((member) => foreground.contains(member.name))
              .every((member) => member.color == Colors.red),
          isTrue,
        );
        notifier.redo();
        expect(container.read(elementProvider).elements, recolored.elements);
        final labels = preset.elements
            .where((member) => member.type.isNormalText)
            .toList();
        if (labels.isNotEmpty) {
          final labelIds = labels
              .where((member) => member.text == labels.first.text)
              .map((member) => member.name)
              .toSet();
          final beforeText = container.read(elementProvider);
          notifier.setInfoSetText(selected, labelIds, 'Custom label');
          final afterText = container.read(elementProvider);
          expect(afterText.undoCount, beforeText.undoCount + 1);
          expect(
            afterText.elements
                .where((member) => labelIds.contains(member.name))
                .every((member) => member.text == 'Custom label'),
            isTrue,
          );
          expect(
            afterText.elements
                .where((member) => member.type == ElementType.batteryText)
                .every((member) => member.text == 'Text'),
            isTrue,
          );
          notifier.undo();
          expect(container.read(elementProvider).elements, beforeText.elements);
        }
        expect(container.read(elementProvider).elements.first, same(personal));
        notifier.setActive(selected.type, id: selected.name);
        notifier.setLocked(selected.type, true);
        final locked = container.read(elementProvider);
        notifier.setInfoSetColor(
          selected,
          Colors.green,
          foregroundIds: foreground,
          fillIds: fills,
        );
        notifier.setInfoSetText(
          selected,
          preset.elements.map((member) => member.name).toSet(),
          'Locked',
        );
        expect(container.read(elementProvider), same(locked));
      }
    },
  );

  testWidgets(
    'Annapurna battery labels open battery styles and move with their set',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(userProfileProvider.notifier)
          .select(UserProfileType.annapurna);
      final notifier = container.read(elementProvider.notifier);
      final presets = builtinBatterySets.where(
        (preset) => preset.user == 'annapurna',
      );
      for (final preset in presets) {
        notifier.applyElementSet(preset.elements, isBatterySetElement);
        final selected = preset.elements.firstWhere(
          (element) => element.type.isNormalText,
          orElse: () => preset.elements.last,
        );
        notifier.setActive(selected.type, id: selected.name);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(child: ElementInfoPanel()),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('Battery Sets-scale')),
          findsOneWidget,
          reason: preset.id,
        );
        expect(
          find.byKey(const ValueKey('set-battery-set-annapurna-my-phone')),
          findsOneWidget,
          reason: preset.id,
        );
        expect(
          find.byKey(const ValueKey('set-battery-set-suraj-twin-rings')),
          findsNothing,
        );
        expect(
          container.read(elementProvider).editableElements,
          hasLength(1),
          reason: preset.id,
        );
        notifier.moveElement(selected.type, 12, 8);
        final moved = container.read(elementProvider).elements;
        for (var index = 0; index < moved.length; index++) {
          expect(moved[index].dx, preset.elements[index].dx + 12);
          expect(moved[index].dy, preset.elements[index].dy + 8);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'Annapurna battery presets preserve labels and live values in export',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final exporter = container.read(lockscreenProvider.notifier);
      for (final preset in builtinBatterySets.where(
        (preset) => preset.user == 'annapurna',
      )) {
        final restored = preset.elements
            .map((element) => LockElement.fromJson(element.toJson()))
            .toList();
        final manifest = exporter
            .buildManifest(ElementState(elements: restored))
            .toXmlString();
        expect(manifest, contains('#battery_level'), reason: preset.id);
        expect(manifest, isNot(contains('75%')), reason: preset.id);
        for (final label in restored.where(
          (element) => element.type.isNormalText,
        )) {
          expect(manifest, contains(label.text), reason: preset.id);
        }
        expect(
          restored.map((element) => element.name),
          preset.elements.map((element) => element.name),
        );
      }
    },
  );

  test(
    'battery preset labels stay grouped without claiming standalone text',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(elementProvider.notifier);
      const personal = LockElement(
        type: ElementType.normalText1,
        text: 'Personal',
      );
      const label = LockElement(
        type: ElementType.normalText1,
        instanceId: 'bt-label',
        text: 'My Phone',
      );
      notifier.add(personal);
      notifier.applyElementSet([
        ...builtinBatterySets.first.elements,
        label,
      ], isBatterySetElement);
      notifier.setActive(label.type, id: label.name);
      notifier.moveElement(label.type, 10, 20);
      expect(container.read(elementProvider).elements.first, same(personal));
      final moved = container.read(elementProvider).elements.last;
      expect(moved.dx, label.dx + 10);
      expect(moved.dy, label.dy + 20);
      notifier.setActive(personal.type, id: personal.name);
      notifier.setText(personal.type, 'Independent');
      expect(
        container.read(elementProvider).elements.first.text,
        'Independent',
      );
      expect(container.read(elementProvider).elements.last.text, label.text);
      notifier.removeElements(isBatterySetElement);
      expect(
        container.read(elementProvider).elements.single.text,
        'Independent',
      );
    },
  );

  test('standalone elements retain independent editing and reordering', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(elementProvider.notifier);
    const first = LockElement(type: ElementType.weatherTemp, dx: 10, dy: 20);
    const second = LockElement(type: ElementType.batteryText, dx: 30, dy: 40);
    notifier.addAll([first, second]);
    expect(container.read(elementProvider).infoSetMembers(first), isEmpty);
    expect(container.read(elementProvider).editableElements, [first, second]);
    notifier.setActive(first.type);
    notifier.setPosition(first.type, 50, 60);
    expect(container.read(elementProvider).elements.last, same(second));
    notifier.setFontSize(first.type, 25);
    expect(container.read(elementProvider).elements.first.fontSize, 25);
    notifier.centerHorizontal(first.type);
    expect(container.read(elementProvider).elements.first.dx, 0);
    expect(container.read(elementProvider).elements.first.dy, 60);
    notifier.reorder(0, 2);
    expect(container.read(elementProvider).elements.first, same(second));
  });

  for (final weather in [true, false]) {
    test(
      '${weather ? "weather" : "battery"} set layer actions stay grouped',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(elementProvider.notifier);
        notifier.applyElementSet(
          builtinWeatherSets.first.elements,
          isWeatherSetElement,
        );
        notifier.applyElementSet(
          builtinBatterySets.first.elements,
          isBatterySetElement,
        );
        final owns = weather ? isWeatherSetElement : isBatterySetElement;
        final before = container.read(elementProvider);
        final members = before.elements.where(owns).toList();
        final selected = members.first;
        expect(before.editableElements.length, 2);
        notifier.toggleVisibility(selected.type, id: selected.name);
        expect(
          container
              .read(elementProvider)
              .elements
              .where(owns)
              .every((member) => !member.isVisible),
          isTrue,
        );
        notifier.toggleVisibility(selected.type, id: selected.name);
        notifier.toggleLock(selected.type, id: selected.name);
        expect(
          container
              .read(elementProvider)
              .elements
              .where(owns)
              .every((member) => member.isLocked),
          isTrue,
        );
        notifier.setActive(selected.type, id: selected.name);
        final locked = container.read(elementProvider).elements;
        notifier.moveElement(selected.type, 50, 50);
        expect(container.read(elementProvider).elements, same(locked));
        notifier.toggleLock(selected.type, id: selected.name);
        notifier.enterGroupMode(selected.type, id: selected.name);
        expect(
          container.read(elementProvider).selectedIds,
          members.map((member) => member.name).toSet(),
        );
        notifier.toggleGroupSelect(members.last.type, id: members.last.name);
        expect(container.read(elementProvider).selectedIds, isEmpty);
        notifier.setActive(selected.type, id: selected.name);
        notifier.resetPosition(selected.type);
        final centered = container
            .read(elementProvider)
            .elements
            .where(owns)
            .toList();
        for (var index = 1; index < members.length; index++) {
          expect(
            centered[index].dx - centered.first.dx,
            closeTo(members[index].dx - members.first.dx, 1e-9),
          );
          expect(
            centered[index].dy - centered.first.dy,
            closeTo(members[index].dy - members.first.dy, 1e-9),
          );
        }
        notifier.remove(selected.type, id: selected.name);
        expect(container.read(elementProvider).elements.any(owns), isFalse);
        expect(container.read(elementProvider).editableElements.length, 1);
        notifier.undo();
        expect(container.read(elementProvider).editableElements.length, 2);
        notifier.reorder(
          container.read(elementProvider).elements.indexWhere(owns),
          weather ? before.elements.length : 0,
        );
        final reordered = container.read(elementProvider).elements;
        final edge = weather
            ? reordered.reversed.take(members.length).toList().reversed.toList()
            : reordered.take(members.length).toList();
        expect(
          edge.map((member) => member.name),
          members.map((member) => member.name),
        );
      },
    );

    test('${weather ? "weather" : "battery"} set moves as one widget', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(elementProvider.notifier);
      notifier.applyElementSet(
        builtinWeatherSets.first.elements,
        isWeatherSetElement,
      );
      notifier.applyElementSet(
        builtinBatterySets.first.elements,
        isBatterySetElement,
      );
      final owns = weather ? isWeatherSetElement : isBatterySetElement;
      final before = container.read(elementProvider);
      final members = before.elements.where(owns).toList();
      final selected = members.firstWhere((element) => element.type.isShape);
      notifier.setActive(selected.type, id: selected.name);
      expect(
        container.read(elementProvider).selectedIds,
        members.map((element) => element.name).toSet(),
      );
      notifier.snapshotForDrag();
      notifier.moveElement(selected.type, 15, -20);
      notifier.setPosition(selected.type, selected.dx + 30, selected.dy - 40);
      final after = container.read(elementProvider);
      for (var index = 0; index < before.elements.length; index++) {
        final original = before.elements[index];
        final moved = after.elements[index];
        if (owns(original)) {
          expect(moved.dx, original.dx + 30);
          expect(moved.dy, original.dy - 40);
          expect(
            moved.copyWith(dx: original.dx, dy: original.dy).toJson(),
            original.toJson(),
          );
        } else {
          expect(moved, same(original));
        }
      }
      expect(after.undoCount, before.undoCount + 1);
      notifier.undo();
      expect(container.read(elementProvider).elements, before.elements);
      notifier.redo();
      expect(container.read(elementProvider).elements, after.elements);
    });

    testWidgets('${weather ? "weather" : "battery"} set scale control', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(elementProvider.notifier);
      final preset = weather
          ? builtinWeatherSets.first
          : builtinBatterySets.first;
      final owns = weather ? isWeatherSetElement : isBatterySetElement;
      notifier.applyElementSet(preset.elements, owns);
      final selected = preset.elements.firstWhere(
        (element) => !element.type.isShape,
      );
      notifier.setActive(selected.type, id: selected.name);
      final before = container.read(elementProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: SingleChildScrollView(child: ElementInfoPanel()),
              ),
            ),
          ),
        ),
      );
      final slider = find.byKey(
        ValueKey('${weather ? "Weather" : "Battery"} Sets-scale'),
      );
      expect(slider, findsOneWidget);
      expect(find.text('Scale'), findsOneWidget);
      expect(find.text('Set Scale'), findsNothing);
      expect(find.text('FONT SIZE'), findsNothing);
      expect(find.text('Font Size'), findsNothing);
      await tester.drag(slider, const Offset(40, 0));
      await tester.pump();
      expect(
        container.read(elementProvider).elements.first.scale,
        greaterThan(before.elements.first.scale),
      );
      expect(container.read(elementProvider).undoCount, before.undoCount + 1);
      notifier.undo();
      await tester.pump();
      expect(tester.widget<Slider>(slider).value, before.elements.first.scale);
      notifier.update(
        selected.type,
        (element) => element.copyWith(isLocked: true),
      );
      await tester.pump();
      expect(tester.widget<Slider>(slider).onChanged, isNull);
      final locked = container.read(elementProvider).elements;
      notifier.scaleElementSet(owns, 2);
      expect(container.read(elementProvider).elements, same(locked));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: LayerManager())),
        ),
      );
      expect(
        find.text(weather ? 'Weather Sets' : 'Battery Sets'),
        findsOneWidget,
      );
      for (final member in preset.elements) {
        expect(find.text(member.label), findsNothing);
      }
      await tester.tap(
        find.byTooltip('Delete ${weather ? "Weather" : "Battery"} Sets'),
      );
      await tester.pump();
      expect(container.read(elementProvider).elements, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    test(
      '${weather ? "weather" : "battery"} set scales and undoes as a unit',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(elementProvider.notifier);
        notifier.applyElementSet(
          builtinWeatherSets.first.elements,
          isWeatherSetElement,
        );
        notifier.applyElementSet(
          builtinBatterySets.first.elements,
          isBatterySetElement,
        );
        final owns = weather ? isWeatherSetElement : isBatterySetElement;
        final before = container.read(elementProvider);
        final members = before.elements.where(owns).toList();
        final xs = members.map((element) => element.dx).toList()..sort();
        final ys = members.map((element) => element.dy).toList()..sort();
        final centerX = (xs.first + xs.last) / 2;
        final centerY = (ys.first + ys.last) / 2;
        notifier.snapshotForDrag();
        for (final scale in [1.5, 3.0, 2.0]) {
          notifier.scaleElementSet(
            owns,
            members.first.scale * scale,
            recordHistory: false,
          );
        }
        final after = container.read(elementProvider);
        expect(after.undoCount, before.undoCount + 1);
        for (var index = 0; index < before.elements.length; index++) {
          final original = before.elements[index];
          final resized = after.elements[index];
          if (!owns(original)) {
            expect(identical(resized, original), isTrue);
            continue;
          }
          expect(
            resized.dx,
            closeTo(centerX + (original.dx - centerX) * 2, 1e-9),
          );
          expect(
            resized.dy,
            closeTo(centerY + (original.dy - centerY) * 2, 1e-9),
          );
          expect(resized.scale, closeTo(original.scale * 2, 1e-9));
          expect(
            resized
                .copyWith(
                  dx: original.dx,
                  dy: original.dy,
                  scale: original.scale,
                )
                .toJson(),
            original.toJson(),
          );
        }
        notifier.undo();
        expect(container.read(elementProvider).elements, before.elements);
        notifier.redo();
        expect(container.read(elementProvider).elements, after.elements);
        notifier.scaleElementSet(owns, members.first.scale);
        final restored = container
            .read(elementProvider)
            .elements
            .where(owns)
            .toList();
        for (var index = 0; index < members.length; index++) {
          expect(restored[index].dx, closeTo(members[index].dx, 1e-9));
          expect(restored[index].dy, closeTo(members[index].dy, 1e-9));
          expect(restored[index].scale, closeTo(members[index].scale, 1e-9));
        }
      },
    );
  }
}
