import 'package:flutter/material.dart';
import '../screens/embedded_manual_screen.dart';

// ============================================================================
// Appliance Quality SOS Button
// 各画面からワンタップで最適なマニュアル（知識基盤）を呼び出すための共通ウィジェット。
// ============================================================================
class ManualHelpButton extends StatelessWidget {
  final String manualPath;
  final Color? color;

  const ManualHelpButton({
    super.key,
    required this.manualPath,
    this.color,
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
            builder: (context) => EmbeddedManualScreen(initialFilePath: manualPath),
            fullscreenDialog: true, // 下からスッと出てくるモーダル表現（iOS風）
          ),
        );
      },
    );
  }
}