/// Konfigurasi aplikasi dari environment variable saat compile time
/// Menggunakan modern Flutter standard: `--dart-define-from-file=config/env_<env>.json`
/// Tanpa third-party package tambahan, zero overhead, aman untuk binary release.
class AppConfig {
  /// Nama environment: 'local', 'dev', atau 'prod'
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'local',
  );

  /// Base URL API Backend
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Helper untuk mengecek environment aktif
  static bool get isLocal => env == 'local';
  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}
