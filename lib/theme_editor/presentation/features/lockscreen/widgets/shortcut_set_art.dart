import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/element_widget.dart';
import 'shortcut_glyphs.dart';

class _TileLook {
  const _TileLook({
    required this.fill,
    required this.kind,
    required this.ink,
    required this.radius,
    required this.shadow,
    this.inkGradient,
    this.detail = Colors.white,
    this.glyphScale = .56,
    this.glyphGloss = false,
    this.tileGloss = false,
    this.colorful = false,
    this.hex = false,
    this.border,
    this.badge,
    this.glyphShadow = false,
  });
  final Gradient fill;
  final GlyphKind? kind;
  final Color ink, detail;
  final Gradient? inkGradient;
  final BorderRadius radius;
  final List<BoxShadow> shadow;
  final double glyphScale;
  final bool glyphGloss, tileGloss, colorful;
  final bool hex;
  final BorderSide? border;

  /// Soft drop shadow under the glyph so it looks raised off the tile.
  final bool glyphShadow;

  /// Dark rounded badge drawn behind the glyph.
  final Gradient? badge;
}

/// App that a shortcut tile opens; [iconType] supplies package/class for MAML.
enum ShortcutApp {
  messages(
    'Messages',
    Icons.chat_bubble_rounded,
    ElementType.mmsIcon,
    Color(0xFF34C759),
  ),
  camera(
    'Camera',
    Icons.camera_alt_rounded,
    ElementType.cameraIcon,
    Color(0xFF4A8BF5),
  ),
  music(
    'Music',
    Icons.music_note_rounded,
    ElementType.musicIcon,
    Color(0xFFFC3C6E),
  ),
  browser(
    'Browser',
    Icons.explore_rounded,
    ElementType.browserIcon,
    Color(0xFF3D7BF7),
  ),
  whatsapp(
    'WhatsApp',
    Icons.call_rounded,
    ElementType.whatsAppIcon,
    Color(0xFF25D366),
  ),
  phone('Phone', Icons.call_rounded, ElementType.dialerIcon, Color(0xFF34C759)),
  settings(
    'Settings',
    Icons.settings_rounded,
    ElementType.settingIcon,
    Color(0xFF8E8E93),
  ),
  flashlight(
    'Flashlight',
    Icons.flashlight_on_rounded,
    null,
    Color(0xFFFFC107),
  ),
  gallery(
    'Gallery',
    Icons.photo_rounded,
    ElementType.galleryIcon,
    Color(0xFFFF9500),
  ),
  contacts(
    'Contacts',
    Icons.contacts_rounded,
    ElementType.contactIcon,
    Color(0xFF5AC8FA),
  ),
  calendar(
    'Calendar',
    Icons.calendar_month_rounded,
    ElementType.calendarIcon,
    Color(0xFFFF3B30),
  ),
  clock(
    'Clock',
    Icons.schedule_rounded,
    ElementType.clockIcon,
    Color(0xFF1C1C1E),
  ),
  notes(
    'Notes',
    Icons.sticky_note_2_rounded,
    ElementType.notesIcon,
    Color(0xFFFFCC00),
  ),
  calculator(
    'Calculator',
    Icons.calculate_rounded,
    ElementType.calculatorIcon,
    Color(0xFFFF9500),
  ),
  weather(
    'Weather',
    Icons.wb_sunny_rounded,
    ElementType.weatherIcon,
    Color(0xFF5AC8FA),
  ),
  telegram(
    'Telegram',
    Icons.send_rounded,
    ElementType.telegramIcon,
    Color(0xFF2AABEE),
  ),
  instagram(
    'Instagram',
    Icons.photo_camera_outlined,
    ElementType.instagramIcon,
    Color(0xFFE1306C),
  ),
  spotify(
    'Spotify',
    Icons.graphic_eq_rounded,
    ElementType.spotifyIcon,
    Color(0xFF1DB954),
  ),
  theme(
    'Themes',
    Icons.palette_rounded,
    ElementType.themeIcon,
    Color(0xFFAF52DE),
  ),
  facebook(
    'Facebook',
    Icons.facebook_rounded,
    null,
    Color(0xFF1877F2),
    'com.facebook.katana',
    'com.facebook.katana.LoginActivity',
  ),
  video(
    'Video',
    Icons.play_circle_rounded,
    ElementType.videoIcon,
    Color(0xFFFF5A5F),
  );

  const ShortcutApp(
    this.label,
    this.icon,
    this.iconType,
    this.brand, [
    this.package,
    this.activity,
  ]);
  final String label;
  final IconData icon;
  final ElementType? iconType;
  final Color brand;

  /// Launch target for apps without a single-icon element.
  final String? package, activity;

  static List<ShortcutApp> parse(String keys) => [
    for (final key in keys.split(','))
      if (ShortcutApp.values.where((a) => a.name == key.trim()).firstOrNull
          case final app?)
        app,
  ];
}

