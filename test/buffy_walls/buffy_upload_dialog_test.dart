import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/buffy_walls/presentation/widgets/buffy_upload_dialog.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/theme_editor/presentation/providers/service_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Brightness brightness, double height) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(1100, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: ThemeData(
          brightness: brightness,
          extensions: [
            brightness == Brightness.dark
                ? AppColorScheme.dark
                : AppColorScheme.light,
          ],
        ),
        home: const Scaffold(body: BuffyUploadDialog()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final brightness in Brightness.values) {
    for (final height in [600.0, 900.0]) {
      testWidgets('upload dialog fits $height height in $brightness', (
        tester,
      ) async {
        await _pump(tester, brightness, height);
        expect(tester.takeException(), isNull);
        expect(find.text('Add Buffy wallpapers'), findsOneWidget);
        expect(find.text('Drop wallpapers here'), findsOneWidget);
        expect(find.text('Add files').hitTestable(), findsOneWidget);
        expect(find.text('Fill from JSON').hitTestable(), findsOneWidget);
        // Nothing to add until files are picked.
        final add = tester.widget<FilledButton>(
          find.ancestor(of: find.text('Add'), matching: find.byType(FilledButton)),
        );
        expect(add.onPressed, isNull);
      });
    }
  }

  testWidgets('Fill from JSON starts from a Buffy sample', (tester) async {
    await _pump(tester, Brightness.dark, 900);
    await tester.tap(find.text('Fill from JSON'));
    await tester.pumpAndSettle();
    // Wall Rio's JSON dialog: its button row only overflows with the square
    // test font, not in the app.
    tester.takeException();
    expect(find.text('Fill details from JSON'), findsOneWidget);
    final editor = tester.widget<TextField>(find.byType(TextField).last);
    expect(editor.controller!.text, contains('"author": "Buffy"'));
    expect(editor.controller!.text, isNot(contains('WallRio')));

    // Applying it closes the editor and reports what matched.
    // Called directly: the square test font makes the button row wider than
    // the dialog, which would put Apply outside it.
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply'))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Fill details from JSON'), findsNothing);
    expect(find.textContaining('JSON details: 0 of 0'), findsOneWidget);
    expect(find.text('Edit JSON'), findsOneWidget);
  });
}
