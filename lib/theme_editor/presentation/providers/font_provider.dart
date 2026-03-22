import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/font_remote_datasource.dart';
import '../../data/models/font_model.dart';
import 'user_profile_provider.dart';

final fontRemoteDsProvider =
    Provider<FontRemoteDataSource>((_) => FontRemoteDataSource());

final fontListProvider = FutureProvider<List<FontEntry>>((ref) async {
  final profile = ref.watch(activeUserProfileProvider);
  if (profile == null) return [];
  final ds = ref.read(fontRemoteDsProvider);
  final result = await ds.fetchFonts(profile.fontApiUrl);
  return [...result.fonts]..sort((a, b) => b.id.compareTo(a.id));
});
