import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 🏆 5大分類 ＋ サブ詳細展開（剣道形の本数分岐対応）の共通試合形式セレクタ
class MatchFormatSelectorView extends StatelessWidget {
  final String currentMatchType;
  final AppThemeColors themeColors;
  final ValueChanged<String> onMatchTypeChanged;

  static const List<String> primaryFormats = [
    '団体戦',
    '個人戦',
    'リーグ戦',
    '勝ち抜き戦',
    '剣道形',
  ];

  static const List<String> kataTypes = ['日本剣道形', '木刀による剣道基本技稽古法'];

  const MatchFormatSelectorView({
    super.key,
    required this.currentMatchType,
    required this.themeColors,
    required this.onMatchTypeChanged,
  });

  /// 試合形式文字列から現在の第1階層を判別
  static String resolvePrimaryFormat(String matchType) {
    if (matchType.contains('勝ち抜き')) return '勝ち抜き戦';
    if (matchType.contains('リーグ')) return 'リーグ戦';
    if (matchType == '個人戦') return '個人戦';
    if (matchType.contains('形') || matchType.contains('稽古法')) return '剣道形';
    return '団体戦';
  }

  /// 剣道形における種別（第2階層）を判別
  static String resolveKataType(String matchType) {
    if (matchType.contains('基本技') ||
        matchType.contains('基本形') ||
        matchType.contains('木刀')) {
      return '木刀による剣道基本技稽古法';
    }
    return '日本剣道形';
  }

  void _onPrimarySelected(String primary) {
    switch (primary) {
      case '個人戦':
        onMatchTypeChanged('個人戦');
        break;
      case '団体戦':
        onMatchTypeChanged('団体戦（5人制）');
        break;
      case '勝ち抜き戦':
        onMatchTypeChanged('勝ち抜き戦（5人制）');
        break;
      case 'リーグ戦':
        onMatchTypeChanged('リーグ団体戦');
        break;
      case '剣道形':
        onMatchTypeChanged('日本剣道形（太刀の形3本）');
        break;
      default:
        onMatchTypeChanged(primary);
    }
  }

  List<({String label, String value})> _getSubOptions(String primary) {
    switch (primary) {
      case '団体戦':
        return [
          (label: '3人制', value: '団体戦（3人制）'),
          (label: '5人制', value: '団体戦（5人制）'),
          (label: '7人制', value: '団体戦（7人制）'),
          (label: 'それ以上', value: '団体戦（それ以上）'),
        ];
      case '勝ち抜き戦':
        return [
          (label: '3人制', value: '勝ち抜き戦（3人制）'),
          (label: '5人制', value: '勝ち抜き戦（5人制）'),
          (label: '7人制', value: '勝ち抜き戦（7人制）'),
          (label: 'それ以上', value: '勝ち抜き戦（それ以上）'),
        ];
      case 'リーグ戦':
        return [
          (label: '団体戦 (5人制)', value: 'リーグ団体戦'),
          (label: '個人戦', value: 'リーグ個人戦'),
          (label: '団体 (3人制)', value: 'リーグ団体戦（3人制）'),
          (label: '団体 (7人制)', value: 'リーグ団体戦（7人制）'),
        ];
      default:
        return [];
    }
  }

  List<({String label, String value})> _getKataDetailOptions(String kataType) {
    if (kataType == '木刀による剣道基本技稽古法') {
      return [
        (label: '基本技（5本）', value: '木刀による剣道基本技稽古法（5本）'),
        (label: '基本技（9本）', value: '木刀による剣道基本技稽古法（9本）'),
      ];
    }
    return [
      (label: '太刀の形（3本）', value: '日本剣道形（太刀の形3本）'),
      (label: '太刀の形（5本）', value: '日本剣道形（太刀の形5本）'),
      (label: '太刀の形（7本）', value: '日本剣道形（太刀の形7本）'),
      (label: '太刀＋小太刀（10本）', value: '日本剣道形（太刀＋小太刀10本）'),
    ];
  }

  bool _isKataOptionSelected(String optValue) {
    if (currentMatchType == optValue) return true;
    // 旧データとの後方互換判定
    if (optValue == '日本剣道形（太刀の形3本）' &&
        (currentMatchType == '剣道形' || currentMatchType == '剣道形（日本剣道形）')) {
      return true;
    }
    if (optValue == '木刀による剣道基本技稽古法（5本）' && currentMatchType == '剣道形（基本形）') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = themeColors.primaryAccent;
    final primary = resolvePrimaryFormat(currentMatchType);
    final subOptions = _getSubOptions(primary);
    final isKata = primary == '剣道形';
    final currentKataType = resolveKataType(currentMatchType);
    final kataDetailOptions = _getKataDetailOptions(currentKataType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 5大分類チップ
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: primaryFormats.map((fmt) {
            final isSel = primary == fmt;
            return AppChoiceChip(
              label: Text(fmt),
              selected: isSel,
              selectedColor: accentColor.withValues(alpha: 0.2),
              onSelected: (s) {
                if (s) _onPrimarySelected(fmt);
              },
            );
          }).toList(),
        ),

        // 2. 剣道形専用の2段階サブ詳細コンテナ
        if (isKata) ...[
          const SizedBox(height: AppSpacing.md),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: themeColors.softAccent.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2-A: 形種別選択
                Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '「剣道形」の種別を選択：',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: kataTypes.map((kt) {
                    final isSel = currentKataType == kt;
                    return AppChoiceChip(
                      label: Text(kt),
                      selected: isSel,
                      selectedColor: accentColor.withValues(alpha: 0.25),
                      onSelected: (s) {
                        if (s) {
                          if (kt == '木刀による剣道基本技稽古法') {
                            onMatchTypeChanged('木刀による剣道基本技稽古法（5本）');
                          } else {
                            onMatchTypeChanged('日本剣道形（太刀の形3本）');
                          }
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                // 2-B: 本数・詳細選択
                Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '「$currentKataType」の本数を選択：',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: kataDetailOptions.map((opt) {
                    final isSel = _isKataOptionSelected(opt.value);
                    return AppChoiceChip(
                      label: Text(opt.label),
                      selected: isSel,
                      selectedColor: accentColor.withValues(alpha: 0.25),
                      onSelected: (s) {
                        if (s) onMatchTypeChanged(opt.value);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ] else if (subOptions.isNotEmpty) ...[
          // 3. 団体戦・リーグ戦・勝ち抜き戦のサブ詳細コンテナ
          const SizedBox(height: AppSpacing.md),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: themeColors.softAccent.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '「$primary」の詳細人数・ルール区分を選択：',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: subOptions.map((opt) {
                    final isSel = currentMatchType == opt.value;
                    return AppChoiceChip(
                      label: Text(opt.label),
                      selected: isSel,
                      selectedColor: accentColor.withValues(alpha: 0.25),
                      onSelected: (s) {
                        if (s) onMatchTypeChanged(opt.value);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
