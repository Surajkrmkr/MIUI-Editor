import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/path_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/nine_patch_png.dart';
import '../../core/utils/wallpaper_palette.dart';
import '../../presentation/features/icon_editor/utils/control_center_painter.dart';
import '../../presentation/features/icon_editor/utils/icon_shape_utils.dart';
import '../../presentation/features/icon_editor/utils/icon_visual_utils.dart';
import '../../presentation/providers/icon_editor_provider.dart';
import '../entities/icon_effect.dart';

/// Generates HyperOS 3 control center (`miui.systemui.plugin`), notification
/// shade (`com.android.systemui`), dialer (`com.android.contacts`),
/// messaging (`com.android.mms`) and Settings (`com.android.settings`)
/// modules from the wallpaper and the icon editor's style.
///
/// Value templates live in `assets/modules/hyperos3/<module>/`; their
/// reference colors are re-mapped to the theme palette. Every drawable is
/// drawn from the theme (shape, radius, effect, texture, gradient, accent).
class ExportSystemModulesUseCase {
  const ExportSystemModulesUseCase();

  static const List<String> modules = [
    'miui.systemui.plugin',
    'com.android.systemui',
    'com.android.contacts',
    'com.android.mms',
    'com.android.settings',
  ];

  static const _drawableDir = 'res/drawable-xxhdpi/';

  /// [style] supplies shape, radius, effect, texture and gradient;
  /// [iconFolder] is the active icon pack (used for empty-state art).
  Future<Failure?> call({
    required Color accent,
    required String themePath,
    required String wallpaperSourcePath,
    IconEditorState style = const IconEditorState(),
    String iconFolder = 'u1',
  }) async {
    try {
      // Load every bundled template first so a stale build fails before
      // anything is written (no half-generated modules).
      final templates = await _loadTemplates();
      await _requireAsset('assets/icons/$iconFolder/com.android.mms.svg');

      final palette = await wallpaperPalette(wallpaperSourcePath);
      final cc = CcStyle(template: style.ccTemplate, palette: palette);
      final wall = await _WallpaperBackground.load(wallpaperSourcePath);
      _removeStaleOutputs(themePath);
      await _writeModules(
        themePath,
        wall,
        accent,
        style,
        cc,
        iconFolder,
        templates,
      );
      final missing = missingOutputs(themePath);
      if (missing.isNotEmpty) {
        return ExportFailure(
          'System modules incomplete, missing: ${missing.take(5).join(', ')}',
        );
      }
      return null;
    } catch (e) {
      return ExportFailure('System modules: $e');
    }
  }

  static const _templateFiles = ['theme_values.xml', 'theme_fallback.xml'];

  /// Shade/control-center blur dim; stock (#59555555) is too weak over light
  /// wallpapers for the white controls drawn on top.
  static const _lightWallpaperDim = Color(0x99262626);

