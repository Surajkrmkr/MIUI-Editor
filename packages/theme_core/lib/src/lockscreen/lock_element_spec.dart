import '../values/alignment2.dart';
import '../values/rgba.dart';
import 'analog.dart';
import 'element_enums.dart';

/// Reference screen height/width the editor lays elements out against.
const double lockscreenScreenRatio = 2340 / 600;

/// Editor canvas size in logical pixels.
const double lockscreenViewWidth = 276.92;
const double lockscreenViewHeight = 600.0;

/// Canvas pixels a tap-to-unlock control must keep above the bottom edge, so
/// it clears the gesture bar (about 156px on a 2340px screen).
const double minUnlockBottomPadding = 40;

/// Canvas pixels content must keep below the top edge, so it clears the
/// status bar and camera cutout (about 156px on a 2340px screen).
const double minTopPadding = 40;

/// Canvas pixels content must keep above the bottom edge.
const double minBottomPadding = 40;

/// Estimated height of [el] in canvas pixels. Texts and digital clocks have
/// no stored height, so it is derived from their font size or scale.
double visualHeightOf(LockElementSpec el) {
  final t = el.type;
  if (t.isAnalog) return el.width * el.scale / lockscreenScreenRatio;
  if (t.isText) return el.fontSize * 1.2;
  if (t.isClock && t != ElementType.weatherIconClock) return 17 * el.scale;
  return el.height * el.scale / lockscreenScreenRatio;
}

/// Canvas pixels between the top of [el] and the top of the screen.
double topPaddingOf(LockElementSpec el) =>
    lockscreenViewHeight / 2 + el.dy - visualHeightOf(el) / 2;

/// Canvas pixels between the bottom of [el] and the bottom of the screen.
double bottomPaddingOf(LockElementSpec el) =>
    lockscreenViewHeight / 2 - (el.dy + visualHeightOf(el) / 2);

/// One lockscreen element as stored in presets and theme specs.
///
/// Pure-data twin of the app's `LockElement`: same fields, same defaults and
/// the same JSON, with colors as [Rgba], alignments as [Alignment2] and font
/// weight as a CSS-style number (100–900).
class LockElementSpec {
  const LockElementSpec({
    required this.type,
    this.instanceId = '',
    this.progressSource = ArcProgressSource.none,
    this.dx = 0,
    this.dy = 0,
    this.scale = 1.0,
    this.height = 200,
    this.width = 200,
    this.radius = 10,
    this.unlockIcon = UnlockIcon.automatic,
    this.unlockIconPath = '',
    this.unlockText = '',
    this.unlockInline = false,
    this.calendarRows = 6,
    this.calendarShowMonth = true,
    this.calendarShowWeekdays = true,
    this.unlockIconScale = .6,
    this.unlockCornerRadius,
    this.unlockBackgroundOpacity = 48 / 255,
    this.unlockThumbOpacity = 96 / 255,
    this.unlockSkin = UnlockSkin.classic,
    this.unlockAccent = _white,
    this.unlockTargetPath = '',
    this.analogStyle = AnalogStyle.indigo,
    this.shortcutStyle = ShortcutStyle.glossDock,
    this.shortcutEdge = ShortcutEdge.right,
    this.calendarStyle = CalendarStyle.classic,
    this.shortcutApps = 'gallery,camera,music,browser,whatsapp,settings',
    this.shortcutThemeIcons = false,
    this.borderWidth = 0,
    this.borderColor = _white,
    this.color = _white,
    this.colorSecondary = _white,
    this.gradientType = GradientType.linear,
    this.gradStartAlign = Alignment2.centerLeft,
    this.gradEndAlign = Alignment2.centerRight,
    this.font = 'Roboto',
    this.align = Alignment2.center,
    this.angle = 0,
    this.path = '',
    this.text = 'Text',
    this.fontSize = 20,
    this.fontWeight = 400,
    this.isShort = false,
    this.isWrap = false,
    this.showGuideLines = false,
    this.isVisible = true,
    this.isLocked = false,
    this.blurRadius = 0,
    this.useSeparateColors = false,
    this.colorDigit1 = _white,
    this.colorDigit2 = _white,
    this.strokeWidth = 0,
    this.strokeColor = _clear,
    this.strokeColorDigit1 = _clear,
    this.strokeColorDigit2 = _clear,
    this.isLiquidGlass = false,
    this.isFrostedGlass = false,
    this.surfaceTexture = 'none',
    this.textureScale = 1.0,
    this.textureOpacity = 0.3,
    this.perspectiveTilt = 0,
    this.shapeStrokeWidth = 8,
    this.startAngle = -90,
    this.sweepAngle = 270,
    this.batteryArc = false,
    this.animation = ElementAnimation.none,
    this.animationDuration = 2000,
    this.animationAmount = 60,
    this.animationOffsetY = 0,
    this.animationLoop = true,
    this.notificationLimit = 3,
    this.animations = const [],
  });

