import 'element_enums.dart';
import '../values/rgba.dart';

/// Apps a shortcut set can launch. Material glyphs live in the app
/// (`ShortcutAppX.icon`).
enum ShortcutApp {
  messages('Messages', ElementType.mmsIcon, Rgba(0xFF34C759)),
  camera('Camera', ElementType.cameraIcon, Rgba(0xFF4A8BF5)),
  music('Music', ElementType.musicIcon, Rgba(0xFFFC3C6E)),
  browser('Browser', ElementType.browserIcon, Rgba(0xFF3D7BF7)),
  whatsapp('WhatsApp', ElementType.whatsAppIcon, Rgba(0xFF25D366)),
  phone('Phone', ElementType.dialerIcon, Rgba(0xFF34C759)),
  settings('Settings', ElementType.settingIcon, Rgba(0xFF8E8E93)),
  flashlight('Flashlight', null, Rgba(0xFFFFC107)),
  gallery('Gallery', ElementType.galleryIcon, Rgba(0xFFFF9500)),
  contacts('Contacts', ElementType.contactIcon, Rgba(0xFF5AC8FA)),
  calendar('Calendar', ElementType.calendarIcon, Rgba(0xFFFF3B30)),
  clock('Clock', ElementType.clockIcon, Rgba(0xFF1C1C1E)),
  notes('Notes', ElementType.notesIcon, Rgba(0xFFFFCC00)),
  calculator('Calculator', ElementType.calculatorIcon, Rgba(0xFFFF9500)),
  weather('Weather', ElementType.weatherIcon, Rgba(0xFF5AC8FA)),
  telegram('Telegram', ElementType.telegramIcon, Rgba(0xFF2AABEE)),
  instagram('Instagram', ElementType.instagramIcon, Rgba(0xFFE1306C)),
  spotify('Spotify', ElementType.spotifyIcon, Rgba(0xFF1DB954)),
  theme('Themes', ElementType.themeIcon, Rgba(0xFFAF52DE)),
  facebook(
    'Facebook',
    null,
    Rgba(0xFF1877F2),
    'com.facebook.katana',
    'com.facebook.katana.LoginActivity',
  ),
  video('Video', ElementType.videoIcon, Rgba(0xFFFF5A5F));

  const ShortcutApp(
    this.label,
    this.iconType,
    this.brandColor, [
    this.package,
    this.activity,
  ]);
  final String label;
  final ElementType? iconType;
  final Rgba brandColor;

  /// Launch target for apps without a single-icon element.
  final String? package, activity;

  static List<ShortcutApp> parse(String keys) => [
    for (final key in keys.split(','))
      if (ShortcutApp.values.where((a) => a.name == key.trim()).firstOrNull
          case final app?)
        app,
  ];
}
