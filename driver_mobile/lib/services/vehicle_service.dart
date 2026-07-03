import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';
import 'auth_service.dart';

class VehicleService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token ?? ''}"
    };
  }

  Future<Map<String, dynamic>> getVehicles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/vehicles"),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to fetch vehicles"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> addVehicle({
    required String registrationNumber,
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/vehicles"),
        headers: headers,
        body: jsonEncode({
          "registration_number": registrationNumber,
          "make": make,
          "model": model,
          "year": year,
          "color": color
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Failed to register vehicle"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getActiveVehicle() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/vehicles/active"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": "Active vehicle not found"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> uploadVehicleDocument({
    required String vehicleId,
    required String documentType, // rc_card, insurance, puc, fitness_certificate
    required String filePath,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/vehicles/$vehicleId/upload-document"),
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
        return {"success": false, "message": data["detail"] ?? "Failed to upload document"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
