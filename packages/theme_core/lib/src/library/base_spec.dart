import '../lockscreen/design_profile.dart';
import '../spec/theme_spec.dart';

/// Where things go on a lockscreen and in which units; the layout in
/// [baseSpec] follows it.
const baseLayoutGuide = '''
The lockscreen canvas is 277 wide and 600 tall. 1 unit is 3.9 px of the 1080x2340 screen. The origin is the middle; x grows to the right and y downwards. Visible range: dx -138 to 138, dy -300 to 300. An element's dx and dy move its middle from its align point (the middle of the screen unless align is set).
Units differ by field. In canvas units: dx, dy, fontSize, and for containerBG elements width, height and radius. In screen pixels (units x 3.9): width and height of unlock controls, icons, images, shapes and calendarGrid. If something looks 4 times too big or small, this is why.
Zones from the top: clock -200 to -130, date or weekday about -104, one main card -40 to 56, free space 70 to 200 for a second widget, unlock control at 250. Keep 12 units of margin from the left and right edges.
A containerBG needs color and colorSecondary with alpha (for example #33FFFFFF and #11FFFFFF); the default colorSecondary is opaque white and turns a translucent card white.
Text on a card has its own dx and dy, so when you move a card, move the text on it by the same amount.
''';

/// The starting point for a new theme: a lockscreen whose pieces are placed
/// and sized so that nothing overlaps or leaves the screen. Change the look
/// (colors, fonts, styles) and add widgets from there.
Map<String, Object?> baseSpec({
  required String title,
  String? wallpaper,
  String? week,
  String? folder,
}) => {
  'specVersion': 1,
  'meta': {
    'title': title,
    'designer': 'MIUI Editor',
    'authorTag': 'MIUIEditor',
    'version': '1.0',
    'uiVersion': 17,
  },
  if (week != null || folder != null)
    'workspace': {'week': ?week, 'folder': ?folder},
  'wallpaper': {'home': wallpaper ?? 'WALLPAPER.jpg'},
  'icons': {'pack': 'u7'},
  'lockscreen': {'bgAlpha': 0.25, 'elements': baseElements()},
};

/// The base lockscreen: a thin clock, the weekday, a glass weather card and a
/// slide-to-unlock control.
List<Map<String, Object?>> baseElements() => [
  {
    'type': 'hourClock',
    'dx': -40,
    'dy': -170,
    'fontSize': 140,
    'fontWeight': 300,
  },
  {
    'type': 'minClock',
    'dx': 40,
    'dy': -170,
    'fontSize': 140,
    'fontWeight': 300,
  },
  {'type': 'weekClock', 'dy': -104, 'fontSize': 16, 'fontWeight': 400},
  {
    'type': 'containerBG1',
    'dy': 8,
    'width': 232,
    'height': 96,
    'radius': 24,
    'color': '#33FFFFFF',
    'colorSecondary': '#11FFFFFF',
    'borderWidth': 1,
    'borderColor': '#44FFFFFF',
    'blurRadius': 15,
  },
  {
    'type': 'weatherTemp',
    'dx': -58,
    'dy': 6,
    'fontSize': 38,
    'fontWeight': 300,
  },
  {'type': 'weatherCity', 'dx': 50, 'dy': -8, 'fontSize': 18},
  {'type': 'weatherDesc', 'dx': 50, 'dy': 12, 'fontSize': 14},
  {'type': 'slideToUnlock', 'dy': 250, 'width': 780, 'height': 140},
  {'type': 'swipeUpUnlock', 'dy': 250},
];

/// The starter lockscreen as a design, to tell when a theme never left it.
final baseDesign = DesignProfile(
  ThemeSpec.parse(baseSpec(title: 'Base')).spec!.lockscreen.elements,
);
