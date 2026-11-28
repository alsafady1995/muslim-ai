/// Build-time configuration. Pass with:
///   flutter run --dart-define-from-file=env/dev.json
/// Never commit real values; see env/example.json.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const revenueCatAppleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
  static const revenueCatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  static const premiumEntitlement = String.fromEnvironment('REVENUECAT_ENTITLEMENT_ID', defaultValue: 'premium');
  static const posthogKey = String.fromEnvironment('POSTHOG_KEY');
  static const posthogHost = String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://eu.i.posthog.com');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const environment = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL', defaultValue: 'https://asmi3ni.com/privacy/');
  static const termsUrl = String.fromEnvironment('TERMS_URL', defaultValue: 'https://asmi3ni.com/terms/');

  /// Web preview with no backend: auth, AI and payments are simulated (lib/demo/).
  static const demoMode = bool.fromEnvironment('DEMO_MODE');

  /// Internal builds only: Settings → Accuracy recordings, for the recitation accuracy
  /// benchmark (scripts/accuracy). Never set in store builds.
  static const benchmarkRecorder = bool.fromEnvironment('BENCHMARK_RECORDER');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