  static const _white = Rgba(0xFFFFFFFF);
  static const _clear = Rgba(0x00000000);

  final ElementType type;
  final String instanceId;
  final ArcProgressSource progressSource;
  final double dx, dy, scale, height, width, radius;
  final UnlockIcon unlockIcon;
  final String unlockIconPath, unlockText, unlockTargetPath;
  final bool unlockInline;
  final int calendarRows;
  final bool calendarShowMonth, calendarShowWeekdays;
  final double unlockIconScale, unlockBackgroundOpacity, unlockThumbOpacity;
  final double? unlockCornerRadius;
  final UnlockSkin unlockSkin;
  final Rgba unlockAccent;
  final AnalogStyle analogStyle;
  final ShortcutStyle shortcutStyle;
  final ShortcutEdge shortcutEdge;
  final CalendarStyle calendarStyle;

  /// Comma-separated shortcut app keys, in slot order.
  final String shortcutApps;

  /// Shortcut tiles show the theme's exported app icons instead of glyph art.
  final bool shortcutThemeIcons;
  final double borderWidth, angle, fontSize, blurRadius, strokeWidth;
  final Rgba borderColor,
      color,
      colorSecondary,
      colorDigit1,
      colorDigit2,
      strokeColor,
      strokeColorDigit1,
      strokeColorDigit2;
  final GradientType gradientType;
  final Alignment2 gradStartAlign, gradEndAlign, align;
  final String font, path, text;

  /// 100–900, where 400 is normal and 700 bold.
  final int fontWeight;
  final bool isShort,
      isWrap,
      showGuideLines,
      isVisible,
      isLocked,
      useSeparateColors,
      isLiquidGlass,
      isFrostedGlass;

  /// [IconTexture] name, baked into clock and container PNGs.
  final String surfaceTexture;
  final double textureScale, textureOpacity;

  /// Degrees the clock text turns about the screen's vertical centre line,
  /// so the digits grow linearly across the screen; baked into the PNGs.
  final double perspectiveTilt;
  final double shapeStrokeWidth, startAngle, sweepAngle;
  final bool batteryArc;
  final ElementAnimation animation;
  final int animationDuration;
  final double animationAmount, animationOffsetY;
  final bool animationLoop;
  final int notificationLimit;
  final List<ElementAnimationTrack> animations;

  ArcProgressSource get effectiveProgressSource =>
      progressSource == ArcProgressSource.none && batteryArc
      ? ArcProgressSource.battery
      : progressSource;

  bool get isBold => fontWeight >= 600;

  Rgba get arcTrackColor => colorSecondary == color
      ? colorSecondary.withAlpha((colorSecondary.a * 0.25).round())
      : colorSecondary;

  List<ElementAnimationTrack> get activeAnimations {
    final tracks = animations.isNotEmpty
        ? animations
        : [
            if (animation != ElementAnimation.none)
              ElementAnimationTrack(
                type: animation,
                duration: animationDuration,
                amount: animationAmount,
                offsetY: animationOffsetY,
                loop: animationLoop,
              ),
          ];
    final unique = <ElementAnimation, ElementAnimationTrack>{};
    for (final track in tracks) {
      if (track.type != ElementAnimation.none) unique[track.type] = track;
    }
    return unique.values.toList(growable: false);
  }

