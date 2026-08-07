import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🌟 換装核心：アプリの最上位ゲートで一括同期サービスを常時リッスン。
    // これにより、端末が管理者であろうが観客であろうが、同じ道場IDに入った全端末間で
    // 双方向のリアルタイム通信が全自動で完全開通します。
    ref.watch(dojoRoomSyncProvider);

    // ★ アプリ全体と統一した iOS 風 (Liquid Glass) のガラス背景
    final cardBgColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.4)
        : AppKendoColors.pureWhite.withValues(alpha: 0.6);

    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent, // 背景のオーブを透かす
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
                        vertical: 40,
                        horizontal: AppSpacing.xl,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        border: Border.all(
                          color: isDark
                              ? AppKendoColors.pureWhite.withValues(alpha: 0.2)
                              : AppKendoColors.pureWhite.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/kendo_icon.png',
                            width: 80,
                            height: 80,
                            color: textColor.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Kendo Sync',
                            style: TextStyle(
                              fontSize: AppFontSize.jumbo,
                              fontWeight: AppFontWeight.bold,
                              color: textColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Stage2 β：利用権限を選択してください',
                            style: TextStyle(
                              fontSize: AppFontSize.bodySmall,
                              color: subTextColor,
                              fontWeight: AppFontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          // =========================================================================
                          // 🛡️ 現場運用要件：現在どの道場空間に接続しているかを明示し、一発で切り替えるボタン
                          // =========================================================================
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
                                  vertical: AppSpacing.compact,
                                ),
                                child: InkWell(
                                  onTap: () => RoomJoinQrDialog.show(context),
                                  borderRadius: AppRadius.round,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.mediumLg,
                                      vertical: AppSpacing.modernValue,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppKendoColors.pureWhite.withValues(
                                              alpha: 0.08,
                                            )
                                          : const Color(0xFFF2F3F7),
                                      borderRadius: AppRadius.round,
                                      border: Border.all(
                                        color: isDark
                                            ? AppKendoColors.pureWhite
                                                  .withValues(alpha: 0.15)
                                            : AppKendoColors.pureBlack
                                                  .withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.nano,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppKendoColors.tealAccent
                                                      .withValues(alpha: 0.15)
                                                : AppKendoColors.indigo
                                                      .withValues(alpha: 0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.shield_outlined,
                                            color: isDark
                                                ? AppKendoColors.tealAccent
                                                : AppKendoColors
                                                      .indigo
                                                      .shade700,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
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
                                                      ? AppKendoColors.pureWhite
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
                                                ? AppKendoColors.pureWhite
                                                      .withValues(alpha: 0.12)
                                                : AppKendoColors.pureWhite,
                                            borderRadius: AppRadius.medium,
                                            border: Border.all(
                                              color: isDark
                                                  ? AppKendoColors.transparent
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
                          const SizedBox(height: AppSpacing.xxl),
                          _buildRoleRow(
                            context,
                            ref,
                            '最高管理者 (Admin)',
                            UserRole.admin,
                            AppKendoColors.purple,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildRoleRow(
                            context,
                            ref,
                            '大会運営者 (Operator)',
                            UserRole.operator,
                            AppKendoColors.teal,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildRoleRow(
                            context,
                            ref,
                            '試合記録者 (Recorder)',
                            UserRole.recorder,
                            AppKendoColors.indigo,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildRoleRow(
                            context,
                            ref,
                            '一般観客席 (Viewer) [PIN不要]',
                            UserRole.viewer,
                            AppKendoColors.blueGrey,
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
    WidgetRef ref,
    String title,
    UserRole role,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.85),
          elevation: 0,
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
        child: Text(
          title,
          style: const TextStyle(
            color: AppKendoColors.pureWhite,
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.subhead,
          ),
        ),
      ),
    );
  }
}