  /// Each module is regenerated from scratch; older exports left Sample2's
  /// fixed art (doodle backgrounds, dark dialer, old status-bar icons) and
  /// dark-mode folders here, which would override the generated theme.
  static void _removeStaleOutputs(String themePath) {
    for (final m in modules) {
      final dir = Directory(PathConstants.p('$themePath$m'));
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  }

  Future<Map<String, String>> _loadTemplates() async {
    final out = <String, String>{};
    for (final m in modules) {
      for (final f in _templateFiles) {
        final key = 'assets/modules/hyperos3/$m/$f';
        await _requireAsset(key);
        out[key] = await rootBundle.loadString(key);
      }
    }
    return out;
  }

  static Future<void> _requireAsset(String key) async {
    try {
      await rootBundle.load(key);
    } catch (_) {
      throw StateError(
        'bundled asset "$key" is missing. The app was built before this '
        'asset was added; do a full rebuild (hot reload does not add assets).',
      );
    }
  }

  /// Key generated files that must exist after a successful run (day and
  /// night). Used to reject half-written themes before packing an MTZ.
  static List<String> missingOutputs(String themePath) {
    const required = {
      'miui.systemui.plugin': 'qs_background_enabled.png',
      'com.android.systemui': 'notification_item_bg.9.png',
      'com.android.mms': 'miuix_appcompat_action_button_main_new.png',
      'com.android.settings': 'ic_wifi_settings.png',
    };
    return [
      for (final m in modules) ...[
        if (!File(PathConstants.p('$themePath$m/theme_values.xml'))
            .existsSync())
          '$m/theme_values.xml',
        if (required[m] case final f?
            when !File(PathConstants.p(
              '$themePath$m/$_drawableDir$f',
            )).existsSync())
          '$m/$_drawableDir$f',
      ],
    ];
  }

  Future<void> _writeModules(
    String themePath,
    _WallpaperBackground wall,
    Color accent,
    IconEditorState style,
    CcStyle cc,
    String iconFolder,
    Map<String, String> templates,
  ) async {
    final lightWallpaper = !wall.isDark;
    // Light mode only: apps always draw dark text and dark status-bar icons.
    final pal = SystemPalette(accent, dark: false);
    final look = SurfaceStyle.fromEditor(style, pal);

    for (final m in modules) {
      final dir = PathConstants.p('$themePath$m/');
      await Directory(
        PathConstants.p('$dir$_drawableDir'),
      ).create(recursive: true);
      final values = templates['assets/modules/hyperos3/$m/theme_values.xml']!;
      final remapped = remapValues(
        values,
        pal,
        followWallpaperMode: m != modules.first,
      );
      final themed = switch (m) {
        'miui.systemui.plugin' => withColors(remapped, {
          ...ControlCenterPainter.colors(cc),
          if (lightWallpaper) 'blur_dim_color': _lightWallpaperDim,
        }),
        // Wi-Fi / Bluetooth long-press lists live in SystemUI.
        'com.android.systemui' => withColors(remapped, {
          'control_center_detail_item_selectable_background_color_s':
              cc.palette.primary,
          if (lightWallpaper) ...{
            'shade_dim_color': _lightWallpaperDim,
            'notification_control_center_blur_dim_color': _lightWallpaperDim,
          },
        }),
        // Fills the letter-avatar circle (stock #f4ffffff); black hid it.
        'com.android.contacts' => withColors(remapped, {
          'word_photo_color': Color.lerp(Colors.white, pal.accent, .22)!,
        }),
        _ => remapped,
      };
      await File(
        PathConstants.p('${dir}theme_values.xml'),
      ).writeAsString(themed);
      await File(PathConstants.p('${dir}theme_fallback.xml')).writeAsString(
        templates['assets/modules/hyperos3/$m/theme_fallback.xml']!,
      );
    }

    final w = _Writer(themePath);
    await _controlCenter(w, cc);
    await _notifications(w, pal, look);
    await _messaging(w, pal, look, wall, iconFolder);
    await _dialer(w, pal, look, wall);
    await _settings(w, pal, look, wall, style);
  }

  // ── Colors ──────────────────────────────────────────────────────────────

  static const _refAccents = {0xf97c76, 0xbdfa00};
  static const _refSurfaces = {0xfee0e8, 0xf7f2ec};
  static const _refWhites = {0xffffff, 0xfafafa, 0xf0f0f0};
  static const _refSecondaryGrey = 0x8c93b0;

  /// White entries that are text/icons (already light-on-dark), not surfaces.
  static final _foregroundName = RegExp(
    r'text|clock|date|icon|tint|title|header',
  );

  /// Rewrites reference colors to the palette, keeping each value's alpha.
  /// Fixed semantic colors (red alerts, green call, orange) are untouched.
  @visibleForTesting
  static String remapValues(
    String xml,
    SystemPalette p, {
    required bool followWallpaperMode,
  }) {
    final flip = followWallpaperMode && p.dark;
    var out = xml.replaceAllMapped(
      RegExp(r'(name="([^"]+)"[^>]*>\s*)#([0-9a-fA-F]{8})(?![0-9a-fA-F])'),
      (m) {
        final name = m[2]!;
        final v = int.parse(m[3]!, radix: 16);
        final a = (v >> 24) & 0xff, rgb = v & 0xffffff;
        // Status-bar tints are fixed per background brightness, not per mode.
        final fixed = name.endsWith('_icon_color_single_tone');
        Color? c;
        if (_refAccents.contains(rgb)) {
          c = p.accent;
        } else if (_refSurfaces.contains(rgb)) {
          c = p.surface;
        } else if (rgb == _refSecondaryGrey) {
          c = p.secondary;
        } else if (flip && !fixed && rgb == 0x000000) {
          c = Colors.white;
        } else if (flip &&
            !fixed &&
            _refWhites.contains(rgb) &&
            !_foregroundName.hasMatch(name)) {
          c = p.darkSurface;
        }
        return c == null ? m[0]! : '${m[1]}${_hex(a, c)}';
      },
    );
    if (flip) {
      out = out.replaceFirst(
        'template="LightTemplate"',
        'template="DarkTemplate"',
      );
    }
    return out;
  }

  static String _hex(int alpha, Color c) =>
      '#${alpha.toRadixString(16).padLeft(2, '0')}'
      '${(c.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';

  // ── Control center: miui.systemui.plugin ────────────────────────────────

  Future<void> _controlCenter(_Writer w, CcStyle cc) async {
    const m = 'miui.systemui.plugin';
    for (final state in TileState.values) {
      await w.png(
        m,
        'qs_background_${state.name}.png',
        188,
        188,
        (c, r) => ControlCenterPainter.tile(c, r, state, cc),
      );
    }
    final cr = cc.cardRadius;
    for (final state in [
      TileState.enabled,
      TileState.disabled,
      TileState.unavailable,
    ]) {
      await w.nine(
        m,
        'qs_card_background_${state.name}.9.png',
        210,
        210,
        NinePatchSpec(
          xDivs: const [104, 105],
          yDivs: const [105, 106],
          outlineRadius: cr,
        ),
        (c, r) => ControlCenterPainter.card(c, r, state, cc),
      );
    }
  }

  /// Palette extracted from the wallpaper image (drives control center colours).
  static Future<WallpaperPalette> wallpaperPalette(String path) async {
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    final image = (await codec.getNextFrame()).image;
    try {
      return await WallpaperPalette.fromImage(image);
    } finally {
      image.dispose();
    }
  }

  /// Replaces the values of the named colors (other entries untouched).
  @visibleForTesting
  static String withColors(String xml, Map<String, Color> colors) {
    var out = xml;
    final missing = StringBuffer();
    for (final MapEntry(key: name, value: c) in colors.entries) {
      final hex = c.toARGB32().toRadixString(16).padLeft(8, '0');
      final re = RegExp('(<color name="$name"\\s*>)#[0-9a-fA-F]{6,8}(</color>)');
      if (re.hasMatch(out)) {
        out = out.replaceAllMapped(re, (mm) => '${mm[1]}#$hex${mm[2]}');
      } else {
        missing.writeln('  <color name="$name" >#$hex</color>');
      }
    }
    if (missing.isEmpty) return out;
    final close = out.lastIndexOf('</MIUI_Theme_Values>');
    return '${out.substring(0, close)}$missing${out.substring(close)}';
  }

  // ── Notification shade: com.android.systemui ────────────────────────────

  Future<void> _notifications(
    _Writer w,
    SystemPalette p,
    SurfaceStyle look,
  ) async {
    const m = 'com.android.systemui';
    final cr = look.radius(60, 68);
    for (final (name, color) in [
      ('notification_item_bg.9.png', p.notificationBg),
      ('modal_dialog_bg.9.png', p.dialogBg),
    ]) {
      await w.nine(
        m,
        name,
        138,
        138,
        NinePatchSpec.centre(
          138,
          138,
          radius: cr,
          alpha: (color.a * 255).round(),
        ),
        (c, r) => look.surface(
          c,
          RRect.fromRectAndRadius(r, Radius.circular(cr)),
          color,
        ),
      );
    }
  }

  // ── Messaging: com.android.mms ──────────────────────────────────────────

  Future<void> _messaging(
    _Writer w,
    SystemPalette p,
    SurfaceStyle look,
    _WallpaperBackground wall,
    String iconFolder,
  ) async {
    const m = 'com.android.mms';
    // Compose (+), search and attachment screens use their own backgrounds.
    for (final name in [
      'miuix_appcompat_window_bg_light.9.png',
      'conversation_bg.9.png',
      'search_bg.9.png',
      'attachment_screen_bg.9.png',
      'window_bg_verification_list.9.png',
    ]) {
      await _windowBackground(w, m, name, wall);
    }
    await _bars(w, m, wall, {
      'conversation_actionbar_bg.9.png': (276, true),
      'conversation_actionbar_bottom_bg.9.png': (248, false),
      'message_edit_bottom_panel.9.png': (238, false),
    });

    final br = look.radius(60, 83);
    const bubble = Rect.fromLTWH(0, 0, 168, 168);
    await w.nine(
      m,
      'message_bubble_in_bg_n.9.png',
      168,
      168,
      NinePatchSpec(
        xDivs: const [84, 85],
        yDivs: const [83, 84],
        padding: const [50, 50, 50, 50],
        outlineRadius: br,
      ),
      (c, _) => look.surface(
        c,
        RRect.fromRectAndRadius(bubble, Radius.circular(br)),
        p.bubbleIn,
      ),
    );
    // Outgoing bubbles keep a 36px transparent gutter on the right (status tick).
    for (final name in [
      'message_bubble_out_bg_n.9.png',
      'mi_message_bubble_out_bg_n.9.png',
      'message_bubble_out_last_bg.9.png',
    ]) {
      await w.nine(
        m,
        name,
        204,
        168,
        NinePatchSpec(
          xDivs: const [84, 85],
          yDivs: const [83, 84],
          padding: const [50, 86, 50, 50],
          outlineRadius: br,
        ),
        (c, _) => look.accentSurface(
          c,
          RRect.fromRectAndRadius(bubble, Radius.circular(br)),
        ),
      );
    }
    final fr = look.radius(40, 69);
    await w.nine(
      m,
      'compose_message_editor_bg.9.png',
      200,
      138,
      NinePatchSpec(
        xDivs: const [100, 101],
        yDivs: const [68, 69],
        outlineRadius: fr,
      ),
      (c, r) => look.surface(
        c,
        RRect.fromRectAndRadius(r, Radius.circular(fr)),
        p.field,
      ),
    );
    await _searchField(w, m, p, look);
    await _fab(w, m, look);
    await _emptyArt(
      w,
      m,
      'ic_conversation_empty.png',
      300,
      192,
      'assets/icons/$iconFolder/com.android.mms.svg',
      p,
    );
  }

  // ── Dialer: com.android.contacts ────────────────────────────────────────

  Future<void> _dialer(
    _Writer w,
    SystemPalette p,
    SurfaceStyle look,
    _WallpaperBackground wall,
  ) async {
    const m = 'com.android.contacts';
    await _windowBackground(
      w,
      m,
      'miuix_appcompat_window_bg_light.9.png',
      wall,
    );
    // Stock section header ("A", "B"…) is an opaque white bar; keep it clear
    // so the wallpaper shows, with the reference theme's metrics.
    await w.nine(
      m,
      'list_view_item_group_header_bg_light.9.png',
      144,
      100,
      const NinePatchSpec(
        xDivs: [81, 83],
        yDivs: [57, 58],
        padding: [80, 60, 1, 1],
      ),
      (c, r) {},
    );
    await _bars(w, m, wall, {
      'actionbar_drawable_bg.9.png': (276, true),
      'bottom_navigation_background.9.png': (248, false),
    });
    final kr = look.radius(60, 100);
    await w.nine(
      m,
      'dialerpad_background.9.png',
      200,
      220,
      const NinePatchSpec(
        xDivs: [99, 101],
        yDivs: [219, 220],
        padding: [0, 0, 60, 0],
      ),
      (c, r) => look.surface(
        c,
        RRect.fromRectAndCorners(
          r,
          topLeft: Radius.circular(kr),
          topRight: Radius.circular(kr),
        ),
        p.sheetOver(wall.bottom),
      ),
    );
    await w.png(
      m,
      'dialer_btn_call_bg.png',
      180,
      180,
      (c, r) => look.accentSurface(
        c,
        RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(90)),
      ),
    );
    await _searchField(w, m, p, look);
  }

