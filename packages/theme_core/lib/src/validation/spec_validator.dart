import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../assets/asset_paths.dart';
import '../library/base_spec.dart';
import '../lockscreen/design_profile.dart';
import '../lockscreen/element_enums.dart';
import '../lockscreen/lock_element_spec.dart';
import '../spec/font_lookup.dart';
import '../spec/font_ref.dart';
import '../spec/spec_issue.dart';
import '../spec/theme_spec.dart';
import 'validation.dart';
import 'wallpaper_sampler.dart';

/// Checks a theme spec beyond its shape: value ranges, files on disk, name
/// safety, element sanity and legibility.
///
/// Every issue has a stable `code`; errors block a build, warnings don't.
class SpecValidator {
  const SpecValidator();

  /// Validates raw JSON text.
  ValidationReport validateText(String text, ValidationOptions options) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException catch (e) {
      return ValidationReport([
        SpecIssue(
          code: 'spec.json',
          path: '',
          message: 'Not valid JSON: ${e.message}',
          hint: e.offset == null ? null : 'Problem near character ${e.offset}.',
        ),
      ]);
    }
    return validate(json, options);
  }

  /// Validates an already decoded JSON value.
  ValidationReport validate(Object? json, ValidationOptions options) {
    final parsed = ThemeSpec.parse(json);
    final spec = parsed.spec;
    if (spec == null) return ValidationReport(parsed.issues);

    final issues = [...parsed.issues];
    final run = _Run(spec, options, issues);
    run.meta();
    run.output();
    run.icons();
    run.systemUi();
    run.lockscreen();
    run.fonts();
    run.wallpaperAndContrast();
    return ValidationReport(issues, spec: spec);
  }
}

const _targetUiVersion = 17;
const _maxNameLength = 100;
final _reserved = RegExp(
  r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\..*)?$',
  caseSensitive: false,
);
final _idPattern = RegExp(r'^[A-Za-z0-9_-]*$');

/// Why [name] can't be a file name on macOS/Windows, or null if it can.
String? _unsafeName(String name) {
  if (name.trim().isEmpty) return 'is empty';
  if (name.length > _maxNameLength) {
    return 'is longer than $_maxNameLength characters';
  }
  if (name.runes.any(
    (c) => c < 0x20 || '<>:"/\\|?*'.contains(String.fromCharCode(c)),
  )) {
    return 'contains a character not allowed in file names (< > : " / \\ | ? *)';
  }
  if (name.endsWith('.') || name.endsWith(' ')) {
    return 'ends with a dot or space';
  }
  if (_reserved.hasMatch(name)) return 'is a reserved Windows name';
  return null;
}

bool _looksLikeFont(Uint8List b) {
  if (b.length < 4) return false;
  final tag = String.fromCharCodes(b.sublist(0, 4));
  return (b[0] == 0 && b[1] == 1 && b[2] == 0 && b[3] == 0) ||
      tag == 'OTTO' ||
      tag == 'true' ||
      tag == 'ttcf';
}

class _Run {
  _Run(this.spec, this.options, this.issues);

  final ThemeSpec spec;
  final ValidationOptions options;
  final List<SpecIssue> issues;

  String resolve(String path) =>
      p.isAbsolute(path) ? path : p.normalize(p.join(options.baseDir, path));

  void error(String code, String path, String message, {String? hint}) => issues
      .add(SpecIssue(code: code, path: path, message: message, hint: hint));

  void warn(String code, String path, String message, {String? hint}) =>
      issues.add(
        SpecIssue(
          code: code,
          path: path,
          message: message,
          hint: hint,
          severity: IssueSeverity.warning,
        ),
      );

  void range(String path, double v, double min, double max, {String? name}) {
    if (v.isNaN || v < min || v > max) {
      error(
        'range',
        path,
        '${name ?? p.basename(path)} is $v; it must be between $min and $max.',
      );
    }
  }

  // ── meta / output ────────────────────────────────────────────────────────

