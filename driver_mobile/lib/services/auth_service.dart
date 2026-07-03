import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  
  static const String _keyAccessToken = "access_token";
  static const String _keyRefreshToken = "refresh_token";

  /// Send login OTP request
  Future<Map<String, dynamic>> login(String mobileNumber) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mobile_number": mobileNumber}),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "OTP sent successfully",
          "debug_code": data["debug_code"],
        };
      } else {
        return {
          "success": false,
          "message": data["detail"] ?? "Failed to request OTP code",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Connection error: Could not reach backend ($e)",
      };
    }
  }

  /// Verify OTP and store tokens
  Future<Map<String, dynamic>> verifyOtp({
    required String mobileNumber,
    required String otp,
    String? deviceInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mobile_number": mobileNumber,
          "otp": otp,
          "device_info": deviceInfo ?? "Flutter Mobile Client",
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _storage.write(key: _keyAccessToken, value: data["access_token"]);
        await _storage.write(key: _keyRefreshToken, value: data["refresh_token"]);
        
        return {
          "success": true,
          "role": data["role"],
          "is_profile_complete": data["is_profile_complete"],
          "is_kyc_verified": data["is_kyc_verified"],
        };
      } else {
        return {
          "success": false,
          "message": data["detail"] ?? "OTP verification failed",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Verification error: $e",
      };
    }
  }

  /// Refresh the authentication tokens
  Future<Map<String, dynamic>> refreshToken() async {
    final rToken = await getRefreshToken();
    if (rToken == null) {
      return {"success": false, "message": "No refresh token stored"};
    }

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/auth/refresh-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": rToken}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _storage.write(key: _keyAccessToken, value: data["access_token"]);
        await _storage.write(key: _keyRefreshToken, value: data["refresh_token"]);
        return {
          "success": true,
          "is_profile_complete": data["is_profile_complete"],
          "is_kyc_verified": data["is_kyc_verified"],
        };
      } else {
        await logout();
        return {
          "success": false,
          "message": data["detail"] ?? "Session refresh failed",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Connection error: $e",
      };
    }
  }

  /// Fetch currently authenticated user system record
  Future<Map<String, dynamic>> getMe() async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/auth/me"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${token ?? ''}"
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to fetch user record"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Logout of the application
  Future<void> logout() async {
    final rToken = await getRefreshToken();
    if (rToken != null) {
      try {
        await http.post(
          Uri.parse("${ApiConfig.baseUrl}/auth/logout"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"refresh_token": rToken}),
        );
      } catch (_) {}
    }
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<bool> hasCredentials() async {
    final token = await getRefreshToken();
    return token != null;
  }
}
