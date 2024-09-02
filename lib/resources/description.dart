class ThemeDesc {
  static String? getXmlString() {
    return '''
        <?xml version='1.0' encoding='utf-8' standalone='yes' ?>
          <MIUI-Theme>
            <title>Test</title>
            <designer>Subhangi</designer>
            <author>Subhangi</author>
            <version>1.0</version>
            <uiVersion>15</uiVersion>
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

  static String? clockManifest() {
    return '''
        <?xml version="1.0" encoding="utf-8"?>
        <Clock version="2" frameRate="30" type="awesome" useVariableUpdater="DateTime.Minute" screenWidth="1080" resDensity="480" scaleByDensity="false" >
        <DateTime x="#view_width/2" y="#view_height/2-70" align="center" alignV="center" size="200" color="#ffffffff" format="hh:mm" fontFamily="mitype-bold"  touchable="true" visibility="not(#applied_light_wallpaper)">
          <Triggers>
            <Trigger action="up" >
              <IntentCommand action="android.intent.action.MAIN" package="com.android.deskclock" class="com.android.deskclock.DeskClockTabActivity" />
            </Trigger>
          </Triggers>
        </DateTime>
        <DateTime x="#view_width/2" y="#view_height/2+60" align="center" alignV="center" size="40" color="#ffffffff" format="dd-MM-yyyy" fontFamily="mitype-light"  touchable="true" visibility="not(#applied_light_wallpaper)">
          <Triggers>
            <Trigger action="up" >
              <IntentCommand action="android.intent.action.MAIN" package="com.android.deskclock" class="com.android.deskclock.DeskClockTabActivity" />
            </Trigger>
          </Triggers>
        </DateTime>
        <DateTime x="#view_width/2" y="#view_height/2+120" align="center" alignV="center" size="40" color="#ffffffff" format="EEEE" fontFamily="mitype-light"  touchable="true" visibility="not(#applied_light_wallpaper)">
          <Triggers>
            <Trigger action="up" >
              <IntentCommand action="android.intent.action.MAIN" package="com.android.deskclock" class="com.android.deskclock.DeskClockTabActivity" />
            </Trigger>
          </Triggers>
        </DateTime>

        <DateTime x="#view_width/2" y="#view_height/2-70" align="center" alignV="center" size="200" color="#FF000000" format="hh:mm" fontFamily="mitype-bold"  touchable="true" visibility="#applied_light_wallpaper">
          <Triggers>
            <Trigger action="up" >
              <IntentCommand action="android.intent.action.MAIN" package="com.android.deskclock" class="com.android.deskclock.DeskClockTabActivity" />
            </Trigger>
          </Triggers>
        </DateTime>
        <DateTime x="#view_width/2" y="#view_height/2+60" align="center" alignV="center" size="40" color="#FF000000" format="dd-MM-yyyy" fontFamily="mitype-light"  touchable="true" visibility="#applied_light_wallpaper">
          <Triggers>
            <Trigger action="up" >
              <IntentCommand action="android.intent.action.MAIN" package="com.android.deskclock" class="com.android.deskclock.DeskClockTabActivity" />
            </Trigger>
          </Triggers>
        </DateTime>
        <DateTime x="#view_width/2" y="#view_height/2+120" align="center" alignV="center" size="40" color="#FF000000" format="EEEE" fontFamily="mitype-light"  touchable="true" visibility="#applied_light_wallpaper">
          <Triggers>
            <Trigger action="up" >
              <IntentCommand action="android.intent.action.MAIN" package="com.android.deskclock" class="com.android.deskclock.DeskClockTabActivity" />
            </Trigger>
          </Triggers>
        </DateTime>
      </Clock>
    ''';
  }
}
