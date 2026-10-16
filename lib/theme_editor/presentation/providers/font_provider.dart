import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/remote/font_catalog_datasource.dart';
import '../../data/datasources/remote/font_remote_datasource.dart';
import '../../data/models/font_model.dart';
import '../../data/models/unified_font.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/element_widget.dart';
import '../../core/utils/remote_fonts.dart';
import 'service_providers.dart';

typedef FontUsage = ({UnifiedFont font, int count});

class FontUsageNotifier extends Notifier<Map<String, FontUsage>> {
  static const preferenceKey = 'lockscreen_font_usage';

  @override
  Map<String, FontUsage> build() {
    final saved = ref.watch(sharedPrefsProvider).getString(preferenceKey);
    if (saved == null) return {};
    try {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      return {
        for (final entry in json.entries)
          entry.key: (
            font: UnifiedFont.fromJson(
              Map<String, dynamic>.from(entry.value['font'] as Map),
            ),
            count: (entry.value['count'] as int).clamp(0, 1 << 53),
          ),
      };
    } catch (error) {
      debugPrint('Could not restore frequent fonts: $error');
      return {};
    }
  }

  Future<void> rememberFont(UnifiedFont font) => _save({
    ...state,
    font.storageKey: (font: font, count: state[font.storageKey]?.count ?? 0),
  });

  Future<void> recordExport(Iterable<LockElement> elements) async {
    final fonts = elements
        .where(
          (element) =>
              element.isVisible &&
              element.type.isExportable &&
              element.type.supportsCustomFont &&
              element.font.isNotEmpty,
        )
        .map((element) => element.font)
        .toSet();
    if (fonts.isEmpty) return;
    final updated = {...state};
    for (final key in fonts) {
      final usage = updated[key];
      updated[key] = (
        font: usage?.font ?? UnifiedFont.fromStorageKey(key),
        count: (usage?.count ?? 0) + 1,
      );
    }
    await _save(updated);
  }

  Future<void> _save(Map<String, FontUsage> updated) async {
    state = updated;
    try {
      final saved = await ref
          .read(sharedPrefsProvider)
          .setString(
            preferenceKey,
            jsonEncode(
              updated.map(
                (key, usage) => MapEntry(key, {
                  'font': usage.font.toJson(),
                  'count': usage.count,
                }),
              ),
            ),
          );
      if (!saved) debugPrint('Could not save frequent fonts');
    } catch (error) {
      debugPrint('Could not save frequent fonts: $error');
    }
  }
}

final fontUsageProvider =
    NotifierProvider<FontUsageNotifier, Map<String, FontUsage>>(
      FontUsageNotifier.new,
    );

final frequentFontsProvider = Provider<List<UnifiedFont>>((ref) {
  final used = ref
      .watch(fontUsageProvider)
      .values
      .where((usage) => usage.count > 0)
      .toList();
  used.sort((first, second) {
    final rank = second.count.compareTo(first.count);
    if (rank != 0) return rank;
    final nameOrder = first.font.name.compareTo(second.font.name);
    return nameOrder != 0
        ? nameOrder
        : first.font.storageKey.compareTo(second.font.storageKey);
  });
  return used.map((usage) => usage.font).toList();
});

final fontRemoteDsProvider = Provider<FontRemoteDataSource>(
  (_) => FontRemoteDataSource(),
);

class FontUserNotifier extends Notifier<UserProfileType> {
  @override
  UserProfileType build() => UserProfileType.suraj;
  void select(UserProfileType t) {
    if (state == t) return;
    try {
      state = t;
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state != t) state = t;
      });
    }
  }
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
  FontSource build() => FontSource.frequent;
  void select(FontSource s) {
    if (state == s) return;
    try {
      state = s;
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state != s) state = s;
      });
    }
  }
}

final fontSourceProvider = NotifierProvider<FontSourceNotifier, FontSource>(
  FontSourceNotifier.new,
);

final googleFontListProvider = Provider<List<UnifiedFont>>((ref) {
  return GoogleFonts.asMap().keys
      .map(
        (name) => UnifiedFont(
          name: name,
          fontFamily: name,
          source: FontSource.google,
        ),
      )
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

final fontCatalogDsProvider = Provider<FontCatalogDataSource>(
  (_) => FontCatalogDataSource(),
);

final fontsourceCatalogProvider = FutureProvider<List<UnifiedFont>>(
  (ref) => ref.read(fontCatalogDsProvider).fetchFontsource(),
);

final fontshareCatalogProvider = FutureProvider<List<UnifiedFont>>(
  (ref) => ref.read(fontCatalogDsProvider).fetchFontshare(),
);

final unifiedFontListProvider = FutureProvider<List<UnifiedFont>>((ref) async {
  final source = ref.watch(fontSourceProvider);
  if (source == FontSource.frequent) {
    final fonts = ref.watch(frequentFontsProvider);
    await Future.wait([
      for (final font in fonts)
        if (font.source == FontSource.api && font.url != null)
          RemoteFonts.ensure(font.fontFamily, font.url!),
    ]);
    return fonts;
  }
  if (source == FontSource.fontsource) {
    return ref.watch(fontsourceCatalogProvider.future);
  }
  if (source == FontSource.fontshare) {
    return ref.watch(fontshareCatalogProvider.future);
  }
  if (source == FontSource.google) {
    return ref.watch(googleFontListProvider);
  }
  final fonts = await ref.watch(fontListProvider.future);
  return fonts
      .map(
        (f) => UnifiedFont(
          name: f.name,
          fontFamily: f.fontFamily,
          source: FontSource.api,
          url: f.url,
        ),
      )
      .toList();
});
