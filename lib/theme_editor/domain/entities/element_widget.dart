import 'package:flutter/material.dart';
import '../../core/extensions/alignment_ext.dart';

// ── Element type ──────────────────────────────────────────────────────────────

enum ElementType {
  containerBG1, containerBG2, containerBG3, containerBG4, containerBG5,
  pngBG1, pngBG2, pngBG3, pngBG4, pngBG5,
  videoWallpaper,
  hourClock, minClock, dotClock, amPmClock,
  weekClock, monthClock, dateClock, weatherIconClock,
  notification,
  dateTimeText1, dateTimeText2, dateTimeText3,
  normalText1, normalText2, normalText3, normalText4, normalText5,
  musicBg, musicNext, musicPrev, musicPlay, musicPause,
  cameraIcon, themeIcon, musicIcon, dialerIcon, mmsIcon,
  contactIcon, whatsAppIcon, telegramIcon, instagramIcon,
  spotifyIcon, settingIcon, galleryIcon,
  swipeUpUnlock,
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
  bool get isText => isDateTime || isNormalText || this == ElementType.notification;
  bool get isClock => const {
    ElementType.hourClock, ElementType.minClock, ElementType.dotClock,
    ElementType.amPmClock, ElementType.weekClock, ElementType.monthClock,
    ElementType.dateClock, ElementType.weatherIconClock,
  }.contains(this);
  bool get isExportable => isClock || isContainer;
  bool get swipeUpUnlock => this == ElementType.swipeUpUnlock;
}

// ── Groups for UI panel ───────────────────────────────────────────────────────

const Map<String, List<ElementType>> kElementGroups = {
  'Container': [ElementType.containerBG1, ElementType.containerBG2,
                ElementType.containerBG3, ElementType.containerBG4,
                ElementType.containerBG5],
  'PNG':       [ElementType.pngBG1, ElementType.pngBG2, ElementType.pngBG3,
                ElementType.pngBG4, ElementType.pngBG5],
  'Animation': [ElementType.videoWallpaper],
  'Clock':     [ElementType.hourClock, ElementType.minClock,
                ElementType.dotClock,  ElementType.amPmClock,
                ElementType.weekClock],
  'Date':      [ElementType.monthClock, ElementType.dateClock],
  'Weather':   [ElementType.weatherIconClock],
  'Notification': [ElementType.notification],
  'DateTime Text': [ElementType.dateTimeText1, ElementType.dateTimeText2,
                    ElementType.dateTimeText3],
  'Text':      [ElementType.normalText1, ElementType.normalText2,
                ElementType.normalText3, ElementType.normalText4,
                ElementType.normalText5],
  'Music':     [ElementType.musicBg, ElementType.musicNext,
                ElementType.musicPrev, ElementType.musicPlay,
                ElementType.musicPause],
  'Icon':      [ElementType.cameraIcon, ElementType.themeIcon,
                ElementType.musicIcon,  ElementType.dialerIcon,
                ElementType.mmsIcon,    ElementType.contactIcon,
                ElementType.whatsAppIcon, ElementType.telegramIcon,
                ElementType.instagramIcon, ElementType.spotifyIcon,
                ElementType.settingIcon, ElementType.galleryIcon],
  'Other':     [ElementType.swipeUpUnlock],
};

// ── Gradient type ─────────────────────────────────────────────────────────────

enum GradientType { linear, radial, sweep }

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
  });

  final ElementType type;
  final double dx, dy, scale, height, width, radius, borderWidth, angle, fontSize;
  final Color borderColor, color, colorSecondary;
  final GradientType gradientType;
  final AlignmentGeometry gradStartAlign, gradEndAlign, align;
  final String font, path, text;
  final FontWeight fontWeight;
  final bool isShort, isWrap, showGuideLines;

  String get name => type.name;

  LockElement copyWith({
    double? dx, double? dy, double? scale, double? height, double? width,
    double? radius, double? borderWidth, double? angle, double? fontSize,
    Color? borderColor, Color? color, Color? colorSecondary,
    GradientType? gradientType,
    AlignmentGeometry? gradStartAlign, AlignmentGeometry? gradEndAlign,
    AlignmentGeometry? align,
    String? font, String? path, String? text,
    FontWeight? fontWeight,
    bool? isShort, bool? isWrap, bool? showGuideLines,
  }) => LockElement(
    type: type,
    dx: dx ?? this.dx,   dy: dy ?? this.dy, scale: scale ?? this.scale,
    height: height ?? this.height, width: width ?? this.width,
    radius: radius ?? this.radius, borderWidth: borderWidth ?? this.borderWidth,
    angle: angle ?? this.angle, fontSize: fontSize ?? this.fontSize,
    borderColor: borderColor ?? this.borderColor,
    color: color ?? this.color, colorSecondary: colorSecondary ?? this.colorSecondary,
    gradientType: gradientType ?? this.gradientType,
    gradStartAlign: gradStartAlign ?? this.gradStartAlign,
    gradEndAlign:   gradEndAlign   ?? this.gradEndAlign,
    align: align ?? this.align,
    font: font ?? this.font, path: path ?? this.path, text: text ?? this.text,
    fontWeight: fontWeight ?? this.fontWeight,
    isShort: isShort ?? this.isShort, isWrap: isWrap ?? this.isWrap,
    showGuideLines: showGuideLines ?? this.showGuideLines,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'dx': dx, 'dy': dy, 'scale': scale,
    'height': height, 'width': width, 'radius': radius,
    'borderWidth': borderWidth, 'angle': angle, 'fontSize': fontSize,
    'borderColor': borderColor.toARGB32(),
    'color': color.toARGB32(), 'colorSecondary': colorSecondary.toARGB32(),
    'gradientType': gradientType.name,
    'gradStartAlign': gradStartAlign.toString(),
    'gradEndAlign':   gradEndAlign.toString(),
    'align': align.toString(),
    'font': font, 'path': path, 'text': text,
    'fontWeight': fontWeight.toString(),
    'isShort': isShort, 'isWrap': isWrap, 'showGuideLines': showGuideLines,
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
