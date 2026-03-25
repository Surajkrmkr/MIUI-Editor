import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme_editor/presentation/providers/service_providers.dart';
import '../../core/services/deployment_service.dart';
import '../../domain/entities/deployment_config.dart';

// ── Service ───────────────────────────────────────────────────────────────────

final deploymentServiceProvider = Provider<DeploymentService>(
  (_) => DeploymentService(),
);

// ── State ─────────────────────────────────────────────────────────────────────

class DeploymentState {
  const DeploymentState({
    this.isRunning = false,
    this.completed = false,
    this.outputLines = const [],
    this.config = const DeploymentConfig(),
  });

  final bool isRunning;
  final bool completed;
  final List<String> outputLines;
  final DeploymentConfig config;

  DeploymentState copyWith({
    bool? isRunning,
    bool? completed,
    List<String>? outputLines,
    DeploymentConfig? config,
  }) =>
      DeploymentState(
        isRunning: isRunning ?? this.isRunning,
        completed: completed ?? this.completed,
        outputLines: outputLines ?? this.outputLines,
        config: config ?? this.config,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DeploymentNotifier extends Notifier<DeploymentState> {
  StreamSubscription<String>? _sub;

  @override
  DeploymentState build() {
    final prefs = ref.read(sharedPrefsProvider);
    return DeploymentState(
      config: DeploymentConfig(
        scriptsDir: prefs.getString('deploy_scripts_dir') ?? '',
        basePath: prefs.getString('deploy_base_path') ?? '',
        maxTab: prefs.getInt('deploy_max_tab') ?? 9,
        email: prefs.getString('deploy_email') ?? '',
        password: prefs.getString('deploy_password') ?? '',
        description: prefs.getString('deploy_description') ?? '',
      ),
    );
  }

  void updateConfig(DeploymentConfig config) {
    state = state.copyWith(config: config);
    _persistConfig(config);
  }

  Future<void> run() async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, completed: false, outputLines: []);

    _sub = ref.read(deploymentServiceProvider).start(state.config).listen(
      (line) => state = state.copyWith(
        outputLines: [...state.outputLines, line],
      ),
      onDone: () {
        state = state.copyWith(isRunning: false, completed: true);
        _sub = null;
      },
      onError: (Object e) {
        state = state.copyWith(
          isRunning: false,
          outputLines: [...state.outputLines, '[FATAL] $e'],
        );
        _sub = null;
      },
    );
  }

  void stop() {
    ref.read(deploymentServiceProvider).stop();
    _sub?.cancel();
    _sub = null;
    state = state.copyWith(isRunning: false);
  }

  void clearOutput() => state = state.copyWith(outputLines: [], completed: false);

  void _persistConfig(DeploymentConfig c) {
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString('deploy_scripts_dir', c.scriptsDir);
    prefs.setString('deploy_base_path', c.basePath);
    prefs.setInt('deploy_max_tab', c.maxTab);
    prefs.setString('deploy_email', c.email);
    prefs.setString('deploy_password', c.password);
    prefs.setString('deploy_description', c.description);
  }
}

final deploymentProvider =
    NotifierProvider<DeploymentNotifier, DeploymentState>(
  DeploymentNotifier.new,
);
