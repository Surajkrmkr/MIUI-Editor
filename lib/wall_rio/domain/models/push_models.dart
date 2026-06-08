import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_models.freezed.dart';
part 'push_models.g.dart';

@freezed
abstract class PushCampaign with _$PushCampaign {
  const factory PushCampaign({
    required String id,
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    required String targetTopic,
    required DateTime createdAt,
    DateTime? scheduledFor,
    @Default('pending') String status, // pending, sent, failed, scheduled
    int? sentCount,
    String? errorMessage,
  }) = _PushCampaign;

  factory PushCampaign.fromJson(Map<String, dynamic> json) => _$PushCampaignFromJson(json);
}

@freezed
abstract class PushTemplate with _$PushTemplate {
  const factory PushTemplate({
    required String id,
    required String name,
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    String? category,
  }) = _PushTemplate;

  factory PushTemplate.fromJson(Map<String, dynamic> json) => _$PushTemplateFromJson(json);
}

@freezed
abstract class FCMTopic with _$FCMTopic {
  const factory FCMTopic({
    required String name,
    required int subscriberCount,
    DateTime? lastUsed,
  }) = _FCMTopic;
}
