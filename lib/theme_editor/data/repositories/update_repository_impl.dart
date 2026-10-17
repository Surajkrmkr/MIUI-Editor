import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/update_info.dart';
import '../../domain/repositories/update_repository.dart';
import '../datasources/remote/github_release_datasource.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  UpdateRepositoryImpl(this._source, {Dio? dio, Directory? stagingDir})
    : _dio = dio ?? Dio(),
      _stagingDir =
          stagingDir ??
          Directory(p.join(Directory.systemTemp.path, stagingName));

  static const stagingName = 'miui_editor_update';
  static final _assetName = RegExp(
    r'^Miui-Editor-[A-Za-z0-9._-]+-(macos|windows)\.zip$',
  );
  static final _sha256 = RegExp(r'^[0-9a-fA-F]{64}$');

  final GitHubReleaseDatasource _source;
  final Dio _dio;
  final Directory _stagingDir;

  @override
  Future<(UpdateInfo?, Failure?)> checkForUpdate({
    required String currentVersion,
    required String platform,
  }) async {
    try {
      final release = await _source.fetchLatestRelease();
      final tag = release['tag_name'];
      if (tag is! String) {
        return (null, const ValidationFailure('Release has no version tag'));
      }
      final latest = Version.parse(tag.replaceFirst(RegExp('^[vV]'), ''));
      final current = Version.parse(currentVersion);
      if (latest <= current) return (null, null);

      final assets = <String, String>{};
      for (final asset in (release['assets'] as List? ?? const [])) {
        if (asset is Map && asset['name'] is String) {
          final url = asset['browser_download_url'];
          if (url is String) assets[asset['name'] as String] = url;
        }
      }
      final name = assets.keys.firstWhere(
        (n) => _assetName.hasMatch(n) && n.endsWith('-$platform.zip'),
        orElse: () => '',
      );
      final assetUrl = assets[name];
      final checksumUrl = assets['$name.sha256'];
      if (assetUrl == null || checksumUrl == null) {
        return (
          null,
          ValidationFailure('Release $tag has no verified $platform build'),
        );
      }
      if (!_isGitHubUrl(assetUrl) || !_isGitHubUrl(checksumUrl)) {
        return (null, const ValidationFailure('Untrusted download location'));
      }
      return (
        UpdateInfo(
          version: latest.toString(),
          notes: release['body'] as String? ?? '',
          pageUrl: release['html_url'] as String? ?? '',
          assetName: name,
          assetUrl: assetUrl,
          checksumUrl: checksumUrl,
        ),
        null,
      );
    } on FormatException catch (e) {
      return (null, ValidationFailure('Invalid version: ${e.message}'));
    } on TimeoutException {
      return (null, const NetworkFailure('Update check timed out'));
    } on SocketException catch (e) {
      return (null, NetworkFailure('Update check failed: ${e.message}'));
    } catch (e) {
      return (null, NetworkFailure('Update check failed: $e'));
    }
  }

  @override
  Future<(String?, Failure?)> download(
    UpdateInfo info, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (!_assetName.hasMatch(info.assetName) ||
          !_isGitHubUrl(info.assetUrl) ||
          !_isGitHubUrl(info.checksumUrl)) {
        return (null, const ValidationFailure('Untrusted update package'));
      }
      final expected = _parseChecksum(
        await _source.fetchChecksum(Uri.parse(info.checksumUrl)),
        info.assetName,
      );
      if (expected == null) {
        return (null, const ValidationFailure('Malformed checksum file'));
      }

      if (await _stagingDir.exists()) await _stagingDir.delete(recursive: true);
      await _stagingDir.create(recursive: true);
      final zipPath = p.join(_stagingDir.path, info.assetName);
      await _dio.download(
        info.assetUrl,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );

      final actual = (await sha256.bind(File(zipPath).openRead()).first)
          .toString();
      if (actual != expected) {
        await File(zipPath).delete();
        return (null, const ValidationFailure('Checksum mismatch'));
      }
      return (zipPath, null);
    } on DioException catch (e) {
      return (null, NetworkFailure('Download failed: ${e.message}'));
    } on FileSystemException catch (e) {
      return (null, FileFailure('Could not save update: ${e.message}'));
    } catch (e) {
      return (null, NetworkFailure('Download failed: $e'));
    }
  }

  static bool _isGitHubUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host == 'github.com';
  }

  /// Accepts `sha256sum`/`shasum` output (`<hash>  <file>`) or a bare hash.
  static String? _parseChecksum(String text, String assetName) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || !_sha256.hasMatch(parts.first)) return null;
    if (parts.length > 1 &&
        p.basename(parts.last.replaceFirst('*', '')) != assetName) {
      return null;
    }
    return parts.first.toLowerCase();
  }
}
