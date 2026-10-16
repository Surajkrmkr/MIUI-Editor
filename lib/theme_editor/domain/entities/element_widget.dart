import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/alignment_ext.dart';

// ── Element type ──────────────────────────────────────────────────────────────

enum ElementType {
  containerBG1,
  containerBG2,
  containerBG3,
  containerBG4,
  containerBG5,
  pngBG1,
  pngBG2,
  pngBG3,
  pngBG4,
  pngBG5,
  videoWallpaper,
  hourClock,
  minClock,
  secClock,
  dotClock,
  dotClock2,
  amPmClock,
  weekClock,
  monthClock,
  dateClock,
  weatherIconClock,
  notification,
  dateTimeText1,
  dateTimeText2,
  dateTimeText3,
  normalText1,
  normalText2,
  normalText3,
  normalText4,
  normalText5,
  musicBg,
  musicNext,
  musicPrev,
  musicPlay,
  musicPause,
  cameraIcon,
  themeIcon,
  musicIcon,
  dialerIcon,
  mmsIcon,
  contactIcon,
  whatsAppIcon,
  telegramIcon,
  instagramIcon,
  spotifyIcon,
  settingIcon,
  galleryIcon,
  swipeUpUnlock,
  tapToUnlock,
  slideToUnlock,

  // Missing values identified
  weatherTemp,
  weatherDesc,
  analogClockBg,
  analogHourHand,
  analogMinHand,
  analogSecHand,
  calendarGrid,
  toggleSwitch,
  missedCalls,
  stepsCount,
  batteryLevel,
  progressBar,
  batteryText,
  rectangleShape,
  circleShape,
  ellipseShape,
  lineShape,
  arcShape,
  stepsGoal,
  stepsDistance,
  stepsCalories,
  stepsDuration,
  stepsSummary,
  weatherCity,
  weatherTemperatureRange,
  weatherAqi,
  weatherHumidity,
  calendarIcon,
  weatherIcon,
  clockIcon,
  notesIcon,
  browserIcon,
  calculatorIcon,
  compassIcon,
  fileManagerIcon,
  videoIcon,
  securityIcon,
  radioIcon,
  recorderIcon,
  downloadsIcon,
  dragToUnlock,
}

