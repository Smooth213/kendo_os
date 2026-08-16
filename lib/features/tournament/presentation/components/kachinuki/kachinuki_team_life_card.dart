import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 勝ち抜き戦のチーム生存状況（残機・シールド表示）カード（純粋UIコンポーネント）
class KachinukiTeamLifeCard extends StatelessWidget {
  final String redTeamName;
  final String whiteTeamName;
  final int redTotal;
  final int redDead;
  final int whiteTotal;
  final int whiteDead;
  final bool isDark;

  const KachinukiTeamLifeCard({
    super.key,
    required this.redTeamName,
    required this.whiteTeamName,
    required this.redTotal,
    required this.redDead,
    required this.whiteTotal,
    required this.whiteDead,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.roundValue),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.xlarge,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFF3F51B5),
        ),
      ),
      child: Column(
        children: [
          Text(
            'チーム生存状況（残機）',
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
              color: isDark ? const Color(0xFFFFFFFF) : AppKendoColors.grey,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      redTeamName,
                      style: TextStyle(
                        fontWeight: AppFontWeight.black,
                        color: isDark
                            ? const Color(0xFFE53935)
                            : const Color(0xFFE53935),
                        fontSize: AppFontSize.subhead,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(
                        redTotal,
                        (i) => Icon(
                          Icons.shield,
                          color: i >= redDead
                              ? AppKendoColors.hansokuRed
                              : (isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0x33000000)),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontWeight: AppFontWeight.black,
                    fontSize: AppFontSize.display,
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                        : const Color(0xFF000000).withValues(alpha: 0.12),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      whiteTeamName,
                      style: TextStyle(
                        fontWeight: AppFontWeight.black,
                        color: isDark
                            ? const Color(0xFF607D8B)
                            : const Color(0xFF607D8B),
                        fontSize: AppFontSize.subhead,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: List.generate(
                        whiteTotal,
                        (i) => Icon(
                          Icons.shield,
                          color: i >= whiteDead
                              ? (isDark
                                    ? const Color(0xFF607D8B)
                                    : const Color(0xFF607D8B))
                              : (isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0x33000000)),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