  int get calendarWeekRows =>
      calendarRows == 1 || calendarRows == 2 ? calendarRows : 6;

  int get calendarDisplayRows =>
      calendarWeekRows +
      (calendarShowMonth ? 1 : 0) +
      (calendarShowWeekdays ? 1 : 0);

  List<DateTime?> calendarDates(DateTime now) {
    final fullMonth = calendarWeekRows == 6;
    final firstDay = fullMonth
        ? 1 - DateTime(now.year, now.month).weekday % 7
        : now.day - now.weekday % 7;
    return List.generate(calendarWeekRows * 7, (index) {
      final date = DateTime(now.year, now.month, firstDay + index);
      return fullMonth && date.month != now.month ? null : date;
    });
  }

  double get unlockTextFontSize {
    final limit =
        unlockHeight /
        lockscreenScreenRatio *
        (type == ElementType.slideToUnlock || unlockInline ? .5 : .22);
    return fontSize < limit ? fontSize : limit;
  }

  UnlockIcon get effectiveUnlockIcon => unlockIcon == UnlockIcon.automatic
      ? (type == ElementType.dragToUnlock
            ? UnlockIcon.plug
            : type == ElementType.slideToUnlock
            ? UnlockIcon.chevron
            : UnlockIcon.lock)
      : unlockIcon;

  double get unlockHeight =>
      type.isUnlockControl &&
          type != ElementType.tapToUnlock &&
          height > width / 3
      ? width / 3
      : height;

  double get effectiveUnlockCornerRadius =>
      (unlockCornerRadius ??
              (type.isUnlockControl && type != ElementType.tapToUnlock
                  ? unlockHeight / 2
                  : radius * lockscreenScreenRatio))
          .clamp(0, (width < unlockHeight ? width : unlockHeight) / 2)
          .toDouble();

  String get name =>
      instanceId.isEmpty ? type.name : '${type.name}_$instanceId';

