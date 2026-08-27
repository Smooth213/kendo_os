import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ★ 旧 permissionProvider を完全撤廃し、新設計の RolePermissions に一元結合
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/security/role_permissions.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';

import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : context.appColors.subTextColor;

    return GlassButton.custom(
      onPressed: onTap,
      color: color,
      surfaceColor: AppKendoColors.pureWhite,
      glassAlpha: isDark ? 0.08 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.bodyMedium,
                fontWeight: AppFontWeight.bold,
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: subTextColor,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ 核心：現在のロール状態をリアルタイムに監視
    final currentRole = ref.watch(currentUserRoleProvider);

    // 一元管理クラス RolePermissions からボタンの表示条件を正確に算出
    final bool showCreateTournament = RolePermissions.canCreateTournament(
      currentRole,
    );
    final bool showPlayerMaster = RolePermissions.canAccessPlayerMaster(
      currentRole,
    );

    // ユーザーにわかりやすい日本語の権限名に変換
    String roleDisplayName;
    switch (currentRole) {
      case UserRole.admin:
        roleDisplayName = '管理者 (Admin)';
        break;
      case UserRole.operator:
        roleDisplayName = '大会運営者 (Operator)';
        break;
      case UserRole.recorder:
        roleDisplayName = '試合記録者 (Recorder)';
        break;
      case UserRole.viewer:
        roleDisplayName = '閲覧専用 (Viewer)';
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerStartColor = isDark
        ? context.appColors.primaryAccent
        : context.appColors.primaryAccent;
    final headerEndColor = isDark
        ? const Color(0xFF1A237E)
        : context.appColors.infoColor;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 32,
                bottom: 48,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerStartColor, headerEndColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.giantValue),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF3F51B5).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kendo Sync',
                        style: TextStyle(
                          fontSize: AppFontSize.heroXxl,
                          fontWeight: AppFontWeight.bold,
                          color: AppKendoColors.pureWhite,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          if (RolePermissions.canAccessSettings(currentRole))
                            IconButton(
                              icon: Icon(
                                Icons.settings,
                                color: AppKendoColors.pureWhite.withValues(
                                  alpha: 0.7,
                                ),
                                size: 22,
                              ),
                              tooltip: 'システム設定',
                              onPressed: () => context.push('/settings'),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.logout_outlined,
                              color: AppKendoColors.pureWhite.withValues(
                                alpha: 0.7,
                              ),
                              size: 22,
                            ),
                            tooltip: '権限を変更（ログアウト）',
                            onPressed: () {
                              // 最初のロール選択画面へ戻る導線を確保
                              ref.read(authSessionProvider.notifier).logout();
                              context.go('/role-select');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '現在の権限: $roleDisplayName',
                    style: const TextStyle(
                      fontSize: AppFontSize.small,
                      color: AppKendoColors.orangeAccent,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (currentRole == UserRole.viewer) {
                          final now = DateTime.now();
                          final yyyy = now.year.toString();
                          final mm = now.month.toString().padLeft(2, '0');
                          final dd = now.day.toString().padLeft(2, '0');
                          final dateId = 'bunaiksen_$yyyy$mm$dd';
                          context.push('/bunaiksen-viewer-home/$dateId');
                        } else {
                          context.push('/bunaiksen-home');
                        }
                      },
                      icon: const Icon(
                        Icons.local_fire_department,
                        color: AppKendoColors.pureWhite,
                      ),
                      label: const Text(
                        '部内戦をはじめる',
                        style: TextStyle(
                          color: AppKendoColors.pureWhite,
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.bodyMedium,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        side: const BorderSide(
                          color: AppKendoColors.pureWhite,
                          width: 1.5,
                        ),
                        backgroundColor: AppKendoColors.pureWhite.withValues(
                          alpha: 0.15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.large,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(
                            children: [
                              // ★ 仕様準拠: ViewerやRecorderには、ボタン自体を「非表示」にして誤操作を完全撲滅
                              if (showCreateTournament) ...[
                                Expanded(
                                  child: _buildActionCard(
                                    context,
                                    icon: Icons.add_circle,
                                    title: '新しい大会\nを作る',
                                    subtitle: '大会・錬成会',
                                    color: context.appColors.primaryAccent,
                                    onTap: () =>
                                        context.push('/create-tournament'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                              ],
                              Expanded(
                                child: _buildActionCard(
                                  context,
                                  icon: Icons.list_alt,
                                  title: '今日の試合\nを作る・見る',
                                  subtitle: '試合進行・記録',
                                  color: context.appColors.primaryAccent,
                                  onTap: () => context.push(
                                    '/tournament-list',
                                    extra: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  context,
                                  icon: Icons.history,
                                  title: '過去の大会\nを見る',
                                  subtitle: 'アーカイブ',
                                  color: context.appColors.subTextColor,
                                  onTap: () => context.push(
                                    '/tournament-list',
                                    extra: true,
                                  ),
                                ),
                              ),
                              if (showPlayerMaster) ...[
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: _buildActionCard(
                                    context,
                                    icon: Icons.manage_accounts,
                                    title: '選手名簿\n(マスタ) 管理',
                                    subtitle: '道場生データ',
                                    color: context.appColors.primaryAccent,
                                    onTap: () => context.push('/master'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ]),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xxl,
                          bottom: AppSpacing.giant,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/kendo_icon.png',
                              width: 72,
                              height: 72,
                              color: isDark
                                  ? const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.45)
                                  : const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Kendo Sync v1.0.0',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontSize: AppFontSize.small,
                                fontWeight: AppFontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
