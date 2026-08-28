import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🌟 換装核心：アプリの最上位ゲートで一括同期サービスを常時リッスン。
    ref.watch(dojoRoomSyncProvider);

    final cardBgColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.75)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.85);

    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.huge,
                  boxShadow: [
                    BoxShadow(
                      color: AppKendoColors.pureBlack.withValues(
                        alpha: isDark ? 0.3 : 0.1,
                      ),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.huge,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: AppSpacing.xl,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.2)
                              : const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/kendo_icon.png',
                            width: 72,
                            height: 72,
                            color: textColor.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Kendo Sync',
                            style: TextStyle(
                              fontSize: AppFontSize.jumbo,
                              fontWeight: AppFontWeight.bold,
                              color: textColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Stage2 β：利用権限を選択してください',
                            style: TextStyle(
                              fontSize: AppFontSize.bodySmall,
                              color: subTextColor,
                              fontWeight: AppFontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // 接続中の道場IDバー
                          Consumer(
                            builder: (context, ref, child) {
                              final dojoId = ref.watch(currentDojoIdProvider);
                              final displayDojoId = dojoId.isNotEmpty
                                  ? dojoId
                                  : '未設定';
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: InkWell(
                                  onTap: () => RoomJoinQrDialog.show(context),
                                  borderRadius: AppRadius.round,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? context.appColors.textColor
                                                .withValues(alpha: 0.08)
                                          : const Color(0xFFF2F3F7),
                                      borderRadius: AppRadius.round,
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(
                                                0xFFFFFFFF,
                                              ).withValues(alpha: 0.15)
                                            : const Color(
                                                0xFF000000,
                                              ).withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.sm,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(
                                                    0xFFFFFFFF,
                                                  ).withValues(alpha: 0.1)
                                                : const Color(
                                                    0xFFFFFFFF,
                                                  ).withValues(alpha: 0.8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.shield_outlined,
                                            size: 20,
                                            color: isDark
                                                ? context.appColors.textColor
                                                : AppKendoColors.indigo,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '接続中の道場ID (ルーム)',
                                                style: TextStyle(
                                                  fontSize: AppFontSize.caption,
                                                  fontWeight:
                                                      AppFontWeight.bold,
                                                  color: context
                                                      .appColors
                                                      .subTextColor,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                displayDojoId,
                                                style: TextStyle(
                                                  fontSize: AppFontSize.subhead,
                                                  fontWeight:
                                                      AppFontWeight.bold,
                                                  color: isDark
                                                      ? context
                                                            .appColors
                                                            .textColor
                                                      : AppKendoColors
                                                            .indigo
                                                            .shade900,
                                                  letterSpacing: 0.8,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.compact,
                                            vertical: AppSpacing.subValue,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(
                                                    0xFFFFFFFF,
                                                  ).withValues(alpha: 0.12)
                                                : const Color(0xFFFFFFFF),
                                            borderRadius: AppRadius.medium,
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.transparent
                                                  : AppKendoColors
                                                        .grey
                                                        .shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '変更',
                                                style: TextStyle(
                                                  fontSize: AppFontSize.small,
                                                  fontWeight:
                                                      AppFontWeight.bold,
                                                  color: isDark
                                                      ? AppKendoColors
                                                            .tealAccent
                                                      : AppKendoColors
                                                            .indigo
                                                            .shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(
                                                Icons.edit,
                                                size: 13,
                                                color: isDark
                                                    ? AppKendoColors.tealAccent
                                                    : AppKendoColors
                                                          .indigo
                                                          .shade700,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 1. 代表・管理者 (Admin)
                          _buildRoleRow(
                            context,
                            ref,
                            title: '代表・管理者 (Admin)',
                            role: UserRole.admin,
                            color: AppKendoColors.purple,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // 2. 監督・引率責任者 (Operator)
                          _buildRoleRow(
                            context,
                            ref,
                            title: '監督・引率責任者 (Operator)',
                            role: UserRole.operator,
                            color: AppKendoColors.teal,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // 3. スコア・記録係 (Recorder)
                          _buildRoleRow(
                            context,
                            ref,
                            title: 'スコア・記録係 (Recorder)',
                            role: UserRole.recorder,
                            color: AppKendoColors.indigo,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // 4. 応援・保護者・選手 (Viewer)
                          _buildRoleRow(
                            context,
                            ref,
                            title: '応援・保護者・選手 (Viewer)',
                            role: UserRole.viewer,
                            color: AppKendoColors.blueGrey,
                            isPinFree: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleRow(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required UserRole role,
    required Color color,
    bool isPinFree = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.88),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
        ),
        onPressed: () async {
          if (role == UserRole.viewer) {
            if (FirebaseAuth.instance.currentUser == null) {
              await FirebaseAuth.instance.signInAnonymously();
            }
            await ref
                .read(authSessionProvider.notifier)
                .establishSession(
                  UserRole.viewer,
                  ref.read(currentDojoIdProvider),
                );
            if (context.mounted) {
              context.go('/');
            }
          } else {
            context.push('/pin-auth?role=${role.name}');
          }
        },
        child: Row(
          children: [
            // 左端バッジ（または位置合わせ用スペース）
            SizedBox(
              width: 32,
              child: isPinFree
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppKendoColors.pureWhite.withValues(alpha: 0.25),
                        borderRadius: AppRadius.small,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'PIN',
                            style: TextStyle(
                              color: AppKendoColors.pureWhite,
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.nano,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xxs),
                          Text(
                            '不要',
                            style: TextStyle(
                              color: AppKendoColors.pureWhite,
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.micro,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 先頭揃えテキスト
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppKendoColors.pureWhite,
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
