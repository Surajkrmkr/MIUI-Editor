import 'package:path/path.dart' as p;

/// File locations inside one theme workspace. Takes only its root, so it works
/// without app settings or OS-specific defaults.
class ThemeLayout {
  ThemeLayout(String root) : root = p.normalize(root);

  /// Workspace directory, no trailing separator.
  final String root;

  /// Directory holding the workspace; the `.mtz` files are written here.
  String get parentDir => p.dirname(root);

  String get descriptionXml => p.join(root, 'description.xml');
  String get pluginConfigXml => p.join(root, 'plugin_config.xml');

  String get wallpaperDir => p.join(root, 'wallpaper');
  String get defaultWallpaper => p.join(wallpaperDir, 'default_wallpaper.jpg');
  String get defaultLockWallpaper =>
      p.join(wallpaperDir, 'default_lock_wallpaper.jpg');

  String get clockDir => p.join(root, 'clock_2x4');
  String get clockManifest => p.join(clockDir, 'manifest.xml');

  String get iconsDir => p.join(root, 'icons');
  String get iconsXhdpi => p.join(iconsDir, 'res', 'drawable-xhdpi');
  String get iconsXxhdpi => p.join(iconsDir, 'res', 'drawable-xxhdpi');
  String get transformConfigXml => p.join(iconsDir, 'transform_config.xml');

  String get lockscreenAdvance => p.join(root, 'lockscreen', 'advance');
  String get beforeVectorPng => p.join(lockscreenAdvance, 'beforeVector.png');
  String get afterVectorPng => p.join(lockscreenAdvance, 'afterVector.png');

  /// Module directory such as `com.android.mms` or `icons`.
  String module(String name) => p.join(root, name);

  String moduleDrawables(String name) =>
      p.join(module(name), 'res', 'drawable-xxhdpi');

  /// Scratch directory used while packing.
  String get tempDir => p.join(root, 'temp');

  String mtzFile(String name) => p.join(parentDir, '$name.mtz');
}
