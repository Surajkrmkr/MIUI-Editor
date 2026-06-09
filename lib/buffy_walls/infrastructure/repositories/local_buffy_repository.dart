import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/buffy_wallpaper.dart';
import '../../domain/repositories/buffy_wallpaper_repository.dart';

class LocalBuffyRepository implements BuffyWallpaperRepository {
  @override
  Future<List<BuffyWallpaper>> loadWallpapers(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return [];
    }
    
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    
    return await compute(_parseBuffyData, content);
  }

  @override
  Future<void> saveWallpapers(String filePath, List<BuffyWallpaper> wallpapers) async {
    final file = File(filePath);
    String originalContent = '{}';
    if (await file.exists()) {
      originalContent = await file.readAsString();
    }
    
    final data = {
      'content': originalContent,
      'wallpapers': wallpapers.map((e) => e.toJson()).toList(),
    };
    
    final jsonString = await compute(_updateAndStringifyBuffyData, data);
    await file.writeAsString(jsonString);
  }
}

List<BuffyWallpaper> _parseBuffyData(String content) {
  final Map<String, dynamic> json = jsonDecode(content);
  final List<dynamic>? popular = json['popular'] as List<dynamic>?;
  if (popular == null) return [];
  return popular.map((e) => BuffyWallpaper.fromJson(e as Map<String, dynamic>)).toList();
}

String _updateAndStringifyBuffyData(Map<String, dynamic> args) {
  final String originalContent = args['content'] as String;
  final List<dynamic> wallpapersJson = args['wallpapers'] as List<dynamic>;
  
  Map<String, dynamic> fullJson = {};
  try {
    if (originalContent.trim().isNotEmpty) {
      fullJson = jsonDecode(originalContent) as Map<String, dynamic>;
    }
  } catch (_) {}
  
  fullJson['popular'] = wallpapersJson;
  
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(fullJson);
}
