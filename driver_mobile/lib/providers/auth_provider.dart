import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';

enum AuthState {
  uninitialized,
  unauthenticated,
  authenticating,
  otpSent,
  profileIncomplete,
  kycIncomplete,
  kycPendingReview,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DriverService _driverService = DriverService();

  AuthState _state = AuthState.uninitialized;
  AuthState get state => _state;

  String? _phoneNumber;
  String? get phoneNumber => _phoneNumber;

  String? _debugOtpCode;
  String? get debugOtpCode => _debugOtpCode;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _driverProfile;
  Map<String, dynamic>? get driverProfile => _driverProfile;

  String? _kycStatus;
  String? get kycStatus => _kycStatus;

  List<dynamic> _kycDocuments = [];
  List<dynamic> get kycDocuments => _kycDocuments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Triggered at application startup to check cached tokens and restore sessions
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    _state = AuthState.uninitialized;
    notifyListeners();

    final hasCreds = await _authService.hasCredentials();
    if (!hasCreds) {
      _isLoading = false;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    final refreshRes = await _authService.refreshToken();
    if (!refreshRes["success"]) {
      _isLoading = false;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    await refreshProfileAndKyc();
    _isLoading = false;
    notifyListeners();
  }

  /// Request OTP code for a phone number
  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    _state = AuthState.authenticating;
    notifyListeners();

    final res = await _authService.login(phone);
    _isLoading = false;

    if (res["success"]) {
      _phoneNumber = phone;
      _debugOtpCode = res["debug_code"];
      _state = AuthState.otpSent;
      notifyListeners();
      return true;
    } else {
      _errorMessage = res["message"];
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP code and transition session
  Future<bool> verifyOtp(String code) async {
    if (_phoneNumber == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _authService.verifyOtp(
      mobileNumber: _phoneNumber!,
      otp: code,
    );
    _isLoading = false;

    if (res["success"]) {
      _debugOtpCode = null;
      await refreshProfileAndKyc();
      return true;
    } else {
      _errorMessage = res["message"];
      notifyListeners();
      return false;
    }
  }

  /// Set up driver profile details and address
  Future<bool> setupProfile({
    required String fullName,
    required String dob,
    required String sex,
    required String emergencyContactNo,
    required Map<String, dynamic> address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Update Profile fields
    final profileRes = await _driverService.updateProfile(
      fullName: fullName,
      dob: dob,
      sex: sex,
      emergencyContactNo: emergencyContactNo,
    );

    if (!profileRes["success"]) {
      _isLoading = false;
      _errorMessage = profileRes["message"];
      notifyListeners();
      return false;
    }

    // 2. Save Address fields
    final addressRes = await _driverService.saveAddress(
      addressLine1: address["address_line1"],
      addressLine2: address["address_line2"],
      city: address["city"],
      state: address["state"],
      postalCode: address["postal_code"],
      country: address["country"] ?? "India",
    );
    
    _isLoading = false;

    if (addressRes["success"]) {
      await refreshProfileAndKyc();
      return true;
    } else {
      _errorMessage = addressRes["message"];
      notifyListeners();
      return false;
    }
  }

  /// Upload a KYC Document
  Future<bool> uploadDocument(String type, String path) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _driverService.uploadDocument(documentType: type, filePath: path);
    _isLoading = false;

    if (res["success"]) {
      await refreshProfileAndKyc();
      return true;
    } else {
      _errorMessage = res["message"];
      notifyListeners();
      return false;
    }
  }

  /// Invalidate session locally and server-side
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _phoneNumber = null;
    _debugOtpCode = null;
    _driverProfile = null;
    _kycStatus = null;
    _kycDocuments = [];
    _isLoading = false;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Fetch latest user profile details and calculate authentication state
  Future<void> refreshProfileAndKyc() async {
    final profileRes = await _driverService.getProfile();
    if (!profileRes["success"]) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    _driverProfile = profileRes["data"];
    final profileData = _driverProfile!;
    
    final bool isProfileComplete = profileData["full_name"] != null && 
                                  profileData["dob"] != null &&
                                  profileData["sex"] != null &&
                                  profileData["full_name"].toString().trim().isNotEmpty;
    
    if (!isProfileComplete) {
      _state = AuthState.profileIncomplete;
      notifyListeners();
      return;
    }

    // Profile is complete, check KYC status
    final kycRes = await _driverService.getKycStatus();
    if (kycRes["success"]) {
      _kycStatus = kycRes["kyc_status"];
      _kycDocuments = kycRes["documents"] ?? [];
    } else {
      _kycStatus = profileData["verification_status"];
    }

    if (_kycStatus == "verified") {
      _state = AuthState.authenticated;
    } else if (_kycStatus == "pending_review") {
      _state = AuthState.kycPendingReview;
    } else {
      _state = AuthState.kycIncomplete;
    }
    
    notifyListeners();
  }

  /// Reset error messages in UI
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
