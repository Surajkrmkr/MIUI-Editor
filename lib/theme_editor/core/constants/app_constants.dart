import 'package:theme_core/theme_core.dart'
    show lockscreenScreenRatio, lockscreenViewHeight, lockscreenViewWidth;

abstract final class AppConstants {
  static const String appName = 'MIUI Editor';

  static const double screenHeight = lockscreenViewHeight;
  static const double screenWidth = lockscreenViewWidth;
  static const double screenRatio = lockscreenScreenRatio;

  static const double winWidth = 1400;
  static const double winHeight = 750;
  static const double winHeightMac = 800;

  static const int iconGridPreviewCount = 8;
  static const int iconGridPreviewOffset = 5;
  static const int defaultThemeCount = 25;

  static const String geminiModel = 'gemini-2.0-flash-lite';
  static const String groqModel = 'llama-3.3-70b-versatile';
  static const String ollamaDefaultModel = 'llama3.2';
  static const String ollamaDefaultHost = 'http://localhost:11434';

  static const String prefsThemeCount = 'themeSettings';
  static const String prefsGeminiKey = 'gemini_api_key';
  static const String prefsAiProvider = 'ai_provider';
  static const String prefsGroqKey = 'groq_api_key';
  static const String prefsOllamaHost = 'ollama_host';
  static const String prefsOllamaModel = 'ollama_model';

  static const String prefsAdbPath = 'adb_user_path';
  static const String prefsAdbLastWireless = 'adb_last_wireless';
  static const String prefsAdbLastSerial = 'adb_last_serial';
  static const String prefsAdbActivityCache = 'adb_activity_cache';
  static const String prefsCanvasLock = 'prefs_canvas_lock';

  static const String updateRepoOwner = 'Surajkrmkr';
  static const String updateRepoName = 'MIUI-Editor';
  static const String prefsUpdateLastCheck = 'update_last_check';
  static const String prefsUpdateSkipped = 'update_skipped_version';
}
