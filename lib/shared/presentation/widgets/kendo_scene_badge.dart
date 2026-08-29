import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合シーン種別
enum KendoMatchScene {
  /// 本戦 / 大会公式戦
  honsen,

  /// 錬成会
  renseikai,

  /// 申合せ試合
  moushiawase,

  /// 部内戦
  bunaiksen,
}

/// 試合シーン判定ヘルパー
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

  /// シーンに対応する日本語ラベル（例: '【錬成】'）を取得
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

  /// シーンの公式カラーを取得
  static Color getColor(KendoMatchScene scene) {
    switch (scene) {
      case KendoMatchScene.honsen:
        return AppKendoColors.indigo;
      case KendoMatchScene.renseikai:
        return AppKendoColors.teal;
      case KendoMatchScene.moushiawase:
        return AppKendoColors.orange;
      case KendoMatchScene.bunaiksen:
        return AppKendoColors.purple;
    }
  }
}

/// 試合シーン（本戦・錬成・申合せ・部内戦）共通バッジWidget
class KendoSceneBadge extends StatelessWidget {
  final KendoMatchScene scene;
  final bool isFilled;

  const KendoSceneBadge({
    super.key,
    required this.scene,
    this.isFilled = false,
  });

  /// 試合オブジェクトから自動判定してバッジを生成
  factory KendoSceneBadge.fromMatch(dynamic match, {bool isFilled = false}) {
    return KendoSceneBadge(
      scene: KendoSceneHelper.detectScene(match),
      isFilled: isFilled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = KendoSceneHelper.getColor(scene);
    final label = KendoSceneHelper.getLabel(scene);

    if (isFilled) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 1.0,
        ),
        decoration: BoxDecoration(color: color, borderRadius: AppRadius.micro),
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
        horizontal: AppSpacing.xs,
        vertical: 1.0,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.0),
        borderRadius: AppRadius.micro,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.micro,
          fontWeight: AppFontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
