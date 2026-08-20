import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 一括ルール変更: STEP 2 詳細ルール設定カード群
class BulkRuleDetailSettingCards extends StatelessWidget {
  final double matchTime;
  final bool isIpponShobu;
  final bool hasExtension;
  final double enchoTime;
  final int enchoCount;
  final bool isEnchoUnlimited;
  final bool hasHantei;
  final bool hasRepresentativeMatch;
  final bool isDaihyoIpponShobu;
  final bool isRenseikai;
  final String renseikaiType;
  final TextEditingController overallTimeController;
  final Color primaryAccent;
  final bool isDark;

  final ValueChanged<double> onMatchTimeChanged;
  final ValueChanged<bool> onIpponShobuChanged;
  final ValueChanged<bool> onExtensionChanged;
  final ValueChanged<double> onEnchoTimeChanged;
  final ValueChanged<int> onEnchoCountChanged;
  final ValueChanged<bool> onEnchoUnlimitedChanged;
  final ValueChanged<bool> onHanteiChanged;
  final ValueChanged<bool> onRepresentativeMatchChanged;
  final ValueChanged<bool> onDaihyoIpponShobuChanged;
  final ValueChanged<bool> onRenseikaiChanged;
  final ValueChanged<String> onRenseikaiTypeChanged;

  const BulkRuleDetailSettingCards({
    super.key,
    required this.matchTime,
    required this.isIpponShobu,
    required this.hasExtension,
    required this.enchoTime,
    required this.enchoCount,
    required this.isEnchoUnlimited,
    required this.hasHantei,
    required this.hasRepresentativeMatch,
    required this.isDaihyoIpponShobu,
    required this.isRenseikai,
    required this.renseikaiType,
    required this.overallTimeController,
    required this.primaryAccent,
    required this.isDark,
    required this.onMatchTimeChanged,
    required this.onIpponShobuChanged,
    required this.onExtensionChanged,
    required this.onEnchoTimeChanged,
    required this.onEnchoCountChanged,
    required this.onEnchoUnlimitedChanged,
    required this.onHanteiChanged,
    required this.onRepresentativeMatchChanged,
    required this.onDaihyoIpponShobuChanged,
    required this.onRenseikaiChanged,
    required this.onRenseikaiTypeChanged,
  });

  Widget _buildCardGroup({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppRadius.large,
        border: Border.all(color: context.appColors.separatorColor),
      ),
      child: Material(
        color: isDark
            ? context.appColors.textColor.withAlpha(128)
            : context.appColors.cardBackground,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    final textColor = context.appColors.textColor;
    final resolvedItems = items.contains(value) ? items : [value, ...items];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: AppFontSize.body)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2E)
                : context.appColors.cardBackground,
            borderRadius: AppRadius.medium,
          ),
          child: DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            style: TextStyle(color: textColor, fontSize: AppFontSize.body),
            onChanged: onChanged,
            items: resolvedItems.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder(item)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基本ルールカード
        _buildCardGroup(
          context: context,
          title: '⏱️ 基本ルール',
          children: [
            _buildDropdownRow<double>(
              context: context,
              label: '試合時間',
              value: matchTime,
              items: const [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0],
              labelBuilder: (v) => '${v == v.toInt() ? v.toInt() : v}分',
              onChanged: (v) {
                if (v != null) onMatchTimeChanged(v);
              },
            ),
            const Divider(height: 20),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '一本勝負形式にする',
                style: TextStyle(fontSize: AppFontSize.body),
              ),
              subtitle: const Text(
                '先に1本取った側を勝者とします',
                style: TextStyle(fontSize: AppFontSize.caption),
              ),
              value: isIpponShobu,
              activeTrackColor: primaryAccent,
              onChanged: onIpponShobuChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 延長ルールカード
        _buildCardGroup(
          context: context,
          title: '🔄 延長ルール（本戦・通常試合）',
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '通常試合の延長戦を行う',
                style: TextStyle(fontSize: AppFontSize.body),
              ),
              value: hasExtension,
              activeTrackColor: primaryAccent,
              onChanged: onExtensionChanged,
            ),
            if (hasExtension) ...[
              const Divider(height: 20),
              _buildDropdownRow<double>(
                context: context,
                label: '延長時間',
                value: enchoTime,
                items: const [1.0, 1.5, 2.0, 3.0],
                labelBuilder: (v) => '${v == v.toInt() ? v.toInt() : v}分',
                onChanged: (v) {
                  if (v != null) onEnchoTimeChanged(v);
                },
              ),
              const Divider(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '延長回数を無制限（決着まで）にする',
                  style: TextStyle(fontSize: AppFontSize.body),
                ),
                value: isEnchoUnlimited,
                activeTrackColor: primaryAccent,
                onChanged: onEnchoUnlimitedChanged,
              ),
              if (!isEnchoUnlimited) ...[
                const Divider(height: 20),
                _buildDropdownRow<int>(
                  context: context,
                  label: '最大延長回数',
                  value: enchoCount,
                  items: const [1, 2, 3, 5],
                  labelBuilder: (v) => '$v回',
                  onChanged: (v) {
                    if (v != null) onEnchoCountChanged(v);
                  },
                ),
              ],
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 個人戦：判定ルール
        _buildCardGroup(
          context: context,
          title: '⚖️ 個人戦ルール',
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '判定（ハンテイ）の適用',
                style: TextStyle(fontSize: AppFontSize.body),
              ),
              subtitle: const Text(
                '延長時間終了時、または引き分け時に判定を行います',
                style: TextStyle(fontSize: AppFontSize.caption),
              ),
              value: hasHantei,
              activeTrackColor: primaryAccent,
              onChanged: onHanteiChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 団体戦：代表戦ルール
        _buildCardGroup(
          context: context,
          title: '⚔️ 団体戦・代表戦ルール',
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '代表戦の適用',
                style: TextStyle(fontSize: AppFontSize.body),
              ),
              subtitle: const Text(
                'チーム引き分け時の決定戦を有効にします',
                style: TextStyle(fontSize: AppFontSize.caption),
              ),
              value: hasRepresentativeMatch,
              activeTrackColor: primaryAccent,
              onChanged: onRepresentativeMatchChanged,
            ),
            if (hasRepresentativeMatch) ...[
              const Divider(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '代表戦は一本勝負',
                  style: TextStyle(fontSize: AppFontSize.body),
                ),
                value: isDaihyoIpponShobu,
                activeTrackColor: primaryAccent,
                onChanged: onDaihyoIpponShobuChanged,
              ),
              const Divider(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppKendoColors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '代表戦の延長戦は、自動的に「時間無制限・一本勝負（サドンデス）」として行われます。',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: isDark
                              ? const Color(0xFF2196F3)
                              : const Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 錬成会ルール
        _buildCardGroup(
          context: context,
          title: '🏆 錬成会（練習マッチ）設定',
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '錬成会モードを有効化',
                style: TextStyle(fontSize: AppFontSize.body),
              ),
              value: isRenseikai,
              activeTrackColor: primaryAccent,
              onChanged: onRenseikaiChanged,
            ),
            if (isRenseikai) ...[
              const Divider(height: 20),
              _buildDropdownRow<String>(
                context: context,
                label: '試合方式',
                value: renseikaiType,
                items: const ['一試合制', '複数試合制', '時間制'],
                labelBuilder: (v) => v,
                onChanged: (v) {
                  if (v != null) onRenseikaiTypeChanged(v);
                },
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '総試合時間（分）',
                    style: TextStyle(fontSize: AppFontSize.body),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppTextField(
                      controller: overallTimeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        suffixText: '分',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
