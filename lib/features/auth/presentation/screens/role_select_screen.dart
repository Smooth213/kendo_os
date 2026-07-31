import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
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
        : Colors.white.withValues(alpha: 0.6);

    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // 背景のオーブを透かす
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.7),
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
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Stage2 β：利用権限を選択してください',
                            style: TextStyle(
                              fontSize: 13,
                              color: subTextColor,
                              fontWeight: FontWeight.bold,
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
                                  vertical: 10,
                                ),
                                child: InkWell(
                                  onTap: () => RoomJoinQrDialog.show(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFF2F3F7),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.15,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.hub_outlined,
                                          color: isDark
                                              ? Colors.tealAccent
                                              : Colors.indigo.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                '接続中の道場ルーム: ',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? Colors.grey.shade400
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  displayDojoId,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    letterSpacing: 0.5,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.transparent
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '変更',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.tealAccent
                                                      : Colors.indigo.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(
                                                Icons.edit,
                                                size: 13,
                                                color: isDark
                                                    ? Colors.tealAccent
                                                    : Colors.indigo.shade700,
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
                          const SizedBox(height: 32),
                          _buildRoleRow(
                            context,
                            ref,
                            '最高管理者 (Admin)',
                            UserRole.admin,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),
                          _buildRoleRow(
                            context,
                            ref,
                            '大会運営者 (Operator)',
                            UserRole.operator,
                            Colors.teal,
                          ),
                          const SizedBox(height: 16),
                          _buildRoleRow(
                            context,
                            ref,
                            '試合記録者 (Recorder)',
                            UserRole.recorder,
                            Colors.indigo,
                          ),
                          const SizedBox(height: 16),
                          _buildRoleRow(
                            context,
                            ref,
                            '一般観客席 (Viewer) [PIN不要]',
                            UserRole.viewer,
                            Colors.blueGrey,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
