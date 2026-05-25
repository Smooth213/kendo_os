import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ★ Public Beta 運用時、一般ユーザーによる内部監査・管理画面への不正侵入を
/// ルーティング層で構造的に検知し、強制切断（遮断）するゼロトラスト・ルートガード。
class InternalRouteGuard {
  const InternalRouteGuard._();

  /// ターゲットパスが内部専用（internal）領域であるか否かを厳格に判定します。
  static bool isInternalPath(String path) {
    final normalized = path.toLowerCase().trim();
    return normalized.contains('/internal') || 
           normalized.contains('observability') || 
           normalized.contains('audit-log') || 
           normalized.contains('master-management');
  }

  /// ルーティング要求をインターセプトし、Public Beta環境下での内部アクセスを拒絶します。
  /// 不正アクセスを検知した場合は、強制的に公開用ホーム画面（'/'）へとリダイレクトします。
  static String? googleTransitGuard(BuildContext context, GoRouterState state, bool isPublicBetaMode) {
    final targetLocation = state.uri.toString();

    if (isInternalPath(targetLocation) && isPublicBetaMode) {
      debugPrint('🚨 [Zero Trust Security Alert] 不正アクセスを検知: Public Beta モード下で内部画面 ($targetLocation) への侵入が試みられたため、強制遮断しホームへ強制リダイレクトしました。');
      return '/'; // 公開ホームへ強制送還
    }

    return null; // セキュリティパス（通常通りルーティングを許可）
  }
}