import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/buffy_walls/presentation/widgets/buffy_wallpaper_form.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final height in [600.0, 720.0, 1000.0]) {
      testWidgets('wallpaper form fits $height height in $brightness', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(1040, height);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                brightness: brightness,
                extensions: [
                  brightness == Brightness.dark
                      ? AppColorScheme.dark
                      : AppColorScheme.light,
                ],
              ),
              home: const Scaffold(body: BuffyWallpaperForm()),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Save Wallpaper').hitTestable(), findsOneWidget);
        expect(find.text('Cancel').hitTestable(), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Designer'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Designer').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}