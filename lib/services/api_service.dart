import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/api_constants.dart';
import '../core/session_manager.dart';

class ApiService {
  final http.Client _client = http.Client();

  // Helper untuk header request dengan bearer token
  Future<Map<String, String>> _getHeaders() async {
    final token = await SessionManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Login Driver
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = await ApiConstants.loginUrl;
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final driver = data['driver'];
        await SessionManager.saveSession(
          token: data['token'],
          driverId: driver['id'],
          driverName: driver['name'],
          driverPhone: driver['phone'] ?? '',
          driverUsername: driver['username'] ?? username,
        );
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Nama pengguna atau kata sandi salah'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Periksa jaringan atau IP server.'
      };
    }
  }

  // 2. Ambil Daftar Pengiriman Driver
  Future<List<dynamic>> getShipments() async {
    try {
      final driverId = await SessionManager.getDriverId();
      final baseUrl = await ApiConstants.shipmentsUrl;
      final url = driverId != null ? '$baseUrl?driver_id=$driverId' : baseUrl;

      final headers = await _getHeaders();
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 2b. Ambil Detail Pengiriman Driver Beserta Checkpoints
  Future<Map<String, dynamic>?> getShipmentDetail(int shipmentId) async {
    try {
      final baseUrl = await ApiConstants.shipmentsUrl;
      final url = '$baseUrl/$shipmentId';

      final headers = await _getHeaders();
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // 3. Unggah Foto Kamera
  Future<String?> uploadPhoto(XFile file) async {
    try {
      final url = await ApiConstants.uploadUrl;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['url'] as String;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // 4. Kirim Checkpoint (Absen, Kendala, Transit, Tiba)
  Future<bool> sendCheckpoint({
    required int shipmentId,
    required String checkpointType,
    required String statusLabel,
    String? description,
    String? photoUrl,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = await ApiConstants.checkpointUrl(shipmentId);
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'checkpoint_type': checkpointType,
          'status_label': statusLabel,
          'description': description,
          'photo_url': photoUrl,
          'latitude': latitude.toStringAsFixed(6),
          'longitude': longitude.toStringAsFixed(6),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
