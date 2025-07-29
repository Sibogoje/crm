import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Invoice> _invoices = [];
  bool _isLoading = false;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  Future<void> loadInvoices() async {
    _setLoading(true);
    try {
      _invoices = await _apiService.getInvoices();

    } catch (e) {

      throw Exception('Failed to load invoices: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    _setLoading(true);
    try {
      final newInvoice = await _apiService.createInvoice(invoice);
      if (newInvoice != null) {
        _invoices.insert(0, newInvoice);
        notifyListeners();
        return newInvoice;
      } else {
        throw Exception('Failed to create invoice');
      }
    } catch (e) {

      throw Exception('Failed to create invoice: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Invoice> createInvoiceFromQuote(int quoteId) async {
    _setLoading(true);
    try {
      final newInvoice = await _apiService.createInvoiceFromQuote(quoteId);
      if (newInvoice != null) {
        _invoices.insert(0, newInvoice);
        notifyListeners();
        return newInvoice;
      } else {
        throw Exception('Failed to create invoice from quote');
      }
    } catch (e) {

      throw Exception('Failed to create invoice from quote: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Invoice> updateInvoice(Invoice invoice) async {
    _setLoading(true);
    try {
      final updatedInvoice = await _apiService.updateInvoice(invoice);
      if (updatedInvoice != null) {
        final index = _invoices.indexWhere((q) => q.id == invoice.id);
        if (index != -1) {
          _invoices[index] = updatedInvoice;
          notifyListeners();
        }
        return updatedInvoice;
      } else {
        throw Exception('Failed to update invoice');
      }
    } catch (e) {

      throw Exception('Failed to update invoice: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteInvoice(int invoiceId) async {
    _setLoading(true);
    try {
      final success = await _apiService.deleteInvoice(invoiceId);
      if (success) {
        _invoices.removeWhere((invoice) => invoice.id == invoiceId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete invoice');
      }
    } catch (e) {

      throw Exception('Failed to delete invoice: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Invoice> recordPayment(int invoiceId, double amount, String paymentMethod) async {
    _setLoading(true);
    try {
      final invoice = _invoices.firstWhere((inv) => inv.id == invoiceId);
      final newPaidAmount = invoice.paidAmount + amount;
      String newStatus = 'sent'; // Default to sent if partially paid
      
      if (newPaidAmount >= invoice.totalAmount) {
        newStatus = 'paid';
      }
      
      final updatedInvoice = invoice.copyWith(
        paidAmount: newPaidAmount,
        status: newStatus,
      );
      
      return await updateInvoice(updatedInvoice);
    } catch (e) {

      throw Exception('Failed to record payment: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get invoices by status
  List<Invoice> getInvoicesByStatus(String status) {
    return _invoices.where((invoice) => invoice.status == status).toList();
  }

  // Get overdue invoices
  List<Invoice> getOverdueInvoices() {
    return _invoices.where((invoice) => invoice.isOverdue).toList();
  }

  // Get total outstanding amount
  double getTotalOutstandingAmount() {
    return _invoices
        .where((invoice) => invoice.status != 'paid' && invoice.status != 'cancelled')
        .fold(0.0, (sum, invoice) => sum + invoice.remainingAmount);
  }

  // Get total paid amount for a period
  double getTotalPaidAmount() {
    return _invoices
        .where((invoice) => invoice.status == 'paid')
        .fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
  }
}
