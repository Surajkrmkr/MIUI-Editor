import 'package:flutter/material.dart';
import '../../core/extensions/alignment_ext.dart';

// ── Element type ──────────────────────────────────────────────────────────────

enum ElementType {
  containerBG1, containerBG2, containerBG3, containerBG4, containerBG5,
  pngBG1, pngBG2, pngBG3, pngBG4, pngBG5,
  videoWallpaper,
  hourClock, minClock, secClock, dotClock, dotClock2, amPmClock,
  weekClock, monthClock, dateClock, weatherIconClock,
  notification,
  dateTimeText1, dateTimeText2, dateTimeText3,
  normalText1, normalText2, normalText3, normalText4, normalText5,
  musicBg, musicNext, musicPrev, musicPlay, musicPause,
  cameraIcon, themeIcon, musicIcon, dialerIcon, mmsIcon,
  contactIcon, whatsAppIcon, telegramIcon, instagramIcon,
  spotifyIcon, settingIcon, galleryIcon,
  swipeUpUnlock, tapToUnlock, slideToUnlock,
  
  // Missing values identified
  weatherTemp, weatherDesc,
  analogClockBg, analogHourHand, analogMinHand, analogSecHand,
  calendarGrid, toggleSwitch, missedCalls, stepsCount,
  batteryLevel, progressBar
}

extension ElementTypeX on ElementType {
  bool get isContainer => name.startsWith('container');
  bool get isPng       => name.startsWith('png');
  bool get isVideo     => this == ElementType.videoWallpaper;
  bool get isIcon => const {
    ElementType.cameraIcon, ElementType.themeIcon, ElementType.musicIcon,
    ElementType.dialerIcon, ElementType.mmsIcon,   ElementType.contactIcon,
    ElementType.whatsAppIcon, ElementType.telegramIcon,
    ElementType.instagramIcon, ElementType.spotifyIcon,
    ElementType.settingIcon, ElementType.galleryIcon,
  }.contains(this);
  bool get isMusic => const {
    ElementType.musicBg, ElementType.musicNext, ElementType.musicPrev,
    ElementType.musicPlay, ElementType.musicPause,
  }.contains(this);
  bool get isDateTime => const {
    ElementType.dateTimeText1, ElementType.dateTimeText2, ElementType.dateTimeText3,
  }.contains(this);
  bool get isNormalText => const {
    ElementType.normalText1, ElementType.normalText2, ElementType.normalText3,
    ElementType.normalText4, ElementType.normalText5,
  }.contains(this);
  bool get isText => isDateTime || isNormalText || this == ElementType.notification || this == ElementType.weatherDesc;
  bool get isClock => const {
    ElementType.hourClock, ElementType.minClock, ElementType.secClock,
    ElementType.dotClock, ElementType.dotClock2,
    ElementType.amPmClock, ElementType.weekClock, ElementType.monthClock,
    ElementType.dateClock, ElementType.weatherIconClock,
    ElementType.analogClockBg, ElementType.analogHourHand, 
    ElementType.analogMinHand, ElementType.analogSecHand,
  }.contains(this);
  bool get isExportable => isClock || isContainer;
  bool get swipeUpUnlock => this == ElementType.swipeUpUnlock;

  String get defaultPath => const {
    ElementType.cameraIcon:    r'\icon\camera',
    ElementType.galleryIcon:   r'\icon\gallery',
    ElementType.settingIcon:   r'\icon\setting',
    ElementType.themeIcon:     r'\icon\theme',
    ElementType.musicIcon:     r'\icon\music',
    ElementType.dialerIcon:    r'\icon\dialer',
    ElementType.mmsIcon:       r'\icon\mms',
    ElementType.contactIcon:   r'\icon\contact',
    ElementType.whatsAppIcon:  r'\icon\whatsApp',
    ElementType.telegramIcon:  r'\icon\telegram',
    ElementType.instagramIcon: r'\icon\instagram',
    ElementType.spotifyIcon:   r'\icon\spotify',
    ElementType.musicBg:       r'\music\bg',
    ElementType.musicNext:     r'\music\next',
    ElementType.musicPrev:     r'\music\prev',
    ElementType.musicPlay:     r'\music\play',
    ElementType.musicPause:    r'\music\pause',
    ElementType.swipeUpUnlock: r'\unlock\unlock',
    ElementType.slideToUnlock: r'\unlock\slider',
    ElementType.tapToUnlock:   r'\unlock\tap',
  }[this] ?? '';
}

// ── Groups for UI panel ───────────────────────────────────────────────────────

