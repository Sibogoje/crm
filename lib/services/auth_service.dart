import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _passwordKey = 'user_password';
  static const String _companyIdKey = 'company_id';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyIdKey);
  }

  Future<bool> login(String email, String password) async {
    if (!EmailValidator.validate(email)) {
      throw Exception('Invalid email format');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Check if user exists
    final storedEmail = prefs.getString(_userEmailKey);
    final storedPassword = prefs.getString(_passwordKey);

    if (storedEmail == null || storedPassword == null) {
      throw Exception('User not found. Please register first.');
    }

    if (storedEmail != email || storedPassword != password) {
      throw Exception('Invalid email or password');
    }

    // Set logged in status
    await prefs.setBool(_isLoggedInKey, true);
    return true;
  }

  Future<bool> register(String email, String password, String companyId) async {
    if (!EmailValidator.validate(email)) {
      throw Exception('Invalid email format');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Check if user already exists
    final existingEmail = prefs.getString(_userEmailKey);
    if (existingEmail != null) {
      throw Exception('User already exists. Please login instead.');
    }

    // Store user credentials
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_passwordKey, password);
    await prefs.setString(_companyIdKey, companyId);
    await prefs.setBool(_isLoggedInKey, true);

    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_companyIdKey);
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString(_passwordKey);

    if (storedPassword != currentPassword) {
      throw Exception('Current password is incorrect');
    }

    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters');
    }

    await prefs.setString(_passwordKey, newPassword);
    return true;
  }
}
