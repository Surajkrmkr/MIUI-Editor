import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileNotifier extends Notifier<UserProfileType> {
  @override
  UserProfileType build() => UserProfileType.defaultUser;

  void select(UserProfileType t) => state = t;
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfileType>(UserProfileNotifier.new);

final activeUserProfileProvider = Provider<UserProfile?>((ref) {
  final type = ref.watch(userProfileProvider);
  return kUserProfiles[type];
});
