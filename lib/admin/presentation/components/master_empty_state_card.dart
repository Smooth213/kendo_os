import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 選手マスタ管理画面の未登録状態（Empty State）カード（純粋UIコンポーネント）
class MasterEmptyStateCard extends StatelessWidget {
  final Color primaryColor;
  final bool isReadOnly;
  final VoidCallback? onRegisterDojo;
  final Widget? iconWidget;
  final Widget? buttonWidget;

  const MasterEmptyStateCard({
    super.key,
    required this.primaryColor,
    this.isReadOnly = false,
    this.onRegisterDojo,
    this.iconWidget,
    this.buttonWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget? actionButton = buttonWidget;
    if (actionButton == null && !isReadOnly && onRegisterDojo != null) {
      actionButton = SizedBox(
        width: 240,
        child: GlassButton(
          onPressed: onRegisterDojo,
          color: primaryColor,
          icon: Icons.account_balance,
          label: '道場名を登録する',
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ??
                Image.asset(
                  'assets/kendo_icon.png',
                  width: 80,
                  height: 80,
                  color: const Color(0x33000000),
                ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'まだ選手が登録されていません',
              style: TextStyle(
                fontSize: AppFontSize.headline,
                fontWeight: AppFontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '選手を追加する前に、まずはあなたたちの道場名・学校名を登録することから始めましょう！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppKendoColors.grey,
                height: 1.5,
                fontSize: AppFontSize.body,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ?actionButton,
          ],
        ),
      ),
    );
  }
}
