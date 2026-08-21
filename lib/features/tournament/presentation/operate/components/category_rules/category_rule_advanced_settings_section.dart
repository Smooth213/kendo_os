import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 詳細設定（得点制限・反則ルール）＆ 上位戦キーワード設定セクション
class CategoryRuleAdvancedSettingsSection extends StatelessWidget {
  final bool isNormal;
  final String categoryKey;
  final int ipponLimit;
  final int hansokuLimit;
  final TextEditingController? keywordsController;
  final ValueChanged<int> onIpponLimitChanged;
  final ValueChanged<int> onHansokuLimitChanged;
  final ValueChanged<List<String>> onKeywordsChanged;

  const CategoryRuleAdvancedSettingsSection({
    super.key,
    required this.isNormal,
    required this.categoryKey,
    required this.ipponLimit,
    required this.hansokuLimit,
    this.keywordsController,
    required this.onIpponLimitChanged,
    required this.onHansokuLimitChanged,
    required this.onKeywordsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Theme(
          data: Theme.of(
            context,
          ).copyWith(dividerColor: AppKendoColors.transparent),
          child: ExpansionTile(
            title: const Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: AppKendoColors.grey,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '詳細設定（得点制限・反則ルール）',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.body,
                    color: AppKendoColors.grey,
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0x33000000),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 勝敗本数制限
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '勝敗本数制限（得点制限）',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.bodySmall,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '勝敗に必要な本数（通常は三本勝負＝2本先取）',
                                style: TextStyle(
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                              ),
                              onPressed: ipponLimit > 1
                                  ? () => onIpponLimitChanged(ipponLimit - 1)
                                  : null,
                            ),
                            Text(
                              '$ipponLimit本',
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.body,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              onPressed: ipponLimit < 5
                                  ? () => onIpponLimitChanged(ipponLimit + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // 反則制限
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '反則制限本数（ペナルティ）',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.bodySmall,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '相手に一本を与える反則の数（公式は反則2回）',
                                style: TextStyle(
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                              ),
                              onPressed: hansokuLimit > 1
                                  ? () =>
                                        onHansokuLimitChanged(hansokuLimit - 1)
                                  : null,
                            ),
                            Text(
                              '$hansokuLimit回',
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.body,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              onPressed: hansokuLimit < 5
                                  ? () =>
                                        onHansokuLimitChanged(hansokuLimit + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isNormal && keywordsController != null) ...[
          const Divider(height: 32),
          const Text(
            '自動判別用キーワード設定',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.body,
              color: AppKendoColors.indigo,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '試合詳細メモに入力された文字と部分一致した場合に、この上位戦ルールを自動適用します。',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: AppKendoColors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: ValueKey('advanced_keywords_field_$categoryKey'),
            controller: keywordsController,
            decoration: const InputDecoration(
              labelText: '自動判定キーワード（カンマ「,」区切り）',
              hintText: '例: 準決勝, 決勝, 3位決定',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(AppSpacing.md),
            ),
            onChanged: (val) {
              final kwList = val
                  .split(',')
                  .map((kw) => kw.trim())
                  .where((kw) => kw.isNotEmpty)
                  .toList();
              onKeywordsChanged(kwList);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppActionChip(
                label: const Text('準決勝以上'),
                onPressed: () {
                  final kws = [
                    '準決勝',
                    '準決',
                    'ベスト4',
                    '決勝',
                    'final',
                    '3位決定',
                    '3決',
                  ];
                  keywordsController!.text = kws.join(', ');
                  onKeywordsChanged(kws);
                },
              ),
              AppActionChip(
                label: const Text('決勝のみ'),
                onPressed: () {
                  final kws = ['決勝', 'final'];
                  keywordsController!.text = kws.join(', ');
                  onKeywordsChanged(kws);
                },
              ),
              AppActionChip(
                label: const Text('3回戦以上'),
                onPressed: () {
                  final kws = [
                    '3回戦',
                    '３回戦',
                    '三回戦',
                    '4回戦',
                    '４回戦',
                    '四回戦',
                    '準決勝',
                    '準決',
                    '決勝',
                    'final',
                  ];
                  keywordsController!.text = kws.join(', ');
                  onKeywordsChanged(kws);
                },
              ),
              AppActionChip(
                label: const Text('クリア'),
                onPressed: () {
                  keywordsController!.text = '';
                  onKeywordsChanged([]);
                },
              ),
            ],
          ),
        ],
        const Divider(height: 32),
      ],
    );
  }
}
