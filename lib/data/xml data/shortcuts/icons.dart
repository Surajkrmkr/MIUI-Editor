import '../../../constants.dart';
import '../../../provider/element.dart';

String cameraIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/camera",
      package: "com.android.camera",
      className: "com.android.camera.Camera");
}

String musicIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/music",
      package: "com.miui.player",
      className: "com.miui.player.ui.MusicBrowserActivity");
}

String themeIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/theme",
      package: "com.android.thememanager",
      className: "com.android.thememanager.ThemeResourceTabActivity");
}

String settingIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/setting",
      package: "com.android.settings",
      className: "com.android.settings.MainSettings");
}

String dialerIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/dialer",
      package: "com.android.contacts",
      className: "com.android.contacts.activities.TwelveKeyDialer");
}

String mmsIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/mms",
      package: "com.android.mms",
      className: "com.android.mms.ui.MmsTabActivity");
}

String contactIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/contact",
      package: "com.android.contacts",
      className: "com.android.contacts.activities.PeopleActivity");
}

String whatsAppIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/whatsApp",
      package: "com.whatsapp",
      className: "com.whatsapp.Main");
}

String telegramIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/telegram",
      package: "org.telegram.messenger",
      className: "org.telegram.messenger");
}

String spotifyIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/spotify",
      package: "com.spotify.music",
      className: "com.spotify.music.MainActivity");
}

String galleryIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/gallery",
      package: "com.miui.gallery",
      className: "com.miui.gallery.activity.HomePageActivity");
}

String instagramIconXml({required ElementWidget ele}) {
  return getIconXml(
      ele: ele,
      path: "icon/instagram",
      package: "com.instagram.android",
      className: "com.instagram.android.activity.MainTabActivity");
}

String getIconXml(
    {required ElementWidget ele,
    required String? path,
    required String? package,
    required String? className}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Button align="center" alignV="center" w="$width" h="$height">
        <Normal>
          <Image align="center" alignV="center" src="$path.png" w="$width" h="$height"/>
        </Normal>
        <Pressed alpha="200">
          <Image align="center" alignV="center" src="$path.png" w="$width" h="$height"/>
        </Pressed>
        <Triggers>
          <Trigger action="up">
            <IntentCommand action="android.intent.action.MAIN" package="$package" class="$className">
              <Extra name="StartActivityWhenLocked" type="boolean" expression="1"/>
              <Extra name="navigation_tab" expression="2" type="int"/>
            </IntentCommand>
            <ExternCommand command="unlock" condition="not(#set_lock)"/>
          </Trigger>
        </Triggers>
      </Button>
	</Group>
''';
}
