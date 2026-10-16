import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/directory_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/preset_favorites_provider.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/service_providers.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/preset_dialog.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/preset/preset_card.dart';

class _PresetDirectory extends DirectoryNotifier {
  @override
  DirectoryState build() => const DirectoryState(
    presetPaths: ['/presets/one', '/presets/two', '/presets/three'],
  );
  @override
  Future<void> loadPresetPaths() async {}
}

void main() {
  testWidgets(
    'card stars do not apply presets and filter updates immediately when unfavorited',
    (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            sharedPrefsProvider.overrideWithValue(preferences),
            directoryProvider.overrideWith(_PresetDirectory.new),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: Scaffold(body: PresetDialog())),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final first = find.byKey(const ValueKey('/presets/one'));
        await tester.tap(
          find.descendant(
            of: first,
            matching: find.byTooltip('Add to favorites'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(PresetDialog), findsOneWidget);
        expect(
          find.descendant(
            of: first,
            matching: find.byTooltip('Remove from favorites'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Show favorites only'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(PresetCard), findsOneWidget);
        await tester.tap(find.byTooltip('Remove from favorites'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('No favorite presets yet'), findsOneWidget);
        await tester.tap(find.text('Show all presets'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(PresetCard), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      });
    },
  );

  test(
    'favorites persist, filter in existing order, follow renames and can be removed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final overrides = [
        sharedPrefsProvider.overrideWithValue(preferences),
        directoryProvider.overrideWith(_PresetDirectory.new),
      ];
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      final notifier = container.read(presetFavoritesProvider.notifier);
      expect(container.read(visiblePresetPathsProvider).length, 3);
      await notifier.toggle('/presets/three/');
      await notifier.toggle('/presets/one');
      container.read(favoritePresetsOnlyProvider.notifier).state = true;
      expect(container.read(visiblePresetPathsProvider), [
        '/presets/one',
        '/presets/three',
      ]);
      final reopened = ProviderContainer(overrides: overrides);
      addTearDown(reopened.dispose);
      expect(reopened.read(presetFavoritesProvider), {
        '/presets/one',
        '/presets/three',
      });
      await notifier.rename('/presets/one', '/presets/renamed');
      expect(container.read(presetFavoritesProvider), {
        '/presets/renamed',
        '/presets/three',
      });
      await notifier.remove('/presets/renamed');
      await notifier.toggle('/presets/three');
      expect(container.read(visiblePresetPathsProvider), isEmpty);
      container.read(favoritePresetsOnlyProvider.notifier).state = false;
      expect(container.read(visiblePresetPathsProvider).length, 3);
    },
  );
}
