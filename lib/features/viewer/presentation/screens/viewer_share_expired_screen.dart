import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 1大会限定 観戦共有リンクが有効期限切れ・停止・無効となった際に表示する案内画面
class ViewerShareExpiredScreen extends StatelessWidget {
  final ViewerShareAccessStatus status;

  const ViewerShareExpiredScreen({super.key, required this.status});

  String get _title {
    switch (status) {
      case ViewerShareAccessStatus.revoked:
        return '観戦リンクは公開停止中です';
      case ViewerShareAccessStatus.expired:
        return '観戦リンクの公開期間が終了しました';
      case ViewerShareAccessStatus.offlineOrUnavailable:
        return '観戦リンクを確認できません';
      case ViewerShareAccessStatus.invalid:
      case ViewerShareAccessStatus.valid:
        return '観戦リンクが無効です';
    }
  }

  String get _message {
    switch (status) {
      case ViewerShareAccessStatus.revoked:
        return 'この大会の観戦共有リンクは、道場の管理者により公開が停止されています。\n'
            '道場関係者の方は「道場ID・入室PIN」から参加して閲覧してください。';
      case ViewerShareAccessStatus.expired:
        return 'この大会の観戦共有リンクは、設定された公開期間を過ぎたため閲覧を終了しました。\n'
            '引き続き大会記録を閲覧する場合は、道場IDと入室PINから参加してください。';
      case ViewerShareAccessStatus.offlineOrUnavailable:
        return '通信環境を確認のうえ、再度リンクを開き直してください。';
      case ViewerShareAccessStatus.invalid:
      case ViewerShareAccessStatus.valid:
        return 'URLが正しくないか、共有トークンが一致しません。\n'
            '道場から共有された最新のQRコードまたはURLをお試しください。';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Scaffold(
      backgroundColor: themeColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: themeColors.cardBackground,
                borderRadius: AppRadius.xlarge,
                border: Border.all(color: themeColors.separatorColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == ViewerShareAccessStatus.revoked
                        ? Icons.block_rounded
                        : Icons.timer_off_outlined,
                    size: 56,
                    color: AppKendoColors.orangeAccent,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSize.header,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: themeColors.subTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppKendoColors.teal,
                        foregroundColor: AppKendoColors.pureWhite,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      onPressed: () => context.go('/role-select'),
                      icon: const Icon(Icons.meeting_room_outlined),
                      label: const Text(
                        '道場ID・入室PINから参加する',
                        style: TextStyle(fontWeight: AppFontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
