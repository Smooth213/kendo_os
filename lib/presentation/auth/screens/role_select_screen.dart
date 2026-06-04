import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/user_role.dart';
import '../../shared/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog.dart';
import '../../shared/providers/dojo_room_sync_provider.dart';

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
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: InkWell(
                                  onTap: () => RoomJoinQrDialog.show(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      // 背景色：ダーク/ライトモードに応じた半透明グラス風
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.07)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.15,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.hub_outlined,
                                          color: isDark
                                              ? Colors.tealAccent
                                              : Colors.teal.shade700,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '接続中の道場ルーム: ',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.6,
                                                              )
                                                        : Colors.black
                                                              .withValues(
                                                                alpha: 0.6,
                                                              ),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: dojoId,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.edit_note,
                                          color: isDark
                                              ? Colors.white30
                                              : Colors.black26,
                                          size: 16,
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
                            '最高管理者 (Admin)',
                            UserRole.admin,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),
                          _buildRoleRow(
                            context,
                            '大会運営者 (Operator)',
                            UserRole.operator,
                            Colors.teal,
                          ),
                          const SizedBox(height: 16),
                          _buildRoleRow(
                            context,
                            '試合記録者 (Recorder)',
                            UserRole.recorder,
                            Colors.indigo,
                          ),
                          const SizedBox(height: 16),
                          _buildRoleRow(
                            context,
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
        onPressed: () {
          if (role == UserRole.viewer) {
            context.go('/?role=viewer');
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
