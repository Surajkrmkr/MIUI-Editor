import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/update_installer_service.dart';
import '../../data/datasources/remote/github_release_datasource.dart';
import '../../data/repositories/update_repository_impl.dart';
import '../../domain/entities/update_info.dart';
import '../../domain/repositories/update_repository.dart';
import '../../domain/usecases/app_update_usecase.dart';
import 'service_providers.dart';

enum UpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  installing,
  error,
}

class UpdateState {
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.currentVersion = '',
    this.info,
    this.progress = 0,
    this.message,
  });

  final UpdatePhase phase;
  final String currentVersion;
  final UpdateInfo? info;
  final double progress;
  final String? message;

  UpdateState copyWith({
    UpdatePhase? phase,
    String? currentVersion,
    UpdateInfo? info,
    double? progress,
    String? message,
  }) => UpdateState(
    phase: phase ?? this.phase,
    currentVersion: currentVersion ?? this.currentVersion,
    info: info ?? this.info,
    progress: progress ?? this.progress,
    message: message,
  );
}

final updateRepositoryProvider = Provider<UpdateRepository>(
  (ref) => UpdateRepositoryImpl(GitHubReleaseDatasource()),
);

final appUpdateUseCaseProvider = Provider<AppUpdateUseCase>(
  (ref) => AppUpdateUseCase(ref.watch(updateRepositoryProvider)),
);

final updateInstallerProvider = Provider<UpdateInstallerService>(
  (_) => const UpdateInstallerService(),
);

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);

final appVersionProvider = FutureProvider<String>(
  (_) async => (await PackageInfo.fromPlatform()).version,
);

class UpdateNotifier extends Notifier<UpdateState> {
  static const _launchCheckInterval = Duration(hours: 12);

  static String? get platform {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return null;
  }

  @override
  UpdateState build() => const UpdateState();

  /// Silent, throttled check for app start-up; ignores skipped versions.
  Future<void> checkOnLaunch() async {
    final prefs = ref.read(sharedPrefsProvider);
    final last = prefs.getInt(AppConstants.prefsUpdateLastCheck) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    if (elapsed < _launchCheckInterval.inMilliseconds) return;
    await check(silent: true);
  }

  Future<void> check({bool silent = false}) async {
    final os = platform;
    if (os == null || state.phase == UpdatePhase.checking) return;
    state = state.copyWith(phase: UpdatePhase.checking);

    final prefs = ref.read(sharedPrefsProvider);
    final version = (await PackageInfo.fromPlatform()).version;
    final (info, failure) = await ref
        .read(appUpdateUseCaseProvider)
        .check(version, os);
    await prefs.setInt(
      AppConstants.prefsUpdateLastCheck,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (failure != null) {
      state = UpdateState(
        phase: silent ? UpdatePhase.idle : UpdatePhase.error,
        currentVersion: version,
        message: silent ? null : failure.message,
      );
    } else if (info == null) {
      state = UpdateState(
        phase: silent ? UpdatePhase.idle : UpdatePhase.upToDate,
        currentVersion: version,
      );
    } else if (silent &&
        prefs.getString(AppConstants.prefsUpdateSkipped) == info.version) {
      state = UpdateState(currentVersion: version);
    } else {
      state = UpdateState(
        phase: UpdatePhase.available,
        currentVersion: version,
        info: info,
      );
    }
  }

  Future<void> skipVersion() async {
    final info = state.info;
    if (info != null) {
      await ref
          .read(sharedPrefsProvider)
          .setString(AppConstants.prefsUpdateSkipped, info.version);
    }
    state = UpdateState(currentVersion: state.currentVersion);
  }

  void dismiss() => state = UpdateState(currentVersion: state.currentVersion);

  Future<void> install() async {
    final info = state.info;
    if (info == null || state.phase == UpdatePhase.downloading) return;
    state = state.copyWith(phase: UpdatePhase.downloading, progress: 0);

    final (zipPath, failure) = await ref
        .read(appUpdateUseCaseProvider)
        .download(
          info,
          onProgress: (value) => state = state.copyWith(progress: value),
        );
    if (zipPath == null) {
      state = state.copyWith(
        phase: UpdatePhase.error,
        message: failure?.message ?? 'Download failed',
      );
      return;
    }

    state = state.copyWith(phase: UpdatePhase.installing);
    final installFailure = await ref
        .read(updateInstallerProvider)
        .install(zipPath);
    if (installFailure != null) {
      state = state.copyWith(
        phase: UpdatePhase.error,
        message: installFailure.message,
      );
    }
  }
}