  // ── Settings: com.android.settings ──────────────────────────────────────

  Future<void> _settings(
    _Writer w,
    SystemPalette p,
    SurfaceStyle look,
    _WallpaperBackground wall,
    IconEditorState style,
  ) async {
    const m = 'com.android.settings';
    await _windowBackground(
      w,
      m,
      'miuix_appcompat_settings_window_bg_light.9.png',
      wall,
    );

    final gr = look.radius(40, 72);
    await w.nine(
      m,
      'miuix_preference_card_group_background_light.9.png',
      247,
      218,
      NinePatchSpec(
        xDivs: const [123, 124],
        yDivs: const [109, 110],
        padding: const [53, 53, 53, 54],
        outlineRadius: gr,
      ),
      (c, r) => look.surface(
        c,
        RRect.fromRectAndRadius(r, Radius.circular(gr)),
        p.card,
      ),
    );
    await w.nine(
      m,
      'search_flexbox_bg.9.png',
      78,
      78,
      const NinePatchSpec(
        xDivs: [38, 39],
        yDivs: [40, 41],
        padding: [14, 14, 14, 14],
        outlineRadius: 39,
      ),
      (c, r) => look.surface(
        c,
        RRect.fromRectAndRadius(r, const Radius.circular(39)),
        p.field,
      ),
    );
    await _searchField(w, m, p, look);

    for (final (i, MapEntry(key: name, value: glyph))
        in _settingsIcons.entries.indexed) {
      await w.png(
        m,
        '$name.png',
        84,
        84,
        (c, r) => _settingsIcon(c, r, style, p, glyph, i),
      );
    }
  }

