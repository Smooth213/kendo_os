import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 大会新規作成: スティッキーボトムアクションバー
class CreateTournamentStickyBottomAction extends ConsumerWidget {
  final int currentPage;
  final VoidCallback onPrevious;
  final VoidCallback onNextOrSave;

  const CreateTournamentStickyBottomAction({
    super.key,
    required this.currentPage,
    required this.onPrevious,
    required this.onNextOrSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final isLastPage = currentPage == 1;
    final Color bottomBarColor = enableLiquidGlass
        ? AppKendoColors.transparent
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));
    final Color separatorColor = enableLiquidGlass
        ? AppKendoColors.transparent
        : (isDark ? const Color(0xFF38383A) : const Color(0x33000000));

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bottomBarColor,
        border: Border(top: BorderSide(color: separatorColor, width: 0.5)),
      ),
      child: Row(
        children: [
          if (currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: OutlinedButton(
                onPressed: onPrevious,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  shape: const CircleBorder(),
                  side: BorderSide(color: separatorColor),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Color(0xFF3F51B5),
                ),
              ),
            ),
          Expanded(
            child: GlassButton(
              onPressed: onNextOrSave,
              color: AppKendoColors.indigo,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              icon: isLastPage ? Icons.check_circle : Icons.navigate_next,
              label: isLastPage ? '保存してチーム登録へ' : '次へ進む',
              expandContent: false,
            ),
          ),
        ],
      ),
    );
  }
}
