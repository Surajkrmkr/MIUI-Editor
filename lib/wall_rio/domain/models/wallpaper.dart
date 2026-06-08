import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallpaper.freezed.dart';
part 'wallpaper.g.dart';

@freezed
abstract class Wallpaper with _$Wallpaper {
  const factory Wallpaper({
    required dynamic id, // Flexible ID (int or string)
    required String name,
    @Default('WallRio') String author,
    @Default('') String url,
    @Default('') String thumbnail,
    @Default([]) List<String> tags,
    @Default('') String category,
    @Default([]) List<String> color,
    @Default(false) bool isPremium,
    @Default('') String subjectId,
    // Live Wallpaper specific fields
    String? videoUrl,
    String? previewVideo,
    String? type,
  }) = _Wallpaper;

  factory Wallpaper.fromJson(Map<String, dynamic> json) => _$WallpaperFromJson(json);
}

@freezed
abstract class RioData with _$RioData {
  const factory RioData({
    @Default([]) List<Map<String, dynamic>> subscription,
    @Default([]) List<Map<String, dynamic>> banners,
    @Default({}) Map<String, dynamic> search,
    @Default([]) List<Wallpaper> walls,
    // Support for collections-based structure
    List<Map<String, dynamic>>? collections,
  }) = _RioData;

  factory RioData.fromJson(Map<String, dynamic> json) => 
      _$RioDataFromJson(_preprocessRioData(json));

  static Map<String, dynamic> _preprocessRioData(Map<String, dynamic> json) {
    // Custom logic to handle different JSON roots
    var processedJson = Map<String, dynamic>.from(json);
    
    // If we have collections but no top-level walls, flatten them for the CMS
    if (processedJson['collections'] != null && processedJson['walls'] == null) {
      final collections = processedJson['collections'] as List;
      final flattenedWalls = [];
      for (var collection in collections) {
        if (collection is Map && collection['walls'] != null) {
          flattenedWalls.addAll(collection['walls'] as List);
        }
      }
      processedJson['walls'] = flattenedWalls;
    }
    
    return processedJson;
  }
}
