import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 🥋 設定画面用 Googleアカウント連携タイル
class SettingsGoogleAuthTile extends ConsumerStatefulWidget {
  const SettingsGoogleAuthTile({super.key});

  @override
  ConsumerState<SettingsGoogleAuthTile> createState() =>
      _SettingsGoogleAuthTileState();
}

class _SettingsGoogleAuthTileState
    extends ConsumerState<SettingsGoogleAuthTile> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkRedirectResult());
  }

  Future<void> _checkRedirectResult() async {
    try {
      final service = ref.read(googleAuthServiceProvider);
      final result = await service.checkRedirectResult();
      if (result != null && mounted) {
        AppSnackBar.showSuccess(
          context,
          'Googleアカウントと連携しました（${result.user?.email ?? ''}）',
        );
      }
    } catch (e) {
      debugPrint('ℹ️ [SettingsGoogleAuthTile] Redirect check: $e');
    }
  }

  Future<void> _handleLink() async {
    final service = ref.read(googleAuthServiceProvider);
    // 🛡️ Webブラウザの User Gesture（直接クリック判定）を途切れさせないため、
    // setState より前に同期的に認証フューチャーを発火
    final authFuture = service.linkOrSignInWithGoogle();
    setState(() => _isLoading = true);

    try {
      final result = await authFuture.timeout(
        const Duration(seconds: 40),
        onTimeout: () => throw Exception(
          '認証画面が開かないか、タイムアウトしました。ブラウザのポップアップブロックを解除するか、再度お試しください。',
        ),
      );
      if (result != null && mounted) {
        AppSnackBar.showSuccess(
          context,
          'Googleアカウントと連携しました（${result.user?.email ?? ''}）',
        );
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('popup-blocked') || errStr.contains('blocked')) {
          _showPopupBlockedDialog();
        } else {
          AppSnackBar.showError(context, '連携を完了できませんでした: $errStr');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPopupBlockedDialog() {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'ポップアップがブロックされました',
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ブラウザのセキュリティ設定により、Googleログイン用の小画面が開けませんでした。'),
            SizedBox(height: AppSpacing.sm),
            Text(
              '【解除方法】\n'
              '1. ブラウザ（Chrome）のアドレスバー右端にある「ポップアップがブロックされました」アイコンをクリックしてください。\n'
              '2. 「常に許可」を選択して「完了」を押してください。\n'
              '3. もう一度「連携する」を押すと、正常にログインできます。',
              style: TextStyle(fontSize: AppFontSize.bodySmall, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkConfirmation(BuildContext context) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Google連携を解除しますか？',
        content: const Text('連携を解除すると、他の端末とのクイックメモや通知既読の自動同期が停止します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(googleAuthServiceProvider).unlinkGoogle();
                if (context.mounted) {
                  AppSnackBar.show(context, 'Googleアカウントの連携を解除しました');
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.showError(context, '連携解除エラー: $e');
                }
              }
            },
            child: const Text(
              '連携解除',
              style: TextStyle(
                color: AppKendoColors.red,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLinked = ref.watch(isGoogleLinkedProvider);
    final email = ref.watch(linkedGoogleEmailProvider);
    final uid = ref.watch(linkedGoogleUidProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    if (isLinked) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppKendoColors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.cloud_done_rounded,
              color: AppKendoColors.green,
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Google連携中',
          style: TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
            color: themeColors.textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email != null && email.isNotEmpty)
              Text(
                email,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.textColor.withValues(alpha: 0.9),
                ),
              ),
            if (uid != null && uid.isNotEmpty)
              Text(
                '同期ID: ${uid.length > 12 ? "${uid.substring(0, 6)}...${uid.substring(uid.length - 4)}" : uid}',
                style: TextStyle(
                  fontSize: AppFontSize.badge,
                  fontFamily: 'monospace',
                  color: themeColors.subTextColor.withValues(alpha: 0.8),
                ),
              ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppKendoColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'クラウド同期有効（メモ・既読共有中）',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppKendoColors.green,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _showUnlinkConfirmation(context),
          child: Text(
            '解除',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: themeColors.subTextColor,
            ),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppKendoColors.blue.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.account_circle,
            color: AppKendoColors.blue,
            size: 22,
          ),
        ),
      ),
      title: Text(
        'Googleアカウント連携',
        style: TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: AppFontWeight.bold,
          color: themeColors.textColor,
        ),
      ),
      subtitle: Text(
        'PCとiPadでクイックメモや通知既読を自動同期します',
        style: TextStyle(
          fontSize: AppFontSize.caption,
          color: themeColors.subTextColor,
        ),
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : ElevatedButton.icon(
              onPressed: _handleLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                foregroundColor: themeColors.textColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.round,
                ),
              ),
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text(
                '連携する',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
    );
  }
}
