import 'package:flutter/material.dart';
import 'package:kendo_os/core/config/runtime_mode.dart';

/// 🔒 [Phase 2-3] ゼロトラスト・ガバナンス防壁ラッパー
///
/// 万が一、ルーターやディープリンクの隙間を突いて Governance Screen や Replay Tool への
/// 不正アクセスが試みられた場合でも、ウィジェットツリーのレンダリング直前で物理的に侵入を拒否します。
class InternalOnlyGuard extends StatelessWidget {
  final Widget child;

  const InternalOnlyGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (RuntimeConfig.currentMode != RuntimeMode.internal) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              '🔒 Governance Alert\n\nこの画面は内部開発システム（Internal Mode）専用に隔離されています。\n一般のStage2 β環境からはアクセスできません。',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return child;
  }
}
