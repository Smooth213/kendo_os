import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';

/// ルーム参加ダイアログのアクションボタン群（キャンセル / 接続開始）
class RoomJoinQrDialogActions extends StatelessWidget {
  final bool isLoading;
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onJoin;

  const RoomJoinQrDialogActions({
    super.key,
    required this.isLoading,
    required this.isDark,
    required this.onCancel,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: isLoading ? null : onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF475569),
            side: BorderSide(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          ),
          child: const Text(
            'キャンセル',
            style: TextStyle(fontWeight: AppFontWeight.bold),
          ),
        ),
        isLoading
            ? const AppLoadingIndicator(color: AppKendoColors.teal)
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.teal,
                  foregroundColor: AppKendoColors.pureWhite,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                ),
                onPressed: onJoin,
                child: const Text(
                  '接続開始',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
      ],
    );
  }
}
