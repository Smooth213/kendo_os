import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合画面のレスポンシブ（タブレット横向き / スマホ縦向き）レイアウトビルダー
class MatchContentLayoutBuilder extends StatelessWidget {
  final BoxConstraints constraints;
  final bool isDark;
  final Widget corruptedBanner;
  final Widget viewOnlyBanner;
  final Widget timerPart;
  final Widget groupButtonPart;
  final Widget scoreboardPart;
  final Widget actionPanelPart;
  final Widget undoArea;
  final Widget bottomButtonPart;

  const MatchContentLayoutBuilder({
    super.key,
    required this.constraints,
    required this.isDark,
    required this.corruptedBanner,
    required this.viewOnlyBanner,
    required this.timerPart,
    required this.groupButtonPart,
    required this.scoreboardPart,
    required this.actionPanelPart,
    required this.undoArea,
    required this.bottomButtonPart,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTabletLandscape = isLandscape && constraints.maxWidth > 600;

    if (isTabletLandscape) {
      return Column(
        children: [
          corruptedBanner,
          viewOnlyBanner,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      timerPart,
                      groupButtonPart,
                      Expanded(child: scoreboardPart),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                      : AppKendoColors.pureBlack.withValues(alpha: 0.12),
                ),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(child: actionPanelPart),
                      undoArea,
                      bottomButtonPart,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      final double currentContentHeight = constraints.maxHeight;
      final bool needsScroll = currentContentHeight < 610.0;
      final double effectiveHeight = needsScroll ? 610.0 : currentContentHeight;

      final mainContent = Column(
        children: [
          corruptedBanner,
          viewOnlyBanner,
          timerPart,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: groupButtonPart,
          ),
          const SizedBox(height: 2),
          scoreboardPart,
          Expanded(child: actionPanelPart),
          undoArea,
          bottomButtonPart,
        ],
      );

      return needsScroll
          ? SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SizedBox(height: effectiveHeight, child: mainContent),
            )
          : mainContent;
    }
  }
}
