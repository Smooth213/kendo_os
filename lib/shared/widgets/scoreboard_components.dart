import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// スコアボード用補助コンポーネント（結果オーバーレイ・ポイントマーク）
class ScoreboardComponents {
  static Widget buildPoint(
    BuildContext context,
    PointDisplay pd,
    bool isDark,
    Color color,
  ) {
    const double fs = 38;
    final pointWidget = pd.isFirstMatchPoint
        ? Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.7 : 1.0),
                width: 3.5,
              ),
            ),
            child: Text(
              pd.mark,
              style: TextStyle(
                fontSize: fs,
                fontWeight: AppFontWeight.bold,
                color: color,
                height: 1.0,
              ),
            ),
          )
        : SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: Text(
                pd.mark,
                style: TextStyle(
                  fontSize: fs,
                  fontWeight: AppFontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
            ),
          );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.1, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
      ),
      child: pointWidget,
    );
  }

  static Widget buildResultOverlay(
    BuildContext context,
    MatchViewState viewState,
    MatchModel match,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String resultText = '引き分け';
    final winner =
        viewState.winner ??
        (match.redScore > match.whiteScore
            ? 'red'
            : (match.whiteScore > match.redScore ? 'white' : 'draw'));
    if (winner == 'red') resultText = '赤 の勝ち';
    if (winner == 'white') resultText = '白 の勝ち';

    return Container(
      height: 60,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
      decoration: BoxDecoration(
        color: context.appColors.primaryAccent,
        borderRadius: AppRadius.full,
        border: isDark
            ? Border.all(color: const Color(0xFF3F51B5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppKendoColors.pureBlack.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        child: Text(
          resultText,
          style: const TextStyle(
            color: AppKendoColors.pureWhite,
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.hero,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
