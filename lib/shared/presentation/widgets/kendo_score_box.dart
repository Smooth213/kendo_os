import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 剣道公式スコア表示バリアント（スタイル形式）
enum ScoreDisplayVariant {
  /// 2段・斜め配置（スコア盤、対戦詳細テーブル、公式記録、観戦ビューアー）
  table,

  /// 横並びインライン（チーム試合状況、大会タイムライン、部内戦ミニカード）
  inline,

  /// 特大視認性モード（試合スコア入力画面、大型電光掲示板）
  scoreboard,
}

/// 技マーク・打突データ（表示用イミュータブルモデル）
class KendoPointMark {
  final String mark;
  final bool isFirst;

  const KendoPointMark({required this.mark, this.isFirst = false});

  /// 特殊記号（先取丸囲み対象外）判定
  bool get isSpecialNonCircle =>
      mark == '◯' || mark == '◎' || mark == '反' || mark == '×' || mark == '✕';

  /// 表示用クリーンマーク（「判定」➔「判」、「✕」➔「×」）
  String get displayMark {
    if (mark == '判定') return '判';
    if (mark == '✕') return '×';
    return mark;
  }
}

/// 技マーク単体バッジ（先取丸囲み・通常文字のガバナンス描画）
class KendoTechMarkBadge extends StatelessWidget {
  final KendoPointMark point;
  final Color color;
  final bool isDark;
  final double? fontSize;
  final double? circleSize;

  const KendoTechMarkBadge({
    super.key,
    required this.point,
    required this.color,
    required this.isDark,
    this.fontSize,
    this.circleSize,
  });

  @override
  Widget build(BuildContext context) {
    final String text = point.displayMark;
    final bool shouldEncircle = point.isFirst && !point.isSpecialNonCircle;

    if (shouldEncircle) {
      final double size = circleSize ?? 14.0;
      final double fs = fontSize ?? AppFontSize.micro;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.7 : 1.0),
            width: size > 30 ? 3.0 : 1.0,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fs,
            color: color,
            fontWeight: AppFontWeight.bold,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? AppFontSize.badge,
          color: color,
          fontWeight: AppFontWeight.bold,
          height: 1.1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 剣道スコアボックス（全画面・全バリアント統合ガバナンスコンポーネント）
class KendoScoreBox extends StatelessWidget {
  final List<KendoPointMark> points;
  final bool isWinner;
  final bool isRed;
  final bool isDark;
  final ScoreDisplayVariant variant;
  final Color? customColor;

  const KendoScoreBox({
    super.key,
    required this.points,
    this.isWinner = false,
    this.isRed = true,
    this.isDark = false,
    this.variant = ScoreDisplayVariant.table,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        customColor ??
        (isRed ? context.appColors.errorColor : context.appColors.infoColor);

    switch (variant) {
      case ScoreDisplayVariant.table:
        return _buildTableVariant(context, color);
      case ScoreDisplayVariant.inline:
        return _buildInlineVariant(context, color);
      case ScoreDisplayVariant.scoreboard:
        return _buildScoreboardVariant(context, color);
    }
  }

  /// ① テーブル形式: 2段斜め配置（1本目左上、2本目右下、勝者丸）
  Widget _buildTableVariant(BuildContext context, Color color) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isWinner)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.6 : 0.4),
                  width: 1.5,
                ),
              ),
            ),
          if (points.isNotEmpty)
            Positioned(
              top: AppSpacing.xs,
              left: 6,
              child: KendoTechMarkBadge(
                point: points[0],
                color: color,
                isDark: isDark,
              ),
            ),
          if (points.length > 1)
            Positioned(
              bottom: AppSpacing.xs,
              right: 6,
              child: KendoTechMarkBadge(
                point: points[1],
                color: color,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }

  /// ② インライン形式: 横並び（チーム試合状況・タイムライン用）
  Widget _buildInlineVariant(BuildContext context, Color color) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: points.map((p) {
        return KendoTechMarkBadge(point: p, color: color, isDark: isDark);
      }).toList(),
    );
  }

  /// ③ 特大スコアボード形式: 入力盤・電光掲示板用
  Widget _buildScoreboardVariant(BuildContext context, Color color) {
    if (points.isEmpty) {
      return const SizedBox(width: 60, height: 60);
    }
    final p = points.first;
    return KendoTechMarkBadge(
      point: p,
      color: color,
      isDark: isDark,
      fontSize: AppFontSize.heroXxl,
      circleSize: 60.0,
    );
  }
}
