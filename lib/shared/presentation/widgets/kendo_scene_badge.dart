import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合シーン種別
enum KendoMatchScene {
  /// 本戦 / 大会公式戦
  honsen,

  /// 錬成（練習試合・錬成会）
  renseikai,

  /// 申合せ（練習試合・特別対戦）
  moushiawase,

  /// 部内戦
  bunaiksen,
}

/// 試合シーンのデザインスタイル情報
class KendoSceneStyle {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const KendoSceneStyle({
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}

/// 試合シーン判定 ＆ 統一スタイル・ラベル提供ヘルパー（Single Source of Truth）
class KendoSceneHelper {
  KendoSceneHelper._();

  /// 汎用試合オブジェクト・ルールから試合シーンを決定論的に判定
  static KendoMatchScene detectScene(dynamic match) {
    if (match == null) return KendoMatchScene.honsen;

    String scene = '';
    String ruleScene = '';
    bool ruleIsRenseikai = false;
    String matchType = '';
    String note = '';
    String? category;

    try {
      scene = (match.matchScene ?? '').toString();
    } catch (_) {}
    try {
      ruleScene = (match.rule?.matchScene ?? '').toString();
    } catch (_) {}
    try {
      ruleIsRenseikai = match.rule?.isRenseikai ?? false;
    } catch (_) {}
    try {
      matchType = (match.matchType ?? '').toString();
    } catch (_) {}
    try {
      note = (match.note ?? '').toString();
    } catch (_) {}
    try {
      category = match.category?.toString();
    } catch (_) {}

    if (scene == 'bunaiksen' ||
        ruleScene == 'bunaiksen' ||
        matchType.contains('部内戦') ||
        note.contains('部内戦') ||
        (category != null && category.contains('部内戦'))) {
      return KendoMatchScene.bunaiksen;
    }

    if (scene == 'moushiawase' ||
        ruleScene == 'moushiawase' ||
        matchType.contains('申し合わせ') ||
        matchType.contains('申合せ') ||
        note.contains('申し合わせ') ||
        note.contains('申合せ') ||
        (category != null &&
            (category.contains('申し合わせ') || category.contains('申合せ')))) {
      return KendoMatchScene.moushiawase;
    }

    if (scene == 'renseikai' ||
        ruleScene == 'renseikai' ||
        ruleIsRenseikai ||
        matchType.contains('錬成') ||
        note.contains('錬成') ||
        (category != null && category.contains('錬成'))) {
      return KendoMatchScene.renseikai;
    }

    return KendoMatchScene.honsen;
  }

  /// シーンに対応する日本語公式ラベル（例: '【錬成】'）を取得
  static String getLabel(KendoMatchScene scene) {
    switch (scene) {
      case KendoMatchScene.honsen:
        return '【本戦】';
      case KendoMatchScene.renseikai:
        return '【錬成】';
      case KendoMatchScene.moushiawase:
        return '【申合せ】';
      case KendoMatchScene.bunaiksen:
        return '【部内戦】';
    }
  }

  /// シーンに対応する絵文字付き公式ラベル（例: '⚔️ 錬成'）を取得
  static String getIconLabel(KendoMatchScene scene) {
    switch (scene) {
      case KendoMatchScene.honsen:
        return '🏆 本戦';
      case KendoMatchScene.renseikai:
        return '⚔️ 錬成';
      case KendoMatchScene.moushiawase:
        return '🤝 申合せ';
      case KendoMatchScene.bunaiksen:
        return '🛡️ 部内戦';
    }
  }

  /// シーンの公式メインカラーを取得（白飛び完全解消 ＆ コントラスト最適化）
  static Color getColor(KendoMatchScene scene, {bool isDark = false}) {
    switch (scene) {
      case KendoMatchScene.honsen:
        // ロイヤルインディゴ（濃紺・青）
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
      case KendoMatchScene.renseikai:
        // ディープオレンジ（濃橙・白飛びゼロ）
        return isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
      case KendoMatchScene.moushiawase:
        // ディープローズ（濃紅・白飛びゼロ）
        return isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D);
      case KendoMatchScene.bunaiksen:
        // ディープパープル（濃紫）
        return isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE);
    }
  }

  /// シーンのバッジスタイル（背景・枠線・文字色）を取得
  static KendoSceneStyle getStyle(
    KendoMatchScene scene, {
    bool isDark = false,
  }) {
    final color = getColor(scene, isDark: isDark);
    return KendoSceneStyle(
      textColor: color,
      backgroundColor: color.withValues(alpha: isDark ? 0.2 : 0.1),
      borderColor: color.withValues(alpha: isDark ? 0.45 : 0.35),
    );
  }
}

/// 試合シーン（本戦・錬成・申合せ・部内戦）共通バッジWidget
class KendoSceneBadge extends StatelessWidget {
  final KendoMatchScene scene;
  final bool isFilled;
  final bool isDark;

  const KendoSceneBadge({
    super.key,
    required this.scene,
    this.isFilled = false,
    this.isDark = false,
  });

  /// 試合オブジェクトから自動判定してバッジを生成
  factory KendoSceneBadge.fromMatch(
    dynamic match, {
    bool isFilled = false,
    bool isDark = false,
  }) {
    return KendoSceneBadge(
      scene: KendoSceneHelper.detectScene(match),
      isFilled: isFilled,
      isDark: isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDark =
        isDark || Theme.of(context).brightness == Brightness.dark;
    final style = KendoSceneHelper.getStyle(scene, isDark: effectiveDark);
    final label = KendoSceneHelper.getLabel(scene);

    if (isFilled) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 1.0,
        ),
        decoration: BoxDecoration(
          color: style.textColor,
          borderRadius: AppRadius.micro,
        ),
        child: Text(
          label.replaceAll('【', '').replaceAll('】', ''),
          style: const TextStyle(
            fontSize: AppFontSize.micro,
            fontWeight: AppFontWeight.bold,
            color: AppKendoColors.pureWhite,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.subValue,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: Border.all(color: style.borderColor, width: 1.0),
        borderRadius: AppRadius.sub,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.nano,
          fontWeight: AppFontWeight.bold,
          color: style.textColor,
        ),
      ),
    );
  }
}
