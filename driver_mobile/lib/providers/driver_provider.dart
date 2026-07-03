import 'dart:async';
import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../services/subscription_service.dart';
import '../services/rsa_service.dart';

class DriverProvider extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final RsaService _rsaService = RsaService();

  List<dynamic> _vehicles = [];
  List<dynamic> get vehicles => _vehicles;

  Map<String, dynamic>? _activeVehicle;
  Map<String, dynamic>? get activeVehicle => _activeVehicle;

  List<dynamic> _plans = [];
  List<dynamic> get plans => _plans;

  List<dynamic> _billingHistory = [];
  List<dynamic> get billingHistory => _billingHistory;

  Map<String, dynamic>? _activeRsaRequest;
  Map<String, dynamic>? get activeRsaRequest => _activeRsaRequest;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _rsaPollingTimer;

  /// Start background polling of active RSA ticket location and dispatch state
  void startRsaPolling() {
    _rsaPollingTimer?.cancel();
    _rsaPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await refreshActiveRsa();
    });
  }

  /// Stop polling active RSA tickets
  void stopRsaPolling() {
    _rsaPollingTimer?.cancel();
    _rsaPollingTimer = null;
  }

  @override
  void dispose() {
    stopRsaPolling();
    super.dispose();
  }

  /// Load all core models for vehicle profiles, billing registers, and plan subscriptions
  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait([
      fetchVehicles(),
      fetchPlans(),
      fetchBillingHistory(),
      refreshActiveRsa(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchVehicles() async {
    final res = await _vehicleService.getVehicles();
    if (res["success"]) {
      _vehicles = res["data"] ?? [];
      if (_vehicles.isNotEmpty) {
        _activeVehicle = _vehicles.first;
      } else {
        _activeVehicle = null;
      }
    }
  }

  Future<void> fetchPlans() async {
    final res = await _subscriptionService.getPlans();
    if (res["success"]) {
      _plans = res["data"] ?? [];
    }
  }

  Future<void> fetchBillingHistory() async {
    final res = await _subscriptionService.getHistory();
    if (res["success"]) {
      _billingHistory = res["data"] ?? [];
    }
  }

  Future<void> refreshActiveRsa() async {
    final res = await _rsaService.getActiveRsaRequest();
    if (res["success"]) {
      final activeData = res["data"];
      if (activeData != null && activeData["active"] == true) {
        _activeRsaRequest = activeData;
        if (_rsaPollingTimer == null) {
          startRsaPolling();
        }
      } else {
        _activeRsaRequest = null;
        stopRsaPolling();
      }
      notifyListeners();
    }
  }

  /// Create a new vehicle details profile
  Future<bool> createVehicle({
    required String registrationNumber,
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _vehicleService.addVehicle(
      registrationNumber: registrationNumber,
      make: make,
      model: model,
      year: year,
      color: color,
    );

    _isLoading = false;
    if (res["success"]) {
      await fetchVehicles();
      return true;
    } else {
      _errorMessage = res["message"];
      notifyListeners();
      return false;
    }
  }

  /// Purchase subscription plan (Razorpay payment mockup)
  Future<bool> purchasePlan(String planId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Mock payment transaction ID
    final txnId = "pay_${DateTime.now().millisecondsSinceEpoch}";
    final res = await _subscriptionService.subscribe(
      planId: planId,
      transactionId: txnId,
      paymentMethod: "Razorpay (Simulated)",
    );

    _isLoading = false;
    if (res["success"]) {
      await fetchBillingHistory();
      return true;
    } else {
      _errorMessage = res["message"];
      notifyListeners();
      return false;
    }
  }

  /// Raise a live roadside dispatch SOS request
  Future<bool> raiseSOS({
    required String issueType,
    required double latitude,
    required double longitude,
    String? description,
    String? locationName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _rsaService.raiseRsaRequest(
      latitude: latitude,
      longitude: longitude,
      issueType: issueType,
      locationName: locationName,
      description: description,
      vehicleId: _activeVehicle != null ? _activeVehicle!["id"] : null,
    );

    _isLoading = false;
    if (res["success"]) {
      await refreshActiveRsa();
      return true;
    } else {
      _errorMessage = res["message"];
      notifyListeners();
      return false;
    }
  }

  /// Cancel active SOS ticket
  Future<bool> cancelSOS() async {
    if (_activeRsaRequest == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _rsaService.cancelRsaRequest(_activeRsaRequest!["id"]);
    _isLoading = false;

    if (res["success"]) {
      _activeRsaRequest = null;
      stopRsaPolling();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res["message"];
      notifyListeners();
      return false;
    }
  }

  /// Complete ticket, submit driver feedback rating, and reset tracking
  Future<bool> completeSOSFeedback(int rating, String comments) async {
    if (_activeRsaRequest == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _rsaService.submitFeedback(
      requestId: _activeRsaRequest!["id"],
      rating: rating,
      comments: comments,
    );
    _isLoading = false;

    if (res["success"]) {
      _activeRsaRequest = null;
      stopRsaPolling();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res["message"];
      notifyListeners();
      return false;
    }
  }
}
