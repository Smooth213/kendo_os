import 'package:flutter/material.dart';
import 'package:kendo_os/security/pin_guard.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 大会全削除やマスタ破棄など、現場での取り返しのつかない誤操作（運用事故）を
/// 「PINコードの再入力」によってランタイムレベルで水際ブロックするディフェンスWidget。
class CriticalActionGuard {
  static void enforce({
    required BuildContext context,
    required UserRole currentRole,
    required VoidCallback onVerified,
    String message = 'この操作は取り消せません。実行するには認証PINを再入力してください。',
  }) {
    // そもそも Viewer は実行不可なので即時リターン
    if (currentRole == UserRole.viewer) return;

    final pinController = TextEditingController();
    String? errorMessage;

    showAppDialog(
      context: context,
      barrierDismissible: false, // 外部タップでの勝手なキャンセルを禁止
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AppDialog(
              backgroundColor: const Color(0xFF161B26),
              titleIcon: Icons.warning_amber_rounded,
              iconColor: Colors.orangeAccent,
              title: '⚠️ 危険操作の再認証',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: AppFontSize.bodySmall),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '再認証PINコード',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      errorText: errorMessage,
                      errorStyle: const TextStyle(color: Colors.orangeAccent),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.8),
                  ),
                  onPressed: () {
                    // PinGuardへ現在のロールと再入力された値を渡して決定論的に直接検証
                    final isValid = PinGuard.validate(
                      currentRole,
                      pinController.text,
                    );
                    if (isValid) {
                      Navigator.of(context).pop();
                      onVerified(); // 認証成功時のみ本番の処理をキック
                    } else {
                      setState(() => errorMessage = 'PINコードが一致しません');
                    }
                  },
                  child: const Text(
                    '認証して実行',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
