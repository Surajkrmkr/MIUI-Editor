class ThemeDesc {
  static String? getXmlString() {
    return '''
        <?xml version='1.0' encoding='utf-8' standalone='yes' ?>
          <MIUI-Theme>
            <title>Test</title>
            <designer>Suraj</designer>
            <author>Sj</author>
            <version>1.0</version>
            <uiVersion>10</uiVersion>
            <keywords>MIUIThemeEditor;40.7.10_1594360719;</keywords>
          </MIUI-Theme>
    ''';
  }

  static String? pluginInfo() {
    return '''
        <?xml version="1.0" encoding="utf-8"?>
        <PluginConfig>
          <iconCalendar/>
          <iconClock/>
          <iconWeather/>
          <lockscreen/>
          <desktopClock/>
          <desktopWallpaper/>
        </PluginConfig>
    ''';
  }
}
