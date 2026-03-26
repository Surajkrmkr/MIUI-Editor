import 'dart:io';

abstract final class PathConstants {
  /// Set this from SharedPreferences before any path operations.
  /// When non-empty it takes precedence over the platform defaults.
  static String customBasePath = '';

  static String get basePath {
    if (customBasePath.isNotEmpty) return customBasePath;
    if (Platform.isWindows) return r'E:\Xiaomi Contract\';
    if (Platform.isAndroid) return '/storage/emulated/0/Xiaomi Contract/';
    if (Platform.isMacOS)   return '/Users/surajkrmkr/Storage/Xiaomi Contract/';
    if (Platform.isLinux)   return '/home/annu/Xiaomi Contract/';
    return '';
  }

  static String get wallBasePath => p('${basePath}Wall$sep');
  static String get sample2Path  => p('${basePath}Sample2$sep');
  static String get presetPath   => p('${basePath}Preset$sep');
  static String get themesBase   => p('${basePath}THEMES$sep');

  static String sample2Lockscreen() => p('${sample2Path}lockscreen${sep}advance$sep');

  static String themePath(String weekNum, String themeName) =>
      p('${themesBase}Week$weekNum$sep$themeName$sep');

  static String tagDirectory(String weekNum) =>
      p('${themesBase}Week$weekNum${sep}1tags$sep');

  static String copyrightDirectory(String weekNum) =>
      p('${themesBase}Week$weekNum${sep}1copyright$sep');

  static String lockscreenAdvance(String tp) =>
      p('${tp}lockscreen${sep}advance$sep');

  static String iconsXhdpi(String tp)  => p('${tp}icons${sep}res${sep}drawable-xhdpi$sep');
  static String iconsXxhdpi(String tp) => p('${tp}icons${sep}res${sep}drawable-xxhdpi$sep');
  static String wallpaperDir(String tp) => p('${tp}wallpaper$sep');

  static String get sep => Platform.isWindows ? r'\' : '/';

  static String p(String path) =>
      Platform.isWindows ? path : path.replaceAll(r'\', '/');

  static const List<String> subDirs = [
    r'res\drawable-xxhdpi\',
    r'res\drawable-nxhdpi\',
    r'framework-miui-res\res\drawable-nxhdpi\',
    r'framework-miui-res\res\drawable-xxhdpi\',
  ];

  static const List<String> themeDirectories = [
    r'\wallpaper\',
    r'\icons\res\drawable-xxhdpi\',
    r'\icons\res\drawable-xhdpi\',
    r'\clock_2x4\',
    r'\lockscreen\advance\icon\',
    r'\lockscreen\advance\png\',
    r'\lockscreen\advance\music\',
    r'\lockscreen\advance\notification\',
  ];

  static const List<String?> lockscreenDefaultPngs = [
    r'\bg',
    r'\icon\camera', r'\icon\gallery', r'\icon\setting',
    r'\icon\theme',  r'\icon\music',   r'\icon\dialer',
    r'\icon\mms',    r'\icon\contact', r'\icon\whatsApp',
    r'\icon\telegram', r'\icon\instagram', r'\icon\spotify',
    r'\music\bg', r'\music\next', r'\music\prev',
    r'\music\play', r'\music\pause',
    r'\unlock\unlock', r'\unlock\slider', r'\unlock\tap',
  ];
}
