import 'dart:io';

class ApiConfig {
  // Base URL for API requests
  static String get baseUrl {
    // In Android Emulator, localhost is 10.0.2.2.
    // For iOS Simulator, localhost is 127.0.0.1 / localhost.
    try {
      if (Platform.isAndroid) {
        return "http://10.0.2.2:8000/api/v1";
      }
    } catch (_) {
      // Fallback for web or non-mobile platforms
    }
    return "http://localhost:8000/api/v1";
  }

  // Base URL for fetching static files (e.g. uploaded images)
  static String get mediaUrl {
    try {
      if (Platform.isAndroid) {
        return "http://10.0.2.2:8000";
      }
    } catch (_) {}
    return "http://localhost:8000";
  }
}
