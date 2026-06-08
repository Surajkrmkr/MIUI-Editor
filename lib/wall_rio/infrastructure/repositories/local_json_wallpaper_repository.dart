import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/wallpaper.dart';
import '../../domain/repositories/wallpaper_repository.dart';

class LocalJsonWallpaperRepository implements WallpaperRepository {
  @override
  Future<RioData> loadData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }
    
    final content = await file.readAsString();
    return await compute(_parseRioData, content);
  }

  @override
  Future<void> saveData(String filePath, RioData data) async {
    final jsonString = await compute(_stringifyRioData, data);
    final file = File(filePath);
    await file.writeAsString(jsonString);
  }
}

RioData _parseRioData(String content) {
  final Map<String, dynamic> json = jsonDecode(content);
  return RioData.fromJson(json);
}

String _stringifyRioData(RioData data) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(data.toJson());
}
