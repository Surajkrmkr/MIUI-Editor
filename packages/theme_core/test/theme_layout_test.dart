import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:theme_core/theme_core.dart';

void main() {
  test('ThemeLayout derives workspace paths from the root alone', () {
    final layout = ThemeLayout('out/Week1/Neon/');

    expect(layout.root, p.normalize('out/Week1/Neon'));
    expect(layout.parentDir, p.normalize('out/Week1'));
    expect(
      layout.descriptionXml,
      p.join('out', 'Week1', 'Neon', 'description.xml'),
    );
    expect(
      layout.iconsXxhdpi,
      p.join('out', 'Week1', 'Neon', 'icons', 'res', 'drawable-xxhdpi'),
    );
    expect(
      layout.moduleDrawables('com.android.mms'),
      p.join(
        'out',
        'Week1',
        'Neon',
        'com.android.mms',
        'res',
        'drawable-xxhdpi',
      ),
    );
    expect(layout.mtzFile('Neon'), p.join('out', 'Week1', 'Neon.mtz'));
  });

  test('trailing separator on the root does not change any path', () {
    expect(
      ThemeLayout('a/b/').lockscreenAdvance,
      ThemeLayout('a/b').lockscreenAdvance,
    );
  });
}
