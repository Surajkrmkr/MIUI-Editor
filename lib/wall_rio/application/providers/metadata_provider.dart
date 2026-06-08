import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cms_provider.dart';

final existingTagsProvider = Provider<List<String>>((ref) {
  final data = ref.watch(cmsProvider).value;
  if (data == null) return [];
  return data.walls.expand((w) => w.tags).toSet().toList()..sort();
});

final existingCategoriesProvider = Provider<List<String>>((ref) {
  final data = ref.watch(cmsProvider).value;
  if (data == null) return [];
  return data.walls.map((w) => w.category).toSet().toList()..sort();
});

final existingColorsProvider = Provider<List<String>>((ref) {
  final data = ref.watch(cmsProvider).value;
  if (data == null) return [];
  return data.walls.expand((w) => w.color).toSet().toList()..sort();
});

final urlPatternProvider = Provider<String?>((ref) {
  final data = ref.watch(cmsProvider).value;
  if (data == null || data.walls.isEmpty) return null;
  final firstUrl = data.walls.first.url;
  final lastSlash = firstUrl.lastIndexOf('/');
  if (lastSlash == -1) return null;
  return firstUrl.substring(0, lastSlash + 1);
});

final thumbnailPatternProvider = Provider<String?>((ref) {
  final data = ref.watch(cmsProvider).value;
  if (data == null || data.walls.isEmpty) return null;
  final firstThumb = data.walls.first.thumbnail;
  final lastSlash = firstThumb.lastIndexOf('/');
  if (lastSlash == -1) return null;
  return firstThumb.substring(0, lastSlash + 1);
});