  void meta() {
    final m = spec.meta;
    if (m.uiVersion != _targetUiVersion) {
      error(
        'meta.ui_version',
        '/meta/uiVersion',
        'uiVersion ${m.uiVersion} is not supported.',
        hint: 'Only HyperOS 3 ($_targetUiVersion) can be built.',
      );
    }
    final bad = _unsafeName(m.title);
    if (bad != null) {
      error(
        'name.unsafe',
        '/meta/title',
        'Title $bad.',
        hint: 'The title becomes a folder name and the default .mtz name.',
      );
    }
    if (m.designer.trim().isEmpty) {
      warn('meta.designer_missing', '/meta/designer', 'Designer is empty.');
    }
    if (m.authorTag.trim().isEmpty) {
      warn('meta.author_missing', '/meta/authorTag', 'Author tag is empty.');
    }
  }

  void output() {
    final name = spec.output.name;
    if (name != null) {
      final bad = _unsafeName(name);
      if (bad != null) {
        error('name.unsafe', '/output/name', 'Output name $bad.');
      }
    }
    final dir = spec.output.dir;
    if (dir != null && File(resolve(dir)).existsSync()) {
      error(
        'output.dir_is_file',
        '/output/dir',
        'Output dir is an existing file.',
      );
    }
  }

  // ── icons ────────────────────────────────────────────────────────────────

  void icons() {
    final i = spec.icons;
    final packs = IconVariant.values.map((v) => v.folder).toList();
    if (!packs.contains(i.pack)) {
      error(
        'icons.pack_unknown',
        '/icons/pack',
        'Unknown icon pack "${i.pack}".',
        hint: 'Available: ${packs.join(', ')}.',
      );
    } else if (options.assetsRoot != null) {
      final dir = p.join(options.assetsRoot!, 'assets', 'icons', i.pack);
      if (!Directory(dir).existsSync()) {
        error(
          'asset.missing',
          '/icons/pack',
          'Icon pack folder not found: $dir',
        );
      } else if (!File(p.join(dir, 'com.android.mms.svg')).existsSync()) {
        error(
          'icons.pack_incomplete',
          '/icons/pack',
          'Pack "${i.pack}" has no com.android.mms.svg, which the system modules need.',
        );
      }
    }

    range('/icons/margin', i.margin, 0, 20);
    range('/icons/padding', i.padding, 0, 20);
    range('/icons/radius', i.radius, 0, 20);
    range('/icons/borderWidth', i.borderWidth, 0, 20);
    range('/icons/effect/intensity', i.effect.intensity, 0, 1);
    range('/icons/effect/blur', i.effect.blur, 0, 100);
    range('/icons/effect/elevation', i.effect.elevation, 0, 20);
    range('/icons/texture/scale', i.texture.scale, 0.1, 5);
    range('/icons/texture/opacity', i.texture.opacity, 0, 1);

    final b = i.background;
    if (b.colors.isEmpty || b.colors.length > 2) {
      error(
        'icons.background_colors',
        '/icons/background/colors',
        'Background needs one or two colors, found ${b.colors.length}.',
      );
    }
    if (b.randomColors && b.palette.isEmpty) {
      error(
        'icons.palette_empty',
        '/icons/background/palette',
        'randomColors is on but the palette is empty.',
      );
    }
    for (final (key, a) in [
      ('start', b.gradientStart),
      ('end', b.gradientEnd),
    ]) {
      if (a.x.abs() > 1 || a.y.abs() > 1) {
        error(
          'range',
          '/icons/background/gradient/$key',
          'Gradient $key $a must stay within -1..1 on both axes.',
        );
      }
    }

    if (i.iconColor.a == 0) {
      warn(
        'icons.invisible',
        '/icons/iconColor',
        'Icon color is fully transparent.',
      );
    } else {
      final fills = b.randomColors ? b.palette : b.colors;
      for (var k = 0; k < fills.length; k++) {
        final ratio = textContrast(i.iconColor, fills[k]);
        if (ratio < 3) {
          warn(
            'contrast.icon',
            b.randomColors
                ? '/icons/background/palette/$k'
                : '/icons/background/colors/$k',
            'Icon glyphs have contrast ${ratio.toStringAsFixed(1)}:1 against '
                '${fills[k].toHex()}; aim for at least 3:1.',
            hint: 'Change iconColor or the background color.',
          );
        }
      }
    }
  }