const Map<String, List<ElementType>> kElementGroups = {
  'Clock':     [ElementType.hourClock, ElementType.minClock, ElementType.secClock,
                ElementType.dotClock,  ElementType.dotClock2, ElementType.amPmClock,
                ElementType.weekClock],
  'Date':      [ElementType.monthClock, ElementType.dateClock],
  'Weather':   [ElementType.weatherIconClock, ElementType.weatherTemp, ElementType.weatherDesc],
  'Notification': [ElementType.notification],
  'DateTime Text': [ElementType.dateTimeText1, ElementType.dateTimeText2,
                    ElementType.dateTimeText3],
  'Text':      [ElementType.normalText1, ElementType.normalText2,
                ElementType.normalText3, ElementType.normalText4,
                ElementType.normalText5],
  'Container': [ElementType.containerBG1, ElementType.containerBG2,
                ElementType.containerBG3, ElementType.containerBG4,
                ElementType.containerBG5],
  'PNG':       [ElementType.pngBG1, ElementType.pngBG2, ElementType.pngBG3,
                ElementType.pngBG4, ElementType.pngBG5],
  'Animation': [ElementType.videoWallpaper],
  'Music':     [ElementType.musicBg, ElementType.musicNext,
                ElementType.musicPrev, ElementType.musicPlay,
                ElementType.musicPause],
  'Icon':      [ElementType.cameraIcon, ElementType.themeIcon,
                ElementType.musicIcon,  ElementType.dialerIcon,
                ElementType.mmsIcon,    ElementType.contactIcon,
                ElementType.whatsAppIcon, ElementType.telegramIcon,
                ElementType.instagramIcon, ElementType.spotifyIcon,
                ElementType.settingIcon, ElementType.galleryIcon],
  'Other':     [ElementType.swipeUpUnlock, ElementType.tapToUnlock, ElementType.slideToUnlock],
};

// ── Gradient type ─────────────────────────────────────────────────────────────

enum GradientType { linear, radial, sweep }

// ── MamlEase enum ─────────────────────────────────────────────────────────────

enum MamlEase {
  linear,
  sineEaseIn, sineEaseOut, sineEaseInOut,
  quadEaseIn, quadEaseOut, quadEaseInOut,
  cubicEaseIn, cubicEaseOut, cubicEaseInOut,
  quartEaseIn, quartEaseOut, quartEaseInOut,
  quintEaseIn, quintEaseOut, quintEaseInOut,
  expoEaseIn, expoEaseOut, expoEaseInOut,
  circEaseIn, circEaseOut, circEaseInOut,
  backEaseIn, backEaseOut, backEaseInOut,
  elasticEaseIn, elasticEaseOut, elasticEaseInOut,
  bounceEaseIn, bounceEaseOut, bounceEaseInOut
}

// ── Pure-Dart entity ──────────────────────────────────────────────────────────

class LockElement {
  const LockElement({
    required this.type,
    this.dx = 0, this.dy = 0, this.scale = 1.0,
    this.height = 200, this.width = 200, this.radius = 10,
    this.borderWidth = 0,
    this.borderColor = const Color(0xFFFFFFFF),
    this.color = const Color(0xFFFFFFFF),
    this.colorSecondary = const Color(0xFFFFFFFF),
    this.gradientType = GradientType.linear,
    this.gradStartAlign = Alignment.centerLeft,
    this.gradEndAlign   = Alignment.centerRight,
    this.font = 'Roboto',
    this.align = Alignment.center,
    this.angle = 0,
    this.path  = '',
    this.text  = 'Text',
    this.fontSize   = 20,
    this.fontWeight = FontWeight.normal,
    this.isShort = false, this.isWrap = false, this.showGuideLines = false,
    this.isVisible = true, this.isLocked = false,
    this.blurRadius = 0,
    this.useSeparateColors = false,
    this.colorDigit1 = const Color(0xFFFFFFFF),
    this.colorDigit2 = const Color(0xFFFFFFFF),
  });

  final ElementType type;
  final double dx, dy, scale, height, width, radius, borderWidth, angle, fontSize, blurRadius;
  final Color borderColor, color, colorSecondary, colorDigit1, colorDigit2;
  final GradientType gradientType;
  final AlignmentGeometry gradStartAlign, gradEndAlign, align;
  final String font, path, text;
  final FontWeight fontWeight;
  final bool isShort, isWrap, showGuideLines, isVisible, isLocked, useSeparateColors;

  String get name => type.name;

