import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyToken = 'driver_token';
  static const String _keyDriverId = 'driver_id';
  static const String _keyDriverName = 'driver_name';
  static const String _keyDriverPhone = 'driver_phone';
  static const String _keyDriverUsername = 'driver_username';

  // Save session upon successful login (valid 45 days)
  static Future<void> saveSession({
    required String token,
    required int driverId,
    required String driverName,
    required String driverPhone,
    required String driverUsername,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyDriverId, driverId);
    await prefs.setString(_keyDriverName, driverName);
    await prefs.setString(_keyDriverPhone, driverPhone);
    await prefs.setString(_keyDriverUsername, driverUsername);
  }

  // Check if session exists
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  // Get current token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Get driver id
  static Future<int?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDriverId);
  }

  // Get driver name
  static Future<String> getDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriverName) ?? 'Sopir';
  }

  // Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