  void systemUi() {
    if (spec.systemUi.accent.a != 0xFF) {
      warn(
        'systemui.accent_alpha',
        '/systemUi/accent',
        'Accent is not fully opaque; system UI colors will look washed out.',
      );
    }
  }

  // ── lockscreen ───────────────────────────────────────────────────────────

  void lockscreen() {
    final ls = spec.lockscreen;
    range('/lockscreen/bgAlpha', ls.bgAlpha, 0, 1);
    final els = ls.elements;
    if (els.isEmpty) return;

    final seen = <String, int>{};
    for (var i = 0; i < els.length; i++) {
      final e = els[i];
      final at = '/lockscreen/elements/$i';
      final first = seen[e.name];
      if (first != null) {
        error(
          'lockscreen.duplicate_element',
          at,
          'Element "${e.name}" is also at index $first; names must be unique.',
          hint: 'Give one of them a different instanceId.',
        );
      } else {
        seen[e.name] = i;
      }
      if (!_idPattern.hasMatch(e.instanceId)) {
        error(
          'lockscreen.bad_instance_id',
          '$at/instanceId',
          'instanceId "${e.instanceId}" may only contain letters, digits, _ and -.',
        );
      }
      _elementSanity(e, at);
    }

    if (!els.any((e) => e.isVisible && _unlockTypes.contains(e.type))) {
      error(
        'lockscreen.no_unlock',
        '/lockscreen/elements',
        'No visible unlock element.',
        hint:
            'Add and enable swipeUpUnlock, tapToUnlock, slideToUnlock or dragToUnlock.',
      );
    }

    if (options.checkDesign) _lockscreenDesign(els);
    for (var i = 0; i < els.length; i++) {
      final e = els[i];
      if (!e.isVisible) continue;
      if (e.type.isHealth ||
          (e.type == ElementType.arcShape &&
              e.effectiveProgressSource == ArcProgressSource.steps)) {
        error(
          'lockscreen.health_unsupported',
          '/lockscreen/elements/$i',
          '"${e.name}" uses Mi Health step data, which does not load on '
              'devices.',
          hint: 'Use battery, weather or calendar widgets instead.',
        );
      }
    }
    for (var i = 0; i < els.length; i++) {
      final e = els[i];
      if (!e.isVisible || e.type != ElementType.tapToUnlock) continue;
      final gap = bottomPaddingOf(e);
      if (gap < minUnlockBottomPadding) {
        error(
          'lockscreen.unlock_bottom',
          '/lockscreen/elements/$i/dy',
          '"${e.name}" is ${gap.toStringAsFixed(0)}px from the bottom edge; '
              'keep at least ${minUnlockBottomPadding.toStringAsFixed(0)}px.',
          hint: 'Lower dy or shrink it so it clears the gesture bar.',
        );
      }
    }
    _lockscreenAssets(els);
  }

