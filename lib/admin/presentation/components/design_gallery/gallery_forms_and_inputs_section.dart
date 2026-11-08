import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 📝 デザインカタログ: 入力フォーム ＆ セレクター セクション
class GalleryFormsAndInputsSection extends StatelessWidget {
  const GalleryFormsAndInputsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '1. 単一行入力: iOS 27 カプセル型 (StadiumBorder)'),
        _buildSingleLineInputCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '2. 複数行入力: Squircle 16px角丸 (文字欠け防止黄金比)'),
        _buildMultilineInputCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '3. 入力状態のバリエーション (States)'),
        _buildInputStatesCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '4. オーダー配置・選手セレクタースロット (Slot Spec)'),
        _buildOrderSlotsSampleCard(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
        top: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.small,
          fontWeight: AppFontWeight.bold,
          color: context.appColors.subTextColor,
        ),
      ),
    );
  }

  /// 単一行カプセル入力
  Widget _buildSingleLineInputCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: context.appColors.inputBackground,
              borderRadius: AppRadius.capsule,
              border: Border.all(
                color: context.appColors.separatorColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: context.appColors.subTextColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '選手名・所属・大会名で検索...',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      color: context.appColors.hintColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.cancel_rounded,
                  size: 16,
                  color: context.appColors.subTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '単一行入力・検索バーはすべて AppRadius.full (カプセル型) で統一',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: context.appColors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 複数行Squircle入力
  Widget _buildMultilineInputCard(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.appColors.inputBackground,
              borderRadius: AppRadius.large,
              border: Border.all(
                color: context.appColors.separatorColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '大会特記事項・審判長注意・クイックメモなど...',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    color: context.appColors.hintColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '0 / 200 文字',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '複数行入力は文字欠けや視覚圧迫を防ぐため Squircle 16px (AppRadius.large) を採用',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: context.appColors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 入力状態のバリエーション
  Widget _buildInputStatesCard(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          // フォーカス状態
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.inputBackground,
                    borderRadius: AppRadius.capsule,
                    border: Border.all(
                      color: context.appColors.primaryAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'フォーカス中 (ハイライト枠)',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.semiBold,
                      color: context.appColors.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // エラー状態
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.inputBackground,
                    borderRadius: AppRadius.capsule,
                    border: Border.all(
                      color: context.appColors.errorColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: context.appColors.errorColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '必須項目が未入力です (エラー枠)',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            color: context.appColors.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // 読み取り専用 / 無効
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.cardBackground,
                    borderRadius: AppRadius.capsule,
                    border: Border.all(
                      color: context.appColors.separatorColor.withValues(
                        alpha: 0.5,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '読み取り専用 (変更不可)',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: context.appColors.disabledTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// オーダー配置スロット
  Widget _buildOrderSlotsSampleCard(BuildContext context) {
    final positions = ['先鋒', '次鋒', '中堅', '副将', '大将'];

    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: positions.map((pos) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.inputBackground,
                  borderRadius: AppRadius.capsule,
                  border: Border.all(
                    color: context.appColors.primaryAccent.withValues(
                      alpha: 0.4,
                    ),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.primaryAccent,
                        borderRadius: AppRadius.capsule,
                      ),
                      child: Text(
                        pos,
                        style: TextStyle(
                          fontSize: AppFontSize.micro,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.onPrimaryAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '未登録',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: context.appColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'オーダー表・メンバー編成スロットはカプセル型スロットで統一',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: context.appColors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