extension ElementTypeX on ElementType {
  bool get isContainer => name.startsWith('container');
  bool get isPng => name.startsWith('png');
  bool get isVideo => this == ElementType.videoWallpaper;
  bool get isWeatherText => const {
    ElementType.weatherTemp,
    ElementType.weatherDesc,
    ElementType.weatherCity,
    ElementType.weatherTemperatureRange,
    ElementType.weatherAqi,
    ElementType.weatherHumidity,
  }.contains(this);
  bool get supportsCustomFont => !isText && this != ElementType.calendarGrid;
  String get label => name
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .replaceAllMapped(
        RegExp(r'([a-zA-Z])([0-9])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .split(' ')
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
  bool get isShape => const {
    ElementType.rectangleShape,
    ElementType.circleShape,
    ElementType.ellipseShape,
    ElementType.lineShape,
    ElementType.arcShape,
  }.contains(this);
  bool get isHealth => const {
    ElementType.stepsCount,
    ElementType.stepsGoal,
    ElementType.stepsDistance,
    ElementType.stepsCalories,
    ElementType.stepsDuration,
    ElementType.stepsSummary,
  }.contains(this);
  String? get healthColumn => const {
    ElementType.stepsCount: 'steps',
    ElementType.stepsGoal: 'goal',
    ElementType.stepsDistance: 'distance',
    ElementType.stepsCalories: 'energy',
    ElementType.stepsDuration: 'strength_duration',
    ElementType.stepsSummary: 'summary',
  }[this];
  String? get defaultIconAsset => const {
    ElementType.cameraIcon: 'com.android.camera',
    ElementType.themeIcon: 'com.android.thememanager',
    ElementType.musicIcon: 'com.miui.player',
    ElementType.dialerIcon: 'com.android.contacts.activities.TwelveKeyDialer',
    ElementType.mmsIcon: 'com.android.mms',
    ElementType.contactIcon: 'com.android.contacts',
    ElementType.whatsAppIcon: 'com.whatsapp',
    ElementType.telegramIcon: 'org.telegram.messenger',
    ElementType.instagramIcon: 'com.instagram.android',
    ElementType.spotifyIcon: 'com.spotify.music',
    ElementType.settingIcon: 'com.android.settings',
    ElementType.galleryIcon: 'com.miui.gallery',
    ElementType.calendarIcon: 'com.android.calendar',
    ElementType.weatherIcon: 'com.miui.weather2',
    ElementType.clockIcon: 'com.android.deskclock',
    ElementType.notesIcon: 'com.miui.notes',
    ElementType.browserIcon: 'com.android.browser',
    ElementType.calculatorIcon: 'com.miui.calculator',
    ElementType.compassIcon: 'com.miui.compass',
    ElementType.fileManagerIcon: 'com.android.fileexplorer',
    ElementType.videoIcon: 'com.miui.video',
    ElementType.securityIcon: 'com.miui.securitycenter',
    ElementType.radioIcon: 'com.miui.fmradio',
    ElementType.recorderIcon: 'com.android.soundrecorder',
    ElementType.downloadsIcon: 'com.android.providers.downloads.ui',
  }[this];
  bool get isIcon => const {
    ElementType.cameraIcon,
    ElementType.themeIcon,
    ElementType.musicIcon,
    ElementType.dialerIcon,
    ElementType.mmsIcon,
    ElementType.contactIcon,
    ElementType.whatsAppIcon,
    ElementType.telegramIcon,
    ElementType.instagramIcon,
    ElementType.spotifyIcon,
    ElementType.settingIcon,
    ElementType.galleryIcon,
    ElementType.calendarIcon,
    ElementType.weatherIcon,
    ElementType.clockIcon,
    ElementType.notesIcon,
    ElementType.browserIcon,
    ElementType.calculatorIcon,
    ElementType.compassIcon,
    ElementType.fileManagerIcon,
    ElementType.videoIcon,
    ElementType.securityIcon,
    ElementType.radioIcon,
    ElementType.recorderIcon,
    ElementType.downloadsIcon,
  }.contains(this);
  bool get isMusic => const {
    ElementType.musicBg,
    ElementType.musicNext,
    ElementType.musicPrev,
    ElementType.musicPlay,
    ElementType.musicPause,
  }.contains(this);
  bool get isDateTime => const {
    ElementType.dateTimeText1,
    ElementType.dateTimeText2,
    ElementType.dateTimeText3,
  }.contains(this);
  bool get isNormalText => const {
    ElementType.normalText1,
    ElementType.normalText2,
    ElementType.normalText3,
    ElementType.normalText4,
    ElementType.normalText5,
  }.contains(this);
  bool get isText =>
      isDateTime ||
      isNormalText ||
      isHealth ||
      this == ElementType.batteryText ||
      this == ElementType.batteryLevel ||
      this == ElementType.notification ||
      isWeatherText;
  bool get isClock => const {
    ElementType.hourClock,
    ElementType.minClock,
    ElementType.secClock,
    ElementType.dotClock,
    ElementType.dotClock2,
    ElementType.amPmClock,
    ElementType.weekClock,
    ElementType.monthClock,
    ElementType.dateClock,
    ElementType.weatherIconClock,
    ElementType.analogClockBg,
    ElementType.analogHourHand,
    ElementType.analogMinHand,
    ElementType.analogSecHand,
  }.contains(this);
  bool get isExportable => isClock || isContainer;
  bool get swipeUpUnlock => this == ElementType.swipeUpUnlock;
  bool get isUnlockControl =>
      this == ElementType.tapToUnlock ||
      this == ElementType.slideToUnlock ||
      this == ElementType.dragToUnlock;

  String get defaultPath =>
      const {
        ElementType.cameraIcon: r'\icon\camera',
        ElementType.galleryIcon: r'\icon\gallery',
        ElementType.settingIcon: r'\icon\setting',
        ElementType.themeIcon: r'\icon\theme',
        ElementType.musicIcon: r'\icon\music',
        ElementType.dialerIcon: r'\icon\dialer',
        ElementType.mmsIcon: r'\icon\mms',
        ElementType.contactIcon: r'\icon\contact',
        ElementType.whatsAppIcon: r'\icon\whatsApp',
        ElementType.telegramIcon: r'\icon\telegram',
        ElementType.instagramIcon: r'\icon\instagram',
        ElementType.spotifyIcon: r'\icon\spotify',
        ElementType.calendarIcon: r'\icon\calendar',
        ElementType.weatherIcon: r'\icon\weather',
        ElementType.clockIcon: r'\icon\clock',
        ElementType.notesIcon: r'\icon\notes',
        ElementType.browserIcon: r'\icon\browser',
        ElementType.calculatorIcon: r'\icon\calculator',
        ElementType.compassIcon: r'\icon\compass',
        ElementType.fileManagerIcon: r'\icon\fileManager',
        ElementType.videoIcon: r'\icon\video',
        ElementType.securityIcon: r'\icon\security',
        ElementType.radioIcon: r'\icon\radio',
        ElementType.recorderIcon: r'\icon\recorder',
        ElementType.downloadsIcon: r'\icon\downloads',
        ElementType.musicBg: r'\music\bg',
        ElementType.musicNext: r'\music\next',
        ElementType.musicPrev: r'\music\prev',
        ElementType.musicPlay: r'\music\play',
        ElementType.musicPause: r'\music\pause',
        ElementType.swipeUpUnlock: r'\unlock\unlock',
        ElementType.slideToUnlock: r'\unlock\slider',
        ElementType.tapToUnlock: r'\unlock\tap',
        ElementType.dragToUnlock: r'\unlock\drag',
      }[this] ??
      '';
}

// ── Groups for UI panel ───────────────────────────────────────────────────────

const Map<String, List<ElementType>> kElementGroups = {
  'Clock': [
    ElementType.hourClock,
    ElementType.minClock,
    ElementType.secClock,
    ElementType.dotClock,
    ElementType.dotClock2,
    ElementType.amPmClock,
    ElementType.weekClock,
  ],
  'Date': [ElementType.monthClock, ElementType.dateClock],
  'Weather': [
    ElementType.weatherIconClock,
    ElementType.weatherTemp,
    ElementType.weatherDesc,
    ElementType.weatherCity,
    ElementType.weatherTemperatureRange,
    ElementType.weatherAqi,
    ElementType.weatherHumidity,
  ],
  'Calendar': [ElementType.calendarGrid],
  'Notification': [ElementType.notification],
  'Battery': [ElementType.batteryText],
  'Geometry': [
    ElementType.rectangleShape,
    ElementType.circleShape,
    ElementType.ellipseShape,
    ElementType.lineShape,
    ElementType.arcShape,
  ],
  'Health': [
    ElementType.stepsCount,
    ElementType.stepsGoal,
    ElementType.stepsDistance,
    ElementType.stepsCalories,
    ElementType.stepsDuration,
    ElementType.stepsSummary,
  ],
  'DateTime Text': [
    ElementType.dateTimeText1,
    ElementType.dateTimeText2,
    ElementType.dateTimeText3,
  ],
  'Text': [
    ElementType.normalText1,
    ElementType.normalText2,
    ElementType.normalText3,
    ElementType.normalText4,
    ElementType.normalText5,
  ],
  'Container': [
    ElementType.containerBG1,
    ElementType.containerBG2,
    ElementType.containerBG3,
    ElementType.containerBG4,
    ElementType.containerBG5,
  ],
  'PNG': [
    ElementType.pngBG1,
    ElementType.pngBG2,
    ElementType.pngBG3,
    ElementType.pngBG4,
    ElementType.pngBG5,
  ],
  'Animation': [ElementType.videoWallpaper],
  'Music': [
    ElementType.musicBg,
    ElementType.musicNext,
    ElementType.musicPrev,
    ElementType.musicPlay,
    ElementType.musicPause,
  ],
  'Icon': [
    ElementType.cameraIcon,
    ElementType.themeIcon,
    ElementType.musicIcon,
    ElementType.dialerIcon,
    ElementType.mmsIcon,
    ElementType.contactIcon,
    ElementType.whatsAppIcon,
    ElementType.telegramIcon,
    ElementType.instagramIcon,
    ElementType.spotifyIcon,
    ElementType.settingIcon,
    ElementType.galleryIcon,
  ],
  'System Icons': [
    ElementType.calendarIcon,
    ElementType.weatherIcon,
    ElementType.clockIcon,
    ElementType.notesIcon,
    ElementType.browserIcon,
    ElementType.calculatorIcon,
    ElementType.compassIcon,
    ElementType.fileManagerIcon,
    ElementType.videoIcon,
    ElementType.securityIcon,
    ElementType.radioIcon,
    ElementType.recorderIcon,
    ElementType.downloadsIcon,
  ],
  'Other': [
    ElementType.swipeUpUnlock,
    ElementType.tapToUnlock,
    ElementType.slideToUnlock,
    ElementType.dragToUnlock,
  ],
};

// ── Gradient type ─────────────────────────────────────────────────────────────

enum GradientType { linear, radial, sweep }

enum ElementAnimation { none, position, rotation, alpha, scale, size }

// ── MamlEase enum ─────────────────────────────────────────────────────────────

enum MamlEase {
  linear,
  sineEaseIn,
  sineEaseOut,
  sineEaseInOut,
  quadEaseIn,
  quadEaseOut,
  quadEaseInOut,
  cubicEaseIn,
  cubicEaseOut,
  cubicEaseInOut,
  quartEaseIn,
  quartEaseOut,
  quartEaseInOut,
  quintEaseIn,
  quintEaseOut,
  quintEaseInOut,
  expoEaseIn,
  expoEaseOut,
  expoEaseInOut,
  circEaseIn,
  circEaseOut,
  circEaseInOut,
  backEaseIn,
  backEaseOut,
  backEaseInOut,
  elasticEaseIn,
  elasticEaseOut,
  elasticEaseInOut,
  bounceEaseIn,
  bounceEaseOut,
  bounceEaseInOut,
}

// ── Pure-Dart entity ──────────────────────────────────────────────────────────

class ElementAnimationTrack {
  const ElementAnimationTrack({
    required this.type,
    this.duration = 2000,
    this.amount = 60,
    this.offsetY = 0,
    this.loop = true,
    this.ease = MamlEase.linear,
    this.startX,
    this.startY,
  });

  final ElementAnimation type;
  final int duration;
  final double amount, offsetY;
  final bool loop;
  final MamlEase ease;
  final double? startX, startY;
  bool get hasCustomStart =>
      type == ElementAnimation.position && startX != null && startY != null;

  ElementAnimationTrack copyWith({
    int? duration,
    double? amount,
    double? offsetY,
    bool? loop,
    MamlEase? ease,
    double? startX,
    double? startY,
    bool clearStartPosition = false,
  }) => ElementAnimationTrack(
    type: type,
    duration: duration ?? this.duration,
    amount: amount ?? this.amount,
    offsetY: offsetY ?? this.offsetY,
    loop: loop ?? this.loop,
    ease: ease ?? this.ease,
    startX: clearStartPosition ? null : startX ?? this.startX,
    startY: clearStartPosition ? null : startY ?? this.startY,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'duration': duration,
    'amount': amount,
    'offsetY': offsetY,
    'loop': loop,
    'ease': ease.name,
    'startX': startX,
    'startY': startY,
  };

  factory ElementAnimationTrack.fromJson(Map<String, dynamic> json) =>
      ElementAnimationTrack(
        type: ElementAnimation.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => ElementAnimation.none,
        ),
        duration: ((json['duration'] as num?)?.toInt() ?? 2000).clamp(
          100,
          60000,
        ),
        amount: (json['amount'] as num?)?.toDouble() ?? 60,
        offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
        startX: (json['startX'] as num?)?.toDouble(),
        startY: (json['startY'] as num?)?.toDouble(),
        loop: json['loop'] as bool? ?? true,
        ease: MamlEase.values.firstWhere(
          (ease) => ease.name == json['ease'],
          orElse: () => MamlEase.linear,
        ),
      );
}

enum ArcProgressSource {
  none,
  battery,
  hour,
  minute,
  second,
  steps;

