import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 代表戦の選手が未設定時のフルスクリーンオーバーレイ
class MatchDaihyoOverlay extends StatelessWidget {
  final VoidCallback onSelectDaihyo;

  const MatchDaihyoOverlay({super.key, required this.onSelectDaihyo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppKendoColors.pureBlack.withValues(alpha: 0.8),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add,
              color: AppKendoColors.pureWhite,
              size: 80,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              '代表戦の選手が未設定です',
              style: TextStyle(
                color: AppKendoColors.pureWhite,
                fontSize: AppFontSize.header,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: 250,
              child: GlassButton(
                onPressed: onSelectDaihyo,
                color: AppKendoColors.indigo,
                label: '代表者を選択する',
                expandContent: false,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.lg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
