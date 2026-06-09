import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/remote/font_remote_datasource.dart';
import '../../data/models/font_model.dart';
import '../../data/models/unified_font.dart';
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
  ref.keepAlive();
  return [...result.fonts]..sort((a, b) => b.id.compareTo(a.id));
});

final fontListProvider = FutureProvider<List<FontEntry>>((ref) async {
  final type = ref.watch(fontUserSelectionProvider);
  return ref.watch(fontListFamilyProvider(type).future);
});

// --- Google Fonts / unified source ---

class FontSourceNotifier extends Notifier<FontSource> {
  @override
  FontSource build() => FontSource.api;
  void select(FontSource s) => state = s;
}

final fontSourceProvider =
    NotifierProvider<FontSourceNotifier, FontSource>(FontSourceNotifier.new);

final googleFontListProvider = Provider<List<UnifiedFont>>((ref) {
  return GoogleFonts.asMap()
      .keys
      .map((name) => UnifiedFont(name: name, fontFamily: name, source: FontSource.google))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

final unifiedFontListProvider = FutureProvider<List<UnifiedFont>>((ref) async {
  final source = ref.watch(fontSourceProvider);
  if (source == FontSource.google) {
    return ref.watch(googleFontListProvider);
  }
  final fonts = await ref.watch(fontListProvider.future);
  return fonts
      .map((f) => UnifiedFont(name: f.name, fontFamily: f.fontFamily, source: FontSource.api))
      .toList();
});
