import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';

class GitHubReleaseDatasource {
  GitHubReleaseDatasource({
    http.Client? client,
    this.owner = AppConstants.updateRepoOwner,
    this.repo = AppConstants.updateRepoName,
  }) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 15);
  static const _maxChecksumBytes = 1024;

  final http.Client _client;
  final String owner;
  final String repo;

  /// `/releases/latest` already excludes drafts and prereleases.
  Future<Map<String, dynamic>> fetchLatestRelease() async {
    final response = await _client
        .get(
          Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest'),
          headers: const {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'miui-editor-updater',
          },
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw AppException('GitHub responded with ${response.statusCode}');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const AppException('Unexpected release response');
    }
    return json;
  }

  Future<String> fetchChecksum(Uri url) async {
    final response = await _client.get(url).timeout(_timeout);
    if (response.statusCode != 200 ||
        response.bodyBytes.length > _maxChecksumBytes) {
      throw const AppException('Checksum file could not be fetched');
    }
    return response.body;
  }
}