  /// Settings list icons: theme shape + gradient (hue-shifted per row so the
  /// list stays varied) + the editor's effect and texture + a white glyph.
  void _settingsIcon(
    Canvas c,
    Rect r,
    IconEditorState style,
    SystemPalette p,
    IconData glyph,
    int index,
  ) {
    const shifts = [0.0, 32, -32, 64, -64, 96];
    // Small list icons need a saturated, mid-dark base so the white glyph reads.
    Color legible(Color c, double hue) {
      final h = HSLColor.fromColor(c);
      return h
          .withHue(hue % 360)
          .withSaturation(h.saturation.clamp(.55, 1.0))
          .withLightness(h.lightness.clamp(.36, .5))
          .toColor();
    }

    final hue =
        HSLColor.fromColor(style.bgColor).hue +
        shifts[index % shifts.length] +
        360;
    final from = legible(style.bgColor, hue);
    final to = legible(style.bgColor2, hue + 18);
    final path = IconShapeUtils.path(
      style.shape,
      r.deflate(1),
      radius: style.radius,
    );
    c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [from, to]),
    );
    final k = r.width / 45;
    IconVisualUtils.applyTexture(
      c,
      path,
      style.texture,
      r,
      scale: style.textureScale,
      opacity: style.textureOpacity * .35,
    );
    IconVisualUtils.applyEffect(
      c,
      path,
      style.effect,
      r,
      from,
      // 84px list icons blur out under full-strength glows; keep effects as a hint.
      intensity: (style.effectIntensity * .4).clamp(0.0, .3),
      blur: style.effectBlur * k,
      elevation: style.effectElevation * k,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          fontFamily: glyph.fontFamily,
          package: glyph.fontPackage,
          fontSize: r.width * .56,
          color: style.iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, r.center - Offset(tp.width / 2, tp.height / 2));
  }

  static const Map<String, IconData> _settingsIcons = {
    'ic_wifi_settings': Icons.wifi_rounded,
    'ic_bluetooth_settings': Icons.bluetooth_rounded,
    'ic_settings_dualsim': Icons.swap_vert_rounded,
    'ic_portable_wlan_hotspot_settings': Icons.wifi_tethering_rounded,
    'ic_vpn': Icons.vpn_key_rounded,
    'ic_device_connection': Icons.link_rounded,
    'ic_display_settings': Icons.light_mode_rounded,
    'ic_sound_settings': Icons.volume_up_rounded,
    'ic_notification_center': Icons.notifications_rounded,
    'ic_ringtone_notification': Icons.notifications_active_rounded,
    'ic_miui_home_settings': Icons.home_rounded,
    'ic_unlock_set_settings': Icons.lock_rounded,
    'ic_security_settings_settings': Icons.fingerprint_rounded,
    'ic_privacy_protection': Icons.privacy_tip_rounded,
    'ic_battery_settings': Icons.battery_full_rounded,
    'ic_system_app_settings': Icons.settings_rounded,
    'ic_account_settings': Icons.person_rounded,
    'ic_accessibility_generic': Icons.accessibility_new_rounded,
    'ic_app_timer': Icons.hourglass_bottom_rounded,
    'healthy_use_device_icon': Icons.spa_rounded,
    'ic_other_advanced_settings': Icons.more_horiz_rounded,
    'ic_user_guide': Icons.touch_app_rounded,
    'ic_vip_service_settings': Icons.favorite_rounded,
    'ic_bugreport_settings': Icons.help_rounded,
    'ic_my_device': Icons.smartphone_rounded,
    'ic_hyper_ai': Icons.auto_awesome_rounded,
    'ic_interconnection': Icons.devices_rounded,
    'ic_minors_control': Icons.child_care_rounded,
    'ic_security_center_settings': Icons.security_rounded,
    'ic_settings_satellite': Icons.satellite_alt_rounded,
    'ic_alarms_ring': Icons.alarm_rounded,
    'ic_telephone_ring': Icons.call_rounded,
    'com_android_thememanager': Icons.palette_rounded,
    'wallet_icon': Icons.account_balance_wallet_rounded,
    'ic_enhanced': Icons.system_update_rounded,
  };

  // ── Shared app pieces ───────────────────────────────────────────────────

  /// The wallpaper itself as an app window background; only thin top and
  /// bottom bands stretch, so the image is never distorted.
  Future<void> _windowBackground(
    _Writer w,
    String m,
    String name,
    _WallpaperBackground wall,
  ) => w.nine(
    m,
    name,
    _WallpaperBackground._w,
    _WallpaperBackground._h,
    const NinePatchSpec(
      xDivs: [0, _WallpaperBackground._w],
      yDivs: [0, 24, _WallpaperBackground._h - 23, _WallpaperBackground._h],
    ),
    (c, r) => c.drawImage(wall.image, Offset.zero, Paint()),
  );

  /// Solid bars tinted to the wallpaper edge they sit on, so they blend in.
  Future<void> _bars(
    _Writer w,
    String m,
    _WallpaperBackground wall,
    Map<String, (int, bool)> bars,
  ) async {
    for (final MapEntry(key: name, value: (h, top)) in bars.entries) {
      await w.nine(
        m,
        name,
        1080,
        h,
        NinePatchSpec(xDivs: const [0, 1080], yDivs: top ? [h - 1, h] : [0, h]),
        (c, r) => c.drawRect(r, Paint()..color = top ? wall.top : wall.bottom),
      );
    }
  }

  Future<void> _searchField(
    _Writer w,
    String m,
    SystemPalette p,
    SurfaceStyle look,
  ) => w.nine(
    m,
    'miuix_appcompat_search_mode_edit_text_bg_light.9.png',
    130,
    120,
    // Dialer and messaging/settings ship slightly different centre bands.
    m == 'com.android.contacts'
        ? const NinePatchSpec(
            xDivs: [64, 66],
            yDivs: [59, 61],
            outlineRadius: 60,
          )
        : const NinePatchSpec(
            xDivs: [65, 66],
            yDivs: [59, 60],
            outlineRadius: 60,
          ),
    (c, r) => look.surface(
      c,
      RRect.fromRectAndRadius(r, const Radius.circular(60)),
      p.field,
    ),
  );

  /// The theme replaces the FAB background, so it must also ship the glyph.
  Future<void> _fab(_Writer w, String m, SurfaceStyle look) async {
    await w.png(
      m,
      'miuix_appcompat_fab_empty_holder.png',
      190,
      190,
      (c, r) => look.accentSurface(
        c,
        RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(95)),
      ),
    );
    await w.png(m, 'miuix_appcompat_action_button_main_new.png', 180, 180, (
      c,
      r,
    ) {
      final plus = Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      c.drawLine(const Offset(90, 52), const Offset(90, 128), plus);
      c.drawLine(const Offset(52, 90), const Offset(128, 90), plus);
    });
  }

  /// Empty-state illustration drawn from the active icon pack's glyph.
  Future<void> _emptyArt(
    _Writer w,
    String m,
    String name,
    int width,
    int height,
    String svgAsset,
    SystemPalette p,
  ) async {
    final info = await vg.loadPicture(SvgAssetLoader(svgAsset), null);
    try {
      await w.png(m, name, width, height, (c, r) {
        final side = height * .9;
        final s = side / info.size.longestSide;
        c.save();
        c.translate(
          r.center.dx - info.size.width * s / 2,
          r.center.dy - info.size.height * s / 2,
        );
        c.scale(s);
        c.saveLayer(
          Offset.zero & info.size,
          Paint()
            ..colorFilter = ColorFilter.mode(
              p.accent.withValues(alpha: .55),
              BlendMode.srcIn,
            ),
        );
        c.drawPicture(info.picture);
        c.restore();
        c.restore();
      });
    } finally {
      info.picture.dispose();
    }
  }
}

