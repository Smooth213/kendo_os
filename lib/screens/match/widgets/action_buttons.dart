import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; 
import '../../../../models/score_event.dart';
import '../../../../providers/match_command_provider.dart';
// ★ 追加：設定を読み込むためのプロバイダ
import '../../../../providers/settings_provider.dart';
import '../../../../models/settings_model.dart';

class ScoreActionPanel extends ConsumerWidget {
  final String matchId;
  final Side side;
  final Color color;
  final Color? textColor; 
  final bool isLocked;

  const ScoreActionPanel({
    super.key,
    required this.matchId,
    required this.side,
    required this.color,
    this.textColor,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Step 3-6: 書き込み処理中フラグを直接監視
    final isProcessing = ref.watch(isMatchCommandProcessingProvider);
    // 元々のロック条件に「処理中」を加える
    final effectiveLocked = isLocked || isProcessing;
    
    // ★ 追加：システム設定を監視
    final settings = ref.watch(settingsProvider);

    return Expanded(
      child: Padding(
        // ★ 修正：ボタン群全体を囲う上下の固定余白を最小限(2px)に
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBtn(context, ref, 'メ', color, PointType.men, settings, effectiveLocked),
                  const SizedBox(width: 6), // ★ ボタン同士の横の隙間も少し締める
                  _buildBtn(context, ref, 'コ', color, PointType.kote, settings, effectiveLocked),
                ],
              ),
            ),
            const SizedBox(height: 4), // ★ ボタン同士の縦の隙間を8pxから4pxに圧縮（ここで高さを確保）
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBtn(context, ref, 'ド', color, PointType.doIdo, settings, effectiveLocked),
                  const SizedBox(width: 6),
                  _buildBtn(context, ref, 'ツ', color, PointType.tsuki, settings, effectiveLocked),
                ],
              ),
            ),
            const SizedBox(height: 4), 
            // ★ Phase 4: Undo(取り消し)を親指圏内・常時表示の特等席へ配置
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBtn(context, ref, '反', color, PointType.hansoku, settings, effectiveLocked),
                  const SizedBox(width: 6),
                  _buildUndoBtn(context, ref, settings, effectiveLocked),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ 修正: isLocked ではなく effectiveLocked を受け取る
  Widget _buildBtn(BuildContext context, WidgetRef ref, String label, Color btnColor, PointType type, SettingsModel settings, bool effectiveLocked) {
    final isHansoku = type == PointType.hansoku;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ★ Phase 8-2: iPad（横幅が広いデバイス）かどうかを判定
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    Color effectiveBtnColor;
    Color effectiveLabelColor;
    BorderSide borderSide;

    // ★ 修正：「反則」ボタン専用のカラーリングロジック
    if (isHansoku) {
      if (side == Side.red) {
        effectiveBtnColor = isDark ? Colors.grey.shade700 : Colors.grey.shade500;
        effectiveLabelColor = Colors.white;
        borderSide = BorderSide.none;
      } else {
        effectiveBtnColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
        effectiveLabelColor = isDark ? Colors.white : Colors.black87;
        borderSide = BorderSide.none; // 反則ボタンはグレーで十分目立つため、白側でも枠線を消して統一感を出します
      }
    } else {
      // 通常の打突ボタン（メ・コ・ド・ツ）
      effectiveBtnColor = (side == Side.white && isDark) ? const Color(0xFF1C1C1E) : btnColor;
      effectiveLabelColor = (side == Side.white && isDark) ? Colors.white : (textColor ?? Colors.white);
      borderSide = side == Side.white 
          ? BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 2) 
          : BorderSide.none;
    }

    if (effectiveLocked) {
      effectiveBtnColor = isDark ? Colors.white10 : Colors.grey.shade200;
      effectiveLabelColor = isDark ? Colors.white24 : Colors.grey.shade400;
      borderSide = BorderSide.none;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0), // ボタン同士の間隔を少し広げて誤タップ防止
        child: ElevatedButton(
          onPressed: effectiveLocked
              ? null
              : () {
                if (settings.strikeVib) {
                  // ★ Step 7-2: 陣営（Side）によっても振動に微細な変化を加え、
                  // 部位（強弱）× 陣営（リズム）で「今どちらに何を打ったか」を直感させる
                  if (side == Side.red) {
                    // 赤：標準的な単発の衝撃
                    _triggerHaptic(type);
                  } else {
                    // 白：極短の2連撃（または異なるリズム）で差別化
                    _triggerHaptic(type);
                    Future.delayed(const Duration(milliseconds: 50), () => _triggerHaptic(type));
                  }
                }
                ref.read(matchCommandProvider).addScoreEvent(matchId, side, type);
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveBtnColor, 
            foregroundColor: effectiveLabelColor, 
            elevation: effectiveLocked ? 0 : 4,
            padding: EdgeInsets.zero, 
            minimumSize: Size.zero, 
            // ★ 追加：Flutter標準の「見えないタップ確保領域」を完全に無効化する魔法のコード
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 16 : 10), // iPadではより丸みを持たせて高級感を
              side: borderSide,
            ),
          ),
          child: Text(
            label, 
            style: TextStyle(
              // ★ iPadなら文字サイズを 40、スマホなら 24 に動的変更
              fontSize: isTablet ? 40 : 24, 
              fontWeight: FontWeight.w900
            )
          ),
        ),
      ),
    );
  }

  void _triggerHaptic(PointType type) {
    switch (type) {
      case PointType.men:
        HapticFeedback.heavyImpact(); // 頭部への重い衝撃
        break;
      case PointType.kote:
        HapticFeedback.mediumImpact(); // 手首への鋭い衝撃
        break;
      case PointType.doIdo:
        HapticFeedback.lightImpact(); // 胴への乾いた衝撃
        break;
      case PointType.tsuki:
      case PointType.hansoku:
        HapticFeedback.vibrate(); // 突き、警告（鋭い振動）
        break;
      default:
        HapticFeedback.selectionClick();
    }
  }

  // ★ Phase 4: 左手・右手どちらの親指からでも即座に押せる、直感的なUndoボタン
  Widget _buildUndoBtn(BuildContext context, WidgetRef ref, SettingsModel settings, bool effectiveLocked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    // 他のボタンの邪魔をしないよう、落ち着いたグレーの配色
    final btnColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton.icon(
          onPressed: effectiveLocked
              ? null
              : () {
                  // ミスを「取り消した」という安堵感を与える中程度の振動
                  if (settings.haptic) HapticFeedback.mediumImpact();
                  ref.read(matchCommandProvider).undoLastEvent(matchId);
                },
          icon: Icon(Icons.undo, size: isTablet ? 32 : 20, color: labelColor),
          label: Text('取消', style: TextStyle(fontSize: isTablet ? 28 : 18, fontWeight: FontWeight.bold, color: labelColor)),
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: labelColor,
            elevation: effectiveLocked ? 0 : 2,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 16 : 10),
            ),
          ),
        ),
      ),
    );
  }
}