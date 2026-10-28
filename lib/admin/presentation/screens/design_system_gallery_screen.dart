import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

/// 🎨 次世代着せ替え基盤: デザインシステム・ギャラリー確認画面
/// 全コンポーネント（フロストガラス、カード、ボタン、シート、ダイアログ等）の質感や
/// Liquid Glass ON/OFF、ダーク/ライトの連動を一望・検証できるプレビュー画面
class DesignSystemGalleryScreen extends ConsumerStatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  ConsumerState<DesignSystemGalleryScreen> createState() =>
      _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState
    extends ConsumerState<DesignSystemGalleryScreen> {
  int _selectedChipIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: const AppHeader(title: 'デザインシステム・ギャラリー'),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            _buildSectionHeader('1. 着せ替え基盤・モード制御'),
            _buildGlassControlCard(settings.enableLiquidGlass),
            const SizedBox(height: AppSpacing.md),
            _buildSectionHeader('2. iOS 27 フロストガラス (AppGlassContainer)'),
            _buildGlassPreviewCard(isDark),
            const SizedBox(height: AppSpacing.md),
            _buildSectionHeader('3. 物理スプリングカード (AppCard)'),
            _buildSpringCardsSection(),
            const SizedBox(height: AppSpacing.md),
            _buildSectionHeader('4. iOS 27 ピルチップ ＆ スイッチ'),
            _buildChipsAndSwitchesSection(),
            const SizedBox(height: AppSpacing.md),
            _buildSectionHeader('5. ダイアログ ＆ シート ＆ 通知バナー'),
            _buildOverlaysSection(context),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildGlassControlCard(bool enableLiquidGlass) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: context.appColors.primaryAccent,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liquid Glass (フロストガラス)',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
                Text(
                  enableLiquidGlass
                      ? 'ON: 薄層ブラー ＋ 0.5pxヘアライン境界'
                      : 'OFF: ソリッド高コントラスト（省電力・屋外モード）',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                  ),
                ),
              ],
            ),
          ),
          AppSwitch(
            value: enableLiquidGlass,
            onChanged: (val) {
              AppHaptics.selection();
              ref
                  .read(settingsProvider.notifier)
                  .updateSettings(
                    ref.read(settingsProvider).copyWith(enableLiquidGlass: val),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPreviewCard(bool isDark) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.appColors.successColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '0.5px Hairline Squircle Border',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.semiBold,
                  color: context.appColors.textColor,
                ),
              ),
              const Spacer(),
              const AppLoadingIndicator.small(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'RepaintBoundaryで高頻度再描画から完全保護された次世代ガラスコンテナ。背面の液状グラデーションやスクロールコンテンツを美しく透過・拡散します。',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: context.appColors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpringCardsSection() {
    return Column(
      children: [
        AppCard(
          onTap: () {
            AppHaptics.light();
            AppSnackBar.showSuccess(context, '0.98倍スプリングバウンス ＆ Light触覚が発火しました');
          },
          child: Row(
            children: [
              Icon(Icons.touch_app, color: context.appColors.primaryAccent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'タップしてスプリング体験 (AppCard)',
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    Text(
                      '指を触れると0.98倍に縮小し、離すと物理スプリングで復元',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: context.appColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: context.appColors.subTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipsAndSwitchesSection() {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: List.generate(4, (index) {
          final labels = ['全コート', '第1試合場', '第2試合場', '部内戦'];
          return AppChoiceChip(
            label: Text(labels[index]),
            selected: _selectedChipIndex == index,
            onSelected: (selected) {
              if (selected) {
                AppHaptics.selection();
                setState(() => _selectedChipIndex = index);
              }
            },
          );
        }),
      ),
    );
  }

  Widget _buildOverlaysSection(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.light();
                    showAppBottomSheet(
                      context: context,
                      builder: (sheetContext) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'iOS 27 ボトムシート',
                                style: TextStyle(
                                  fontSize: AppFontSize.body,
                                  fontWeight: AppFontWeight.bold,
                                  color: context.appColors.textColor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '36x5px カプセルグラブバー ＆ Squircle 連続角丸 ＆ ヘアライン境界',
                                style: TextStyle(
                                  fontSize: AppFontSize.small,
                                  color: context.appColors.subTextColor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('ボトムシート'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.light();
                    showAppDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AppDialog(
                          title: 'iOS 27 ダイアログ',
                          content: const Text(
                            '0.5pxヘアライン境界とSquircle角丸で統一されたダイアログです。',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('閉じる'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('ダイアログ'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.success();
                    AppSnackBar.showSuccess(context, '操作が正常に完了しました');
                  },
                  child: const Text('成功トースト'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.error();
                    AppSnackBar.showError(context, '通信エラーが発生しました');
                  },
                  child: const Text('エラートースト'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
