import '../../../constants.dart';
import '../../../provider/element.dart';

String musicBgXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Group angle="$angle" align="center" alignV="center" w="$width" h="$height" layered="true">
        <Image name="music_album_cover" w="$width" h="$height"/>
        <Image w="$width" h="$height" src="music/bg.png" xfermode="dst_in"/>
      </Group>
    </Group>
''';
}

String musicNextXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Image src="music/next.png" align="center" alignV="center" w="$width" h="$height"/>
    </Group>
    <Button name="music_next" w="$width" h="$height" align="center" alignV="center" x="#sw/2+$dx" y="#sh/2+$dy"/>
''';
}

String musicPrevXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Image src="music/prev.png" align="center" alignV="center" w="$width" h="$height"/>
    </Group>
    <Button name="music_prev" w="$width" h="$height" align="center" alignV="center" x="#sw/2+$dx" y="#sh/2+$dy"/>
''';
}

String musicPlayXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Image src="music/play.png" align="center" alignV="center" w="$width" h="$height" visibility="ifelse(strIsEmpty(@music_control.title),true,false)"/>
    </Group>
    <Button name="music_play" w="$width" h="$height" align="center" alignV="center" x="#sw/2+$dx" y="#sh/2+$dy"/>
''';
}

String musicPauseXml({required ElementWidget ele}) {
  final String width = (ele.width! * ele.scale!).toStringAsFixed(2);
  final String height = (ele.height! * ele.scale!).toStringAsFixed(2);
  final String dx = (ele.dx! * MIUIConstants.ratio).toStringAsFixed(2);
  final String dy = (ele.dy! * MIUIConstants.ratio).toStringAsFixed(2);
  final String angle = (360 - ele.angle!).toStringAsFixed(2);
  return '''
    <Group angle="$angle" x="#sw/2+$dx" y="#sh/2+$dy" align="center" alignV="center">
      <Image src="music/pause.png" align="center" alignV="center" w="$width" h="$height" visibility="ifelse(strIsEmpty(@music_control.title),false,true)"/>
    </Group>
    <Button name="music_pause" w="$width" h="$height" align="center" alignV="center" x="#sw/2+$dx" y="#sh/2+$dy"/>
''';
}
