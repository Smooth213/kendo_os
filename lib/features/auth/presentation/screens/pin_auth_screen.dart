import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/security/pin_guard.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

class PinAuthScreen extends ConsumerWidget {
  final UserRole role;
  const PinAuthScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ★ アプリ全体と統一した iOS 風 (Liquid Glass) のガラス背景
    final cardBgColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);

    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    // 前の画面のボタン色と合わせるためのテーマカラー定義
    Color roleColor;
    switch (role) {
      case UserRole.admin:
        roleColor = Colors.purple;
        break;
      case UserRole.operator:
        roleColor = Colors.teal;
        break;
      case UserRole.recorder:
        roleColor = Colors.indigo;
        break;
      default:
        roleColor = Colors.blueGrey;
    }

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppHeader(backgroundColor: Colors.transparent),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
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
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: textColor.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${role.name.toUpperCase()} 認証ゲート',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '誤操作防止のため、指定のPINコードを入力してください。',
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.5),
                              hintText: '••••',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: roleColor.withValues(
                                  alpha: 0.85,
                                ),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                if (PinGuard.validate(role, controller.text)) {
                                  await ref
                                      .read(authSessionProvider.notifier)
                                      .establishSession(
                                        role,
                                        ref.read(currentDojoIdProvider),
                                      );
                                  if (context.mounted) {
                                    context.go('/');
                                  }
                                } else {
                                  AppSnackBar.showError(
                                    context,
                                    '🔒 PINコードが一致しません。認証を拒絶しました。',
                                  );
                                }
                              },
                              child: const Text(
                                '認証して進入',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
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
}
