import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/asset_paths.dart';
import '../../data/models/tag_model.dart';
import 'usecase_providers.dart';

class TagState {
  const TagState({
    this.data,
    this.appliedTags = const ['Simple','Abstract','Clock','cool','Regular','Slide'],
    this.searchQuery = '',
  });

  final TagsData?    data;
  final List<String> appliedTags;
  final String       searchQuery;

  bool get isLoaded   => data != null;
  bool get canAddMore => appliedTags.length < 6;

  List<String> get searchResults {
    if (searchQuery.isEmpty || data == null) return [];
    final q = searchQuery.toLowerCase();
    return data!.flat.where(
        (t) => t.toLowerCase().contains(q) && t.toLowerCase().startsWith(q))
        .toList();
  }

  TagState copyWith({
    TagsData? data, List<String>? appliedTags, String? searchQuery,
  }) => TagState(
    data:        data        ?? this.data,
    appliedTags: appliedTags ?? this.appliedTags,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

class TagNotifier extends Notifier<TagState> {
  @override
  TagState build() => const TagState();

  Future<void> load() async {
    final raw  = await rootBundle.loadString(AssetPaths.tagsJson);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    state = state.copyWith(data: TagsData.fromJson(json));
  }

  void setSearch(String q)  => state = state.copyWith(searchQuery: q);
  void clearSearch()        => state = state.copyWith(searchQuery: '');

  void addTag(String tag) {
    if (!state.canAddMore || state.appliedTags.contains(tag)) return;
    state = state.copyWith(appliedTags: [...state.appliedTags, tag]);
  }

  void removeTag(String tag) => state = state.copyWith(
    appliedTags: state.appliedTags.where((t) => t != tag).toList(),
  );

  void setTags(List<String> tags) => state = state.copyWith(appliedTags: tags);

  // ✅ Delegates to use case — no direct file IO here
  Future<void> saveToFile(String weekNum, String themeName) async {
    await ref.read(saveTagFileUseCaseProvider).call(
      weekNum, themeName, state.appliedTags);
  }

  Future<void> loadFromFile(String weekNum, String themeName) async {
    final (tags, _) = await ref
        .read(loadTagFileUseCaseProvider)
        .call(weekNum, themeName);
    if (tags != null && tags.isNotEmpty) {
      state = state.copyWith(appliedTags: tags);
    }
  }
}

final tagProvider = NotifierProvider<TagNotifier, TagState>(TagNotifier.new);
