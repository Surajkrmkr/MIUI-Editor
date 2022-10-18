import 'package:xml/xml.dart';

import '../element_map_dart.dart';

final lockscreenManifest = '''
  <?xml version="1.0" encoding="utf-8"?>
    <Lockscreen version="2" frameRate="30" displayDesktop="false" screenWidth="1080">
	  <!--Don't COPY SURAJ's WORK-->
	    <Var expression="#screen_width" name="sw"/>
	    <Var expression="#screen_height" name="sh"/>
	    <Wallpaper/>
      <Group name="bgAlpha"></Group>
      <Image name="bgLock" srcExp="'bg.png'" width="#sw" height="#sh"/>
      ${getGroupStrings()}
    <!--Don't COPY SURAJ's WORK-->
  </Lockscreen>
''';

String? getGroupStrings() {
  String? str = "";

  for (var ele in ElementType.values) {
    str = '${str!}<Group name="${ele.name}"></Group>';
  }
  return str;
}

final lockscreenXml = XmlDocument.parse(lockscreenManifest);


String? getBgAlphaString({double? alpha}){
  return '<Rectangle width="#sw" alpha="$alpha" height="#sh" fillColor="#ff000000"/>';
}