bool _isDock(ShortcutStyle s) =>
    s == ShortcutStyle.glossDock ||
    s == ShortcutStyle.darkDock ||
    s == ShortcutStyle.pastelDock ||
    s == ShortcutStyle.neonCapsule ||
    s == ShortcutStyle.candyCapsule;

bool _isCapsule(ShortcutStyle s) =>
    s == ShortcutStyle.neonCapsule || s == ShortcutStyle.candyCapsule;

/// Dock styles whose panel can sit on the left, right or away from the edge.
bool supportsShortcutEdge(ShortcutStyle s) => _isDock(s) && !_isCapsule(s);

ShortcutEdge _edgeOf(LockElement el) => supportsShortcutEdge(el.shortcutStyle)
    ? el.shortcutEdge
    : ShortcutEdge.floating;

/// Geometry in theme pixels (before `scale`), shared by preview and export.
class ShortcutSetLayout {
  const ShortcutSetLayout._(this.size, this.tiles, this.panel);

  factory ShortcutSetLayout.of(LockElement el) {
    final n = ShortcutApp.parse(el.shortcutApps).length;
    final w = el.width;
    switch (el.shortcutStyle) {
      case ShortcutStyle.socialRow:
      case ShortcutStyle.softRow:
      case ShortcutStyle.glossOrbs:
        final tile = w / (n + max(0, n - 1) * .18 + .5);
        final pad = tile * .25;
        final h = tile + pad * 2;
        return ShortcutSetLayout._(Size(w, h), [
          for (var i = 0; i < n; i++)
            Rect.fromLTWH(pad + i * tile * 1.18, pad, tile, tile),
        ], Offset.zero & Size(w, h));
      case ShortcutStyle.hexGrid:
        final gap = w * .045;
        final tile = (w - gap * 1.5) / 2.5;
        final rows = (n + 1) ~/ 2;
        return ShortcutSetLayout._(
          Size(w, max(1, tile + max(0, rows - 1) * tile * .9)),
          [
            for (var i = 0; i < n; i++)
              Rect.fromLTWH(
                (i % 2) * (tile + gap) +
                    ((i ~/ 2).isOdd ? (tile + gap) / 2 : 0),
                (i ~/ 2) * tile * .9,
                tile,
                tile,
              ),
          ],
          null,
        );
      default:
    }
    if (el.shortcutStyle == ShortcutStyle.socialCards) {
      final h = w * .4;
      final gap = w * .07;
      return ShortcutSetLayout._(Size(w, max(1, n * h + max(0, n - 1) * gap)), [
        for (var i = 0; i < n; i++) Rect.fromLTWH(0, i * (h + gap), w, h),
      ], null);
    }
    if (_isDock(el.shortcutStyle)) {
      final neon = _isCapsule(el.shortcutStyle);
      final tile = w * (neon ? .62 : .64);
      final gap = tile * (neon ? .3 : .12);
      final top = tile * (neon ? .6 : .55);
      final h = top * 2 + n * tile + max(0, n - 1) * gap;
      final x = switch (_edgeOf(el)) {
        ShortcutEdge.right => w * .13,
        ShortcutEdge.left => w - w * .13 - tile,
        ShortcutEdge.floating => (w - tile) / 2,
      };
      return ShortcutSetLayout._(Size(w, h), [
        for (var i = 0; i < n; i++)
          Rect.fromLTWH(x, top + i * (tile + gap), tile, tile),
      ], Offset.zero & Size(w, h));
    }
    final gap = w * .07;
    final tile = (w - gap) / 2;
    final rows = (n + 1) ~/ 2;
    return ShortcutSetLayout._(
      Size(w, max(1, rows * tile + max(0, rows - 1) * gap)),
      [
        for (var i = 0; i < n; i++)
          Rect.fromLTWH(
            (i % 2) * (tile + gap),
            (i ~/ 2) * (tile + gap),
            tile,
            tile,
          ),
      ],
      null,
    );
  }

  final Size size;
  final List<Rect> tiles;
  final Rect? panel;
}

/// Renders panel and tiles; `k` converts theme pixels to logical pixels.
class ShortcutSetArt {
  const ShortcutSetArt._();