  String get label =>
      instanceId.isEmpty ? type.label : '${type.label} $instanceId';

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'dx': dx,
    'dy': dy,
    'scale': scale,
    'height': height,
    'width': width,
    'instanceId': instanceId,
    'progressSource': progressSource.name,
    'radius': radius,
    'unlockIcon': unlockIcon.name,
    'unlockIconPath': unlockIconPath,
    'unlockText': unlockText,
    'unlockInline': unlockInline,
    'calendarRows': calendarRows,
    'calendarShowMonth': calendarShowMonth,
    'calendarShowWeekdays': calendarShowWeekdays,
    'unlockIconScale': unlockIconScale,
    'unlockCornerRadius': unlockCornerRadius,
    'unlockBackgroundOpacity': unlockBackgroundOpacity,
    'unlockThumbOpacity': unlockThumbOpacity,
    'unlockSkin': unlockSkin.name,
    'unlockAccent': unlockAccent.argb,
    'unlockTargetPath': unlockTargetPath,
    'analogStyle': analogStyle.name,
    'shortcutStyle': shortcutStyle.name,
    'shortcutEdge': shortcutEdge.name,
    'calendarStyle': calendarStyle.name,
    'shortcutApps': shortcutApps,
    'shortcutThemeIcons': shortcutThemeIcons,
    'borderWidth': borderWidth,
    'angle': angle,
    'fontSize': fontSize,
    'borderColor': borderColor.argb,
    'color': color.argb,
    'colorSecondary': colorSecondary.argb,
    'colorDigit1': colorDigit1.argb,
    'colorDigit2': colorDigit2.argb,
    'strokeColor': strokeColor.argb,
    'strokeColorDigit1': strokeColorDigit1.argb,
    'strokeColorDigit2': strokeColorDigit2.argb,
    'strokeWidth': strokeWidth,
    'gradientType': gradientType.name,
    'gradStartAlign': gradStartAlign.toLegacyString(),
    'gradEndAlign': gradEndAlign.toLegacyString(),
    'align': align.toLegacyString(),
    'font': font,
    'path': path,
    'text': text,
    'fontWeight': 'FontWeight.w$fontWeight',
    'isShort': isShort,
    'isWrap': isWrap,
    'showGuideLines': showGuideLines,
    'isVisible': isVisible,
    'isLocked': isLocked,
    'useSeparateColors': useSeparateColors,
    'blurRadius': blurRadius,
    'isLiquidGlass': isLiquidGlass,
    'isFrostedGlass': isFrostedGlass,
    'surfaceTexture': surfaceTexture,
    'textureScale': textureScale,
    'textureOpacity': textureOpacity,
    'perspectiveTilt': perspectiveTilt,
    'shapeStrokeWidth': shapeStrokeWidth,
    'startAngle': startAngle,
    'sweepAngle': sweepAngle,
    'batteryArc': batteryArc,
    'animation': animation.name,
    'animationDuration': animationDuration,
    'animationAmount': animationAmount,
    'animationOffsetY': animationOffsetY,
    'animationLoop': animationLoop,
    'notificationLimit': notificationLimit,
    'animations': animations.map((track) => track.toJson()).toList(),
  };

  /// Unknown or missing keys fall back to the same defaults as the app. Colors
  /// also accept `#RRGGBB` / `#AARRGGBB` strings and alignments `[x, y]`.
  factory LockElementSpec.fromJson(Map<String, dynamic> j) {
    T pick<T extends Enum>(List<T> values, String key, T fallback) =>
        values.firstWhere((v) => v.name == j[key], orElse: () => fallback);
    double dbl(String key, double fallback) =>
        (j[key] as num?)?.toDouble() ?? fallback;
    Rgba rgba(String key, Rgba fallback) => Rgba.tryParse(j[key]) ?? fallback;
    Alignment2 align_(String key) =>
        Alignment2.tryParse(j[key]) ?? Alignment2.center;

    return LockElementSpec(
      type: pick(ElementType.values, 'type', ElementType.swipeUpUnlock),
      instanceId: j['instanceId'] as String? ?? '',
      progressSource: pick(
        ArcProgressSource.values,
        'progressSource',
        ArcProgressSource.none,
      ),
      dx: dbl('dx', 0),
      dy: dbl('dy', 0),
      scale: dbl('scale', 1),
      height: dbl('height', 200),
      width: dbl('width', 200),
      radius: dbl('radius', 10),
      unlockIcon: pick(UnlockIcon.values, 'unlockIcon', UnlockIcon.automatic),
      unlockIconPath: j['unlockIconPath'] as String? ?? '',
      unlockText: j['unlockText'] as String? ?? '',
      unlockInline: j['unlockInline'] as bool? ?? false,
      calendarRows: (j['calendarRows'] as num?)?.toInt() ?? 6,
      calendarShowMonth: j['calendarShowMonth'] as bool? ?? true,
      calendarShowWeekdays: j['calendarShowWeekdays'] as bool? ?? true,
      unlockIconScale: dbl('unlockIconScale', .6).clamp(.2, 1).toDouble(),
      unlockCornerRadius: (j['unlockCornerRadius'] as num?)?.toDouble(),
      unlockBackgroundOpacity: dbl(
        'unlockBackgroundOpacity',
        48 / 255,
      ).clamp(0, 1).toDouble(),
      unlockThumbOpacity: dbl(
        'unlockThumbOpacity',
        96 / 255,
      ).clamp(0, 1).toDouble(),
      unlockSkin: pick(UnlockSkin.values, 'unlockSkin', UnlockSkin.classic),
      unlockAccent: rgba('unlockAccent', _white),
      unlockTargetPath: j['unlockTargetPath'] as String? ?? '',
      analogStyle: pick(AnalogStyle.values, 'analogStyle', AnalogStyle.indigo),
      shortcutStyle: pick(
        ShortcutStyle.values,
        'shortcutStyle',
        ShortcutStyle.glossDock,
      ),
      shortcutEdge: pick(
        ShortcutEdge.values,
        'shortcutEdge',
        ShortcutEdge.right,
      ),
      calendarStyle: pick(
        CalendarStyle.values,
        'calendarStyle',
        CalendarStyle.classic,
      ),
      shortcutApps:
          j['shortcutApps'] as String? ??
          'gallery,camera,music,browser,whatsapp,settings',
      shortcutThemeIcons: j['shortcutThemeIcons'] as bool? ?? false,
      borderWidth: dbl('borderWidth', 0),
      angle: dbl('angle', 0),
      fontSize: dbl('fontSize', 20),
      borderColor: rgba('borderColor', _white),
      color: rgba('color', _white),
      colorSecondary: rgba('colorSecondary', _white),
      colorDigit1: rgba('colorDigit1', _white),
      colorDigit2: rgba('colorDigit2', _white),
      strokeColor: rgba('strokeColor', _clear),
      strokeColorDigit1: rgba('strokeColorDigit1', _clear),
      strokeColorDigit2: rgba('strokeColorDigit2', _clear),
      strokeWidth: dbl('strokeWidth', 0),
      gradientType: pick(
        GradientType.values,
        'gradientType',
        GradientType.linear,
      ),
      gradStartAlign: align_('gradStartAlign'),
      gradEndAlign: align_('gradEndAlign'),
      align: align_('align'),
      font: j['font'] as String? ?? 'Roboto',
      path: j['path'] as String? ?? '',
      text: j['text'] as String? ?? 'Text',
      fontWeight: _parseWeight(j['fontWeight']),
      isShort: j['isShort'] as bool? ?? false,
      isWrap: j['isWrap'] as bool? ?? false,
      showGuideLines: j['showGuideLines'] as bool? ?? false,
      isVisible: j['isVisible'] as bool? ?? true,
      isLocked: j['isLocked'] as bool? ?? false,
      useSeparateColors: j['useSeparateColors'] as bool? ?? false,
      blurRadius: dbl('blurRadius', 0),
      isLiquidGlass: j['isLiquidGlass'] as bool? ?? false,
      isFrostedGlass: j['isFrostedGlass'] as bool? ?? false,
      surfaceTexture: j['surfaceTexture'] as String? ?? 'none',
      textureScale: dbl('textureScale', 1),
      textureOpacity: dbl('textureOpacity', 0.3),
      perspectiveTilt: dbl('perspectiveTilt', 0).clamp(-60, 60).toDouble(),
      shapeStrokeWidth: dbl('shapeStrokeWidth', 8),
      startAngle: dbl('startAngle', -90),
      sweepAngle: dbl('sweepAngle', 270),
      batteryArc: j['batteryArc'] as bool? ?? false,
      animation: pick(
        ElementAnimation.values,
        'animation',
        ElementAnimation.none,
      ),
      animationDuration: ((j['animationDuration'] as num?)?.toInt() ?? 2000)
          .clamp(100, 60000),
      animationAmount: dbl('animationAmount', 60),
      animationOffsetY: dbl('animationOffsetY', 0),
      animationLoop: j['animationLoop'] as bool? ?? true,
      notificationLimit: ((j['notificationLimit'] as num?)?.toInt() ?? 3).clamp(
        1,
        10,
      ),
      animations:
          (j['animations'] as List?)
              ?.map(
                (track) => ElementAnimationTrack.fromJson(
                  Map<String, dynamic>.from(track as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  /// `FontWeight.w700`-style strings (as stored today) or a plain 100–900.
  static int _parseWeight(Object? v) {
    final n = switch (v) {
      final int i => i,
      final String s when s.startsWith('FontWeight.w') => int.tryParse(
        s.substring('FontWeight.w'.length),
      ),
      _ => null,
    };
    return n != null && n >= 100 && n <= 900 && n % 100 == 0 ? n : 400;
  }
}
