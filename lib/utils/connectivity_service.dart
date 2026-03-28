import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<List<ConnectivityResult>> _connectivityController =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> _currentConnections = [ConnectivityResult.none];
  bool _isConnected = false;
  Timer? _connectivityCheckTimer;

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivityController.stream;

  bool get isConnected => _isConnected;
  List<ConnectivityResult> get currentConnections => _currentConnections;
  ConnectivityResult get currentConnection => _currentConnections.isNotEmpty
      ? _currentConnections.first
      : ConnectivityResult.none;

  Future<void> initialize() async {
    try {
      _currentConnections = await _connectivity.checkConnectivity();
      _updateConnectionStatus(_currentConnections);

      _connectivity.onConnectivityChanged.listen((
        List<ConnectivityResult> results,
      ) {
        _currentConnections = results;
        _updateConnectionStatus(results);
      });

      // Periodic connectivity check
      _connectivityCheckTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _checkConnectivity(),
      );
    } catch (e) {
      debugPrint('Connectivity initialization error: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.any((result) => result != ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      _connectivityController.add(results);
      debugPrint('Connectivity changed: $_isConnected');
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (!_listsEqual(results, _currentConnections)) {
        _currentConnections = results;
        _updateConnectionStatus(results);
      }
    } catch (e) {
      debugPrint('Connectivity check error: $e');
    }
  }

  bool _listsEqual(List<ConnectivityResult> a, List<ConnectivityResult> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isConnected) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = connectivityStream.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        subscription.cancel();
        completer.complete(true);
      }
    });

    // Timeout if no connection established
    Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete(false);
      }
    });

    return completer.future;
  }

  String getConnectionMessage() {
    switch (currentConnection) {
      case ConnectivityResult.wifi:
        return 'Connected to WiFi';
      case ConnectivityResult.mobile:
        return 'Connected to Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected to Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Connected via Bluetooth';
      case ConnectivityResult.none:
        return 'No Internet Connection';
      default:
        return 'Unknown Connection Status';
    }
  }

  void dispose() {
    _connectivityCheckTimer?.cancel();
    _connectivityController.close();
  }
}
