import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'directory_provider.dart';
import 'service_providers.dart';

String presetFavoriteKey(String value) => path.normalize(path.absolute(value));

class PresetFavoritesNotifier extends Notifier<Set<String>> {
  static const preferenceKey = 'favorite_preset_paths';

  @override
  Set<String> build() => Set.unmodifiable(
    (ref.watch(sharedPrefsProvider).getStringList(preferenceKey) ?? <String>[])
        .map(presetFavoriteKey),
  );

  Future<void> _save(Set<String> values) async {
    final previous = state;
    state = Set.unmodifiable(values);
    try {
      final saved = await ref
          .read(sharedPrefsProvider)
          .setStringList(preferenceKey, values.toList()..sort());
      if (!saved) throw StateError('Could not save preset favorites');
    } catch (_) {
      if (state.length == values.length && state.containsAll(values)) {
        state = previous;
      }
      rethrow;
    }
  }

  Future<void> toggle(String value) {
    final key = presetFavoriteKey(value);
    final values = {...state};
    if (!values.remove(key)) values.add(key);
    return _save(values);
  }

  Future<void> remove(String value) =>
      _save({...state}..remove(presetFavoriteKey(value)));

  Future<void> rename(String previous, String next) {
    final values = {...state};
    if (!values.remove(presetFavoriteKey(previous))) return Future.value();
    values.add(presetFavoriteKey(next));
    return _save(values);
  }
}

final presetFavoritesProvider =
    NotifierProvider<PresetFavoritesNotifier, Set<String>>(
      PresetFavoritesNotifier.new,
    );
final favoritePresetsOnlyProvider = StateProvider<bool>((ref) => false);
final visiblePresetPathsProvider = Provider<List<String>>((ref) {
  final paths = ref.watch(
    directoryProvider.select((state) => state.presetPaths),
  );
  if (!ref.watch(favoritePresetsOnlyProvider)) return paths;
  final favorites = ref.watch(presetFavoritesProvider);
  return paths
      .where((value) => favorites.contains(presetFavoriteKey(value)))
      .toList();
});
