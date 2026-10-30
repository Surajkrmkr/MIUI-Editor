import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/builtin_widget_styles.dart';
import 'package:miui_icon_generator/theme_editor/domain/entities/element_widget.dart';
import 'package:miui_icon_generator/theme_editor/presentation/features/lockscreen/widgets/analog_clock_art.dart';

const _styles = [
  AnalogStyle.bauhausPop,
  AnalogStyle.ripple,
  AnalogStyle.solarEclipse,
  AnalogStyle.memphis,
  AnalogStyle.prism,
  AnalogStyle.ribbon,
  AnalogStyle.terrazzo,
  AnalogStyle.contour,
  AnalogStyle.pixelSun,
  AnalogStyle.kineticTiles,
  AnalogStyle.fanFold,
  AnalogStyle.liquidLoops,
  AnalogStyle.checkerWave,
];

void main() {
  test(
    'abstract styles are selectable, serializable and export four parts',
    () {
      expect(builtinAnalogStyles.styles, hasLength(40));
      for (final style in _styles) {
        final preset = builtinAnalogStyles.styles.singleWhere(
          (s) => s.appearance['analogStyle'] == style.name,
        );
        final element = preset.applyTo(
          const LockElement(type: ElementType.analogClock, dx: 32, dy: -80),
        );
        expect(element.dx, 32);
        expect(element.dy, -80);
        expect(LockElement.fromJson(element.toJson()).analogStyle, style);
        expect(analogPartsOf(element), AnalogPart.values);
        expect(AnalogClockArt.suffix(element, AnalogPart.minute), '_minute');
      }
    },
  );

  testWidgets(
    'new faces and export hands render distinctly at thumbnail and full size',
    (tester) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFF30333B), BlendMode.src);
      final faceBytes = <String>{};
      for (var i = 0; i < _styles.length; i++) {
        final preset = builtinAnalogStyles.styles.singleWhere(
          (s) => s.appearance['analogStyle'] == _styles[i].name,
        );
        final element = preset.applyTo(
          const LockElement(type: ElementType.analogClock),
        );
        canvas.save();
        canvas.translate((i % 5) * 220.0, (i ~/ 5) * 220.0);
        for (final part in analogPartsOf(element)) {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(child: AnalogClockArt.part(element, part, 220)),
            ),
          );
          expect(tester.takeException(), isNull);
          final painter = tester
              .widget<CustomPaint>(find.byType(CustomPaint).last)
              .painter!;
          canvas.save();
          canvas.translate(110, 110);
          canvas.rotate(
            part.angleAt(DateTime(2026, 1, 1, 10, 10, 40)) *
                3.141592653589793 /
                180,
          );
          canvas.translate(-110, -110);
          painter.paint(canvas, const Size.square(220));
          canvas.restore();
          final partRecorder = ui.PictureRecorder();
          painter.paint(Canvas(partRecorder), const Size.square(64));
          final picture = partRecorder.endRecording();
          await tester.runAsync(() async {
            final image = await picture.toImage(64, 64);
            final bytes = await image.toByteData();
            expect(bytes!.buffer.asUint8List().any((b) => b > 0), isTrue);
            if (part == AnalogPart.dial) {
              faceBytes.add(bytes.buffer.asUint8List().toString());
            }
            image.dispose();
          });
          picture.dispose();
        }
        canvas.restore();
      }
      expect(faceBytes, hasLength(_styles.length));
      final picture = recorder.endRecording();
      if (Platform.environment['ANALOG_PREVIEW_PATH'] case final String path) {
        await tester.runAsync(() async {
          final image = await picture.toImage(
            1100,
            ((_styles.length + 4) ~/ 5) * 220,
          );
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      picture.dispose();
    },
  );
}
