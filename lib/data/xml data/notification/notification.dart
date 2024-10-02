import '../../../constants.dart';
import '../../../provider/element.dart';

String notificationXml({required ElementWidget ele}) {
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String color = '#FF${ele.color!.value.toRadixString(16).substring(2, 8)}';
  final String color2 = '#FF${ele.colorSecondary!.value.toRadixString(16).substring(2, 8)}';
  final String radius = ele.radius!.toStringAsFixed(2);
  return '''
    <Var name="w" expression="1024" type="number" />
    <Var name="h" expression="186" type="number" />
    <List name="notification_list" x="0" y="$dy+#sh/2" w="#screen_width" maxHeight="int(#h+20)*3" data="icon:bitmap,title:string,content:string,time:string,info:string,subtext:string,key:int" visibility="#hasnotifications">
		<Item x="540" y="0" w="#w" h="int(#h+20)" align="center">
			<Button x="0" y="0" w="1024" h="(#h+20)" alignChildren="true">
         <Normal>
            <Rectangle x="0" w="1024" h="186" fillColor="#$color2" cornerRadius="25" />
         </Normal>
         <Pressed>
            <Rectangle x="0" w="1024" h="186" fillColor="#$color2" cornerRadius="25" alpha="100"/>
        </Pressed>
				<Image x="#w - 66" y="#h/2" align="center" alignV="center" src="notification/close.png" />
				<Image name="icon" x="#h/2" y="#h/2" w="130" h="130" align="center" alignV="center" />
				<Text name="title" x="#h" y="#h/2-28" w="int(#w-#h-132) - (180-(70*#time_format))" h="48" alignV="center" size="42" color="#$color" marqueeSpeed="30" />
				<Text name="content" x="#h" y="#h/2+30" w="int(#w-#h-132)" h="42" alignV="center" size="36" color="#$color" marqueeSpeed="30" alpha="128" />
				<Text name="time" x="#w - 132" y="#h/2-28" align="right" alignV="center" size="36" color="#$color" alpha="128" />
				<Triggers>
					<Trigger action="down">
						<VariableCommand name="notice_down" expression="1" />
					</Trigger>
					<Trigger action="up">
						<IntentCommand action="com.miui.app.ExtraStatusBarManager.action_remove_keyguard_notification" broadcast="true">
							<Extra name="com.miui.app.ExtraStatusBarManager.extra_notification_key" type="int" expression="#notification_list.key" />
							<Extra name="com.miui.app.ExtraStatusBarManager.extra_notification_click" type="int" expression="#touch_begin_x { #sw/2 + 1024 - 132" />
						</IntentCommand>
					</Trigger>
				</Triggers>
			</Button>
		</Item>
		<AttrDataBinders>
			<AttrDataBinder target="icon" attr="bitmap" data="icon" />
			<AttrDataBinder target="title" attr="text" data="title" />
			<AttrDataBinder target="content" attr="text" data="content" />
			<AttrDataBinder target="time" attr="text" data="time" />
		</AttrDataBinders>
	</List>
''';
}
