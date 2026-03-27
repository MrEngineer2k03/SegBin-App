import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionStatusController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  Stream<bool> get connectionStatus => _connectionStatusController!.stream;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    _connectionStatusController = StreamController<bool>.broadcast();
    
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      // If check fails, assume offline
      _isConnected = false;
      _connectionStatusController?.add(false);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Check if any connection type is available
    final hasConnection = results.any((result) => 
      result != ConnectivityResult.none
    );
    
    // For internet connectivity, we need to verify actual internet access
    // ConnectivityResult.mobile or .wifi doesn't guarantee internet access
    // So we'll treat them as potentially connected, but the actual check
    // should be done at the point of use (e.g., when making API calls)
    _isConnected = hasConnection;
    _connectionStatusController?.add(_isConnected);
  }

  Future<bool> checkInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController?.close();
  }
}

