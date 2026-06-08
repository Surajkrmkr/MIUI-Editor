// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallpaper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Wallpaper _$WallpaperFromJson(Map<String, dynamic> json) => _Wallpaper(
      id: json['id'],
      name: json['name'] as String,
      author: json['author'] as String? ?? 'WallRio',
      url: json['url'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      category: json['category'] as String? ?? '',
      color:
          (json['color'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      isPremium: json['isPremium'] as bool? ?? false,
      subjectId: json['subjectId'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      previewVideo: json['previewVideo'] as String?,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$WallpaperToJson(_Wallpaper instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'author': instance.author,
      'url': instance.url,
      'thumbnail': instance.thumbnail,
      'tags': instance.tags,
      'category': instance.category,
      'color': instance.color,
      'isPremium': instance.isPremium,
      'subjectId': instance.subjectId,
      'videoUrl': instance.videoUrl,
      'previewVideo': instance.previewVideo,
      'type': instance.type,
    };

_RioData _$RioDataFromJson(Map<String, dynamic> json) => _RioData(
      subscription: (json['subscription'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      banners: (json['banners'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      search: json['search'] as Map<String, dynamic>? ?? const {},
      walls: (json['walls'] as List<dynamic>?)
              ?.map((e) => Wallpaper.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      collections: (json['collections'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$RioDataToJson(_RioData instance) => <String, dynamic>{
      'subscription': instance.subscription,
      'banners': instance.banners,
      'search': instance.search,
      'walls': instance.walls,
      'collections': instance.collections,
    };
