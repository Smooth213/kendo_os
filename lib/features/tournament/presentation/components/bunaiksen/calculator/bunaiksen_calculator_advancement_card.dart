import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/bunaiksen_calculator_match_generator.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 試合作成シート用：決勝トーナメント進出方式選択カードWidget
class BunaiksenCalculatorAdvancementCard extends StatelessWidget {
  final TournamentAdvancementMethod advancementMethod;
  final ValueChanged<TournamentAdvancementMethod> onChanged;
  final AppThemeColors themeColors;
  final bool isDark;

  const BunaiksenCalculatorAdvancementCard({
    super.key,
    required this.advancementMethod,
    required this.onChanged,
    required this.themeColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 決勝トーナメント進出者の配置方法',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildCard(
            title: '順位直結配置 (Aリーグ1位 vs Bリーグ2位)',
            subtitle: '予選リーグ終了時、順位確定後に自動で名前が割り振られます',
            method: TournamentAdvancementMethod.directRank,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildCard(
            title: '🎲 くじ引き・抽選枠配置 (抽選枠1番 vs 2番)',
            subtitle: 'その場でデジタル抽選または紙くじを引き、タップで配置します',
            method: TournamentAdvancementMethod.lottery,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required TournamentAdvancementMethod method,
  }) {
    final isSelected = advancementMethod == method;
    return InkWell(
      borderRadius: AppRadius.small,
      onTap: () {
        AppHaptics.selection();
        onChanged(method);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColors.primaryAccent.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: AppRadius.small,
          border: Border.all(
            color: isSelected
                ? themeColors.primaryAccent
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isSelected
                  ? themeColors.primaryAccent
                  : (isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.caption,
                      color: isSelected ? themeColors.primaryAccent : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