  void _lockscreenDesign(List<LockElementSpec> els) {
    const at = '/lockscreen/elements';
    const reference =
        'Start from get_base_spec or add a widget (list_widgets).';
    final design = DesignProfile(els);
    if (design.count < DesignProfile.minElements) {
      warn(
        'lockscreen.sparse',
        at,
        'Only ${design.count} visible elements; a good lockscreen has at '
            'least ${DesignProfile.minElements}.',
        hint: reference,
      );
    }
    if (!design.hasClock) {
      warn(
        'lockscreen.no_clock',
        at,
        'No clock.',
        hint: 'Add hourClock and minClock, dotClock or analogClock.',
      );
    }
    if (!design.hasInfo) {
      warn(
        'lockscreen.no_info',
        at,
        'No widget shows live information such as weather, battery or '
            'calendar (music does not count).',
        hint: 'Add a widget from list_widgets other than music.',
      );
    }
    if (!design.hasDecoration) {
      warn(
        'lockscreen.no_decoration',
        at,
        'No shape, card or image to give the layout structure.',
        hint: 'Add a rectangleShape, a containerBG or a png element.',
      );
    }
    if (design.textCount >= 2 && design.fontSizes < 2) {
      warn(
        'lockscreen.one_font_size',
        at,
        'All text and clocks use one font size.',
        hint: 'Vary fontSize so there is a clear main and secondary text.',
      );
    }
    if (!design.hasSwipeUp) {
      warn(
        'lockscreen.no_swipe_up',
        at,
        'No swipeUpUnlock.',
        hint: 'Every lockscreen has swipeUpUnlock next to its unlock control.',
      );
    }
    for (var i = 0; i < els.length; i++) {
      final e = els[i];
      if (!e.isVisible) continue;
      if (e.type == ElementType.dragToUnlock) {
        warn(
          'lockscreen.drag_unlock',
          '$at/$i',
          'dragToUnlock is not used.',
          hint: 'Use slideToUnlock or tapToUnlock with swipeUpUnlock.',
        );
      }
      final shortcuts = e.type == ElementType.shortcutSet
          ? [
              for (final key in e.shortcutApps.split(','))
                if (_thirdPartyApps.contains(key.trim())) key.trim(),
            ]
          : [if (_thirdPartyIcons.contains(e.type)) e.type.name];
      if (shortcuts.isNotEmpty) {
        warn(
          'shortcut.third_party',
          '$at/$i',
          'Shortcuts use system apps only, not ${shortcuts.join(', ')}.',
          hint:
              'Use messages, camera, music, browser, phone, settings, '
              'flashlight, gallery, contacts, calendar, clock, notes, '
              'calculator, weather, theme or video.',
        );
      }
    }
    _safeArea(els);
    _spread(
      design,
      const {ElementType.hourClock, ElementType.minClock},
      'clock.spread',
      'The hour and minute are far apart.',
      'Keep them one compact group, about the width of a digit apart.',
      (e) => e.fontSize * e.scale * .9,
    );
    _spread(
      design,
      const {
        ElementType.weekClock,
        ElementType.monthClock,
        ElementType.dateClock,
      },
      'date.spread',
      'The weekday, month and day are spread apart.',
      'Keep them close enough to read as one date.',
      (_) => 90,
    );
    _similar(design);
  }

  /// Warns about content under the status bar or over the gesture bar.
  /// Backgrounds, shapes and the swipe-up area may bleed to the edges.
  void _safeArea(List<LockElementSpec> els) {
    for (var i = 0; i < els.length; i++) {
      final e = els[i];
      final t = e.type;
      if (!e.isVisible ||
          t.isDecoration ||
          t.swipeUpUnlock ||
          t.isVideo ||
          t == ElementType.depthLayer) {
        continue;
      }
      final at = '/lockscreen/elements/$i/dy';
      final top = topPaddingOf(e);
      if (top < minTopPadding) {
        warn(
          'lockscreen.top_edge',
          at,
          '"${e.name}" is ${top.toStringAsFixed(0)}px from the top edge and '
              'can run under the status bar; keep at least '
              '${minTopPadding.toStringAsFixed(0)}px.',
          hint: 'Increase dy to move it down so it clears the status bar.',
        );
      }
      // Tap unlock has its own, stricter bottom error.
      if (t != ElementType.tapToUnlock) {
        final bottom = bottomPaddingOf(e);
        if (bottom < minBottomPadding) {
          warn(
            'lockscreen.bottom_edge',
            at,
            '"${e.name}" is ${bottom.toStringAsFixed(0)}px from the bottom '
                'edge and can touch the gesture bar; keep at least '
                '${minBottomPadding.toStringAsFixed(0)}px.',
            hint: 'Decrease dy to move it up, or shrink it.',
          );
        }
      }
    }
  }

