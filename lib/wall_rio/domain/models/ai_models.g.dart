// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AIAnalysisResult _$AIAnalysisResultFromJson(Map<String, dynamic> json) =>
    _AIAnalysisResult(
      name: json['name'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      colors:
          (json['colors'] as List<dynamic>).map((e) => e as String).toList(),
      category: json['category'] as String?,
    );

Map<String, dynamic> _$AIAnalysisResultToJson(_AIAnalysisResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'tags': instance.tags,
      'colors': instance.colors,
      'category': instance.category,
    };
