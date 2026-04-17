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
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildBtn(context, ref, 'メ', color, PointType.men, settings, effectiveLocked)),
                  const SizedBox(width: 6), // ★ ボタン同士の横の隙間も少し締める
                  Expanded(child: _buildBtn(context, ref, 'コ', color, PointType.kote, settings, effectiveLocked)),
                ],
              ),
            ),
            const SizedBox(height: 4), // ★ ボタン同士の縦の隙間を8pxから4pxに圧縮（ここで高さを確保）
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildBtn(context, ref, 'ド', color, PointType.doIdo, settings, effectiveLocked)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildBtn(context, ref, 'ツ', color, PointType.tsuki, settings, effectiveLocked)),
                ],
              ),
            ),
            const SizedBox(height: 4), // ★ ここも4pxに
            Expanded(
              child: _buildBtn(context, ref, '反', color, PointType.hansoku, settings, effectiveLocked),
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

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
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
          elevation: isDark ? 0 : (side == Side.white ? 2 : 8), // ★ Enum比較に修正
          shadowColor: btnColor.withValues(alpha: 0.5), 
          padding: EdgeInsets.zero, 
          minimumSize: Size.zero, 
          // ★ 追加：Flutter標準の「見えないタップ確保領域」を完全に無効化する魔法のコード
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 角丸もスペースに合わせて少しシャープに
            side: borderSide,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(2), // 内部余白も極限まで削る
            child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
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
}