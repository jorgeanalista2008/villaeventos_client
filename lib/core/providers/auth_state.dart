import 'package:flutter/material.dart';
import '../api/api_service.dart';

class AuthState extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _profile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;

  AuthState() {
    checkSession();
  }

  /// Recovers client session on app startup if a valid JWT token exists
  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    final token = await ApiService.getToken();
    if (token != null) {
      final result = await ApiService.getClientProfile();
      if (result['success']) {
        _isAuthenticated = true;
        _profile = result['data'];
      } else {
        // Clear session if token is expired or server rejects it
        await ApiService.clearSession();
        _isAuthenticated = false;
        _profile = null;
      }
    } else {
      _isAuthenticated = false;
      _profile = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Client authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.loginClient(email, password);
    if (result['success']) {
      _isAuthenticated = true;
      _profile = result['data'];
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Client registration
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required String direccion,
    required String latitud,
    required String longitud,
    required String notas,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.registerClient(
      nombre: nombre,
      telefono: telefono,
      email: email,
      password: password,
      direccion: direccion,
      latitud: latitud,
      longitud: longitud,
      notas: notas,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Clears auth token and profiles
  Future<void> logout() async {
    await ApiService.clearSession();
    _isAuthenticated = false;
    _profile = null;
    notifyListeners();
  }
}
