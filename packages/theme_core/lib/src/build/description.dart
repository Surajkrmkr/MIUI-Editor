class ThemeDescription {
  ThemeDescription._();

  static String buildDescription({
    required String themeName,
    required String designerName,
    required String authorTag,
    String uiVersion = '17',
  }) =>
      '''<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<MIUI-Theme>
  <title>$themeName</title>
  <designer>$designerName</designer>
  <author>$authorTag</author>
  <version>1.0</version>
  <uiVersion>$uiVersion</uiVersion>
  <editorVersion>2.0.5</editorVersion>
  <resourceType>theme</resourceType>
  <moduleVersion>com.android.contacts:0.0.2;com.android.mms:0.0.2;com.android.settings:0.0.2;com.android.systemui:0.0.2;</moduleVersion>
  <miuiAdapterVersion>3.2</miuiAdapterVersion>
</MIUI-Theme>''';

  static const String pluginConfig = '''<?xml version="1.0" encoding="utf-8"?>
<PluginConfig>
  <iconCalendar/>
  <iconClock/>
  <iconWeather/>
  <lockscreen/>
  <desktopClock/>
  <desktopWallpaper/>
</PluginConfig>''';

  static const String clockManifest = '''<?xml version="1.0" encoding="utf-8"?>
<Clock version="2" frameRate="30" type="awesome"
  useVariableUpdater="DateTime.Minute" screenWidth="1080"
  resDensity="480" scaleByDensity="false">
  <DateTime x="#view_width/2" y="#view_height/2-70"
    align="center" alignV="center" size="200" color="#ffffffff"
    format="hh:mm" fontFamily="mitype-bold" touchable="true"
    visibility="not(#applied_light_wallpaper)">
    <Triggers><Trigger action="up">
      <IntentCommand action="android.intent.action.MAIN"
        package="com.android.deskclock"
        class="com.android.deskclock.DeskClockTabActivity"/>
    </Trigger></Triggers>
  </DateTime>
  <DateTime x="#view_width/2" y="#view_height/2+60"
    align="center" alignV="center" size="40" color="#ffffffff"
    format="dd-MM-yyyy" fontFamily="mitype-light" touchable="true"
    visibility="not(#applied_light_wallpaper)">
    <Triggers><Trigger action="up">
      <IntentCommand action="android.intent.action.MAIN"
        package="com.android.deskclock"
        class="com.android.deskclock.DeskClockTabActivity"/>
    </Trigger></Triggers>
  </DateTime>
  <DateTime x="#view_width/2" y="#view_height/2+120"
    align="center" alignV="center" size="40" color="#ffffffff"
    format="EEEE" fontFamily="mitype-light" touchable="true"
    visibility="not(#applied_light_wallpaper)">
    <Triggers><Trigger action="up">
      <IntentCommand action="android.intent.action.MAIN"
        package="com.android.deskclock"
        class="com.android.deskclock.DeskClockTabActivity"/>
    </Trigger></Triggers>
  </DateTime>
</Clock>''';
}
