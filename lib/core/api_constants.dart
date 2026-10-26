import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';

class ApiConstants {
  // Key penyimpanan custom server IP/URL untuk kemudahan testing di device fisik
  static const String _keyServerUrl = 'custom_server_url';

  // Base URL default diambil langsung dari compile-time environment AppConfig
  static String get defaultBaseUrl => AppConfig.baseUrl;

  // Simpan custom base URL (misal: http://192.168.1.5:3000 saat test di HP fisik)
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    var cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    // Jika user hanya input IP atau hostname tanpa http, otomatis lengkapi
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl:3000';
    }
    await prefs.setString(_keyServerUrl, cleanUrl);
  }

  // Reset ke URL bawaan environment saat ini
  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServerUrl);
  }

  // Dapatkan Base URL aktif (prioritas: custom override dev fisik -> AppConfig.baseUrl)
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl) ?? defaultBaseUrl;
  }

  // Endpoint URLs
  static Future<String> get loginUrl async => '${await getBaseUrl()}/api/mobile/auth/login';
  static Future<String> get shipmentsUrl async => '${await getBaseUrl()}/api/mobile/shipments';
  static Future<String> get uploadUrl async => '${await getBaseUrl()}/api/upload';

  static Future<String> checkpointUrl(int shipmentId) async =>
      '${await getBaseUrl()}/api/mobile/shipments/$shipmentId/checkpoint';
}
