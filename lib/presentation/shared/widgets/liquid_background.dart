import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../operate/providers/settings_provider.dart';

class LiquidBackground extends ConsumerWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 軽量モード: すりガラス効果をOFFにしてパフォーマンスを最優先
    if (!settings.enableLiquidGlass) {
      return Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: child,
      );
    }

    // Liquid Glassモード: テーマカラーのオーブ（光の玉）を配置し、全体に強いブラーをかける
    return Stack(
      children: [
        // ベース背景色
        Container(
          color: isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF2F2F7),
        ),
        // オーブ1: 左上 (テーマカラー: インディゴ)
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.indigo.withValues(alpha: 0.3) : Colors.indigo.withValues(alpha: 0.15),
            ),
          ),
        ),
        // オーブ2: 右下 (テーマカラー: ティール)
        Positioned(
          bottom: -150,
          right: -50,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.teal.withValues(alpha: 0.25) : Colors.teal.withValues(alpha: 0.12),
            ),
          ),
        ),
        // 強力なブラー（すりガラスフィルター）を全体にかける
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        // 前面の Scaffold 等
        child,
      ],
    );
  }
}