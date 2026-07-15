import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ConsentService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return _storage.read(key: 'access_token');
  }

  /// Record user's consent acceptance for Terms + Privacy + Marketing.
  Future<bool> acceptConsent({
    required bool termsAccepted,
    required bool privacyAccepted,
    bool marketingConsent = false,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/consent/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'terms_accepted': termsAccepted,
          'privacy_accepted': privacyAccepted,
          'marketing_consent': marketingConsent,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Check if the user has accepted the current version of T&C.
  Future<Map<String, dynamic>> getConsentStatus() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/consent/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'terms_accepted': false, 'is_current_version': false};
    } catch (_) {
      return {'terms_accepted': false, 'is_current_version': false};
    }
  }
}
