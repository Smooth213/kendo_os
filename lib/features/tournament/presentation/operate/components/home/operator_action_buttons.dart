import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 大会運営用 アクションボタン群（2列スマートグリッド構成）
class OperatorActionButtons extends ConsumerWidget {
  final String tournamentId;
  const OperatorActionButtons({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);
    final bool isReadOnly = permissions.isReadOnly;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isBunaiksen = tournamentId.startsWith('bunaiksen_');
    final Color viewerThemeColor = isBunaiksen
        ? AppKendoColors.purple
        : AppKendoColors.blueGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isReadOnly) ...[
          // 1. 最重要プライマリアクション: 「試合（対戦）を作成」
          _buildPrimaryMatchCreateButton(
            context,
            enableLiquidGlass,
            () => context.push('/setup-match/$tournamentId'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // 2. 2列スマートグリッド（4つの管理機能）
        Row(
          children: [
            if (!isReadOnly)
              Expanded(
                child: _buildCompactTile(
                  context: context,
                  enableLiquidGlass: enableLiquidGlass,
                  icon: Icons.gavel,
                  title: '試合ルール設定',
                  color: AppKendoColors.teal,
                  onTap: () =>
                      context.push('/tournament/$tournamentId/category-rules'),
                ),
              ),
            if (!isReadOnly) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildCompactTile(
                context: context,
                enableLiquidGlass: enableLiquidGlass,
                icon: Icons.cast_connected,
                title: '観客の画面を確認',
                color: viewerThemeColor,
                onTap: () {
                  final dojoId = ref.read(currentDojoIdProvider);
                  if (isBunaiksen) {
                    context.push(
                      '/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$dojoId',
                    );
                  } else {
                    context.push(
                      '/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId',
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildCompactTile(
                context: context,
                enableLiquidGlass: enableLiquidGlass,
                icon: Icons.print,
                title: '試合結果一覧',
                color: AppKendoColors.blueGrey,
                onTap: () => context.push('/official-record/$tournamentId'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildCompactTile(
                context: context,
                enableLiquidGlass: enableLiquidGlass,
                icon: Icons.picture_as_pdf,
                title: '大会プログラム管理',
                color: isDark
                    ? context.appColors.rosePink
                    : context.appColors.errorColor,
                onTap: () => context.push('/tournament/$tournamentId/programs'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCompactTile(
          context: context,
          enableLiquidGlass: enableLiquidGlass,
          icon: Icons.groups_outlined,
          title: 'チーム試合状況',
          color: AppKendoColors.indigo,
          onTap: () => context.push('/court-status?tournamentId=$tournamentId'),
        ),
      ],
    );
  }

  /// 🌟 最重要プライマリボタン: 「試合（対戦）を作成」
  Widget _buildPrimaryMatchCreateButton(
    BuildContext context,
    bool enableLiquidGlass,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppKendoColors.indigo;

    return Material(
      color: AppKendoColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      primaryColor.withValues(alpha: 0.45),
                      primaryColor.withValues(alpha: 0.28),
                    ]
                  : [primaryColor, primaryColor.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppKendoColors.pureWhite.withValues(alpha: 0.2),
                  borderRadius: AppRadius.small,
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: AppKendoColors.pureWhite,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '試合（対戦）を作成',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.body,
                      color: AppKendoColors.pureWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.arrow_forward_ios,
                size: 13,
                color: AppKendoColors.pureWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📱 2列グリッド用 コンパクトスマートカードタイル
  Widget _buildCompactTile({
    required BuildContext context,
    required bool enableLiquidGlass,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppKendoColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: enableLiquidGlass
                ? (isDark
                      ? color.withValues(alpha: 0.18)
                      : color.withValues(alpha: 0.12))
                : context.appColors.cardBackground,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: color.withValues(alpha: enableLiquidGlass ? 0.35 : 0.25),
              width: 1.2,
            ),
            boxShadow: enableLiquidGlass
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.body,
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : context.appColors.textColor,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 11,
                color: isDark
                    ? const Color(0x80FFFFFF)
                    : context.appColors.textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
