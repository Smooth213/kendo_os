import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/application/clipboard_import_service.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// クリップボードからの大会情報取り込みを起動するAppBarアクションボタン。
///
/// 背景コンテナと境界線を備え、ライトモード（白背景）およびダークモードの
/// いずれにおいても高い視認性（WCAG AA 準拠コントラスト比）を保証します。
class ClipboardImportButton extends ConsumerWidget {
  final VoidCallback? onImportCompleted;

  const ClipboardImportButton({super.key, this.onImportCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 白背景でも黒背景でもくっきり認識できる高コントラストカラー設計
    final fgColor = isDark
        ? const Color(0xFFFBBF24) // ダークモード: 鮮やかなアンバーゴールド
        : const Color(0xFFB45309); // ライトモード: 深みのある高コントラスト・ディープアンバー

    final bgColor = isDark
        ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
        : const Color(0xFFD97706).withValues(alpha: 0.12);

    final borderColor = isDark
        ? const Color(0xFFF59E0B).withValues(alpha: 0.38)
        : const Color(0xFFD97706).withValues(alpha: 0.30);

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),

      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: IconButton(
        icon: Icon(Icons.content_paste_go_rounded, color: fgColor, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        tooltip: 'クリップボードから取り込み',
        onPressed: () {
          AppHaptics.light();
          ref.read(clipboardImportServiceProvider).importManually(context);
          onImportCompleted?.call();
        },
      ),
    );
  }
}
