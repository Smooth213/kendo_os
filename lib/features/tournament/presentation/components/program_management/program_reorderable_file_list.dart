import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 プログラムアップロード前の並び替え可能ファイルリスト（ReorderableListView）
class ProgramReorderableFileList extends StatelessWidget {
  final List<PlatformFile> orderedFiles;
  final int selectedIndex;
  final bool isDark;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onFileSelected;

  const ProgramReorderableFileList({
    super.key,
    required this.orderedFiles,
    required this.selectedIndex,
    required this.isDark,
    required this.onReorder,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: isDark
            ? const Color(0xFF1C1C1E)
            : context.appColors.cardBackground,
      ),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        itemCount: orderedFiles.length,
        onReorderItem: onReorder,
        itemBuilder: (context, index) {
          final file = orderedFiles[index];
          final isSelected = selectedIndex == index;
          return Container(
            key: ValueKey(kIsWeb ? file.name : (file.path ?? file.name)),
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              borderRadius: AppRadius.small,
              border: isSelected
                  ? Border.all(
                      color: context.appColors.primaryAccent.withValues(
                        alpha: isDark ? 0.6 : 0.4,
                      ),
                      width: 1.2,
                    )
                  : null,
            ),
            child: Material(
              color: isSelected
                  ? (isDark
                        ? context.appColors.primaryAccent.withValues(
                            alpha: 0.25,
                          )
                        : context.appColors.softAccent)
                  : (isDark
                        ? const Color(0xFF1C1C1E)
                        : AppKendoColors.transparent),
              borderRadius: AppRadius.small,
              child: ListTile(
                selected: isSelected,
                selectedTileColor: AppKendoColors.transparent,
                tileColor: AppKendoColors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.small,
                ),
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected
                      ? context.appColors.primaryAccent
                      : (isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA)),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected
                          ? AppKendoColors.pureWhite
                          : context.appColors.subTextColor,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  file.name,
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: isSelected
                        ? AppFontWeight.bold
                        : AppFontWeight.regular,
                    color: isSelected
                        ? (isDark
                              ? AppKendoColors.pureWhite
                              : context.appColors.primaryAccent)
                        : context.appColors.textColor,
                  ),
                ),
                trailing: Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: isSelected
                      ? (isDark
                            ? AppKendoColors.pureWhite
                            : context.appColors.primaryAccent)
                      : context.appColors.subTextColor,
                ),
                onTap: () => onFileSelected(index),
              ),
            ),
          );
        },
      ),
    );
  }
}
