class ApiConstants {
  // Base URL pointing to Next.js API
  // 10.0.2.2 is the localhost alias for Android Emulator
  // For physical device testing, change to your PC's LAN IP (e.g. http://192.168.1.10:3000)
  static const String baseUrl = 'http://10.0.2.2:3000';

  static const String loginUrl = '$baseUrl/api/mobile/auth/login';
  static const String shipmentsUrl = '$baseUrl/api/mobile/shipments';
  static const String uploadUrl = '$baseUrl/api/upload';

  static String checkpointUrl(int shipmentId) =>
      '$baseUrl/api/mobile/shipments/$shipmentId/checkpoint';
}
