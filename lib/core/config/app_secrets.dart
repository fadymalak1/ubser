/// Central place for runtime secrets (API keys).
///
/// IMPORTANT:
/// Never hardcode real API keys here. Google scans public repositories and
/// will automatically disable any key that gets pushed in source.
///
/// Inject the Gemini key at build/run time via `--dart-define`:
///
///   flutter run --dart-define=GEMINI_API_KEY=YOUR_NEW_KEY
///   flutter build apk --dart-define=GEMINI_API_KEY=YOUR_NEW_KEY
///
/// When the key is missing, [AppSecrets.geminiApiKey] returns an empty
/// string and every Gemini call gracefully falls back to offline logic.
class AppSecrets {
  const AppSecrets._();

  /// Gemini API key (Google AI Studio).
  ///
  /// Returns an empty string when not provided so the app keeps running
  /// without crashing — the AI features simply use their offline fallbacks.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// True only when a non-empty Gemini key has been injected.
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
