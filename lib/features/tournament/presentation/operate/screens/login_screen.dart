import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/infrastructure/repository/auth_repository.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS 26 スタイル: ログインのイメージカラー「ピンク」を維持しつつ、ダークモードでは彩度を微調整
    const Color pinkAccent = Color(0xFFFF9EFF);
    final Color buttonColor = isDark ? const Color(0xFFE599E5) : pinkAccent;

    // iOS Native カラーパレット
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color primaryText = isDark ? Colors.white : Colors.black;
    final Color secondaryText = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF636366);

    // ボタン上の文字色は視認性の高い「深い紺」で固定
    const buttonTextColor = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // iOS Native: Elevation（浮き上がり）を光の輪で表現
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: isDark ? 0.3 : 0.2),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/kendo_icon.png',
                  width: 140,
                  height: 140,
                  color: isDark
                      ? Colors.white
                      : buttonColor, // ダークモードではアイコンを白抜きにしても美しい
                ),
              ),
              const SizedBox(height: 40),

              // ★ タイトルも洗練されたフォントと色使いへ
              Text(
                'Kendo Sync',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: primaryText, // ★ メインテキスト色を使用
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '次世代の剣道スコア入力システム',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: secondaryText,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 80),

              // ★ プレミアムなログインボタン（他画面のボタンと同等のクオリティ）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.login,
                    color: buttonTextColor,
                    size: 24,
                  ),
                  label: const Text(
                    'Googleでログイン',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: buttonTextColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  onPressed: () async {
                    try {
                      debugPrint("🔘 [LoginScreen] ログインボタン押下");
                      await ref.read(authRepositoryProvider).signInWithGoogle();
                      if (!context.mounted) return;
                      context.go('/');
                    } catch (e) {
                      debugPrint("❌ [LoginScreen] ログインエラー: $e");
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ログインに失敗しました: ${e.toString()}')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor.withValues(alpha: 0.6),
                    foregroundColor: buttonTextColor,
                    minimumSize: const Size(double.infinity, 60),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
