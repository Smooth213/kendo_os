import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 初期道場名・学校名の登録ボトムシート & ダイアログ
class MasterRegisterOrganizationBottomSheet {
  static void show(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppKendoColors.purpleAccent
        : context.appColors.primaryAccent;
    final dialogBgColor = isDark
        ? const Color(0xFF1E1E1E)
        : context.appColors.textColor;
    final inputBgColor = isDark
        ? const Color(0xFF2C2C2C)
        : context.appColors.cardBackground;
    final textColor = context.appColors.textColor;

    final initialName = ref.read(currentDojoNameProvider).value ?? '';
    final controller = TextEditingController(text: initialName);

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final keyboardHeight = kIsWeb
              ? 0.0
              : MediaQuery.of(context).viewInsets.bottom;
          final isKeyboardVisible = keyboardHeight > 0;
          final screenHeight = MediaQuery.of(context).size.height;
          final maxSheetHeight = screenHeight * 0.9;

          return Container(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            decoration: BoxDecoration(
              color: dialogBgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xlargeValue),
              ),
            ),
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xl,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0x33000000),
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    '道場名・学校名の登録',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: isDark
                          ? AppKendoColors.purpleAccent
                          : const Color(0xFF9C27B0),
                      fontSize: AppFontSize.header,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    '選手を追加する前に、道場名または学校名を入力してください。',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: AppKendoColors.grey,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    controller: controller,
                    autofocus: false,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: '道場名・学校名',
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : AppKendoColors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      filled: true,
                      fillColor: inputBgColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'キャンセル',
                          style: TextStyle(
                            color: isDark
                                ? context.appColors.subTextColor
                                : AppKendoColors.grey,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: AppKendoColors.pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('登録'),
                        onPressed: () async {
                          final newName = TextSanitizer.clean(controller.text);
                          if (newName.isEmpty) return;

                          final dojoId = ref.read(currentDojoIdProvider);
                          final safeDojoId = dojoId.isNotEmpty
                              ? dojoId
                              : 'test201';
                          final firestore = ref.read(firestoreProvider);

                          await firestore
                              .collection('organizations')
                              .doc(safeDojoId)
                              .set({'name': newName}, SetOptions(merge: true));

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  if (!kIsWeb && isKeyboardVisible)
                    SizedBox(height: keyboardHeight),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static void showMustRegisterDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppKendoColors.purpleAccent
        : context.appColors.primaryAccent;

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: Icons.warning_amber_rounded,
        iconColor: context.appColors.warningColor,
        title: '道場名の登録が必要です',
        content: const Text(
          '選手を登録する前に、まずは道場名・学校名を登録してください。',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              show(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: AppKendoColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              elevation: 0,
            ),
            child: const Text(
              '道場名を入力',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
