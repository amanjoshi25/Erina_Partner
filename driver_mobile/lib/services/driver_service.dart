import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';
import 'auth_service.dart';

class DriverService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token ?? ''}"
    };
  }

  /// Fetch driver profile details
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/drivers/profile"),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to fetch profile"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Update driver profile details
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String dob, // YYYY-MM-DD
    required String sex,
    required String emergencyContactNo,
    String? email,
    String? emergencyContactName,
    String? emergencyContactRelation,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/drivers/profile"),
        headers: headers,
        body: jsonEncode({
          "full_name": fullName,
          "dob": dob,
          "sex": sex,
          "emergency_contact_no": emergencyContactNo,
          "email": email,
          "emergency_contact_name": emergencyContactName,
          "emergency_contact_relation": emergencyContactRelation,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Profile update failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Fetch driver permanent address details
  Future<Map<String, dynamic>> getAddress() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/drivers/address"),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Address not found"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Set up or update driver address
  Future<Map<String, dynamic>> saveAddress({
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/drivers/address"),
        headers: headers,
        body: jsonEncode({
          "address_line1": addressLine1,
          "address_line2": addressLine2,
          "city": city,
          "state": state,
          "postal_code": postalCode,
          "country": country,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Address save failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Upload Driver Document (DL, PAN, Selfie) to KYC upload endpoint
  Future<Map<String, dynamic>> uploadDocument({
    required String documentType, // driving_licence, pan_card, selfie
    required String filePath,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/kyc/upload"),
      );

      request.headers["Authorization"] = "Bearer ${token ?? ''}";
      request.fields["document_type"] = documentType;
      
      String extension = filePath.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') {
        mimeType = 'image/png';
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Document upload failed"};
      }
    } catch (e) {
      return {"success": false, "message": "File upload error: $e"};
    }
  }

  /// Get status of all uploads & KYC requests
  Future<Map<String, dynamic>> getKycStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/kyc/status"),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "kyc_status": data["kyc_status"], "documents": data["documents"]};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to fetch KYC status"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Admin bypass function for local sandbox testing: approve/reject documents
  Future<Map<String, dynamic>> adminVerifyDocument({
    required String documentId,
    required String status, // approved, rejected
    String? rejectionReason,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/kyc/admin/verify"),
        headers: headers,
        body: jsonEncode({
          "document_id": documentId,
          "status": status,
          "rejection_reason": rejectionReason,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Verification update failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
