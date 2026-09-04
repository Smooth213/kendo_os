import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_share_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 観客用大会ホームのヘッダーアクション（QR共有ボタン）
class ViewerHomeHeaderActions extends ConsumerWidget {
  final String tournamentId;
  final bool isDark;
  final Color iconColor;

  const ViewerHomeHeaderActions({
    super.key,
    required this.tournamentId,
    required this.isDark,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.qr_code_2, color: iconColor),
          tooltip: '大会を共有する',
          onPressed: () {
            ViewerShareDialog.show(
              context,
              tournamentId: tournamentId,
              dojoId: ref.read(currentDojoIdProvider),
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
