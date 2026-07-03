import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class SubscriptionService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token ?? ''}"
    };
  }

  Future<Map<String, dynamic>> getPlans() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/subscriptions/plans"),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to fetch plans"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> subscribe({
    required String planId,
    required String transactionId,
    String paymentMethod = "Razorpay",
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/subscriptions/subscribe"),
        headers: headers,
        body: jsonEncode({
          "plan_id": planId,
          "transaction_id": transactionId,
          "payment_method": paymentMethod
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Subscription purchase failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/subscriptions/history"),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to fetch billing history"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
