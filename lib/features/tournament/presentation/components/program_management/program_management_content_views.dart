import 'package:flutter/material.dart';
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

        return InkWell(
          onTap: isUploading
              ? () => AppSnackBar.show(context, 'アップロード中です。完了するまでお待ちください。')
              : () => context.push(
                  isViewerMode
                      ? '/program-viewer?role=viewer'
                      : '/program-viewer',
                  extra: {'programs': programs, 'index': index},
                ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
            elevation: 2,
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
                        if (!isViewerMode)
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
  }) {
    return ListView.builder(
      itemCount: programs.length,
      itemExtent: 68.0,
      itemBuilder: (context, index) {
        final program = programs[index];
        final isUploading = program.fileUrl.contains('placehold.co');

        return ListTile(
          leading: ClipRRect(
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
          title: Text(
            program.title,
            style: const TextStyle(fontWeight: AppFontWeight.bold),
          ),
          subtitle: Text(program.fileType.toUpperCase()),
          trailing: isViewerMode
              ? null
              : IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(program),
                ),
          onTap: isUploading
              ? () => AppSnackBar.show(context, 'アップロード中です。完了するまでお待ちください。')
              : () => context.push(
                  isViewerMode
                      ? '/program-viewer?role=viewer'
                      : '/program-viewer',
                  extra: {'programs': programs, 'index': index},
                ),
        );
      },
    );
  }
}
