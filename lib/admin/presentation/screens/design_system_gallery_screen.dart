import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/presentation/components/design_gallery/gallery_buttons_and_actions_section.dart';
import 'package:kendo_os/admin/presentation/components/design_gallery/gallery_dock_and_overlays_section.dart';
import 'package:kendo_os/admin/presentation/components/design_gallery/gallery_forms_and_inputs_section.dart';
import 'package:kendo_os/admin/presentation/components/design_gallery/gallery_kendo_domain_section.dart';
import 'package:kendo_os/admin/presentation/components/design_gallery/gallery_palette_typography_section.dart';
import 'package:kendo_os/admin/presentation/components/design_gallery/gallery_scene_and_status_section.dart';
import 'package:kendo_os/admin/presentation/components/design_gallery/gallery_textures_and_springs_section.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

/// 🎨 Kendo Sync 全網羅デザインカタログ画面（Design System Master Gallery）
/// 全コンポーネント（競技ドメイン、シーンバッジ、ボタン、フォーム、ドック、カラー、ガラス）を
/// カテゴリ別タブで一望・検証できるマスタースクリーン
class DesignSystemGalleryScreen extends ConsumerStatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  ConsumerState<DesignSystemGalleryScreen> createState() =>
      _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState
    extends ConsumerState<DesignSystemGalleryScreen> {
  int _selectedTabIndex = 0;

  static const List<({String label, IconData icon})> _tabs = [
    (label: '基盤・ガラス', icon: Icons.auto_awesome),
    (label: '競技・スコア', icon: Icons.sports_kabaddi),
    (label: 'シーン・状態', icon: Icons.label_important_outline),
    (label: 'ボタン', icon: Icons.touch_app_outlined),
    (label: '入力フォーム', icon: Icons.edit_note_rounded),
    (label: 'ドック・シート', icon: Icons.layers_outlined),
    (label: 'カラー・文字', icon: Icons.palette_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: const AppHeader(title: 'デザインシステム・ギャラリー'),
        body: Column(
          children: [
            _buildTabSelector(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  _buildTabContent(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 上部タブセレクター（iOS 27 カプセル型ピルチップ水平スクロール）
  Widget _buildTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: AppChoiceChip(
              icon: tab.icon,
              label: Text(tab.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  AppHaptics.selection();
                  setState(() => _selectedTabIndex = index);
                }
              },
            ),
          );
        }),
      ),
    );
  }

  /// 選択されたタブのコンテンツ
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const GalleryTexturesAndSpringsSection();
      case 1:
        return const GalleryKendoDomainSection();
      case 2:
        return const GallerySceneAndStatusSection();
      case 3:
        return const GalleryButtonsAndActionsSection();
      case 4:
        return const GalleryFormsAndInputsSection();
      case 5:
        return const GalleryDockAndOverlaysSection();
      case 6:
        return const GalleryPaletteTypographySection();
      default:
        return const GalleryTexturesAndSpringsSection();
    }
  }
}
