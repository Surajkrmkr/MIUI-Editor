import 'package:xml/xml.dart';

import '../element_map_dart.dart';

final lockscreenManifest = '''
  <?xml version="1.0" encoding="utf-8"?>
    <Lockscreen version="2" frameRate="30" displayDesktop="false" screenWidth="1080">
	  <!--Don't COPY SURAJ's WORK-->
	    <Var expression="#screen_width" name="sw"/>
	    <Var expression="#screen_height" name="sh"/>
	    <Wallpaper name="wall" pivotX="#wall.bmp_width/2" pivotY="#wall.bmp_height/2">
        <ScaleAnimation loop="false">
          <Item value="1.3" time="0" easeType="ExpoEaseOut" />
          <Item value="1" time="1000" />
        </ScaleAnimation>
	    </Wallpaper>
      <VariableBinders>
        <ContentProviderBinder name="WeatherService" uri="content://weather/actualWeatherData/1" columns="city_id,city_name,weather_type,aqilevel,description,temperature,forecast_type,tmphighs,tmplows,wind,humidity" countName="hasweather">
          <Variable name="cityName" type="string" column="city_name"/>
          <Variable name="typeID" type="int" column="weather_type"/>
          <Variable name="descriPtion" type="string" column="description"/>
          <Variable name="temp" type="int" column="temperature"/>
          <Variable name="aqi" type="int" column="aqilevel"/>
          <Variable name="tmpLows" type="string" column="tmplows"/>
          <Variable name="tmpHighs" type="string" column="tmphighs"/>
          <Trigger>
            <VariableCommand name="airQuality" expression="ifelse(#aqi}=0**#aqi{50,'Good', #aqi}=50**#aqi{100,'Moderate', #aqi}=100**#aqi{150,'Slightly Polluted', #aqi}=150**#aqi{200,'Moderately Polluted', #aqi}=200**#aqi{300,'Heavily Polluted', #aqi}=300**#aqi{=500,'Severely Polluted', 'N/A')" type="string"/>
            <VariableCommand name="w_outID" expression="ifelse(#typeID}25||#typeID{0,0, (#ID}=4**#typeID{=6||#typeID}=8**#typeID{=11||#typeID==25),4,#typeID}=13**#typeID{=17,13 ,#ID}=18**#typeID{=21||#typeID==23,18,#typeID)"/>
          </Trigger>
        </ContentProviderBinder>
        <ContentProviderBinder name="data" uri="content://keyguard.notification/notifications" columns="icon,title,content,time,info,subtext,key" countName="hasnotifications">
          <List name="notification_list"/>
        </ContentProviderBinder>
      </VariableBinders>
      <Group name="bgAlpha"></Group>
      <Image name="bgLock" srcExp="'bg.png'" width="#sw" height="#sh"/>
      ${getGroupStrings()}
    <!--Don't COPY SURAJ's WORK-->
  </Lockscreen>
''';

String? getGroupStrings() {
  String? str = "";

  for (var ele in ElementType.values) {
    if (ele == ElementType.musicBg) {
      str =
          '${str!}<MusicControl name="music_control" align="center" alignV="center" autoShow="true" defAlbumCover="music/bg.png" enableLyric="true" updateLyricInterval="100"></MusicControl>';
    } else {
      str = '${str!}<Group name="${ele.name}"></Group>';
    }
  }
  return str;
}

final lockscreenXml = XmlDocument.parse(lockscreenManifest);

String? getBgAlphaString({double? alpha}) {
  return '<Rectangle width="#sw" alpha="$alpha" height="#sh" fillColor="#ff000000"/>';
}
