import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';

enum AuthState {
  uninitialized,
  splash,
  languageSelection,
  roleSelection,
  unauthenticated,
  authenticating,
  otpSent,
  termsNotAccepted,
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

  String _selectedRole = 'Driver';
  String get selectedRole => _selectedRole;

  int _onboardingStep = 0;
  int get onboardingStep => _onboardingStep;

  String _preferredLanguage = 'en';
  String get preferredLanguage => _preferredLanguage;

  // ── Role selection ──────────────────────────────────────────────────────────
  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<void> completeLanguageSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    _state = AuthState.roleSelection;
    notifyListeners();
  }

  Future<void> completeRoleSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('role_selected', true);
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Triggered at application startup — shows splash then restores session.
  Future<void> tryAutoLogin() async {
    _state = AuthState.splash;
    notifyListeners();

    // Allow splash animation to play
    await Future.delayed(const Duration(milliseconds: 2500));

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final bool isLanguageSelected = prefs.getBool('language_selected') ?? false;
    if (!isLanguageSelected) {
      _isLoading = false;
      _state = AuthState.languageSelection;
      notifyListeners();
      return;
    }

    final bool isRoleSelected = prefs.getBool('role_selected') ?? false;
    if (!isRoleSelected) {
      _isLoading = false;
      _state = AuthState.roleSelection;
      notifyListeners();
      return;
    }

    final hasCredentials = await _authService.hasCredentials();
    if (!hasCredentials) {
      _isLoading = false;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    final refreshRes = await _authService.refreshToken();
    if (!refreshRes['success']) {
      _isLoading = false;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    // Restore onboarding state from token response
    final tokenData = refreshRes['data'];
    if (tokenData != null) {
      _onboardingStep = tokenData['onboarding_step'] ?? 0;
      _preferredLanguage = tokenData['preferred_language'] ?? 'en';
      final termsAccepted = tokenData['terms_accepted'] ?? false;
      if (!termsAccepted) {
        _isLoading = false;
        _state = AuthState.termsNotAccepted;
        notifyListeners();
        return;
      }
    }

    await refreshProfileAndKyc();
    _isLoading = false;
    notifyListeners();
  }

  /// Request OTP for phone number login.
  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    _state = AuthState.authenticating;
    notifyListeners();

    final res = await _authService.login(phone);
    _isLoading = false;

    if (res['success']) {
      _phoneNumber = phone;
      _debugOtpCode = res['debug_code'];
      _state = AuthState.otpSent;
      notifyListeners();
      return true;
    } else {
      _errorMessage = res['message'];
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and initialize session.
  Future<bool> verifyOtp(String code) async {
    if (_phoneNumber == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _authService.verifyOtp(
      mobileNumber: _phoneNumber!,
      otp: code,
      role: _selectedRole,
    );
    _isLoading = false;

    if (res['success']) {
      _debugOtpCode = null;

      // Check onboarding state from token response
      final data = res['data'];
      if (data != null) {
        _onboardingStep = data['onboarding_step'] ?? 0;
        _preferredLanguage = data['preferred_language'] ?? 'en';
        final termsAccepted = data['terms_accepted'] ?? false;
        if (!termsAccepted) {
          _state = AuthState.termsNotAccepted;
          notifyListeners();
          return true;
        }
      }

      await refreshProfileAndKyc();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }

  /// Complete profile setup.
  Future<bool> setupProfile({
    required String fullName,
    required String dob,
    required String sex,
    required String emergencyContactNo,
    required Map<String, dynamic> address,
    String? email,
    String? emergencyContactName,
    String? emergencyContactRelation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final profileRes = await _driverService.updateProfile(
      fullName: fullName,
      dob: dob,
      sex: sex,
      emergencyContactNo: emergencyContactNo,
      email: email,
      emergencyContactName: emergencyContactName,
      emergencyContactRelation: emergencyContactRelation,
    );

    if (!profileRes['success']) {
      _isLoading = false;
      _errorMessage = profileRes['message'];
      notifyListeners();
      return false;
    }

    final addressRes = await _driverService.saveAddress(
      addressLine1: address['address_line1'],
      addressLine2: address['address_line2'],
      city: address['city'],
      state: address['state'],
      postalCode: address['postal_code'],
      country: address['country'] ?? 'India',
    );

    _isLoading = false;

    if (addressRes['success']) {
      await refreshProfileAndKyc();
      return true;
    } else {
      _errorMessage = addressRes['message'];
      notifyListeners();
      return false;
    }
  }

  /// Upload a KYC or vehicle document.
  Future<bool> uploadDocument(String type, String path) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _driverService.uploadDocument(
        documentType: type, filePath: path);
    _isLoading = false;

    if (res['success']) {
      await refreshProfileAndKyc();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }

  /// Logout current device.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _clearState();
  }

  void _clearState() {
    _phoneNumber = null;
    _debugOtpCode = null;
    _driverProfile = null;
    _kycStatus = null;
    _kycDocuments = [];
    _onboardingStep = 0;
    _isLoading = false;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Fetch latest profile and determine routing state.
  Future<void> refreshProfileAndKyc() async {
    final profileRes = await _driverService.getProfile();
    if (!profileRes['success']) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    _driverProfile = profileRes['data'];
    final profileData = _driverProfile!;

    // Check terms acceptance via profile onboarding_step
    final onboardingStep = profileData['onboarding_step'] as int? ?? 0;
    final termsAccepted = profileData['terms_accepted'] as bool? ?? false;
    _onboardingStep = onboardingStep;

    if (!termsAccepted) {
      _state = AuthState.termsNotAccepted;
      notifyListeners();
      return;
    }

    final bool isProfileComplete =
        profileData['full_name'] != null &&
        profileData['dob'] != null &&
        profileData['sex'] != null &&
        profileData['full_name'].toString().trim().isNotEmpty;

    if (!isProfileComplete) {
      _state = AuthState.profileIncomplete;
      notifyListeners();
      return;
    }

    // Fetch KYC document wallet
    final kycRes = await _driverService.getKycStatus();
    if (kycRes['success']) {
      _kycStatus = kycRes['kyc_status'];
      _kycDocuments = kycRes['documents'] ?? [];
    } else {
      _kycStatus = profileData['verification_status'];
    }

    if (_kycStatus == 'verified') {
      _state = AuthState.authenticated;
    } else if (_kycStatus == 'pending_review') {
      _state = AuthState.kycPendingReview;
    } else {
      _state = AuthState.kycIncomplete;
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