/// How surfaces (cards, bubbles, fields) are painted, derived from the icon
/// editor so system modules share the icons' design language.
class SurfaceStyle {
  SurfaceStyle._(
    this.roundness,
    this.kind,
    this.accent,
    this.accent2,
    this.dark,
  );

  factory SurfaceStyle.fromEditor(IconEditorState s, SystemPalette p) {
    final kind = switch (s.effect) {
      IconEffect.liquidGlass ||
      IconEffect.glass ||
      IconEffect.gloss ||
      IconEffect.holographic ||
      IconEffect.aurora => SurfaceKind.glass,
      IconEffect.clay ||
      IconEffect.softUi ||
      IconEffect.bevel => SurfaceKind.soft,
      IconEffect.neon => SurfaceKind.outline,
      _ => SurfaceKind.flat,
    };
    final second = HSLColor.fromColor(p.accent);
    return SurfaceStyle._(
      (s.radius / IconShapeUtils.maxRadius).clamp(0.0, 1.0),
      kind,
      p.accent,
      second.withHue((second.hue + 28) % 360).toColor(),
      p.dark,
    );
  }

  /// 0..1 from the editor's Radius slider.
  final double roundness;
  final SurfaceKind kind;
  final Color accent, accent2;
  final bool dark;

  /// Corner radius between [sharp] (Radius 0) and [round] (Radius max).
  double radius(double sharp, double round) =>
      sharp + (round - sharp) * roundness;

