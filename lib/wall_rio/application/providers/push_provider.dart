import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/push_models.dart';
import '../../infrastructure/services/fcm_sender_service.dart';

class PushCampaignsNotifier extends AsyncNotifier<List<PushCampaign>> {
  final _sender = FCMSenderService();

  @override
  FutureOr<List<PushCampaign>> build() async => [];

  Future<bool> sendCampaign({
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    required String targetTopic,
  }) async {
    final success = await _sender.sendToTopic(
      topic: targetTopic,
      title: title,
      body: body,
      imageUrl: imageUrl,
      deepLink: deepLink ?? '',
    );

    if (success) {
      final newCampaign = PushCampaign(
        id: const Uuid().v4(),
        title: title,
        body: body,
        imageUrl: imageUrl,
        deepLink: deepLink,
        targetTopic: targetTopic,
        createdAt: DateTime.now(),
        status: 'sent',
        sentCount: 1,
      );
      state = AsyncValue.data([newCampaign, ...state.value ?? []]);
    }
    return success;
  }
}

final pushCampaignsProvider =
    AsyncNotifierProvider<PushCampaignsNotifier, List<PushCampaign>>(
  PushCampaignsNotifier.new,
);

class PushTemplatesNotifier extends AsyncNotifier<List<PushTemplate>> {
  @override
  FutureOr<List<PushTemplate>> build() async {
    return [
      const PushTemplate(
        id: '1',
        name: 'New Collection',
        title: '🔥 New Collection Alert!',
        body: 'Check out our latest [Category] wallpapers now.',
      ),
      const PushTemplate(
        id: '2',
        name: 'Daily Trending',
        title: 'Trending Wallpapers of the Day',
        body: 'See what everyone is downloading right now.',
      ),
    ];
  }

  void saveTemplate(PushTemplate template) {
    state = AsyncValue.data([...state.value ?? [], template]);
  }
}

final pushTemplatesProvider =
    AsyncNotifierProvider<PushTemplatesNotifier, List<PushTemplate>>(
  PushTemplatesNotifier.new,
);

class FCMTopicsNotifier extends AsyncNotifier<List<FCMTopic>> {
  @override
  FutureOr<List<FCMTopic>> build() async {
    return const [
      FCMTopic(name: 'all', subscriberCount: 0),
      FCMTopic(name: 'anime', subscriberCount: 0),
      FCMTopic(name: 'amoled', subscriberCount: 0),
      FCMTopic(name: 'premium', subscriberCount: 0),
    ];
  }
}

final fcmTopicsProvider =
    AsyncNotifierProvider<FCMTopicsNotifier, List<FCMTopic>>(
  FCMTopicsNotifier.new,
);
