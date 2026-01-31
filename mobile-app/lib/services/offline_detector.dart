import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to detect network connectivity status
class OfflineDetector {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device is currently online
  static Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();

      // Consider device online if has any active connection
      return !result.contains(ConnectivityResult.none) && result.isNotEmpty;
    } catch (e) {
      // Assume offline if check fails
      return false;
    }
  }

  /// Get human-readable connection status
  static Future<String> getConnectionStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result.contains(ConnectivityResult.mobile)) {
        return 'Mobile Network';
      } else if (result.contains(ConnectivityResult.wifi)) {
        return 'WiFi Connected';
      } else if (result.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet Connected';
      } else if (result.contains(ConnectivityResult.vpn)) {
        return 'VPN Connected';
      } else if (result.contains(ConnectivityResult.none) || result.isEmpty) {
        return 'No Connection';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unable to determine';
    }
  }

  /// Stream of connectivity changes
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return !result.contains(ConnectivityResult.none) && result.isNotEmpty;
    });
  }
}