  String get label => switch (this) {
    none => 'None',
    battery => 'Battery',
    hour => 'Hour (24h)',
    minute => 'Minute',
    second => 'Second',
    steps => 'Steps / Goal',
  };

  double fraction({
    required DateTime time,
    required double batteryLevel,
    required double stepCount,
    required double stepGoal,
  }) {
    final value = switch (this) {
      none => 1.0,
      battery => batteryLevel / 100,
      hour => time.hour / 24,
      minute => time.minute / 60,
      second => time.second / 60,
      steps => stepGoal > 0 ? stepCount / stepGoal : 0.0,
    };
    return value.clamp(0.0, 1.0).toDouble();
  }
}

enum UnlockIcon {
  automatic(null, 'Default'),
  lock(Icons.lock_rounded, 'Lock'),
  lockOpen(Icons.lock_open_rounded, 'Open lock'),
  chevron(Icons.chevron_right_rounded, 'Chevron'),
  arrow(Icons.arrow_forward_rounded, 'Arrow'),
  power(Icons.power_settings_new_rounded, 'Power'),
  none(null, 'None'),
  customPng(null, 'PNG image'),
  plug(Icons.power_rounded, 'Plug');

  const UnlockIcon(this.icon, this.label);
  final IconData? icon;
  final String label;
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
    this.calendarRows = 6,
    this.calendarShowMonth = true,
    this.calendarShowWeekdays = true,
    this.unlockIconScale = .6,
    this.unlockCornerRadius,
    this.unlockBackgroundOpacity = 48 / 255,
    this.unlockThumbOpacity = 96 / 255,
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
        AppConstants.screenRatio *
        (type == ElementType.slideToUnlock ? .5 : .22);
    return fontSize < limit ? fontSize : limit;
  }

