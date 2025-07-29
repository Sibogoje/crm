import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/database_service.dart';

class ClientProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Client> _clients = [];
  bool _isLoading = false;
  String? _error;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadClients() async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _clients = await _apiService.getClients();

      _error = null;
    } catch (e) {

      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Client?> getClient(String id) async {
    try {
      return await _apiService.getClient(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createClient(Client client) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final clientId = await _apiService.createClient(client);
      
      // Add the new client to the local list
      final newClient = client.copyWith(updatedAt: DateTime.now());
      final updatedClient = Client(
        id: clientId,
        name: newClient.name,
        email: newClient.email,
        phone: newClient.phone,
        address: newClient.address,
        taxId: newClient.taxId,
        company: newClient.company,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _clients.add(updatedClient);
      _clients.sort((a, b) => a.name.compareTo(b.name));
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClient(Client client) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.updateClient(client);
      
      if (success) {
        // Update the client in the local list
        final index = _clients.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          _clients[index] = client.copyWith(updatedAt: DateTime.now());
          _clients.sort((a, b) => a.name.compareTo(b.name));
        }
        _error = null;
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClient(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.deleteClient(id);
      
      if (success) {
        // Remove the client from the local list
        _clients.removeWhere((client) => client.id == id);
        _error = null;
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
