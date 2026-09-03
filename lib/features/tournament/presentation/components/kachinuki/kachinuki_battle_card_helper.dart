import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 勝ち抜き戦バトルカードの選手名パース・連勝バッジ・スコアマーク補助ヘルパー
class KachinukiBattleCardHelper {
  const KachinukiBattleCardHelper._();

  /// 選手名文字列から役職コロンや欠員を取り除き、苗字と名前のマップを返す
  static Map<String, String> parseName(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  /// 連勝バッジ（🔥 2人抜き / 🔥 2人抜き中）ウィジェットを構築
  static Widget? buildStreakBadge({
    required bool isWin,
    required bool isStreaking,
    required int streak,
    required bool isDark,
  }) {
    if (isWin && streak >= 2) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
              : const Color(0xFFD4AF37),
          borderRadius: AppRadius.small,
        ),
        child: Text(
          '🔥 $streak人抜き',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: AppFontSize.badge,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      );
    } else if (isStreaking) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
              : const Color(0xFFD4AF37),
          borderRadius: AppRadius.small,
          border: Border.all(color: const Color(0xFFD4AF37)),
        ),
        child: Text(
          '🔥 $streak人抜き中',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: AppFontSize.badge,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      );
    }
    return null;
  }

  /// スコアマーク（◯、メ、コなど）のウィジェットリストを構築
  static Widget buildScoreMarks(
    List<PointDisplay> pts,
    Color color,
    bool isFaded,
    bool isDark,
  ) {
    if (pts.isEmpty) return const SizedBox(width: 20);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pts.map((p) {
        final textColor = isFaded
            ? (isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000))
            : color;
        if (p.isFirstMatchPoint && p.mark != '◯') {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: textColor, width: 2),
            ),
            child: Text(
              p.mark,
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Text(
            p.mark,
            style: TextStyle(
              fontSize: AppFontSize.subhead,
              fontWeight: AppFontWeight.black,
              color: textColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}
