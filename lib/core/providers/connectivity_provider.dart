import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  bool _showRestoredBanner = false;
  Timer? _timer;
  bool _isChecking = false;

  bool get isConnected => _isConnected;
  bool get showRestoredBanner => _showRestoredBanner;

  ConnectivityProvider() {
    _init();
  }

  void _init() {
    // Check connection immediately
    _checkConnection();
    // Periodic check every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      // We look up google.com as it's highly reliable.
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateConnectionState(hasInternet);
    } catch (_) {
      _updateConnectionState(false);
    } finally {
      _isChecking = false;
    }
  }

  void _updateConnectionState(bool newStatus) {
    if (_isConnected == newStatus) return;

    if (!_isConnected && newStatus) {
      // Connection restored!
      _isConnected = true;
      _showRestoredBanner = true;
      notifyListeners();

      // Hide restored success message after 3 seconds
      Timer(const Duration(seconds: 3), () {
        _showRestoredBanner = false;
        notifyListeners();
      });
    } else {
      // Connection lost!
      _isConnected = newStatus;
      _showRestoredBanner = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
