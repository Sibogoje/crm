import 'package:flutter/foundation.dart';
import '../models/receipt.dart';
import '../services/receipt_service.dart';

class ReceiptProvider extends ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();
  
  List<Receipt> _receipts = [];
  bool _isLoading = false;
  String? _error;
  
  List<Receipt> get receipts => _receipts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get receipts for a specific invoice
  List<Receipt> getReceiptsForInvoice(int invoiceId) {
    return _receipts.where((receipt) => receipt.invoiceId == invoiceId).toList();
  }
  
  // Get total amount received for an invoice
  double getTotalReceivedForInvoice(int invoiceId) {
    return getReceiptsForInvoice(invoiceId).fold(0.0, (sum, receipt) => sum + receipt.amount);
  }

  Future<void> loadReceipts() async {
    _setLoading(true);
    _clearError();
    
    try {
      _receipts = await _receiptService.getReceipts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load receipts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReceiptsForInvoice(int invoiceId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final invoiceReceipts = await _receiptService.getReceiptsForInvoice(invoiceId);
      
      // Replace receipts for this invoice
      _receipts.removeWhere((receipt) => receipt.invoiceId == invoiceId);
      _receipts.addAll(invoiceReceipts);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load receipts for invoice: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createReceipt(Receipt receipt) async {
    _setLoading(true);
    _clearError();
    
    try {
      final newReceipt = await _receiptService.createReceipt(receipt);
      _receipts.add(newReceipt);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create receipt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReceipt(Receipt receipt) async {
    _setLoading(true);
    _clearError();
    
    try {
      final updatedReceipt = await _receiptService.updateReceipt(receipt);
      final index = _receipts.indexWhere((r) => r.id == receipt.id);
      
      if (index != -1) {
        _receipts[index] = updatedReceipt;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update receipt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteReceipt(int receiptId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _receiptService.deleteReceipt(receiptId);
      _receipts.removeWhere((receipt) => receipt.id == receiptId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete receipt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setError(String error) {
    _error = error;
    if (kDebugMode) {

    }
  }

  void clearReceipts() {
    _receipts.clear();
    _clearError();
    notifyListeners();
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
