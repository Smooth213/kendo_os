import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 ヘッダーの actions 等に配置できるプログラム閲覧アイコンボタン
class ProgramHeaderAction extends StatelessWidget {
  final String tournamentId;
  final bool isViewerMode;
  final Color? color;

  const ProgramHeaderAction({
    super.key,
    required this.tournamentId,
    this.isViewerMode = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (tournamentId.isEmpty) return const SizedBox.shrink();
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    final iconColor = color ?? themeColors?.primaryAccent;

    return IconButton(
      icon: Icon(Icons.menu_book_rounded, color: iconColor),
      tooltip: '大会プログラム',
      onPressed: () {
        AppHaptics.light();
        ProgramBottomSheet.show(
          context,
          tournamentId: tournamentId,
          isViewerMode: isViewerMode,
        );
      },
    );
  }
}
