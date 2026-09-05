import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_reorderable_file_list.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// プログラムアップロード前のプレビュー・タイトル・順番確認ダイアログ
class ProgramTitlePreviewDialog {
  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required List<PlatformFile> files,
  }) async {
    String title = '';
    List<PlatformFile> orderedFiles = List.from(files);
    int selectedIndex = 0;
    final PageController previewController = PageController();
    final formKey = GlobalKey<FormState>();
    bool showValidationHighlight = false;

    return showAppDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          return AppDialog(
            title: '順番とタイトルの確認',
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            content: Form(
              key: formKey,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        color: AppKendoColors.pureBlack,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: previewController,
                              itemCount: orderedFiles.length,
                              onPageChanged: (index) =>
                                  setState(() => selectedIndex = index),
                              itemBuilder: (context, index) {
                                final file = orderedFiles[index];
                                final isPdf =
                                    file.extension?.toLowerCase() == 'pdf';
                                return InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  child: Center(
                                    child: isPdf
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.picture_as_pdf,
                                                color: AppKendoColors.pureWhite,
                                                size: 64,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              Text(
                                                'PDFプレビュー非対応\n(アップロード後に確認可能)',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppKendoColors
                                                      .pureWhite
                                                      .withValues(alpha: 0.7),
                                                  fontSize: AppFontSize.small,
                                                ),
                                              ),
                                            ],
                                          )
                                        : kIsWeb
                                        ? (file.bytes != null
                                              ? Image.memory(
                                                  file.bytes!,
                                                  fit: BoxFit.contain,
                                                )
                                              : const Icon(
                                                  Icons.broken_image,
                                                  color:
                                                      AppKendoColors.pureWhite,
                                                  size: 64,
                                                ))
                                        : (file.path != null
                                              ? Image.file(
                                                  File(file.path!),
                                                  fit: BoxFit.contain,
                                                )
                                              : const Icon(
                                                  Icons.broken_image,
                                                  color:
                                                      AppKendoColors.pureWhite,
                                                  size: 64,
                                                )),
                                  ),
                                );
                              },
                            ),
                            if (orderedFiles.length > 1) ...[
                              Positioned(
                                left: AppSpacing.sm,
                                top: 0,
                                bottom: 0,
                                child: Icon(
                                  Icons.chevron_left,
                                  color: AppKendoColors.pureWhite.withAlpha(
                                    128,
                                  ),
                                  size: 32,
                                ),
                              ),
                              Positioned(
                                right: AppSpacing.sm,
                                top: 0,
                                bottom: 0,
                                child: Icon(
                                  Icons.chevron_right,
                                  color: AppKendoColors.pureWhite.withAlpha(
                                    128,
                                  ),
                                  size: 32,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      color: isDark
                          ? const Color(0xFF1C1C2E)
                          : context.appColors.softAccent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📝 プログラム名（ベースタイトル）',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              color: isDark
                                  ? AppKendoColors.pureWhite
                                  : context.appColors.primaryAccent,
                              fontSize: AppFontSize.bodySmall,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            initialValue: title,
                            autofocus: false,
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: '例：1日目 進行表',
                              hintStyle: TextStyle(
                                color: context.appColors.subTextColor,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF2C2C3E)
                                  : context.appColors.cardBackground,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.small,
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF3A3A6A)
                                      : context.appColors.separatorColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.small,
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF3A3A6A)
                                      : context.appColors.separatorColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.small,
                                borderSide: BorderSide(
                                  color: context.appColors.primaryAccent,
                                  width: 1.5,
                                ),
                              ),
                              errorStyle: const TextStyle(
                                color: AppKendoColors.redAccent,
                                fontWeight: AppFontWeight.bold,
                              ),
                            ),
                            onChanged: (value) => setState(() => title = value),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'プログラムのタイトルを入力してください';
                              }
                              return null;
                            },
                          ),
                          if (title.trim().isEmpty)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.only(
                                top: 6,
                                left: AppSpacing.xs,
                                right: AppSpacing.xs,
                                bottom: AppSpacing.xs,
                              ),
                              decoration: showValidationHighlight
                                  ? BoxDecoration(
                                      color: AppKendoColors.hansokuRed,
                                      borderRadius: AppRadius.sub,
                                      border: Border.all(
                                        color: AppKendoColors.hansokuRed,
                                        width: 1.2,
                                      ),
                                    )
                                  : null,
                              child: Row(
                                children: [
                                  Icon(
                                    showValidationHighlight
                                        ? Icons.error_outline
                                        : Icons.info_outline,
                                    size: 13,
                                    color: showValidationHighlight
                                        ? AppKendoColors.hansokuRed
                                        : context.appColors.warningColor,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'タイトルは必須です（入力しないと保存できません）',
                                    style: TextStyle(
                                      fontSize: AppFontSize.caption,
                                      color: showValidationHighlight
                                          ? AppKendoColors.hansokuRed
                                          : context.appColors.warningColor,
                                      fontWeight: showValidationHighlight
                                          ? AppFontWeight.bold
                                          : AppFontWeight.semiBold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (orderedFiles.length > 1) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF252540)
                                    : context.appColors.cardBackground,
                                borderRadius: AppRadius.small,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF3A3A6A)
                                      : context.appColors.primaryAccent
                                            .withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: context.appColors.primaryAccent,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      '複数アップロードのガイド：\n'
                                      '• 下のリストをドラッグして並び順を変更できます。\n'
                                      '• 保存時、自動的に「[入力タイトル] (1/n)」のように連番が付与されて保存されます。',
                                      style: TextStyle(
                                        fontSize: AppFontSize.small,
                                        fontWeight: AppFontWeight.semiBold,
                                        color: isDark
                                            ? context.appColors.textColor
                                            : context.appColors.primaryAccent,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: ProgramReorderableFileList(
                        orderedFiles: orderedFiles,
                        selectedIndex: selectedIndex,
                        isDark: isDark,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            final item = orderedFiles.removeAt(oldIndex);
                            orderedFiles.insert(newIndex, item);
                            selectedIndex = orderedFiles.indexOf(item);
                            previewController.jumpToPage(selectedIndex);
                          });
                        },
                        onFileSelected: (index) {
                          setState(() => selectedIndex = index);
                          previewController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'title': title.trim(),
                      'files': orderedFiles,
                    });
                  } else {
                    setState(() => showValidationHighlight = true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.indigo,
                  foregroundColor: AppKendoColors.pureWhite,
                ),
                child: const Text('アップロード開始'),
              ),
            ],
          );
        },
      ),
    );
  }
}