  LockElement copyWith({
    double? dx, double? dy, double? scale, double? height, double? width,
    double? radius, double? borderWidth, double? angle, double? fontSize,
    Color? borderColor, Color? color, Color? colorSecondary,
    Color? colorDigit1, Color? colorDigit2,
    GradientType? gradientType,
    AlignmentGeometry? gradStartAlign, AlignmentGeometry? gradEndAlign,
    AlignmentGeometry? align,
    String? font, String? path, String? text,
    FontWeight? fontWeight,
    bool? isShort, bool? isWrap, bool? showGuideLines,
    bool? isVisible, bool? isLocked, bool? useSeparateColors,
    double? blurRadius,
  }) => LockElement(
    type: type,
    dx: dx ?? this.dx,   dy: dy ?? this.dy, scale: scale ?? this.scale,
    height: height ?? this.height, width: width ?? this.width,
    radius: radius ?? this.radius, borderWidth: borderWidth ?? this.borderWidth,
    angle: angle ?? this.angle, fontSize: fontSize ?? this.fontSize,
    borderColor: borderColor ?? this.borderColor,
    color: color ?? this.color, colorSecondary: colorSecondary ?? this.colorSecondary,
    colorDigit1: colorDigit1 ?? this.colorDigit1,
    colorDigit2: colorDigit2 ?? this.colorDigit2,
    gradientType: gradientType ?? this.gradientType,
    gradStartAlign: gradStartAlign ?? this.gradStartAlign,
    gradEndAlign:   gradEndAlign   ?? this.gradEndAlign,
    align: align ?? this.align,
    font: font ?? this.font, path: path ?? this.path, text: text ?? this.text,
    fontWeight: fontWeight ?? this.fontWeight,
    isShort: isShort ?? this.isShort, isWrap: isWrap ?? this.isWrap,
    showGuideLines: showGuideLines ?? this.showGuideLines,
    isVisible: isVisible ?? this.isVisible,
    isLocked: isLocked ?? this.isLocked,
    useSeparateColors: useSeparateColors ?? this.useSeparateColors,
    blurRadius: blurRadius ?? this.blurRadius,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'dx': dx, 'dy': dy, 'scale': scale,
    'height': height, 'width': width, 'radius': radius,
    'borderWidth': borderWidth, 'angle': angle, 'fontSize': fontSize,
    'borderColor': borderColor.toARGB32(),
    'color': color.toARGB32(), 'colorSecondary': colorSecondary.toARGB32(),
    'colorDigit1': colorDigit1.toARGB32(), 'colorDigit2': colorDigit2.toARGB32(),
    'gradientType': gradientType.name,
    'gradStartAlign': gradStartAlign.toString(),
    'gradEndAlign':   gradEndAlign.toString(),
    'align': align.toString(),
    'font': font, 'path': path, 'text': text,
    'fontWeight': fontWeight.toString(),
    'isShort': isShort, 'isWrap': isWrap, 'showGuideLines': showGuideLines,
    'isVisible': isVisible, 'isLocked': isLocked, 'useSeparateColors': useSeparateColors,
    'blurRadius': blurRadius,
  };

  factory LockElement.fromJson(Map<String, dynamic> j) => LockElement(
    type: ElementType.values.firstWhere(
        (e) => e.name == j['type'], orElse: () => ElementType.swipeUpUnlock),
    dx: (j['dx'] as num?)?.toDouble() ?? 0,
    dy: (j['dy'] as num?)?.toDouble() ?? 0,
    scale:  (j['scale']  as num?)?.toDouble() ?? 1,
    height: (j['height'] as num?)?.toDouble() ?? 200,
    width:  (j['width']  as num?)?.toDouble() ?? 200,
    radius: (j['radius'] as num?)?.toDouble() ?? 10,
    borderWidth: (j['borderWidth'] as num?)?.toDouble() ?? 0,
    angle:    (j['angle']    as num?)?.toDouble() ?? 0,
    fontSize: (j['fontSize'] as num?)?.toDouble() ?? 20,
    borderColor:    Color(j['borderColor']    as int? ?? 0xFFFFFFFF),
    color:          Color(j['color']          as int? ?? 0xFFFFFFFF),
    colorSecondary: Color(j['colorSecondary'] as int? ?? 0xFFFFFFFF),
    colorDigit1:    Color(j['colorDigit1']    as int? ?? 0xFFFFFFFF),
    colorDigit2:    Color(j['colorDigit2']    as int? ?? 0xFFFFFFFF),
    gradientType: GradientType.values.firstWhere(
        (e) => e.name == j['gradientType'], orElse: () => GradientType.linear),
    gradStartAlign: AlignmentX.fromString(j['gradStartAlign'] ?? ''),
    gradEndAlign:   AlignmentX.fromString(j['gradEndAlign']   ?? ''),
    align:          AlignmentX.fromString(j['align']          ?? ''),
    font: j['font'] as String? ?? 'Roboto',
    path: j['path'] as String? ?? '',
    text: j['text'] as String? ?? 'Text',
    fontWeight: _fw(j['fontWeight'] as String? ?? ''),
    isShort:       j['isShort']       as bool? ?? false,
    isWrap:        j['isWrap']        as bool? ?? false,
    showGuideLines:j['showGuideLines']as bool? ?? false,
    isVisible:     j['isVisible']     as bool? ?? true,
    isLocked:      j['isLocked']      as bool? ?? false,
    useSeparateColors: j['useSeparateColors'] as bool? ?? false,
    blurRadius:    (j['blurRadius']   as num?)?.toDouble() ?? 0,
  );

  static FontWeight _fw(String s) {
    const m = {
      'FontWeight.w100': FontWeight.w100, 'FontWeight.w200': FontWeight.w200,
      'FontWeight.w300': FontWeight.w300, 'FontWeight.w400': FontWeight.w400,
      'FontWeight.w500': FontWeight.w500, 'FontWeight.w600': FontWeight.w600,
      'FontWeight.w700': FontWeight.w700, 'FontWeight.w800': FontWeight.w800,
      'FontWeight.w900': FontWeight.w900,
    };
    return m[s] ?? FontWeight.normal;
  }
}
