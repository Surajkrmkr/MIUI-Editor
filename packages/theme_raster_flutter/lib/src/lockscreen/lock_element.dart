import 'package:flutter/material.dart';
import 'package:theme_core/theme_core.dart';
import 'alignment_ext.dart';

/// Material glyph for each unlock icon; the enum itself lives in theme_core.
extension UnlockIconX on UnlockIcon {
  IconData? get icon => switch (this) {
    UnlockIcon.lock => Icons.lock_rounded,
    UnlockIcon.lockOpen => Icons.lock_open_rounded,
    UnlockIcon.chevron => Icons.chevron_right_rounded,
    UnlockIcon.arrow => Icons.arrow_forward_rounded,
    UnlockIcon.power => Icons.power_settings_new_rounded,
    UnlockIcon.plug => Icons.power_rounded,
    UnlockIcon.fingerprint => Icons.fingerprint_rounded,
    UnlockIcon.play => Icons.play_arrow_rounded,
    UnlockIcon.automatic || UnlockIcon.none || UnlockIcon.customPng => null,
  };
}

class LockElement {
  const LockElement({
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
    this.unlockAccent = const Color(0xFFFFFFFF),
    this.unlockTargetPath = '',
    this.analogStyle = AnalogStyle.indigo,
    this.shortcutStyle = ShortcutStyle.glossDock,
    this.shortcutEdge = ShortcutEdge.right,
    this.calendarStyle = CalendarStyle.classic,
    this.shortcutApps = 'gallery,camera,music,browser,whatsapp,settings',
    this.shortcutThemeIcons = false,
    this.borderWidth = 0,
    this.borderColor = const Color(0xFFFFFFFF),
    this.color = const Color(0xFFFFFFFF),
    this.colorSecondary = const Color(0xFFFFFFFF),
    this.gradientType = GradientType.linear,
    this.gradStartAlign = Alignment.centerLeft,
    this.gradEndAlign = Alignment.centerRight,
    this.font = 'Roboto',
    this.align = Alignment.center,
    this.angle = 0,
    this.path = '',
    this.text = 'Text',
    this.fontSize = 20,
    this.fontWeight = FontWeight.normal,
    this.isShort = false,
    this.isWrap = false,
    this.showGuideLines = false,
    this.isVisible = true,
    this.isLocked = false,
    this.blurRadius = 0,
    this.useSeparateColors = false,
    this.colorDigit1 = const Color(0xFFFFFFFF),
    this.colorDigit2 = const Color(0xFFFFFFFF),
    this.strokeWidth = 0,
    this.strokeColor = const Color(0x00000000),
    this.strokeColorDigit1 = const Color(0x00000000),
    this.strokeColorDigit2 = const Color(0x00000000),
    this.isLiquidGlass = false,
    this.isFrostedGlass = false,
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

  final ElementType type;
  final String instanceId;
  final ArcProgressSource progressSource;
  ArcProgressSource get effectiveProgressSource =>
      progressSource == ArcProgressSource.none && batteryArc
      ? ArcProgressSource.battery
      : progressSource;
  final double shapeStrokeWidth,
      startAngle,
      sweepAngle,
      animationAmount,
      animationOffsetY;
  final bool batteryArc, animationLoop;
  final ElementAnimation animation;
  final int animationDuration;
  final int notificationLimit;
  final List<ElementAnimationTrack> animations;

  bool get isBold => fontWeight.value >= FontWeight.w600.value;
  Color get arcTrackColor => colorSecondary == color
      ? colorSecondary.withValues(alpha: colorSecondary.a * 0.25)
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

  final double dx,
      dy,
      scale,
      height,
      width,
      radius,
      borderWidth,
      angle,
      fontSize,
      blurRadius,
      strokeWidth;
  final Color borderColor,
      color,
      colorSecondary,
      colorDigit1,
      colorDigit2,
      strokeColor,
      strokeColorDigit1,
      strokeColorDigit2;
  final GradientType gradientType;
  final AlignmentGeometry gradStartAlign, gradEndAlign, align;
  final String font, path, text;
  final FontWeight fontWeight;
  final UnlockIcon unlockIcon;
  final String unlockIconPath;
  final String unlockText;
  final bool unlockInline;
  final int calendarRows;
  final bool calendarShowMonth, calendarShowWeekdays;
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

  final double unlockIconScale, unlockBackgroundOpacity, unlockThumbOpacity;
  final double? unlockCornerRadius;
  final UnlockSkin unlockSkin;
  final Color unlockAccent;
  final String unlockTargetPath;
  final AnalogStyle analogStyle;
  final ShortcutStyle shortcutStyle;
  final ShortcutEdge shortcutEdge;
  final CalendarStyle calendarStyle;

  /// Comma-separated shortcut app keys, in slot order.
  final String shortcutApps;

  /// Shortcut tiles show the theme's exported app icons instead of glyph art.
  final bool shortcutThemeIcons;
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
          .clamp(0, (width < unlockHeight ? width : unlockHeight) / 2);
  final bool isShort,
      isWrap,
      showGuideLines,
      isVisible,
      isLocked,
      useSeparateColors,
      isLiquidGlass,
      isFrostedGlass;

  /// See [LockElementSpec.perspectiveTilt].
  final double perspectiveTilt;

  /// Turn about the screen centre for [perspectiveTilt], or null when flat.
  Matrix4? get perspectiveMatrix => perspectiveTilt == 0
      ? null
      : (Matrix4.identity()
          ..setEntry(3, 2, .0025)
          ..rotateY(perspectiveTilt * 3.141592653589793 / 180));

  String get name =>
      instanceId.isEmpty ? type.name : '${type.name}_$instanceId';
  String get label =>
      instanceId.isEmpty ? type.label : '${type.label} $instanceId';

  LockElement copyWith({
    String? instanceId,
    ArcProgressSource? progressSource,
    double? dx,
    double? dy,
    double? scale,
    double? height,
    double? width,
    double? radius,
    UnlockIcon? unlockIcon,
    String? unlockIconPath,
    String? unlockText,
    bool? unlockInline,
    int? calendarRows,
    bool? calendarShowMonth,
    bool? calendarShowWeekdays,
    double? unlockIconScale,
    double? unlockCornerRadius,
    double? unlockBackgroundOpacity,
    double? unlockThumbOpacity,
    UnlockSkin? unlockSkin,
    Color? unlockAccent,
    String? unlockTargetPath,
    AnalogStyle? analogStyle,
    ShortcutStyle? shortcutStyle,
    ShortcutEdge? shortcutEdge,
    CalendarStyle? calendarStyle,
    String? shortcutApps,
    bool? shortcutThemeIcons,
    double? borderWidth,
    double? angle,
    double? fontSize,
    Color? borderColor,
    Color? color,
    Color? colorSecondary,
    Color? colorDigit1,
    Color? colorDigit2,
    Color? strokeColor,
    Color? strokeColorDigit1,
    Color? strokeColorDigit2,
    double? strokeWidth,
    GradientType? gradientType,
    AlignmentGeometry? gradStartAlign,
    AlignmentGeometry? gradEndAlign,
    AlignmentGeometry? align,
    String? font,
    String? path,
    String? text,
    FontWeight? fontWeight,
    bool? isShort,
    bool? isWrap,
    bool? showGuideLines,
    bool? isVisible,
    bool? isLocked,
    bool? useSeparateColors,
    double? blurRadius,
    bool? isLiquidGlass,
    bool? isFrostedGlass,
    double? perspectiveTilt,
    double? shapeStrokeWidth,
    double? startAngle,
    double? sweepAngle,
    bool? batteryArc,
    bool? animationLoop,
    ElementAnimation? animation,
    int? animationDuration,
    double? animationAmount,
    double? animationOffsetY,
    int? notificationLimit,
    List<ElementAnimationTrack>? animations,
  }) => LockElement(
    type: type,
    dx: dx ?? this.dx,
    instanceId: instanceId ?? this.instanceId,
    progressSource: progressSource ?? this.progressSource,
    dy: dy ?? this.dy,
    scale: scale ?? this.scale,
    height: height ?? this.height,
    width: width ?? this.width,
    radius: radius ?? this.radius,
    unlockIcon: unlockIcon ?? this.unlockIcon,
    unlockIconPath: unlockIconPath ?? this.unlockIconPath,
    unlockText: unlockText ?? this.unlockText,
    unlockInline: unlockInline ?? this.unlockInline,
    calendarRows: calendarRows ?? this.calendarRows,
    calendarShowMonth: calendarShowMonth ?? this.calendarShowMonth,
    calendarShowWeekdays: calendarShowWeekdays ?? this.calendarShowWeekdays,
    unlockIconScale: unlockIconScale ?? this.unlockIconScale,
    unlockCornerRadius: unlockCornerRadius ?? this.unlockCornerRadius,
    unlockBackgroundOpacity:
        unlockBackgroundOpacity ?? this.unlockBackgroundOpacity,
    unlockThumbOpacity: unlockThumbOpacity ?? this.unlockThumbOpacity,
    unlockSkin: unlockSkin ?? this.unlockSkin,
    unlockAccent: unlockAccent ?? this.unlockAccent,
    unlockTargetPath: unlockTargetPath ?? this.unlockTargetPath,
    analogStyle: analogStyle ?? this.analogStyle,
    shortcutStyle: shortcutStyle ?? this.shortcutStyle,
    shortcutEdge: shortcutEdge ?? this.shortcutEdge,
    calendarStyle: calendarStyle ?? this.calendarStyle,
    shortcutApps: shortcutApps ?? this.shortcutApps,
    shortcutThemeIcons: shortcutThemeIcons ?? this.shortcutThemeIcons,
    borderWidth: borderWidth ?? this.borderWidth,
    angle: angle ?? this.angle,
    fontSize: fontSize ?? this.fontSize,
    borderColor: borderColor ?? this.borderColor,
    color: color ?? this.color,
    colorSecondary: colorSecondary ?? this.colorSecondary,
    colorDigit1: colorDigit1 ?? this.colorDigit1,
    colorDigit2: colorDigit2 ?? this.colorDigit2,
    strokeColor: strokeColor ?? this.strokeColor,
    strokeColorDigit1: strokeColorDigit1 ?? this.strokeColorDigit1,
    strokeColorDigit2: strokeColorDigit2 ?? this.strokeColorDigit2,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    gradientType: gradientType ?? this.gradientType,
    gradStartAlign: gradStartAlign ?? this.gradStartAlign,
    gradEndAlign: gradEndAlign ?? this.gradEndAlign,
    align: align ?? this.align,
    font: font ?? this.font,
    path: path ?? this.path,
    text: text ?? this.text,
    fontWeight: fontWeight ?? this.fontWeight,
    isShort: isShort ?? this.isShort,
    isWrap: isWrap ?? this.isWrap,
    showGuideLines: showGuideLines ?? this.showGuideLines,
    isVisible: isVisible ?? this.isVisible,
    isLocked: isLocked ?? this.isLocked,
    useSeparateColors: useSeparateColors ?? this.useSeparateColors,
    blurRadius: blurRadius ?? this.blurRadius,
    isLiquidGlass: isLiquidGlass ?? this.isLiquidGlass,
    isFrostedGlass: isFrostedGlass ?? this.isFrostedGlass,
    perspectiveTilt: perspectiveTilt ?? this.perspectiveTilt,
    shapeStrokeWidth: shapeStrokeWidth ?? this.shapeStrokeWidth,
    startAngle: startAngle ?? this.startAngle,
    sweepAngle: sweepAngle ?? this.sweepAngle,
    batteryArc: batteryArc ?? this.batteryArc,
    animation: animation ?? this.animation,
    animationDuration: animationDuration ?? this.animationDuration,
    animationAmount: animationAmount ?? this.animationAmount,
    animationOffsetY: animationOffsetY ?? this.animationOffsetY,
    animationLoop: animationLoop ?? this.animationLoop,
    notificationLimit: notificationLimit ?? this.notificationLimit,
    animations: animations ?? this.animations,
  );

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
    'unlockAccent': unlockAccent.toARGB32(),
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
    'borderColor': borderColor.toARGB32(),
    'color': color.toARGB32(),
    'colorSecondary': colorSecondary.toARGB32(),
    'colorDigit1': colorDigit1.toARGB32(),
    'colorDigit2': colorDigit2.toARGB32(),
    'strokeColor': strokeColor.toARGB32(),
    'strokeColorDigit1': strokeColorDigit1.toARGB32(),
    'strokeColorDigit2': strokeColorDigit2.toARGB32(),
    'strokeWidth': strokeWidth,
    'gradientType': gradientType.name,
    'gradStartAlign': gradStartAlign.toString(),
    'gradEndAlign': gradEndAlign.toString(),
    'align': align.toString(),
    'font': font,
    'path': path,
    'text': text,
    'fontWeight': 'FontWeight.w${fontWeight.value}',
    'isShort': isShort,
    'isWrap': isWrap,
    'showGuideLines': showGuideLines,
    'isVisible': isVisible,
    'isLocked': isLocked,
    'useSeparateColors': useSeparateColors,
    'blurRadius': blurRadius,
    'isLiquidGlass': isLiquidGlass,
    'isFrostedGlass': isFrostedGlass,
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

  factory LockElement.fromJson(Map<String, dynamic> j) => LockElement(
    type: ElementType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => ElementType.swipeUpUnlock,
    ),
    instanceId: j['instanceId'] as String? ?? '',
    progressSource: ArcProgressSource.values.firstWhere(
      (source) => source.name == j['progressSource'],
      orElse: () => ArcProgressSource.none,
    ),
    dx: (j['dx'] as num?)?.toDouble() ?? 0,
    dy: (j['dy'] as num?)?.toDouble() ?? 0,
    scale: (j['scale'] as num?)?.toDouble() ?? 1,
    height: (j['height'] as num?)?.toDouble() ?? 200,
    width: (j['width'] as num?)?.toDouble() ?? 200,
    radius: (j['radius'] as num?)?.toDouble() ?? 10,
    unlockIcon: UnlockIcon.values.firstWhere(
      (icon) => icon.name == j['unlockIcon'],
      orElse: () => UnlockIcon.automatic,
    ),
    unlockIconPath: j['unlockIconPath'] as String? ?? '',
    unlockText: j['unlockText'] as String? ?? '',
    unlockInline: j['unlockInline'] as bool? ?? false,
    calendarRows: (j['calendarRows'] as num?)?.toInt() ?? 6,
    calendarShowMonth: j['calendarShowMonth'] as bool? ?? true,
    calendarShowWeekdays: j['calendarShowWeekdays'] as bool? ?? true,
    unlockIconScale: ((j['unlockIconScale'] as num?)?.toDouble() ?? .6).clamp(
      .2,
      1,
    ),
    unlockCornerRadius: (j['unlockCornerRadius'] as num?)?.toDouble(),
    unlockBackgroundOpacity:
        ((j['unlockBackgroundOpacity'] as num?)?.toDouble() ?? 48 / 255).clamp(
          0,
          1,
        ),
    unlockThumbOpacity:
        ((j['unlockThumbOpacity'] as num?)?.toDouble() ?? 96 / 255).clamp(0, 1),
    unlockSkin: UnlockSkin.values.firstWhere(
      (skin) => skin.name == j['unlockSkin'],
      orElse: () => UnlockSkin.classic,
    ),
    unlockAccent: Color(j['unlockAccent'] as int? ?? 0xFFFFFFFF),
    unlockTargetPath: j['unlockTargetPath'] as String? ?? '',
    analogStyle: AnalogStyle.values.firstWhere(
      (style) => style.name == j['analogStyle'],
      orElse: () => AnalogStyle.indigo,
    ),
    shortcutStyle: ShortcutStyle.values.firstWhere(
      (style) => style.name == j['shortcutStyle'],
      orElse: () => ShortcutStyle.glossDock,
    ),
    shortcutEdge: ShortcutEdge.values.firstWhere(
      (edge) => edge.name == j['shortcutEdge'],
      orElse: () => ShortcutEdge.right,
    ),
    calendarStyle: CalendarStyle.values.firstWhere(
      (style) => style.name == j['calendarStyle'],
      orElse: () => CalendarStyle.classic,
    ),
    shortcutApps:
        j['shortcutApps'] as String? ??
        'gallery,camera,music,browser,whatsapp,settings',
    shortcutThemeIcons: j['shortcutThemeIcons'] as bool? ?? false,
    borderWidth: (j['borderWidth'] as num?)?.toDouble() ?? 0,
    angle: (j['angle'] as num?)?.toDouble() ?? 0,
    fontSize: (j['fontSize'] as num?)?.toDouble() ?? 20,
    borderColor: Color(j['borderColor'] as int? ?? 0xFFFFFFFF),
    color: Color(j['color'] as int? ?? 0xFFFFFFFF),
    colorSecondary: Color(j['colorSecondary'] as int? ?? 0xFFFFFFFF),
    colorDigit1: Color(j['colorDigit1'] as int? ?? 0xFFFFFFFF),
    colorDigit2: Color(j['colorDigit2'] as int? ?? 0xFFFFFFFF),
    strokeColor: Color(j['strokeColor'] as int? ?? 0x00000000),
    strokeColorDigit1: Color(j['strokeColorDigit1'] as int? ?? 0x00000000),
    strokeColorDigit2: Color(j['strokeColorDigit2'] as int? ?? 0x00000000),
    strokeWidth: (j['strokeWidth'] as num?)?.toDouble() ?? 0,
    gradientType: GradientType.values.firstWhere(
      (e) => e.name == j['gradientType'],
      orElse: () => GradientType.linear,
    ),
    gradStartAlign: AlignmentX.fromString(j['gradStartAlign'] ?? ''),
    gradEndAlign: AlignmentX.fromString(j['gradEndAlign'] ?? ''),
    align: AlignmentX.fromString(j['align'] ?? ''),
    font: j['font'] as String? ?? 'Roboto',
    path: j['path'] as String? ?? '',
    text: j['text'] as String? ?? 'Text',
    fontWeight: _fw(j['fontWeight'] as String? ?? ''),
    isShort: j['isShort'] as bool? ?? false,
    isWrap: j['isWrap'] as bool? ?? false,
    showGuideLines: j['showGuideLines'] as bool? ?? false,
    isVisible: j['isVisible'] as bool? ?? true,
    isLocked: j['isLocked'] as bool? ?? false,
    useSeparateColors: j['useSeparateColors'] as bool? ?? false,
    blurRadius: (j['blurRadius'] as num?)?.toDouble() ?? 0,
    isLiquidGlass: j['isLiquidGlass'] as bool? ?? false,
    isFrostedGlass: j['isFrostedGlass'] as bool? ?? false,
    perspectiveTilt: ((j['perspectiveTilt'] as num?)?.toDouble() ?? 0).clamp(
      -60,
      60,
    ),
    shapeStrokeWidth: (j['shapeStrokeWidth'] as num?)?.toDouble() ?? 8,
    startAngle: (j['startAngle'] as num?)?.toDouble() ?? -90,
    sweepAngle: (j['sweepAngle'] as num?)?.toDouble() ?? 270,
    batteryArc: j['batteryArc'] as bool? ?? false,
    animation: ElementAnimation.values.firstWhere(
      (value) => value.name == j['animation'],
      orElse: () => ElementAnimation.none,
    ),
    animationDuration: ((j['animationDuration'] as num?)?.toInt() ?? 2000)
        .clamp(100, 60000),
    animationAmount: (j['animationAmount'] as num?)?.toDouble() ?? 60,
    animationOffsetY: (j['animationOffsetY'] as num?)?.toDouble() ?? 0,
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

  static FontWeight _fw(String s) {
    const m = {
      'FontWeight.w100': FontWeight.w100,
      'FontWeight.w200': FontWeight.w200,
      'FontWeight.w300': FontWeight.w300,
      'FontWeight.w400': FontWeight.w400,
      'FontWeight.w500': FontWeight.w500,
      'FontWeight.w600': FontWeight.w600,
      'FontWeight.w700': FontWeight.w700,
      'FontWeight.w800': FontWeight.w800,
      'FontWeight.w900': FontWeight.w900,
    };
    return m[s] ?? FontWeight.normal;
  }
}
