import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/security_level.dart';

/// アプリケーション全体のセキュリティレベル（大会運用防衛モード）を動的に管理するプロバイダー。
final securityLevelProvider = StateProvider<SecurityLevel>((ref) {
  return SecurityLevel.event; // 初期設定は標準運用（EVENT）
});
