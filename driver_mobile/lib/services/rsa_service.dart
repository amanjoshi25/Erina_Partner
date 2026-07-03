import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class RsaService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token ?? ''}"
    };
  }

  Future<Map<String, dynamic>> raiseRsaRequest({
    required double latitude,
    required double longitude,
    required String issueType,
    String? locationName,
    String? vehicleId,
    String? description,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/rsa/requests"),
        headers: headers,
        body: jsonEncode({
          "latitude": latitude,
          "longitude": longitude,
          "issue_type": issueType,
          "location_name": locationName ?? "Current Location",
          "vehicle_id": vehicleId,
          "description": description
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to create RSA request"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getActiveRsaRequest() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/rsa/requests/active"),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to check active RSA"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> cancelRsaRequest(String requestId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/rsa/requests/$requestId/cancel"),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"]};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to cancel request"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> submitFeedback({
    required String requestId,
    required int rating,
    String? comments,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/rsa/requests/$requestId/feedback"),
        headers: headers,
        body: jsonEncode({
          "rating": rating,
          "comments": comments
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"]};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to submit feedback"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
