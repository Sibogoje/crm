import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> checkAuthStatus() async {

    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _apiService.isLoggedIn();

      if (_isLoggedIn) {
        _currentUser = _apiService.currentUser;

      }
      _error = null;
    } catch (e) {

      _error = e.toString();
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);
      if (result != null) {
        _isLoggedIn = true;
        _currentUser = result['user'];
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String companyName,
    required String companyEmail,
    required String companyPhone,
    required String companyAddress,
    required String companyTaxId,
    String currency = 'USD',
    double defaultTaxRate = 0.0,
    String invoicePrefix = 'INV',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        companyName: companyName,
        companyEmail: companyEmail,
        companyPhone: companyPhone,
        companyAddress: companyAddress,
        companyTaxId: companyTaxId,
        currency: currency,
        defaultTaxRate: defaultTaxRate,
        invoicePrefix: invoicePrefix,
      );

      if (result != null) {
        _isLoggedIn = true;
        _currentUser = result['user'];
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _apiService.logout();
    _isLoggedIn = false;
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      _currentUser = _apiService.currentUser;
      notifyListeners();
    } catch (e) {

    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
