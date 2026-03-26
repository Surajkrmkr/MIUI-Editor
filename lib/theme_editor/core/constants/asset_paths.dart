enum IconVariant {
  u1('u1', 'Style 1'),
  u2('u2', 'Style 2'),
  u3('u3', 'Style 3'),
  u4('u4', 'Style 4');

  const IconVariant(this.folder, this.displayName);
  final String folder;
  final String displayName;
}

abstract final class AssetPaths {
  static String iconSvg(IconVariant v, String name) =>
      'assets/icons/${v.folder}/$name.svg';
  static String weatherIcon(String code) =>
      'assets/lockscreen/weatherIcon/weather_$code.png';
  static String userAvatar(String name) => 'assets/users/$name.png';
  static String ninePatch(String name)  => 'assets/9pngs/$name';
  static const String tagsJson = 'assets/tags/tags.json';

  static const List<int> weatherCodes = [0,1,2,3,4,7,12,13,18,22,24];
  static const List<String?> weekNames = [
    'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'
  ];
  static const List<String?> monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
}
