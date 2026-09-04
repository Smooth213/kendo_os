import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// プログラム管理のグリッド＆リストコンテンツ表示
class ProgramManagementContentViews {
  static Widget buildGridView({
    required BuildContext context,
    required List<ProgramModel> programs,
    required String Function(String) getSafeUrl,
    required void Function(ProgramModel) onDelete,
    bool isViewerMode = false,
    bool isSelectionMode = false,
    Set<String> selectedProgramIds = const {},
    void Function(ProgramModel)? onToggleSelection,
    void Function(ProgramModel)? onLongPress,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        final isUploading = program.fileUrl.contains('placehold.co');
        final isSelected = selectedProgramIds.contains(program.id);

        return InkWell(
          onTap: () {
            if (isSelectionMode) {
              onToggleSelection?.call(program);
            } else if (isUploading) {
              AppSnackBar.show(context, 'アップロード中です。完了するまでお待ちください。');
            } else {
              context.push(
                isViewerMode
                    ? '/program-viewer?role=viewer'
                    : '/program-viewer',
                extra: {'programs': programs, 'index': index},
              );
            }
          },
          onLongPress: (!isViewerMode && !isSelectionMode)
              ? () => onLongPress?.call(program)
              : null,
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.medium,
              side: isSelectionMode && isSelected
                  ? BorderSide(color: context.appColors.primaryAccent, width: 2)
                  : BorderSide.none,
            ),
            elevation: isSelected ? 4 : 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                program.fileType == 'pdf'
                    ? Container(
                        color: context.appColors.separatorColor,
                        child: const Icon(
                          Icons.picture_as_pdf,
                          size: 64,
                          color: AppKendoColors.redAccent,
                        ),
                      )
                    : Image.network(
                        getSafeUrl(program.fileUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: context.appColors.separatorColor,
                          child: const Icon(
                            Icons.broken_image,
                            color: AppKendoColors.grey,
                          ),
                        ),
                      ),
                if (isSelectionMode)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppKendoColors.pureWhite,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? context.appColors.primaryAccent
                            : context.appColors.subTextColor,
                        size: 24,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: AppKendoColors.pureBlack.withAlpha(153),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            program.title,
                            style: const TextStyle(
                              color: AppKendoColors.pureWhite,
                              fontSize: AppFontSize.small,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isViewerMode && !isSelectionMode)
                          GestureDetector(
                            onTap: () => onDelete(program),
                            child: Icon(
                              Icons.delete,
                              color: AppKendoColors.pureWhite.withValues(
                                alpha: 0.7,
                              ),
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildListView({
    required BuildContext context,
    required List<ProgramModel> programs,
    required String Function(String) getSafeUrl,
    required void Function(ProgramModel) onDelete,
    bool isViewerMode = false,
    bool isSelectionMode = false,
    Set<String> selectedProgramIds = const {},
    void Function(ProgramModel)? onToggleSelection,
    void Function(ProgramModel)? onLongPress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      itemCount: programs.length,
      itemExtent: 68.0,
      itemBuilder: (context, index) {
        final program = programs[index];
        final isUploading = program.fileUrl.contains('placehold.co');
        final isSelected = selectedProgramIds.contains(program.id);

        final tile = ListTile(
          selected: isSelectionMode && isSelected,
          selectedTileColor: isSelectionMode && isSelected
              ? context.appColors.primaryAccent.withValues(alpha: 0.15)
              : null,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? context.appColors.primaryAccent
                        : (isDark
                              ? AppKendoColors.pureWhite
                              : context.appColors.subTextColor),
                    size: 22,
                  ),
                ),
              ClipRRect(
                borderRadius: AppRadius.small,
                child: Container(
                  width: 48,
                  height: 48,
                  color: context.appColors.separatorColor,
                  child: program.fileType == 'pdf'
                      ? const Icon(
                          Icons.picture_as_pdf,
                          color: AppKendoColors.redAccent,
                        )
                      : Image.network(
                          getSafeUrl(program.fileUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: AppKendoColors.grey,
                                  size: 24,
                                ),
                              ),
                        ),
                ),
              ),
            ],
          ),
          title: Text(
            program.title,
            style: const TextStyle(fontWeight: AppFontWeight.bold),
          ),
          subtitle: Text(program.fileType.toUpperCase()),
          onTap: () {
            if (isSelectionMode) {
              onToggleSelection?.call(program);
            } else if (isUploading) {
              AppSnackBar.show(context, 'アップロード中です。完了するまでお待ちください。');
            } else {
              context.push(
                isViewerMode
                    ? '/program-viewer?role=viewer'
                    : '/program-viewer',
                extra: {'programs': programs, 'index': index},
              );
            }
          },
          onLongPress: (!isViewerMode && !isSelectionMode)
              ? () => onLongPress?.call(program)
              : null,
        );

        if (isViewerMode || isSelectionMode) {
          return tile;
        }

        return Slidable(
          key: ValueKey('slidable_program_${program.id}'),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => onDelete(program),
                backgroundColor: AppKendoColors.redAccent,
                foregroundColor: AppKendoColors.pureWhite,
                icon: Icons.delete,
                label: '削除',
              ),
            ],
          ),
          child: tile,
        );
      },
    );
  }
}