  void surface(Canvas c, RRect rr, Color fill) {
    switch (kind) {
      case SurfaceKind.flat:
        c.drawRRect(rr, Paint()..color = fill);
      case SurfaceKind.glass:
        c.drawRRect(rr, Paint()..color = fill);
        c.drawRRect(
          rr,
          Paint()
            ..shader = ui.Gradient.linear(
              rr.outerRect.topLeft,
              rr.outerRect.bottomCenter,
              [
                Colors.white.withValues(alpha: dark ? .14 : .4),
                Colors.white.withValues(alpha: 0),
              ],
            ),
        );
        c.drawRRect(
          rr.deflate(1.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white.withValues(alpha: dark ? .22 : .7),
        );
      case SurfaceKind.soft:
        c.drawRRect(rr, Paint()..color = fill);
        c.drawRRect(
          rr.deflate(2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..shader = ui.Gradient.linear(
              rr.outerRect.topLeft,
              rr.outerRect.bottomRight,
              [
                Colors.white.withValues(alpha: dark ? .12 : .6),
                Colors.black.withValues(alpha: dark ? .25 : .08),
              ],
            ),
        );
      case SurfaceKind.outline:
        c.drawRRect(rr, Paint()..color = fill.withValues(alpha: fill.a * .5));
        c.drawRRect(
          rr.deflate(2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = accent.withValues(alpha: .8),
        );
    }
  }

  /// Accent-filled surfaces (outgoing bubbles, FAB, call button).
  void accentSurface(Canvas c, RRect rr) {
    final r = rr.outerRect;
    final paint = kind == SurfaceKind.flat
        ? (Paint()..color = accent)
        : (Paint()
            ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [
              accent,
              accent2,
            ]));
    c.drawRRect(rr, paint);
    if (kind == SurfaceKind.glass) {
      c.drawRRect(
        rr.deflate(1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: .35),
      );
    }
  }
}

enum SurfaceKind { flat, glass, soft, outline }

/// Theme colours for the system modules, derived from the accent and whether
/// the wallpaper is dark.
class SystemPalette {
  SystemPalette(this.accent, {required this.dark});

  final Color accent;
  final bool dark;

  Color get surface => dark
      ? Color.lerp(const Color(0xff121212), accent, .18)!
      : Color.lerp(Colors.white, accent, .16)!;
  Color get darkSurface => Color.lerp(const Color(0xff1c1c1e), accent, .08)!;

  /// Dark-mode app background and list-card colours, tinted by the accent.

  /// Secondary text grey, tinted toward the accent.
  Color get secondary => Color.lerp(const Color(0xff8a8f99), accent, .3)!;
  Color get notificationBg => dark
      ? darkSurface.withValues(alpha: .92)
      : Color.lerp(
          const Color(0xfffafafa),
          accent,
          .04,
        )!.withValues(alpha: .95);
  Color get dialogBg => notificationBg.withValues(alpha: .98);
  Color get card => dark
      ? darkSurface.withValues(alpha: .86)
      : Color.lerp(Colors.white, accent, .03)!.withValues(alpha: .84);
  Color get bubbleIn => dark
      ? Colors.white.withValues(alpha: .12)
      : Colors.white.withValues(alpha: .7);
  Color get field => dark
      ? Colors.white.withValues(alpha: .1)
      : Colors.black.withValues(alpha: .06);

  /// Slightly lifted sheet over a wallpaper edge colour (dialer keypad).
  Color sheetOver(Color edge) =>
      Color.lerp(edge, dark ? Colors.black : Colors.white, .35)!;
}

/// Wallpaper cover-cropped to 1080×2400 (20:9) with a light/dark veil, plus
/// the averaged edge colours used to tint bars.
class _WallpaperBackground {
  _WallpaperBackground(this.image, this.top, this.bottom, this.isDark);

  final ui.Image image;
  final Color top, bottom;
  final bool isDark;

  static const _w = 1080, _h = 2400;

  static Future<_WallpaperBackground> load(String path) async {
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    final src = (await codec.getNextFrame()).image;

    final cover = _cover(src.width.toDouble(), src.height.toDouble());
    final luminance = await _luminance(src, cover);
    final dark = luminance < .45;
    // Lift every wallpaper to >= .78 luminance so dark text/icons stay legible.
    const target = .78;
    final veil = luminance >= target
        ? .18
        : ((target - luminance) / (1 - luminance)).clamp(.18, .82);

    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    const dst = Rect.fromLTWH(0, 0, 1080, 2400);
    c.drawImageRect(
      src,
      cover,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
    c.drawRect(
      dst,
      Paint()..color = Colors.white.withValues(alpha: veil),
    );
    final image = await rec.endRecording().toImage(_w, _h);
    src.dispose();

    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return _WallpaperBackground(
      image,
      _average(rgba, 0, 276),
      _average(rgba, _h - 248, _h),
      dark,
    );
  }

  static Rect _cover(double w, double h) {
    const aspect = _w / _h;
    if (w / h > aspect) {
      final cw = h * aspect;
      return Rect.fromLTWH((w - cw) / 2, 0, cw, h);
    }
    final ch = w / aspect;
    return Rect.fromLTWH(0, (h - ch) / 2, w, ch);
  }

  static Future<double> _luminance(ui.Image src, Rect cover) async {
    final rec = ui.PictureRecorder();
    Canvas(
      rec,
    ).drawImageRect(src, cover, const Rect.fromLTWH(0, 0, 54, 96), Paint());
    final small = await rec.endRecording().toImage(54, 96);
    final data = (await small.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    small.dispose();
    var sum = 0.0;
    final n = data.lengthInBytes ~/ 4;
    for (var i = 0; i < n; i++) {
      final o = i * 4;
      sum +=
          (.2126 * data.getUint8(o) +
              .7152 * data.getUint8(o + 1) +
              .0722 * data.getUint8(o + 2)) /
          255;
    }
    return sum / n;
  }

  static Color _average(ByteData rgba, int y0, int y1) {
    var r = 0, g = 0, b = 0, n = 0;
    for (var y = y0; y < y1; y += 4) {
      for (var x = 0; x < _w; x += 8) {
        final o = (y * _w + x) * 4;
        r += rgba.getUint8(o);
        g += rgba.getUint8(o + 1);
        b += rgba.getUint8(o + 2);
        n++;
      }
    }
    return Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
  }
}

class _Writer {
  _Writer(this.themePath);
  final String themePath;

  Future<Uint8List> _render(
    int w,
    int h,
    void Function(Canvas, Rect) draw,
  ) async {
    final rec = ui.PictureRecorder();
    final rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    draw(Canvas(rec, rect), rect);
    final img = await rec.endRecording().toImage(w, h);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return bytes!.buffer.asUint8List();
  }

  Future<void> _save(String module, String name, Uint8List bytes) async {
    final dir = '$themePath$module/${ExportSystemModulesUseCase._drawableDir}';
    await File(PathConstants.p('$dir$name')).writeAsBytes(bytes);
  }

  Future<void> png(
    String module,
    String name,
    int w,
    int h,
    void Function(Canvas, Rect) draw,
  ) async => _save(module, name, await _render(w, h, draw));

  Future<void> nine(
    String module,
    String name,
    int w,
    int h,
    NinePatchSpec spec,
    void Function(Canvas, Rect) draw,
  ) async {
    assert(name.endsWith('.9.png'));
    await _save(
      module,
      name,
      NinePatchPng.compile(await _render(w, h, draw), spec),
    );
  }
}
