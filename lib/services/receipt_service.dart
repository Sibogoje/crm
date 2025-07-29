import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt.dart';

class ReceiptService {
  static const String baseUrl = 'https://grinpath.com/ebs/backend/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Receipt>> getReceipts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/receipts.php'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> receiptsData = data['data'] ?? [];
          return receiptsData.map((item) => Receipt.fromMap(item)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load receipts');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load receipts: $e');
    }
  }

  Future<List<Receipt>> getReceiptsForInvoice(int invoiceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/receipts.php?invoice_id=$invoiceId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> receiptsData = data['data'] ?? [];
          return receiptsData.map((item) => Receipt.fromMap(item)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load receipts for invoice');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load receipts for invoice: $e');
    }
  }

  Future<Receipt> createReceipt(Receipt receipt) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/receipts.php'),
        headers: headers,
        body: json.encode(receipt.toApiMap()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Receipt.fromMap(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create receipt');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create receipt: $e');
    }
  }

  Future<Receipt> updateReceipt(Receipt receipt) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/receipts.php?id=${receipt.id}'),
        headers: headers,
        body: json.encode(receipt.toApiMap()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Receipt.fromMap(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update receipt');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update receipt: $e');
    }
  }

  Future<void> deleteReceipt(int receiptId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/receipts.php?id=$receiptId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete receipt');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  Future<Receipt?> getReceiptById(int receiptId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/receipts.php?id=$receiptId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Receipt.fromMap(data['data']);
        }
        return null;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get receipt: $e');
    }
  }
}
