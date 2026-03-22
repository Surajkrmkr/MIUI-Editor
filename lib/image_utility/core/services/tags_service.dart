import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:miui_icon_generator/theme_editor/core/constants/asset_paths.dart';

/// Service to load and manage valid tags from tags.json
class TagsService {
  List<String> _allTags = [];
  bool _isLoaded = false;

  /// Load tags from tags.json file
  Future<void> loadTags(String tagsJsonPath) async {
    if (_isLoaded) return;

    try {
      final file = File(tagsJsonPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        _parseTags(data);
        _isLoaded = true;
      } else {
        throw Exception('tags.json file not found at: $tagsJsonPath');
      }
    } catch (e) {
      throw Exception('Failed to load tags: $e');
    }
  }

  /// Load tags from bundled assets (fallback)
  Future<void> loadTagsFromAssets() async {
    if (_isLoaded) return;

    try {
      final content = await rootBundle.loadString(AssetPaths.tagsJson);
      final data = json.decode(content) as Map<String, dynamic>;
      _parseTags(data);
      _isLoaded = true;
    } catch (e) {
      // Use default tags if loading fails
      _loadDefaultTags();
    }
  }

  void _parseTags(Map<String, dynamic> data) {
    _allTags.clear();
    final dataList = data['data'] as List;
    
    for (final category in dataList) {
      final subTags = category['subTags'] as List;
      _allTags.addAll(subTags.map((tag) => tag.toString()));
    }

    // Remove duplicates and sort
    _allTags = _allTags.toSet().toList()..sort();
  }

  void _loadDefaultTags() {
    // Basic fallback tags
    _allTags = [
      'Simple',
    ];
    _isLoaded = true;
  }

  /// Get all available tags
  List<String> getAllTags() {
    if (!_isLoaded) {
      _loadDefaultTags();
    }
    return List.from(_allTags);
  }

  /// Check if tags are loaded
  bool get isLoaded => _isLoaded;

  /// Get tags count
  int get tagsCount => _allTags.length;
}