  static Widget panel(LockElement el, double k) {
    final l = ShortcutSetLayout.of(el);
    final p = l.panel!;
    final opacity = el.unlockBackgroundOpacity.clamp(0, 1).toDouble();
    final base = el.colorSecondary;
    if (el.shortcutStyle == ShortcutStyle.neonCapsule) {
      final glow = el.borderColor;
      return Container(
        width: p.width * k,
        height: p.height * k,
        decoration: BoxDecoration(
          color: base.withValues(alpha: base.a * opacity),
          borderRadius: BorderRadius.circular(p.width / 2 * k),
          border: Border.all(
            color: Color.lerp(glow, Colors.white, .35)!,
            width: max(el.borderWidth, p.width * .014) * k,
          ),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: .75),
              blurRadius: p.width * .07 * k,
            ),
            BoxShadow(
              color: glow.withValues(alpha: .3),
              blurRadius: p.width * .2 * k,
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(p.width / 2 * k),
            gradient: RadialGradient(
              radius: .9,
              colors: [base.withValues(alpha: 0), glow.withValues(alpha: .18)],
              stops: const [.75, 1],
            ),
          ),
        ),
      );
    }
    final corner = Radius.circular(p.width * .2 * k);
    if (el.shortcutStyle == ShortcutStyle.softRow) {
      return Container(
        width: p.width * k,
        height: p.height * k,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(p.height / 2 * k),
          gradient: LinearGradient(
            colors: [
              base,
              Color.lerp(base, Colors.black, .28)!,
              base,
              Color.lerp(base, Colors.black, .22)!,
              base,
            ],
            stops: const [0, .4, .5, .62, 1],
          ).withOpacity(opacity),
        ),
      );
    }
    if (el.shortcutStyle == ShortcutStyle.glossOrbs) {
      return Container(
        width: p.width * k,
        height: p.height * k,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(p.height * .3 * k),
          gradient: LinearGradient(
            colors: [
              base,
              Color.lerp(base, Colors.white, .12)!,
              Color.lerp(base, Colors.black, .08)!,
              base,
            ],
          ).withOpacity(opacity),
          border: Border.all(
            color: el.borderColor.withValues(alpha: .4),
            width: max(el.borderWidth, p.height * .02) * k,
          ),
        ),
      );
    }
    if (el.shortcutStyle == ShortcutStyle.candyCapsule) {
      return Container(
        width: p.width * k,
        height: p.height * k,
        decoration: BoxDecoration(
          color: base.withValues(alpha: base.a * opacity),
          borderRadius: BorderRadius.circular(p.width / 2 * k),
        ),
      );
    }
    return Container(
      width: p.width * k,
      height: p.height * k,
      decoration: BoxDecoration(
        borderRadius: el.shortcutStyle == ShortcutStyle.socialRow
            ? BorderRadius.circular(p.height * .28 * k)
            : switch (_edgeOf(el)) {
                ShortcutEdge.right => BorderRadius.horizontal(left: corner),
                ShortcutEdge.left => BorderRadius.horizontal(right: corner),
                ShortcutEdge.floating => BorderRadius.all(corner),
              },
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(base, Colors.white, .15)!,
            base,
            Color.lerp(base, Colors.black, .12)!,
          ].map((c) => c.withValues(alpha: c.a * opacity)).toList(),
        ),
        border: el.borderWidth > 0
            ? Border.all(
                color: el.borderColor.withValues(alpha: .5),
                width: el.borderWidth * k,
              )
            : null,
      ),
    );
  }

  static Widget tile(LockElement el, int index, double k) {
    final l = ShortcutSetLayout.of(el);
    final app = ShortcutApp.parse(el.shortcutApps)[index];
    final rect = l.tiles[index];
    final w = rect.width * k, h = rect.height * k;
    if (el.shortcutStyle == ShortcutStyle.socialCards) {
      return _socialCard(el, app, w, h);
    }
    final s = min(w, h);
    final look = _look(el, app, index, s);
    final glyphSize =
        s * look.glyphScale * el.unlockIconScale.clamp(.2, 1) / .6;
    Widget glyph = look.kind == null
        ? Icon(app.icon, size: glyphSize, color: look.ink)
        : CustomPaint(
            size: Size.square(glyphSize),
            painter: GlyphPainter(
              look.kind!,
              ink: look.ink,
              gradient: look.inkGradient,
              detail: look.detail,
              gloss: look.glyphGloss,
              colorful: look.colorful,
            ),
          );
    if (look.glyphShadow && look.kind != null) {
      glyph = Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(0, glyphSize * .07),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: glyphSize * .05,
                sigmaY: glyphSize * .05,
              ),
              child: CustomPaint(
                size: Size.square(glyphSize),
                painter: GlyphPainter(
                  look.kind!,
                  ink: Colors.black.withValues(alpha: .3),
                  detail: Colors.black.withValues(alpha: .3),
                ),
              ),
            ),
          ),
          glyph,
        ],
      );
    }
    if (look.badge case final badge?) {
      glyph = Container(
        width: glyphSize * 1.75,
        height: glyphSize * 1.75,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: badge,
          borderRadius: BorderRadius.circular(glyphSize * .4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .35),
              blurRadius: glyphSize * .15,
              offset: Offset(0, glyphSize * .06),
            ),
          ],
        ),
        child: glyph,
      );
    }
    final shape = look.hex
        ? const _HexBorder()
        : RoundedRectangleBorder(borderRadius: look.radius);
    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          gradient: look.fill,
          shadows: look.shadow,
        ),
        position: DecorationPosition.background,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(
            shape: look.border == null
                ? shape
                : RoundedRectangleBorder(
                    borderRadius: look.radius,
                    side: look.border!,
                  ),
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (look.tileGloss)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: h * .45,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: .16),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                glyph,
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _socialCard(
    LockElement el,
    ShortcutApp app,
    double w,
    double h,
  ) {
    final card = el.colorSecondary;
    final (title, tagline, badge) = switch (app) {
      ShortcutApp.whatsapp => (
        const [Color(0xFF8ACB6F), Color(0xFF4E9A4B)],
        'Connect with your close ones.',
        Icon(
          Icons.done_all_rounded,
          size: h * .14,
          color: const Color(0xFF5B8ED8),
        ),
      ),
      ShortcutApp.instagram => (
        const [Color(0xFFE86AA8), Color(0xFF8A3FF0)],
        "It's time to post your clicks.",
        SizedBox(
          width: h * .2,
          height: h * .16,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                bottom: 0,
                child: Icon(
                  Icons.favorite_rounded,
                  size: h * .1,
                  color: const Color(0xFFD9534F),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.favorite_rounded,
                  size: h * .07,
                  color: const Color(0xFFD9534F),
                ),
              ),
            ],
          ),
        ),
      ),
      ShortcutApp.facebook => (
        const [Color(0xFF86A6FF), Color(0xFF4B4BD8)],
        "Let's celebrate friendship.",
        Icon(
          Icons.thumb_up_rounded,
          size: h * .14,
          color: const Color(0xFF8AA6CF),
        ),
      ),
      _ => (
        [Color.lerp(app.brand, Colors.white, .35)!, app.brand],
        'Open ${app.label}.',
        Icon(app.icon, size: h * .13, color: app.brand),
      ),
    };
    final iconSize = h * .66;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: card.withValues(
                  alpha: card.a * el.unlockBackgroundOpacity.clamp(0, 1),
                ),
                borderRadius: BorderRadius.circular(h * .17),
              ),
            ),
          ),
          Positioned(
            left: w * .05,
            top: h * .3,
            child: Text(
              app.label.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                fontSize: h * .3,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: h * .02,
                height: 1,
                color: Colors.white.withValues(alpha: .035),
              ),
            ),
          ),
          Positioned(left: w * .085, top: h * .17, child: badge),
          Positioned(
            left: w * .085,
            top: h * .44,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: LinearGradient(colors: title).createShader,
              child: Text(
                app.label,
                style: TextStyle(
                  fontSize: h * .17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: h * .008,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: w * .11,
            top: h * .7,
            child: Text(
              tagline,
              style: TextStyle(
                fontSize: h * .075,
                height: 1,
                letterSpacing: h * .003,
                color: el.color,
              ),
            ),
          ),
          Positioned(
            right: w * .04,
            top: -h * .2,
            width: iconSize,
            height: iconSize,
            child: _socialIcon(app, iconSize, card),
          ),
        ],
      ),
    );
  }

  /// Big glossy app badge that overlaps the card edge and fades into it.
  static Widget _socialIcon(ShortcutApp app, double s, Color card) {
    final round = app == ShortcutApp.whatsapp;
    final (top, bottom) = switch (app) {
      ShortcutApp.whatsapp => (
        const Color(0xFF7CC66A),
        const Color(0xFF3E8E3A),
      ),
      ShortcutApp.instagram => (
        const Color(0xFF9A3F8E),
        const Color(0xFF2A1630),
      ),
      ShortcutApp.facebook => (
        const Color(0xFF5257B5),
        const Color(0xFF1E2148),
      ),
      _ => (
        Color.lerp(app.brand, Colors.white, .15)!,
        Color.lerp(app.brand, Colors.black, .55)!,
      ),
    };
    const silver = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF2F2F2), Color(0xFF9A9A9A)],
    );
    final glyph = switch (app) {
      ShortcutApp.whatsapp => CustomPaint(
        size: Size.square(s * .5),
        painter: const GlyphPainter(
          GlyphKind.handset,
          ink: Color(0xFFBDBDBD),
          gradient: silver,
        ),
      ),
      ShortcutApp.instagram => CustomPaint(
        size: Size.square(s * .6),
        painter: const GlyphPainter(
          GlyphKind.instagram,
          ink: Colors.white,
          gradient: silver,
        ),
      ),
      ShortcutApp.facebook => CustomPaint(
        size: Size.square(s),
        painter: const GlyphPainter(
          GlyphKind.facebookF,
          ink: Colors.white,
          gradient: silver,
        ),
      ),
      _ => Icon(app.icon, size: s * .5, color: Colors.white),
    };
    final radius = BorderRadius.circular(round ? s / 2 : s * .2);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: round ? silver : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .55),
            blurRadius: s * .12,
            offset: Offset(0, s * .06),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(round ? s * .07 : 0),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [top, bottom],
                  ),
                ),
              ),
              Center(child: glyph),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      card.withValues(alpha: 0),
                      card.withValues(alpha: .85),
                    ],
                    stops: const [.6, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static LinearGradient _vertical(Color top, Color bottom) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, bottom],
  );

  static LinearGradient _diagonal(Color a, Color b) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [a, b],
  );

  static _TileLook _look(LockElement el, ShortcutApp app, int index, double s) {
    final soft = [
      BoxShadow(
        color: Colors.black.withValues(alpha: .28),
        blurRadius: s * .09,
        offset: Offset(0, s * .045),
      ),
    ];
    switch (el.shortcutStyle) {
      case ShortcutStyle.glossDock:
        final navy = el.unlockAccent;
        final light = el.borderColor;
        final navyTile = _vertical(Color.lerp(navy, Colors.white, .14)!, navy);
        final lightTile = _vertical(Colors.white, light);
        final dark = _vertical(Color.lerp(navy, Colors.white, .1)!, navy);
        return switch (app) {
          ShortcutApp.gallery => _TileLook(
            fill: navyTile,
            kind: GlyphKind.gallery,
            ink: el.color,
            inkGradient: _vertical(el.color, Color.lerp(el.color, navy, .28)!),
            glyphGloss: true,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.camera => _TileLook(
            fill: navyTile,
            kind: GlyphKind.lens,
            ink: el.color,
            detail: const Color(0xFF5E73D8),
            glyphScale: .66,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.music => _TileLook(
            fill: lightTile,
            kind: GlyphKind.note,
            ink: navy,
            inkGradient: dark,
            glyphGloss: true,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.browser => _TileLook(
            fill: lightTile,
            kind: GlyphKind.compass,
            ink: navy,
            inkGradient: dark,
            detail: navy,
            glyphScale: .7,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.whatsapp => _TileLook(
            fill: _vertical(
              Color.lerp(navy, Colors.white, .62)!,
              Color.lerp(navy, Colors.white, .45)!,
            ),
            kind: GlyphKind.whatsapp,
            ink: navy,
            inkGradient: dark,
            detail: el.color,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.settings => _TileLook(
            fill: navyTile,
            kind: GlyphKind.gear,
            ink: el.color,
            inkGradient: _vertical(el.color, Color.lerp(el.color, navy, .3)!),
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          _ => _TileLook(
            fill: index.isEven ? navyTile : lightTile,
            kind: _kindFor(app),
            ink: index.isEven ? el.color : navy,
            detail: index.isEven ? navy : el.color,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
        };
      case ShortcutStyle.whiteTiles:
        return _TileLook(
          fill: _diagonal(Colors.white, el.unlockAccent),
          kind: _kindFor(app, mono: true),
          ink: el.color,
          detail: el.unlockAccent,
          glyphScale: .32,
          radius: BorderRadius.circular(s * .15),
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .35),
              blurRadius: s * .12,
              offset: Offset(0, s * .05),
            ),
          ],
        );
      case ShortcutStyle.leafTiles:
        final big = Radius.circular(s * .6);
        final small = Radius.circular(s * .1);
        final tint = [
          el.unlockAccent,
          el.borderColor,
          el.colorSecondary,
          el.strokeColor.a > 0 ? el.strokeColor : el.unlockAccent,
        ][index % 4];
        final kind = switch (app) {
          ShortcutApp.settings => GlyphKind.gearWrench,
          ShortcutApp.browser => GlyphKind.chrome,
          ShortcutApp.flashlight => GlyphKind.torch,
          _ => _kindFor(app, mono: true),
        };
        return _TileLook(
          fill: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color.lerp(tint, Colors.white, .22)!, tint],
          ),
          kind: kind,
          ink: el.color,
          detail: Colors.white,
          colorful: kind == GlyphKind.chrome,
          glyphScale: .4,
          radius: switch (index % 4) {
            0 || 2 => BorderRadius.only(
              topLeft: big,
              topRight: small,
              bottomLeft: small,
              bottomRight: small,
            ),
            1 => BorderRadius.only(
              topLeft: small,
              topRight: small,
              bottomLeft: small,
              bottomRight: big,
            ),
            _ => BorderRadius.only(
              topLeft: small,
              topRight: small,
              bottomLeft: big,
              bottomRight: small,
            ),
          },
          shadow: [
            BoxShadow(color: tint.withValues(alpha: .5), blurRadius: s * .2),
          ],
        );
      case ShortcutStyle.darkDock:
        final (a, b) = switch (app) {
          ShortcutApp.gallery => (
            const Color(0xFFFFC371),
            const Color(0xFFFF5F6D),
          ),
          ShortcutApp.camera => (
            const Color(0xFFA7C8FF),
            const Color(0xFF4F7EF2),
          ),
          ShortcutApp.music => (
            const Color(0xFFFF4F7B),
            const Color(0xFFFFB04A),
          ),
          ShortcutApp.browser => (
            const Color(0xFFC2A6FF),
            const Color(0xFF6748F4),
          ),
          ShortcutApp.whatsapp => (
            const Color(0xFFA6EE90),
            const Color(0xFF36B54A),
          ),
          ShortcutApp.settings => (
            const Color(0xFFE6EAF2),
            const Color(0xFF8A93A6),
          ),
          _ => (Color.lerp(app.brand, Colors.white, .35)!, app.brand),
        };
        return _TileLook(
          fill: _diagonal(
            Color.lerp(el.unlockAccent, Colors.white, .1)!,
            el.unlockAccent,
          ),
          kind: switch (app) {
            ShortcutApp.whatsapp => GlyphKind.whatsappOutline,
            ShortcutApp.browser => GlyphKind.chrome,
            _ => _kindFor(app, mono: true),
          },
          ink: b,
          inkGradient: _diagonal(a, b),
          detail: el.unlockAccent,
          glyphScale: .46,
          tileGloss: true,
          radius: BorderRadius.circular(s * .3),
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .45),
              blurRadius: s * .1,
              offset: Offset(0, s * .05),
            ),
          ],
        );
      case ShortcutStyle.neonCapsule:
        final glow = el.borderColor;
        return _TileLook(
          fill: _vertical(
            el.unlockAccent,
            Color.lerp(el.unlockAccent, glow, .62)!,
          ),
          kind: _kindFor(app, mono: true),
          ink: el.color,
          inkGradient: _vertical(el.color, Color.lerp(el.color, glow, .45)!),
          detail: el.unlockAccent,
          glyphScale: .62,
          tileGloss: true,
          radius: BorderRadius.circular(s * .28),
          shadow: [
            BoxShadow(color: glow.withValues(alpha: .3), blurRadius: s * .14),
          ],
        );
      case ShortcutStyle.candyCapsule:
        final (kind, ink, detail) = switch (app) {
          ShortcutApp.gallery => (
            GlyphKind.gallery,
            const Color(0xFF8ED37C),
            Colors.white,
          ),
          ShortcutApp.camera => (
            GlyphKind.lensFlat,
            const Color(0xFFB9A4F2),
            const Color(0xFF3B2F63),
          ),
          ShortcutApp.music => (
            GlyphKind.tiktokNote,
            Colors.white,
            Colors.white,
          ),
          ShortcutApp.theme => (
            GlyphKind.brush,
            const Color(0xFFE58AB4),
            Colors.white,
          ),
          ShortcutApp.settings => (
            GlyphKind.flowerGear,
            const Color(0xFF9C7BEA),
            Colors.white,
          ),
          _ => (
            _kindFor(app, mono: true),
            Color.lerp(app.brand, Colors.white, .25)!,
            el.unlockAccent,
          ),
        };
        return _TileLook(
          fill: _vertical(
            Color.lerp(el.unlockAccent, Colors.white, .08)!,
            el.unlockAccent,
          ),
          kind: kind,
          ink: ink,
          detail: detail,
          glyphScale: .6,
          radius: BorderRadius.circular(s * .38),
          shadow: const [],
        );
      case ShortcutStyle.softRow:
        final (top, bottom, kind, detail) = switch (app) {
          ShortcutApp.camera || ShortcutApp.clock => (
            const Color(0xFFA6E68C),
            const Color(0xFF66C34F),
            _kindFor(app, mono: true),
            Colors.white,
          ),
          ShortcutApp.gallery => (
            const Color(0xFF80C6F8),
            const Color(0xFF4F6FE6),
            GlyphKind.galleryScene,
            const Color(0xFFF0C431),
          ),
          ShortcutApp.music => (
            const Color(0xFFE56E76),
            const Color(0xFFCB4B40),
            GlyphKind.noteSoft,
            Colors.white,
          ),
          ShortcutApp.video => (
            const Color(0xFF3C3D44),
            const Color(0xFF2A2B31),
            GlyphKind.playTik,
            Colors.white,
          ),
          ShortcutApp.calculator => (
            Colors.white,
            const Color(0xFFE9E9EE),
            GlyphKind.calculator,
            const Color(0xFFCFCFD4),
          ),
          _ => (
            Color.lerp(app.brand, Colors.white, .3)!,
            app.brand,
            _kindFor(app, mono: true),
            Colors.white,
          ),
        };
        final dark = app == ShortcutApp.calculator;
        return _TileLook(
          fill: _vertical(top, bottom),
          kind: kind,
          ink: dark ? Colors.black : el.color,
          inkGradient: dark
              ? null
              : _vertical(el.color, Color.lerp(el.color, bottom, .22)!),
          detail: detail,
          glyphScale: switch (app) {
            ShortcutApp.music => .95,
            ShortcutApp.calculator => .82,
            _ => .74,
          },
          glyphShadow: !dark,
          radius: BorderRadius.circular(s * .26),
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: s * .06,
              offset: Offset(0, s * .03),
            ),
          ],
        );
      case ShortcutStyle.glossOrbs:
        final (top, bottom, kind, ink, detail) = switch (app) {
          ShortcutApp.camera || ShortcutApp.gallery => (
            const Color(0xFFA3E688),
            const Color(0xFF5EBB47),
            _kindFor(app, mono: true),
            el.color,
            Colors.white,
          ),
          ShortcutApp.settings => (
            const Color(0xFFF4F4F6),
            const Color(0xFFAEAEB4),
            GlyphKind.gearSpokes,
            const Color(0xFF1A1A1C),
            const Color(0xFFD8D8DC),
          ),
          ShortcutApp.music => (
            const Color(0xFFE47C7C),
            const Color(0xFFC94A42),
            GlyphKind.note,
            el.color,
            Colors.white,
          ),
          ShortcutApp.browser => (
            const Color(0xFF86C0F7),
            const Color(0xFF4E6DE0),
            GlyphKind.compassFlat,
            el.color,
            const Color(0xFF4E6DE0),
          ),
          ShortcutApp.calculator => (
            const Color(0xFFF4F4F6),
            const Color(0xFFAEAEB4),
            GlyphKind.calculatorBody,
            const Color(0xFF151517),
            const Color(0xFFEDEDEF),
          ),
          _ => (
            Color.lerp(app.brand, Colors.white, .35)!,
            app.brand,
            _kindFor(app, mono: true),
            el.color,
            app.brand,
          ),
        };
        return _TileLook(
          fill: RadialGradient(
            center: const Alignment(0, -.55),
            radius: 1.05,
            colors: [top, bottom],
          ),
          kind: kind,
          ink: ink,
          detail: detail,
          glyphScale: .64,
          tileGloss: true,
          border: BorderSide(
            color: Colors.white.withValues(alpha: .45),
            width: s * .025,
          ),
          radius: BorderRadius.circular(s / 2),
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: s * .06,
              offset: Offset(0, s * .03),
            ),
          ],
        );
      case ShortcutStyle.socialCards:
        return _TileLook(
          fill: _vertical(el.colorSecondary, el.colorSecondary),
          kind: null,
          ink: el.color,
          radius: BorderRadius.zero,
          shadow: const [],
        );
      case ShortcutStyle.socialRow:
        final (a, b, kind) = switch (app) {
          ShortcutApp.instagram => (
            const Color(0xFFF8A13F),
            const Color(0xFFC13584),
            GlyphKind.instagram,
          ),
          ShortcutApp.whatsapp => (
            const Color(0xFF9BE07A),
            const Color(0xFF3FA535),
            GlyphKind.whatsappOutline,
          ),
          ShortcutApp.telegram => (
            const Color(0xFF7FA6F2),
            const Color(0xFF3B5BA8),
            GlyphKind.telegram,
          ),
          ShortcutApp.music => (
            const Color(0xFFE5675B),
            const Color(0xFFA8302A),
            GlyphKind.youtube,
          ),
          ShortcutApp.spotify => (
            const Color(0xFF7FA2F0),
            const Color(0xFF3A5FD0),
            GlyphKind.spotify,
          ),
          _ => (
            Color.lerp(app.brand, Colors.white, .3)!,
            Color.lerp(app.brand, Colors.black, .2)!,
            _kindFor(app, mono: true),
          ),
        };
        return _TileLook(
          fill: RadialGradient(
            center: const Alignment(.4, -.5),
            radius: 1.1,
            colors: [a, b],
          ),
          kind: kind,
          ink: el.color,
          detail: b,
          glyphScale: .62,
          border: BorderSide(color: el.borderColor, width: s * .03),
          radius: BorderRadius.circular(s * .2),
          shadow: const [],
        );
      case ShortcutStyle.hexGrid:
        final tint = [
          el.unlockAccent,
          el.borderColor,
          el.colorSecondary,
          el.strokeColor.a > 0 ? el.strokeColor : el.unlockAccent,
        ][index % 4];
        return _TileLook(
          fill: _diagonal(Color.lerp(tint, Colors.white, .35)!, tint),
          kind: switch (app) {
            ShortcutApp.camera => GlyphKind.lensFlat,
            ShortcutApp.browser => GlyphKind.compassFlat,
            _ => _kindFor(app, mono: true),
          },
          ink: el.color,
          inkGradient: _vertical(
            el.color,
            Color.lerp(el.color, Colors.grey, .4)!,
          ),
          detail: const Color(0xFF3C3C40),
          badge: _vertical(const Color(0xFF5E5E63), const Color(0xFF38383C)),
          glyphScale: .2,
          hex: true,
          radius: BorderRadius.zero,
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: s * .06,
              offset: Offset(0, s * .03),
            ),
          ],
        );
      case ShortcutStyle.pastelDock:
        const paper = Color(0xFFE9E9EF);
        final glyph = el.color;
        final glossy = _vertical(
          glyph,
          Color.lerp(glyph, const Color(0xFFBFC6D6), .6)!,
        );
        return switch (app) {
          ShortcutApp.gallery => _TileLook(
            fill: _vertical(const Color(0xFFFFC879), const Color(0xFFFF7E5F)),
            kind: GlyphKind.gallery,
            ink: glyph,
            inkGradient: glossy,
            glyphGloss: true,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.camera => _TileLook(
            fill: _vertical(const Color(0xFF7487F2), const Color(0xFF3E4EC4)),
            kind: GlyphKind.lens,
            ink: glyph,
            detail: const Color(0xFF8C7BFF),
            glyphScale: .66,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.music => _TileLook(
            fill: _vertical(Colors.white, paper),
            kind: GlyphKind.note,
            ink: const Color(0xFF6E5CF0),
            inkGradient: _vertical(
              const Color(0xFFF2557A),
              const Color(0xFF5A6CF0),
            ),
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.browser => _TileLook(
            fill: _vertical(Colors.white, paper),
            kind: GlyphKind.compass,
            ink: const Color(0xFF3D6BE0),
            inkGradient: _vertical(
              const Color(0xFF86B2FA),
              const Color(0xFF3A66DA),
            ),
            detail: const Color(0xFFF0453A),
            glyphScale: .7,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.whatsapp => _TileLook(
            fill: _vertical(const Color(0xFFFFF8BC), const Color(0xFFF2E38A)),
            kind: GlyphKind.whatsapp,
            ink: const Color(0xFF45B83C),
            inkGradient: _vertical(
              const Color(0xFF86E276),
              const Color(0xFF38A834),
            ),
            detail: Colors.white,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          ShortcutApp.settings => _TileLook(
            fill: _vertical(const Color(0xFFD3D7E0), const Color(0xFF9AA1B0)),
            kind: GlyphKind.gear,
            ink: glyph,
            inkGradient: glossy,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
          _ => _TileLook(
            fill: _vertical(
              Color.lerp(app.brand, Colors.white, .45)!,
              Color.lerp(app.brand, Colors.white, .2)!,
            ),
            kind: _kindFor(app),
            ink: glyph,
            detail: app.brand,
            shadow: soft,
            radius: BorderRadius.circular(s * .24),
          ),
        };
    }
  }

  /// Drawn glyph for an app, or null to fall back to a Material icon.
  static GlyphKind? _kindFor(ShortcutApp app, {bool mono = false}) =>
      switch (app) {
        ShortcutApp.messages => GlyphKind.bubble,
        ShortcutApp.camera => mono ? GlyphKind.camera : GlyphKind.lens,
        ShortcutApp.music => GlyphKind.note,
        ShortcutApp.browser => mono ? GlyphKind.chrome : GlyphKind.compass,
        ShortcutApp.whatsapp =>
          mono ? GlyphKind.whatsappOutline : GlyphKind.whatsapp,
        ShortcutApp.phone => GlyphKind.handset,
        ShortcutApp.settings => GlyphKind.gear,
        ShortcutApp.flashlight => mono ? GlyphKind.bulb : GlyphKind.torch,
        ShortcutApp.gallery => GlyphKind.gallery,
        ShortcutApp.clock => GlyphKind.clockFace,
        ShortcutApp.instagram => GlyphKind.instagram,
        ShortcutApp.telegram => GlyphKind.telegram,
        ShortcutApp.spotify => GlyphKind.spotify,
        _ => null,
      };

  /// PNG parts written to `shortcut/<name><suffix>.png` on export.
  static Map<String, Widget> exportParts(LockElement el) {
    const k = 1 / 3;
    final l = ShortcutSetLayout.of(el);
    return {
      if (l.panel case final p?)
        '_panel': Padding(
          padding: EdgeInsets.all(panelInset(p) * k),
          child: panel(el, k),
        ),
      for (var i = 0; i < l.tiles.length; i++)
        '_$i': Padding(
          padding: EdgeInsets.all(l.tiles[i].width * k * _shadowPad),
          child: tile(el, i, k),
        ),
    };
  }

  /// Extra margin around exported tiles so shadows and glows are not clipped.
  static const _shadowPad = .2;
  static double exportInset(Rect tile) => tile.width * _shadowPad;
  static double panelInset(Rect panel) => panel.width * .25;
}

/// Editor preview of a shortcut set.
class ShortcutSetPreview extends StatelessWidget {
  const ShortcutSetPreview({super.key, required this.element});
  final LockElement element;

  @override
  Widget build(BuildContext context) {
    const k = 1 / AppConstants.screenRatio;
    final l = ShortcutSetLayout.of(element);
    return SizedBox(
      width: l.size.width * k,
      height: l.size.height * k,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (l.panel != null) ShortcutSetArt.panel(element, k),
          for (var i = 0; i < l.tiles.length; i++)
            Positioned(
              left: l.tiles[i].left * k,
              top: l.tiles[i].top * k,
              child: ShortcutSetArt.tile(element, i, k),
            ),
        ],
      ),
    );
  }
}

/// Pointy-top hexagon with softly rounded corners.
class _HexBorder extends ShapeBorder {
  const _HexBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final c = rect.center;
    final r = rect.shortestSide / 2;
    final points = [
      for (var i = 0; i < 6; i++)
        c + Offset(cos(-pi / 2 + i * pi / 3), sin(-pi / 2 + i * pi / 3)) * r,
    ];
    final round = r * .14;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final prev = points[(i + 5) % 6],
          p = points[i],
          next = points[(i + 1) % 6];
      final a = p + (prev - p) / (prev - p).distance * round;
      final b = p + (next - p) / (next - p).distance * round;
      i == 0 ? path.moveTo(a.dx, a.dy) : path.lineTo(a.dx, a.dy);
      path.quadraticBezierTo(p.dx, p.dy, b.dx, b.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
