import '../../../constants.dart';
import '../../../provider/element.dart';

String cameraIconXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Button align="center" alignV="center" w="$width" h="$height">
        <Normal>
          <Image align="center" alignV="center" src="icon/camera.png" w="$width" h="$height"/>
        </Normal>
        <Pressed alpha="200">
          <Image align="center" alignV="center" src="icon/camera.png" w="$width" h="$height"/>
        </Pressed>
        <Triggers>
          <Trigger action="up">
            <IntentCommand action="android.intent.action.MAIN" package="com.android.camera" class="com.android.camera.Camera">
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

String musicIconXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Button align="center" alignV="center" w="$width" h="$height">
        <Normal>
          <Image align="center" alignV="center" src="icon/music.png" w="$width" h="$height"/>
        </Normal>
        <Pressed alpha="200">
          <Image align="center" alignV="center" src="icon/music.png" w="$width" h="$height"/>
        </Pressed>
        <Triggers>
          <Trigger action="up">
            <IntentCommand action="android.intent.action.MAIN" package="com.miui.player" class="com.miui.player.ui.MusicBrowserActivity">
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

String themeIconXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Button align="center" alignV="center" w="$width" h="$height">
        <Normal>
          <Image align="center" alignV="center" src="icon/theme.png" w="$width" h="$height"/>
        </Normal>
        <Pressed alpha="200">
          <Image align="center" alignV="center" src="icon/theme.png" w="$width" h="$height"/>
        </Pressed>
        <Triggers>
          <Trigger action="up">
            <IntentCommand action="android.intent.action.MAIN" package="com.android.thememanager" class="com.android.thememanager.ThemeResourceTabActivity">
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

String settingIconXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Button align="center" alignV="center" w="$width" h="$height">
        <Normal>
          <Image align="center" alignV="center" src="icon/setting.png" w="$width" h="$height"/>
        </Normal>
        <Pressed alpha="200">
          <Image align="center" alignV="center" src="icon/setting.png" w="$width" h="$height"/>
        </Pressed>
        <Triggers>
          <Trigger action="up">
            <IntentCommand action="android.intent.action.MAIN" package="com.android.settings" class="com.android.settings.MainSettings">
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

String galleryIconXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Button align="center" alignV="center" w="$width" h="$height">
        <Normal>
          <Image align="center" alignV="center" src="icon/gallery.png" w="$width" h="$height"/>
        </Normal>
        <Pressed alpha="200">
          <Image align="center" alignV="center" src="icon/gallery.png" w="$width" h="$height"/>
        </Pressed>
        <Triggers>
          <Trigger action="up">
            <IntentCommand action="android.intent.action.MAIN" package="com.miui.gallery" class="com.miui.gallery.activity.HomePageActivity">
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
