import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for runtime secrets (API keys).
///
/// Keys are loaded with this priority:
///   1. `--dart-define=GEMINI_API_KEY=...` (highest — useful for CI/CD)
///   2. The `.env` file bundled as an asset (loaded by `dotenv.load()` in
///      `main()` before `runApp`)
///   3. Empty string — every Gemini call then surfaces a clear error to the
///      user instead of silently failing.
///
/// SECURITY:
/// Never hardcode real keys in source. Google scans public repositories and
/// will auto-disable any key that gets pushed. The `.env` file is in
/// `.gitignore` and is the recommended local store.
class AppSecrets {
  const AppSecrets._();

  /// `--dart-define` takes priority over the `.env` file.
  static const String _dartDefineGeminiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Gemini API key (Google AI Studio).
  ///
  /// Returns an empty string when not provided. UI layers should treat the
  /// empty case as "missing key" and show a clear message.
  static String get geminiApiKey {
    if (_dartDefineGeminiKey.isNotEmpty) {
      return _dartDefineGeminiKey;
    }
    try {
      final fromEnv = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
      return fromEnv.trim();
    } catch (_) {
      // dotenv was not initialised yet (or .env asset missing). Treat as empty.
      return '';
    }
  }

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
