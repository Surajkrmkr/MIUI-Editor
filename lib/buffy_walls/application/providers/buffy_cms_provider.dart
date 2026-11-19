import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/buffy_catalog_json.dart';
import '../../domain/models/buffy_wallpaper.dart';
import 'buffy_storage_provider.dart';

class BuffyCmsState {
  final List<BuffyWallpaper> wallpapers;

  /// Root fields of the catalog other than the wallpapers (banners, titles, …).
  final Map<String, dynamic> fields;
  final bool isLoading;
  final String? error;

  /// The catalog as loaded from Cloudflare R2, and its generation. Null until loaded.
  final String? catalogJson;
  final String? generation;

  /// Edits not published yet; they exist only in memory.
  final bool isDirty;

  BuffyCmsState({
    this.wallpapers = const [],
    this.fields = const {},
    this.isLoading = false,
    this.error,
    this.catalogJson,
    this.generation,
    this.isDirty = false,
  });

  BuffyCmsState copyWith({
    List<BuffyWallpaper>? wallpapers,
    Map<String, dynamic>? fields,
    bool? isLoading,
    String? error,
    String? catalogJson,
    String? generation,
    bool? isDirty,
  }) {
    return BuffyCmsState(
      wallpapers: wallpapers ?? this.wallpapers,
      fields: fields ?? this.fields,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      catalogJson: catalogJson ?? this.catalogJson,
      generation: generation ?? this.generation,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class BuffyCmsNotifier extends Notifier<BuffyCmsState> {
  @override
  BuffyCmsState build() {
    // Signing in rebuilds the publisher; pick up the catalog then.
    ref.listen(buffyCatalogPublisherProvider, (_, next) {
      if (next is AsyncData && !state.isDirty) load();
    });
    Future.microtask(load);
    return BuffyCmsState();
  }

  Future<void>? _loading;

  /// Loads the live catalog from Cloudflare R2, dropping unpublished edits.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final publisher = await ref.read(buffyCatalogPublisherProvider.future);
      final live = await publisher.load();
      final walls = await compute(parseBuffyCatalog, live.json);
      final fields = await compute(parseBuffyCatalogFields, live.json);
      state = state.copyWith(
        wallpapers: walls,
        fields: fields,
        isLoading: false,
        catalogJson: live.json,
        generation: live.generation,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// The catalog with the current edits applied.
  Future<String> buildCatalogJson() => compute(encodeBuffyCatalog, (
    catalog: state.catalogJson!,
    fields: state.fields,
    wallpapers: state.wallpapers.map((w) => w.toJson()).toList(),
  ));

  /// Sets a root field; new keys go last.
  void setField(String key, Object? value) {
    if (key == kBuffyWallpapersKey) {
      throw ArgumentError('"$key" is edited through the wallpaper actions');
    }
    state = state.copyWith(
      fields: {...state.fields, key: value},
      isDirty: true,
    );
  }

  void removeField(String key) {
    state = state.copyWith(
      fields: {...state.fields}..remove(key),
      isDirty: true,
    );
  }

  void markPublished(String json, String generation) {
    state = state.copyWith(
      catalogJson: json,
      generation: generation,
      isDirty: false,
    );
  }

  void addWallpaper(BuffyWallpaper wallpaper) {
    state = state.copyWith(
      wallpapers: [wallpaper, ...state.wallpapers],
      isDirty: true,
    );
  }

  void updateWallpaper(BuffyWallpaper wallpaper) {
    state = state.copyWith(
      wallpapers: state.wallpapers
          .map((w) => w.id == wallpaper.id ? wallpaper : w)
          .toList(),
      isDirty: true,
    );
  }

  void deleteWallpaper(int id) {
    state = state.copyWith(
      wallpapers: state.wallpapers.where((w) => w.id != id).toList(),
      isDirty: true,
    );
  }
}

final buffyCmsProvider = NotifierProvider<BuffyCmsNotifier, BuffyCmsState>(() {
  return BuffyCmsNotifier();
});
