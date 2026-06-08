// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PushCampaign _$PushCampaignFromJson(Map<String, dynamic> json) =>
    _PushCampaign(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      deepLink: json['deepLink'] as String?,
      targetTopic: json['targetTopic'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scheduledFor: json['scheduledFor'] == null
          ? null
          : DateTime.parse(json['scheduledFor'] as String),
      status: json['status'] as String? ?? 'pending',
      sentCount: (json['sentCount'] as num?)?.toInt(),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$PushCampaignToJson(_PushCampaign instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'imageUrl': instance.imageUrl,
      'deepLink': instance.deepLink,
      'targetTopic': instance.targetTopic,
      'createdAt': instance.createdAt.toIso8601String(),
      'scheduledFor': instance.scheduledFor?.toIso8601String(),
      'status': instance.status,
      'sentCount': instance.sentCount,
      'errorMessage': instance.errorMessage,
    };

_PushTemplate _$PushTemplateFromJson(Map<String, dynamic> json) =>
    _PushTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      deepLink: json['deepLink'] as String?,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$PushTemplateToJson(_PushTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'title': instance.title,
      'body': instance.body,
      'imageUrl': instance.imageUrl,
      'deepLink': instance.deepLink,
      'category': instance.category,
    };
