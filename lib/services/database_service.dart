import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/item.dart';
import '../models/quote.dart';
import '../models/invoice.dart';
import '../models/receipt.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Change this to your local XAMPP server IP
  static const String baseUrl = 'https://grinpath.com/ebs/backend/api';
  
  String? _token;
  Map<String, dynamic>? _currentUser;

  // Authentication methods
  Future<Map<String, dynamic>?> register({
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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'company_name': companyName,
          'company_email': companyEmail,
          'company_phone': companyPhone,
          'company_address': companyAddress,
          'company_tax_id': companyTaxId,
          'currency': currency,
          'default_tax_rate': defaultTaxRate,
          'invoice_prefix': invoicePrefix,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _currentUser = data['user'];
        
        // Save token to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('current_user', jsonEncode(_currentUser));
        
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _currentUser = data['user'];
        
        // Save token to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('current_user', jsonEncode(_currentUser));
        
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
  }

  Future<bool> isLoggedIn() async {


    
    if (_token != null) {

      return true;
    }
    

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    
    if (_token != null) {
      final userJson = prefs.getString('current_user');

      if (userJson != null) {
        _currentUser = jsonDecode(userJson);

      }
    }
    
    final isLoggedIn = _token != null;

    return isLoggedIn;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Client operations
  Future<List<Client>> getClients() async {

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/clients.php'),
        headers: _headers,
      );




      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> clientsJson = data['records'] ?? [];
        final clients = clientsJson.map((json) => Client.fromMap(json)).toList();

        return clients;
      } else {
        throw Exception('Failed to load clients: ${response.statusCode}');
      }
    } catch (e) {

      throw Exception('Network error: $e');
    }
  }

  Future<Client?> getClient(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/clients.php?id=$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Client.fromMap(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load client');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<String> createClient(Client client) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clients.php'),
        headers: _headers,
        body: jsonEncode({
          'name': client.name,
          'email': client.email,
          'phone': client.phone,
          'address': client.address,
          'tax_id': client.taxId,
          'client_company': client.company,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create client');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> updateClient(Client client) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/clients.php'),
        headers: _headers,
        body: jsonEncode({
          'id': client.id,
          'name': client.name,
          'email': client.email,
          'phone': client.phone,
          'address': client.address,
          'tax_id': client.taxId,
          'client_company': client.company,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update client');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> deleteClient(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/clients.php'),
        headers: _headers,
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete client');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Company operations
  Future<Map<String, dynamic>> getCompanyInfo() async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/company.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': data['success'] ?? false,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: Failed to load company information',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateCompanyInfo(Map<String, dynamic> companyData) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/company.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(companyData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Company information updated successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update company information',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update current user data
          _currentUser = data['user'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user', jsonEncode(_currentUser));
        }
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Profile updated successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Company?> getCompany() async {
    // Implementation for getting company info
    // This would need a separate endpoint
    return null;
  }

  // Items operations
  Future<List<Item>> getItems() async {

    if (_token == null) {

      return [];
    }

    try {

      final response = await http.get(
        Uri.parse('$baseUrl/items.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );




      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> itemsData = data['data'];

          return itemsData.map((item) => Item.fromMap(item)).toList();
        } else {

          return [];
        }
      } else {

        return [];
      }
    } catch (e) {

      return [];
    }
  }

  Future<bool> createItem(Item item) async {

    if (_token == null) {

      return false;
    }

    try {

      final response = await http.post(
        Uri.parse('$baseUrl/items.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(item.toApiMap()),
      );




      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {

          return true;
        } else {

          return false;
        }
      } else {

        return false;
      }
    } catch (e) {

      return false;
    }
  }

  Future<bool> updateItem(Item item) async {

    if (_token == null || item.id == null) {

      return false;
    }

    try {

      final response = await http.put(
        Uri.parse('$baseUrl/items.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'id': item.id.toString(),
          ...item.toApiMap(),
        }),
      );




      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {

          return true;
        } else {

          return false;
        }
      } else {

        return false;
      }
    } catch (e) {

      return false;
    }
  }

  Future<bool> deleteItem(int itemId) async {

    if (_token == null) {

      return false;
    }

    try {

      final response = await http.delete(
        Uri.parse('$baseUrl/items.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'id': itemId.toString()}),
      );




      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {

          return true;
        } else {

          return false;
        }
      } else {

        return false;
      }
    } catch (e) {

      return false;
    }
  }

  // Quote operations
  Future<List<Quote>> getQuotes() async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }


      final response = await http.get(
        Uri.parse('$baseUrl/quotes.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );




      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> quotesJson = data['data'] as List<dynamic>;

          return quotesJson.map((json) => Quote.fromMap(json)).toList();
        } else {

          return [];
        }
      } else {

        return [];
      }
    } catch (e) {

      return [];
    }
  }

  Future<Quote?> createQuote(Quote quote) async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }


      final response = await http.post(
        Uri.parse('$baseUrl/quotes.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(quote.toApiMap()),
      );




      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {

          return Quote.fromMap(data['data']);
        } else {

          return null;
        }
      } else {

        return null;
      }
    } catch (e) {

      return null;
    }
  }

  Future<Quote?> updateQuote(Quote quote) async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }


      final response = await http.put(
        Uri.parse('$baseUrl/quotes.php?id=${quote.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(quote.toApiMap()),
      );




      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {

          return Quote.fromMap(data['data']);
        } else {

          return null;
        }
      } else {

        return null;
      }
    } catch (e) {

      return null;
    }
  }

  Future<bool> deleteQuote(int quoteId) async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }


      final response = await http.delete(
        Uri.parse('$baseUrl/quotes.php?id=$quoteId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );




      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {

          return true;
        } else {

          return false;
        }
      } else {

        return false;
      }
    } catch (e) {

      return false;
    }
  }

  // Invoice operations
  Future<List<Invoice>> getInvoices() async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/invoices.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((json) => Invoice.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load invoices: ${response.statusCode}');
      }
    } catch (e) {

      throw Exception('Failed to load invoices: $e');
    }
  }

  Future<Invoice?> createInvoice(Invoice invoice) async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }
      

      final response = await http.post(
        Uri.parse('$baseUrl/invoices.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(invoice.toApiMap()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return Invoice.fromMap(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create invoice');
      }
    } catch (e) {

      throw Exception('Failed to create invoice: $e');
    }
  }

  Future<Invoice?> createInvoiceFromQuote(int quoteId) async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }
      

      final response = await http.post(
        Uri.parse('$baseUrl/invoices.php/convert-quote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'quote_id': quoteId.toString()}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return Invoice.fromMap(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create invoice from quote');
      }
    } catch (e) {

      throw Exception('Failed to create invoice from quote: $e');
    }
  }

  Future<Invoice?> updateInvoice(Invoice invoice) async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }
      

      final response = await http.put(
        Uri.parse('$baseUrl/invoices.php/${invoice.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(invoice.toApiMap()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return Invoice.fromMap(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update invoice');
      }
    } catch (e) {

      throw Exception('Failed to update invoice: $e');
    }
  }

  Future<bool> deleteInvoice(int invoiceId) async {
    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }
      

      final response = await http.delete(
        Uri.parse('$baseUrl/invoices.php/$invoiceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {

        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete invoice');
      }
    } catch (e) {

      throw Exception('Failed to delete invoice: $e');
    }
  }

  // Receipt operations - Similar implementation needed
  Future<List<Receipt>> getReceipts() async {
    // TODO: Implement receipts API endpoint
    return [];
  }

  // Utility methods
  String get currentUserId => _currentUser?['id']?.toString() ?? '';
  String get currentCompanyId => _currentUser?['company_id']?.toString() ?? '';
  Map<String, dynamic>? get currentUser => _currentUser;
}
