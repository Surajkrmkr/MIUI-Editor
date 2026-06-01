import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/font_remote_datasource.dart';
import '../../data/models/font_model.dart';
import '../../domain/entities/user_profile.dart';

final fontRemoteDsProvider =
    Provider<FontRemoteDataSource>((_) => FontRemoteDataSource());

class FontUserNotifier extends Notifier<UserProfileType> {
  @override
  UserProfileType build() => UserProfileType.suraj;
  void select(UserProfileType t) => state = t;
}

final fontUserSelectionProvider =
    NotifierProvider<FontUserNotifier, UserProfileType>(FontUserNotifier.new);

final fontListFamilyProvider =
    FutureProvider.family<List<FontEntry>, UserProfileType>((ref, type) async {
  final profile = kUserProfiles[type];
  if (profile == null) return [];
  final ds = ref.read(fontRemoteDsProvider);
  final result = await ds.fetchFonts(profile.fontApiUrl);
  
  // Keep the data in memory after the first fetch
  ref.keepAlive();
  
  return [...result.fonts]..sort((a, b) => b.id.compareTo(a.id));
});

// For compatibility with existing UI if needed, or we update the UI
final fontListProvider = FutureProvider<List<FontEntry>>((ref) async {
  final type = ref.watch(fontUserSelectionProvider);
  return ref.watch(fontListFamilyProvider(type).future);
});
