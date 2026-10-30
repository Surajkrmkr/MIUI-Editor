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
  analogClock,
  shortcutSet,
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
  flashlightIcon,
  dragToUnlock,
  depthLayer,
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
    ElementType.flashlightIcon: 'flashlight',
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
    ElementType.flashlightIcon,
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
    ElementType.analogClock,
  }.contains(this);
  bool get isExportable =>
      isClock ||
      isContainer ||
      this == ElementType.shortcutSet ||
      this == ElementType.calendarGrid;
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
        ElementType.flashlightIcon: r'\icon\flashlight',
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

/// Exported theme icon name (e.g. `com.android.camera`) for a lockscreen image
/// path such as `icon/camera`, or null if no icon element uses that path.
String? exportedIconForLockscreenPath(String relativePath) {
  final wanted = relativePath
      .replaceAll(r'\', '/')
      .replaceFirst(RegExp('^/'), '');
  for (final type in ElementType.values) {
    if (!type.isIcon) continue;
    final path = type.defaultPath.replaceAll(r'\', '/').replaceFirst('/', '');
    if (path == wanted) return type.defaultIconAsset;
  }
  return null;
}

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
  'Analog Clock': [ElementType.analogClock],
  'Custom Widgets': [ElementType.shortcutSet],
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
    ElementType.flashlightIcon,
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
  bounceEaseInOut;

  /// Easing name as MAML spells it, e.g. `SineEaseIn`.
  String get mamlName => '${name[0].toUpperCase()}${name.substring(1)}';
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

  /// MAML expression for [fraction], 0 to 1; null for [none].
  String? get mamlFraction => switch (this) {
    none => null,
    battery => 'min(1,max(0,#battery_level/100))',
    hour => '#hour24/24',
    minute => '#minute/60',
    second => '#second/60',
    steps =>
      'ifelse(gt(int(@MiSteps_goal),0),min(1,max(0,int(@MiSteps_steps)/max(1,int(@MiSteps_goal)))),0)',
  };
}

/// Icon drawn on tap/slide/drag unlock controls. The Material glyph for each
/// value lives in the app (`UnlockIconX.icon`).
enum UnlockIcon {
  automatic('Default'),
  lock('Lock'),
  lockOpen('Open lock'),
  chevron('Chevron'),
  arrow('Arrow'),
  power('Power'),
  none('None'),
  customPng('PNG image'),
  plug('Plug'),
  fingerprint('Fingerprint'),
  play('Play');

  const UnlockIcon(this.label);
  final String label;
}

enum ShortcutStyle {
  glossDock,
  whiteTiles,
  leafTiles,
  darkDock,
  pastelDock,
  socialRow,
  hexGrid,
  neonCapsule,
  socialCards,
  candyCapsule,
  softRow,
  glossOrbs,
}

/// Which screen edge a dock is attached to; [floating] rounds every corner.
enum ShortcutEdge { right, left, floating }

/// Look of the calendar grid; [classic] is the original plain grid.
enum CalendarStyle {
  classic,
  pillColumn,
  plusCircles,
  stripHeader,
  glassCard,
  neonCyber,
  neoBrutalism,
  bentoGrid,
  gradientAura,
  minimalDots,
  splitFlap,
  capsuleRow,
  floatingBadges,
  abstractGeometric,
  outlineRings,
  monolith,
  bracketModern,
  softNeumorphism,
  lunarPhase,
  polarArc,
  cyberMatrix,
  ticketStub,
  notebookSpiral,
  tearOff,
  chalkboard,
  graphPaper,
  washiTape,
  retroLcd,
  windowChrome,
  editorial,
  ledger,
  postageStamp,
}

enum AnalogStyle {
  indigo,
  minimal,
  classic,
  numerals,
  dots,
  ring,
  sport,
  woodPanel,
  crimsonGlass,
  romanWall,
  neonGlow,
  auroraRing,
  luxuryGold,
  frostedGlass,
  orbit,
  orbitDigital,
  flowerCard,
  bauhausPop,
  ripple,
  solarEclipse,
  memphis,
  prism,
  ribbon,
  terrazzo,
  contour,
  pixelSun,
  kineticTiles,
  fanFold,
  liquidLoops,
  checkerWave,
  cyberReticle,
  sunsetGrid,
  zenGarden,
  vortex,
  circuitTrace,
  artDeco,
  squirclePebble,
  moireRings,
  brutalistPop,
  holoWarp,
  atomicStar,
  honeycomb,
  gearwork,
  radarSweep,
  petalBloom,
  ringedPlanet,
  stainedGlass,
  blueprint,
  vinylRecord,
  gaugeDial,
}

/// Visual skin of tap/slide/drag unlock controls; [classic] is the original look.
enum UnlockSkin {
  classic,
  waveNotch,
  glowOrb,
  ringButton,
  gradientPill,
  ghostStack,
  insetTile,
  neonOrbs,
  outlineTile,
  cardStack,
  pillStack,
  carved,
  meet,
  neonLine,
  liquidGlass,
  gradientFlow,
  groove,
  hexBadge,
  ticketPunch,
  keycap,
  domeRay,
  radarPulse,
  gemDiamond,
  shieldCrest,
  speechBubble,
  dialKnob,
  sealScallop,
  dotTrail,
  zipper,
  rulerSlide,
  sunMoon,
  bracketTrack,
  stairSteps,
  ropeBead,
  slotPlate,
  waveTrack,
  pixelRun,
}
