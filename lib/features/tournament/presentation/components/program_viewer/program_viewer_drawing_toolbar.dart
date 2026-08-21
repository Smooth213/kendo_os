import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_controls.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 🏆 プログラムビューア: 2段目描画ツールバー（ペン・マーカー・消しゴム・アンドゥ・全消去）
class ProgramViewerDrawingToolbar extends StatelessWidget {
  static const Color yellowPenColor = Color(0xFFCA8A04);

  final String selectedTool;
  final Color activePenColor;
  final bool activeIsShared;
  final bool canUseSharedPen;
  final bool isDark;
  final ValueChanged<String> onSelectTool;
  final ValueChanged<Color> onSelectPenColor;
  final VoidCallback onUndo;
  final VoidCallback onClearAll;

  const ProgramViewerDrawingToolbar({
    super.key,
    required this.selectedTool,
    required this.activePenColor,
    required this.activeIsShared,
    required this.canUseSharedPen,
    required this.isDark,
    required this.onSelectTool,
    required this.onSelectPenColor,
    required this.onUndo,
    required this.onClearAll,
  });

  static String getPenName(Color color) {
    if (color == AppKendoColors.pink) {
      return 'ピンク';
    }
    if (color == yellowPenColor || color == AppKendoColors.yellow) {
      return 'イエロー';
    }
    if (color == AppKendoColors.blue) {
      return 'ブルー';
    }
    if (color == AppKendoColors.pureBlack) {
      return 'ブラック';
    }
    return 'ペン';
  }

  void _showPenPicker(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.roundValue,
              left: AppSpacing.roundValue,
              right: AppSpacing.roundValue,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ペンの選択',
                    style: TextStyle(
                      fontSize: AppFontSize.headline,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (canUseSharedPen) ...[
                    const Text(
                      '📢 共有ペン (全員の画面に反映されます)',
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        color: AppKendoColors.pureBlack,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ProgramViewerPenOption(
                          color: AppKendoColors.pink,
                          label: 'ピンク (共有)',
                          isSelected: activePenColor == AppKendoColors.pink,
                          onTap: () {
                            onSelectPenColor(AppKendoColors.pink);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 10),
                        ProgramViewerPenOption(
                          color: yellowPenColor,
                          label: 'イエロー (共有)',
                          isSelected: activePenColor == yellowPenColor,
                          onTap: () {
                            onSelectPenColor(yellowPenColor);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                  ],
                  const Text(
                    '📝 個人ペン (自分だけのメモです)',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: AppKendoColors.pureBlack,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ProgramViewerPenOption(
                        color: AppKendoColors.blue,
                        label: 'ブルー (個人)',
                        isSelected: activePenColor == AppKendoColors.blue,
                        onTap: () {
                          onSelectPenColor(AppKendoColors.blue);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 10),
                      ProgramViewerPenOption(
                        color: AppKendoColors.pureBlack,
                        label: 'ブラック (個人)',
                        isSelected: activePenColor == AppKendoColors.pureBlack,
                        onTap: () {
                          onSelectPenColor(AppKendoColors.pureBlack);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: AppKendoColors.pureBlack.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🎨 1. 【描画グループ】(ペン選択 + ペン + マーカー)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF424242)
                    : const Color(0xFFF5F5F5),
                borderRadius: AppRadius.small,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              child: Row(
                children: [
                  // ペン選択ボタン
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (selectedTool == 'eraser') {
                          onSelectTool('pen');
                        }
                        _showPenPicker(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: activePenColor.withAlpha(26),
                          borderRadius: AppRadius.small,
                          border: Border.all(
                            color: activePenColor.withAlpha(128),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedTool == 'marker'
                                  ? Icons.border_color
                                  : Icons.edit,
                              size: 18,
                              color: activePenColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                selectedTool == 'marker'
                                    ? '${getPenName(activePenColor)} (マーカー)'
                                    : activeIsShared
                                    ? '${getPenName(activePenColor)} (共有)'
                                    : '${getPenName(activePenColor)} (個人)',
                                style: TextStyle(
                                  color: activePenColor,
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.body,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: activePenColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // ペンツール
                  ProgramViewerToolButton(
                    tool: 'pen',
                    icon: Icons.edit,
                    tooltip: 'ペン',
                    isSelected: selectedTool == 'pen',
                    isDark: isDark,
                    activeColor: activePenColor,
                    onTap: () => onSelectTool('pen'),
                  ),
                  // 蛍光マーカー
                  ProgramViewerToolButton(
                    tool: 'marker',
                    icon: Icons.border_color,
                    tooltip: '蛍光マーカー',
                    isSelected: selectedTool == 'marker',
                    isDark: isDark,
                    activeColor: activePenColor,
                    onTap: () => onSelectTool('marker'),
                  ),
                ],
              ),
            ),
          ),

          // 2つのグループの間の区切り
          const SizedBox(width: AppSpacing.md),

          // 🧹 2. 【消去・履歴グループ】(消しゴム + 1つ戻る + 全消し)
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF424242)
                  : const Color(0xFFECEFF1).withAlpha(220),
              borderRadius: AppRadius.small,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF616161)
                    : const Color(0xFFCFD8DC),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 消しゴムツール
                ProgramViewerToolButton(
                  tool: 'eraser',
                  icon: Icons.cleaning_services,
                  tooltip: '消しゴム',
                  isSelected: selectedTool == 'eraser',
                  isDark: isDark,
                  activeColor: const Color(0xFF607D8B),
                  onTap: () => onSelectTool('eraser'),
                ),

                // 小さな縦仕切り線
                Container(
                  height: 20,
                  width: 1,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF607D8B),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                ),

                // 1つ戻る (Undo)
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.subValue),
                  iconSize: 20,
                  icon: Icon(
                    Icons.undo,
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.7)
                        : const Color(0xFF607D8B),
                  ),
                  tooltip: '1つ戻す',
                  onPressed: onUndo,
                ),

                // 全消去 (Delete Sweep)
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.subValue),
                  iconSize: 20,
                  icon: Icon(
                    Icons.delete_sweep,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF607D8B),
                  ),
                  tooltip: 'すべて消す',
                  onPressed: () async {
                    final shouldDelete = await showAppDialog<bool>(
                      context: context,
                      builder: (context) => AppDialog(
                        title: '全消去の確認',
                        content: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: activeIsShared
                                    ? 'このプログラムに引かれた【共有ペン】をすべて消去しますか？\n'
                                    : 'このプログラムに引かれた【個人ペン】をすべて消去しますか？\n',
                              ),
                              if (activeIsShared)
                                const TextSpan(
                                  text: '※他の人の画面からも消えてしまいます。間違いないですか？\n',
                                  style: TextStyle(
                                    color: AppKendoColors.redAccent,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              const TextSpan(text: '※一度削除したデータは元に戻すことができません。'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'キャンセル',
                              style: TextStyle(color: AppKendoColors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppKendoColors.redAccent,
                            ),
                            child: const Text('すべて消去する'),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      onClearAll();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
