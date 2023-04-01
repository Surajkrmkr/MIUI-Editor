import '../../../provider/element.dart';

String containerBGXml({required ElementWidget ele}) => '''
		<Image name="containerBG" srcExp="'container/${ele.name}.png'" width="#sw" height="#sh"/>
''';