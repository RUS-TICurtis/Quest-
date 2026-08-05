import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo(this._connectivity);

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    // In connectivity_plus > 5.0.0, checkConnectivity returns a List<ConnectivityResult>
    return !results.contains(ConnectivityResult.none);
  }
}

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo(Connectivity());
});
