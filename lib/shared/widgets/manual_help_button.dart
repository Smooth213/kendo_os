import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_screen.dart';

// ============================================================================
// Appliance Quality SOS Button
// 各画面からワンタップで最適なマニュアル（知識基盤）を呼び出すための共通ウィジェット。
// ============================================================================
class ManualHelpButton extends StatelessWidget {
  final String manualPath;
  final Color? color;
  final int? initialTab; // ★ 0: 通常クイック, 1: 部内戦クイック, 2: 総合

  const ManualHelpButton({
    super.key,
    required this.manualPath,
    this.color,
    this.initialTab,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, color: color, size: 26),
      tooltip: 'ヘルプ・マニュアルを開く',
      onPressed: () {
        // 現在の画面の上に、マニュアル画面を被せて表示する
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EmbeddedManualScreen(
              initialFilePath: manualPath,
              initialTab: initialTab,
            ),
            fullscreenDialog: true, // 下からスッと出てくるモーダル表現（iOS風）
          ),
        );
      },
    );
  }
}