  final double unlockIconScale, unlockBackgroundOpacity, unlockThumbOpacity;
  final double? unlockCornerRadius;
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
                  : radius * AppConstants.screenRatio))
          .clamp(0, (width < unlockHeight ? width : unlockHeight) / 2);
  final bool isShort,
      isWrap,
      showGuideLines,
      isVisible,
      isLocked,
      useSeparateColors,
      isLiquidGlass;

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
    int? calendarRows,
    bool? calendarShowMonth,
    bool? calendarShowWeekdays,
    double? unlockIconScale,
    double? unlockCornerRadius,
    double? unlockBackgroundOpacity,
    double? unlockThumbOpacity,
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
    calendarRows: calendarRows ?? this.calendarRows,
    calendarShowMonth: calendarShowMonth ?? this.calendarShowMonth,
    calendarShowWeekdays: calendarShowWeekdays ?? this.calendarShowWeekdays,
    unlockIconScale: unlockIconScale ?? this.unlockIconScale,
    unlockCornerRadius: unlockCornerRadius ?? this.unlockCornerRadius,
    unlockBackgroundOpacity:
        unlockBackgroundOpacity ?? this.unlockBackgroundOpacity,
    unlockThumbOpacity: unlockThumbOpacity ?? this.unlockThumbOpacity,
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
    'calendarRows': calendarRows,
    'calendarShowMonth': calendarShowMonth,
    'calendarShowWeekdays': calendarShowWeekdays,
    'unlockIconScale': unlockIconScale,
    'unlockCornerRadius': unlockCornerRadius,
    'unlockBackgroundOpacity': unlockBackgroundOpacity,
    'unlockThumbOpacity': unlockThumbOpacity,
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
    'fontWeight': fontWeight.toString(),
    'isShort': isShort,
    'isWrap': isWrap,
    'showGuideLines': showGuideLines,
    'isVisible': isVisible,
    'isLocked': isLocked,
    'useSeparateColors': useSeparateColors,
    'blurRadius': blurRadius,
    'isLiquidGlass': isLiquidGlass,
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
