import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';

class FontModel {
  List<Fonts>? fonts;

  FontModel({this.fonts});

  FontModel.fromJson(Map<String, dynamic> json) {
    if (json['fonts'] != null) {
      fonts = <Fonts>[];
      json['fonts'].forEach((v) {
        fonts!.add(Fonts.fromJson(v));
      });
    }
  }
}

class Fonts {
  int? id;
  String? name;
  String? url;
  DynamicCachedFonts? dynamicCachedFonts;

  Fonts({this.id, this.name, this.url});

  Fonts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    url = json['url'];

    dynamicCachedFonts = DynamicCachedFonts(
      fontFamily:
          name!, 
      url:
          url!, 
    );
    dynamicCachedFonts!.load();
  }

}
