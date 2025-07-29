import 'package:flutter/foundation.dart';
import '../models/quote.dart';
import '../services/database_service.dart';

class QuoteProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Quote> _quotes = [];
  bool _isLoading = false;
  String? _error;

  List<Quote> get quotes => _quotes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Quote> get draftQuotes => _quotes.where((q) => q.status == 'draft').toList();
  List<Quote> get sentQuotes => _quotes.where((q) => q.status == 'sent').toList();
  List<Quote> get acceptedQuotes => _quotes.where((q) => q.status == 'accepted').toList();
  List<Quote> get rejectedQuotes => _quotes.where((q) => q.status == 'rejected').toList();
  List<Quote> get expiredQuotes => _quotes.where((q) => q.status == 'expired').toList();

  Future<void> loadQuotes() async {
    _setLoading(true);
    _setError(null);

    try {

      _quotes = await _apiService.getQuotes();

      notifyListeners();
    } catch (e) {

      _setError('Failed to load quotes: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createQuote(Quote quote) async {
    _setLoading(true);
    _setError(null);

    try {

      final createdQuote = await _apiService.createQuote(quote);
      if (createdQuote != null) {
        _quotes.insert(0, createdQuote);
        notifyListeners();

      } else {
        throw Exception('Failed to create quote');
      }
    } catch (e) {

      _setError('Failed to create quote: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateQuote(Quote quote) async {
    _setLoading(true);
    _setError(null);

    try {

      final updatedQuote = await _apiService.updateQuote(quote);
      if (updatedQuote != null) {
        final index = _quotes.indexWhere((q) => q.id == quote.id);
        if (index != -1) {
          _quotes[index] = updatedQuote;
          notifyListeners();

        }
      } else {
        throw Exception('Failed to update quote');
      }
    } catch (e) {

      _setError('Failed to update quote: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteQuote(int quoteId) async {
    _setLoading(true);
    _setError(null);

    try {

      final success = await _apiService.deleteQuote(quoteId);
      if (success) {
        _quotes.removeWhere((q) => q.id == quoteId);
        notifyListeners();

      } else {
        throw Exception('Failed to delete quote');
      }
    } catch (e) {

      _setError('Failed to delete quote: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
