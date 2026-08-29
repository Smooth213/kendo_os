import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合結果・決着ステータス種別
enum KendoMatchResultType {
  /// 通常決着
  normal,

  /// 延長戦決着
  encho,

  /// 代表戦決着
  daihyosen,

  /// 不戦勝
  fusen,

  /// 引き分け
  draw,
}

/// 試合結果タグ共通コンポーネント
class KendoMatchResultTag extends StatelessWidget {
  final KendoMatchResultType type;
  final String? customLabel;

  const KendoMatchResultTag({super.key, required this.type, this.customLabel});

  /// 試合情報から自動判定して生成
  factory KendoMatchResultTag.fromMatch({
    required bool isDone,
    required int redScore,
    required int whiteScore,
    required String matchType,
    required String note,
  }) {
    if (!isDone) {
      return const KendoMatchResultTag(type: KendoMatchResultType.normal);
    }

    if (matchType.contains('代表') || note.contains('代表')) {
      return const KendoMatchResultTag(type: KendoMatchResultType.daihyosen);
    }

    if (note.contains('延長') || matchType.contains('延長')) {
      return const KendoMatchResultTag(type: KendoMatchResultType.encho);
    }

    if (note.contains('不戦') || matchType.contains('不戦')) {
      return const KendoMatchResultTag(type: KendoMatchResultType.fusen);
    }

    if (redScore == whiteScore) {
      return const KendoMatchResultTag(type: KendoMatchResultType.draw);
    }

    return const KendoMatchResultTag(type: KendoMatchResultType.normal);
  }

  @override
  Widget build(BuildContext context) {
    if (type == KendoMatchResultType.normal) {
      return const SizedBox.shrink();
    }

    String label = customLabel ?? '';
    Color color = AppKendoColors.grey;

    switch (type) {
      case KendoMatchResultType.encho:
        label = label.isEmpty ? '延長' : label;
        color = AppKendoColors.orange;
        break;
      case KendoMatchResultType.daihyosen:
        label = label.isEmpty ? '代表戦' : label;
        color = AppKendoColors.purple;
        break;
      case KendoMatchResultType.fusen:
        label = label.isEmpty ? '不戦勝' : label;
        color = AppKendoColors.blue;
        break;
      case KendoMatchResultType.draw:
        label = label.isEmpty ? '引き分け' : label;
        color = AppKendoColors.grey;
        break;
      case KendoMatchResultType.normal:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 1.0,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
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
