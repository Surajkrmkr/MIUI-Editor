import 'package:xml/xml.dart';

import '../element_map_dart.dart';

final lockscreenManifest = '''
  <?xml version="1.0" encoding="utf-8"?>
    <Lockscreen version="2" frameRate="30" displayDesktop="false" screenWidth="1080">
      <Var expression="#screen_width" name="sw"/>
      <Var expression="#screen_height" name="sh"/>
      <Wallpaper name="wall" pivotX="#wall.bmp_width/2" pivotY="#wall.bmp_height/2">
        <ScaleAnimation loop="false">
          <Item value="1.3" time="0" easeType="ExpoEaseOut" />
          <Item value="1" time="1000" />
        </ScaleAnimation>
      </Wallpaper>
      <Video layerType="bottom" name="mamlVideo"/>
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
      <ExternalCommands>
        <Trigger action="init">
          <VideoCommand command="config" loop="1" path="&apos;video.mp4&apos;" scaleMode="2" target="mamlVideo"/>
          <VideoCommand command="play" target="mamlVideo"/>
          <IntentCommand action="initialization" broadcast="true">
          <Extra expression="#btnVar" name="bg_number" type="number"/>
          </IntentCommand>
        </Trigger>
        <Trigger action="pause">
          <AnimationCommand command="play(0,0)" target="resumeAni"/>
          <VideoCommand command="seekTo" target="mamlVideo" time="0"/>
        </Trigger>
        <Trigger action="resume">
          <AnimationCommand command="play" target="resumeAni"/>
          <VideoCommand command="play" delay="100" target="mamlVideo"/>
        </Trigger>
      </ExternalCommands>
      <Button x="0" y="0" w="1080" h="#sh" visibility="#hasnotifications}0">
          <Triggers>
            <Trigger action="up,cancel">
              <VariableCommand name="notice_down" expression="0" />
            </Trigger>
          </Triggers>
      </Button>
      <Group name="bgAlpha"></Group>
      <Image name="bgLock" srcExp="'bg.png'" width="#sw" height="#sh"/>
      ${getGroupStrings()}
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

const iconTransformConfig = '''
<?xml version="1.0" encoding="UTF-8"?>
<IconTransform>
    <PointsMapping>
        <Point fromX="0" fromY="0" toX="22" toY="22"/>
        <Point fromX="0" fromY="90" toX="22" toY="68"/>
        <Point fromX="90" fromY="90" toX="68" toY="68"/>
        <Point fromX="90" fromY="0" toX="68" toY="22"/>
    </PointsMapping>
</IconTransform>
''';
