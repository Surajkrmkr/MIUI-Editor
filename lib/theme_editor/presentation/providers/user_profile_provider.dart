import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileNotifier extends Notifier<UserProfileType> {
  @override
  UserProfileType build() => UserProfileType.defaultUser;

  void select(UserProfileType t) {
    ref.read(iconStyleOverrideProvider.notifier).select(null);
    state = t;
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfileType>(
      UserProfileNotifier.new,
    );

/// Icon folder chosen in the style picker; null falls back to the profile's own set.
class IconStyleOverrideNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? folder) => state = folder;
}

final iconStyleOverrideProvider =
    NotifierProvider<IconStyleOverrideNotifier, String?>(
      IconStyleOverrideNotifier.new,
    );

final activeUserProfileProvider = Provider<UserProfile?>((ref) {
  final type = ref.watch(userProfileProvider);
  final profile = kUserProfiles[type];
  final folder = ref.watch(iconStyleOverrideProvider);
  if (profile == null || folder == null) return profile;
  return UserProfile(
    type: profile.type,
    iconFolder: folder,
    avatarAsset: profile.avatarAsset,
    fontApiUrl: profile.fontApiUrl,
    displayName: profile.displayName,
    authorTag: profile.authorTag,
  );
});
