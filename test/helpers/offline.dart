import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🛡️ STEP 1-2 要件：通信切断・遮断シミュレータ
class OfflineNetworkSimulator {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void disconnect() { _isOnline = false; }
  void connect() { _isOnline = true; }
}

final offlineNetworkSimulatorProvider = Provider((ref) => OfflineNetworkSimulator());