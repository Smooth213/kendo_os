import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 部内戦の試合結果・スコアマーク（メ、コ、ド、ツ、反、判、◯等）を美しく描画する純粋UIコンポーネント
class BunaiksenScoreMarks extends StatelessWidget {
  final MatchModel match;
  final bool isDark;
  final bool isFinished;
  final Color? textColor;
  final Color? iconColor;

  const BunaiksenScoreMarks({
    super.key,
    required this.match,
    required this.isDark,
    this.isFinished = true,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor =
        textColor ??
        (isFinished
            ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF475569))
            : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000)));

    final effectiveIconColor =
        iconColor ??
        (isFinished
            ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF475569))
            : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF475569)));

    // 完全無得点の引き分け
    if (match.redScore == 0 && match.whiteScore == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Icon(Icons.close, size: 18, color: effectiveIconColor),
      );
    }

    // KendoRuleEngine を使用し、Undoされたイベントを除外した正確な結果を使用
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(match.events, match, match.rule);

    final rDisplays = analysis.displays[Side.red] ?? [];
    final wDisplays = analysis.displays[Side.white] ?? [];

    // 表示用のマークを抽出して、1本目なら丸囲み文字に変換
    String rMarksStr = rDisplays
        .map((d) {
          if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
          if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
          if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
          if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
          if (d.mark == '反') return '反';
          if (d.mark == '判定') return '判';
          if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
          return d.mark;
        })
        .join('');

    String wMarksStr = wDisplays
        .map((d) {
          if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
          if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
          if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
          if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
          if (d.mark == '反') return '反';
          if (d.mark == '判定') return '判';
          if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
          return d.mark;
        })
        .join('');

    final bool isDraw = match.redScore == match.whiteScore;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rMarksStr,
          style: TextStyle(
            fontSize: AppFontSize.header,
            fontWeight: AppFontWeight.bold,
            color: effectiveTextColor,
            height: 1.1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            isDraw ? Icons.close : Icons.remove,
            size: 16,
            color: effectiveIconColor,
          ),
        ),
        Text(
          wMarksStr,
          style: TextStyle(
            fontSize: AppFontSize.header,
            fontWeight: AppFontWeight.bold,
            color: effectiveTextColor,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