  /// Warns when visible elements of [types] sit further apart than the
  /// largest of their [limit]s.
  void _spread(
    DesignProfile design,
    Set<ElementType> types,
    String code,
    String message,
    String hint,
    double Function(LockElementSpec) limit,
  ) {
    final group = [
      for (final e in design.elements)
        if (types.contains(e.type)) e,
    ];
    if (group.length < 2) return;
    var widest = 0.0;
    for (final a in group) {
      for (final b in group) {
        widest = math.max(
          widest,
          math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2)),
        );
      }
    }
    if (widest > group.map(limit).reduce(math.max)) {
      warn(code, '/lockscreen/elements', message, hint: hint);
    }
  }

  void _similar(DesignProfile design) {
    const at = '/lockscreen/elements';
    const change =
        'Change the clock style and position, the widgets, the unlock control '
        'and the color scheme.';
    final close =
        [
            for (final n in options.similarDesigns)
              if (n.title != spec.meta.title)
                (
                  name: n.title,
                  score: design.similarityTo(n.design),
                  other: n.design,
                ),
          ].where((m) => m.score >= DesignProfile.sameDesign).toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    if (close.isNotEmpty) {
      final top = close.first;
      final shared = design.sharedWith(top.other);
      warn(
        'lockscreen.too_similar',
        at,
        'Too close to "${top.name}" (similarity '
            '${top.score.toStringAsFixed(2)}'
            '${shared.isEmpty ? '' : '; shares ${shared.join(', ')}'}).',
        hint: change,
      );
    }
    final starter = design.similarityTo(baseDesign);
    if (starter >= DesignProfile.starterLayout) {
      warn(
        'lockscreen.base_layout',
        at,
        'Still the starter layout from get_base_spec (similarity '
            '${starter.toStringAsFixed(2)}); it only shows where things fit.',
        hint: change,
      );
    }
  }

  static const _thirdPartyApps = {
    'whatsapp',
    'telegram',
    'instagram',
    'spotify',
    'facebook',
  };

  static const _thirdPartyIcons = {
    ElementType.whatsAppIcon,
    ElementType.telegramIcon,
    ElementType.instagramIcon,
    ElementType.spotifyIcon,
  };

  static const _unlockTypes = {
    ElementType.swipeUpUnlock,
    ElementType.tapToUnlock,
    ElementType.slideToUnlock,
    ElementType.dragToUnlock,
  };

  void _elementSanity(LockElementSpec e, String at) {
    if (e.width <= 0 || e.height <= 0) {
      error('range', at, '"${e.name}" needs a positive width and height.');
    }
    if (e.scale <= 0) {
      error('range', '$at/scale', '"${e.name}" scale must be above 0.');
    }
    if (e.fontSize <= 0 && (e.type.isText || e.type.isClock)) {
      error('range', '$at/fontSize', '"${e.name}" fontSize must be above 0.');
    }
    final cx = e.dx * lockscreenScreenRatio, cy = e.dy * lockscreenScreenRatio;
    if (e.isVisible && (cx.abs() > 540 || cy.abs() > 1170)) {
      warn(
        'lockscreen.off_screen',
        at,
        '"${e.name}" is centred off the screen (dx ${e.dx}, dy ${e.dy}).',
        hint: 'Visible range is about |dx| ≤ 138 and |dy| ≤ 300.',
      );
    }
    if (e.type == ElementType.tapToUnlock && e.unlockSkin == UnlockSkin.meet) {
      error(
        'lockscreen.unsupported_skin',
        '$at/unlockSkin',
        '"${e.name}": the meet skin needs a track to drag along, which a tap '
            'unlock does not have.',
        hint: 'Use slideToUnlock or dragToUnlock with meet, or another skin.',
      );
    }
    if (e.unlockIcon == UnlockIcon.customPng && e.unlockIconPath.isEmpty) {
      error(
        'lockscreen.missing_path',
        '$at/unlockIconPath',
        '"${e.name}" uses a custom unlock icon but unlockIconPath is empty.',
      );
    }
  }

  void _lockscreenAssets(List<LockElementSpec> els) {
    final dirPath = spec.lockscreen.assetsDir;
    if (dirPath == null) {
      error(
        'lockscreen.assets_dir_missing',
        '/lockscreen/assetsDir',
        'The lockscreen needs an assetsDir with bg.png and any custom images.',
      );
      return;
    }
    final dir = resolve(dirPath);
    if (!Directory(dir).existsSync()) {
      error('asset.missing', '/lockscreen/assetsDir', 'Folder not found: $dir');
      return;
    }
    if (!File(p.join(dir, 'bg.png')).existsSync()) {
      error(
        'asset.missing',
        '/lockscreen/assetsDir',
        'bg.png is missing from $dir; the lockscreen manifest always references it.',
      );
    }
    for (var i = 0; i < els.length; i++) {
      final e = els[i];
      if (e.unlockIcon == UnlockIcon.customPng && e.unlockIconPath.isNotEmpty) {
        final f = p.isAbsolute(e.unlockIconPath)
            ? e.unlockIconPath
            : p.join(dir, e.unlockIconPath);
        if (!File(f).existsSync()) {
          error(
            'asset.missing',
            '/lockscreen/elements/$i/unlockIconPath',
            'Custom unlock icon not found: $f',
          );
        }
      }
    }
  }

  // ── fonts ────────────────────────────────────────────────────────────────

  void fonts() {
    final needed = spec.requiredFontRefs.toSet();
    final declared = <String>{};
    for (var i = 0; i < spec.fonts.length; i++) {
      final f = spec.fonts[i];
      final at = '/fonts/$i';
      if (!declared.add(f.ref)) {
        warn('font.duplicate', at, 'Font "${f.ref}" is declared twice.');
      }
      if (!needed.contains(f.ref)) {
        warn('font.unused', at, 'No element uses font "${f.ref}".');
        continue;
      }
      final path = f.path;
      if (path == null) continue; // reported below as missing
      final file = File(resolve(path));
      if (!file.existsSync()) {
        error('asset.missing', '$at/path', 'Font file not found: ${file.path}');
      } else if (!_looksLikeFont(file.readAsBytesSync())) {
        error(
          'font.invalid',
          '$at/path',
          '${file.path} is not a TrueType/OpenType font.',
        );
      }
    }
    for (final ref in needed) {
      final entry = spec.fontFor(ref);
      if (entry == null || entry.path == null) {
        final parsed = FontRef.parse(ref);
        if (findFontFile(parsed.family, options.fontsDirs) != null) continue;
        error(
          'font.file_missing',
          entry == null ? '/fonts' : '/fonts/${spec.fonts.indexOf(entry)}',
          'Font "${parsed.family}" ($ref) has no local file.',
          hint:
              'Add {"ref": "$ref", "path": "<font>.ttf"} to fonts; without it '
              'the text is drawn as placeholder blocks, or pass --fonts-dir '
              'with a folder holding ${parsed.family}.ttf.'
              '${parsed.url != null ? ' Download it from ${parsed.url}.' : ''}',
        );
      }
    }
  }

  // ── wallpaper + contrast ─────────────────────────────────────────────────

  void wallpaperAndContrast() {
    final w = spec.wallpaper;
    Uint8List? lockBytes;
    for (final (key, path) in [
      ('home', w.home),
      if (w.lock != null) ('lock', w.lock!),
    ]) {
      final file = File(resolve(path));
      final at = '/wallpaper/$key';
      if (!file.existsSync()) {
        error('asset.missing', at, 'Wallpaper not found: ${file.path}');
        continue;
      }
      final bytes = file.readAsBytesSync();
      final decoder = img.findDecoderForData(bytes);
      if (decoder == null || decoder.startDecode(bytes) == null) {
        error(
          'asset.undecodable',
          at,
          '${file.path} is not a readable image.',
          hint: 'Use JPEG or PNG.',
        );
        continue;
      }
      if (key == (w.lock != null ? 'lock' : 'home')) lockBytes = bytes;
    }

    if (!options.checkContrast || lockBytes == null) return;
    final texts = [
      for (var i = 0; i < spec.lockscreen.elements.length; i++)
        if (isLegibilityChecked(spec.lockscreen.elements[i])) i,
    ];
    if (texts.isEmpty) return;

    final sampler = WallpaperSampler.decode(
      lockBytes,
      overlayAlpha: spec.lockscreen.bgAlpha,
    );
    if (sampler == null) return;
    for (final i in texts) {
      final e = spec.lockscreen.elements[i];
      final bg = sampler.around(e);
      final ratio = textContrast(e.color, bg);
      if (ratio < 3) {
        warn(
          'contrast.text',
          '/lockscreen/elements/$i/color',
          '"${e.name}" text has about ${ratio.toStringAsFixed(1)}:1 contrast '
              'against the wallpaper behind it; aim for at least 3:1.',
          hint:
              'Change the text color, add a stroke, or raise lockscreen.bgAlpha.',
        );
      }
    }
  }
}
