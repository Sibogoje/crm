import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/database_service.dart';

class ItemProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Item> get products => _items.where((item) => !item.isService).toList();
  List<Item> get services => _items.where((item) => item.isService).toList();

  Future<void> loadItems() async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {

      _items = await _apiService.getItems();

      _error = null;
    } catch (e) {

      _error = 'Failed to load items: $e';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(Item item) async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.createItem(item);
      if (success) {

        await loadItems(); // Reload to get the new item with ID
        return true;
      } else {

        _error = 'Failed to add item';
        return false;
      }
    } catch (e) {

      _error = 'Failed to add item: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem(Item item) async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.updateItem(item);
      if (success) {

        await loadItems(); // Reload to get updated data
        return true;
      } else {

        _error = 'Failed to update item';
        return false;
      }
    } catch (e) {

      _error = 'Failed to update item: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(int itemId) async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.deleteItem(itemId);
      if (success) {

        await loadItems(); // Reload to remove deleted item
        return true;
      } else {

        _error = 'Failed to delete item';
        return false;
      }
    } catch (e) {

      _error = 'Failed to delete item: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Item? getItemById(int id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Item> getItemsByCategory(String category) {
    return _items.where((item) => item.category.toLowerCase() == category.toLowerCase()).toList();
  }

  List<String> getCategories() {
    final categories = _items.map((item) => item.category).toSet().toList();
    categories.sort();
    return categories;
  }
}
