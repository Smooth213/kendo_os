import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/organization_graduation_type.dart';
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
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => _MasterRegisterOrganizationSheet(ref: ref),
    );
  }

  static void showMustRegisterDialog(BuildContext context, WidgetRef ref) {
    final primaryColor = context.appColors.primaryAccent;

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
            child: Text(
              'キャンセル',
              style: TextStyle(color: context.appColors.subTextColor),
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
              shape: const StadiumBorder(),
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

class _MasterRegisterOrganizationSheet extends StatefulWidget {
  final WidgetRef ref;

  const _MasterRegisterOrganizationSheet({required this.ref});

  @override
  State<_MasterRegisterOrganizationSheet> createState() =>
      _MasterRegisterOrganizationSheetState();
}

class _MasterRegisterOrganizationSheetState
    extends State<_MasterRegisterOrganizationSheet> {
  late final TextEditingController controller;
  OrganizationGraduationType _selectedGraduationType =
      OrganizationGraduationType.juniorDojo;

  @override
  void initState() {
    super.initState();
    final initialName = widget.ref.read(currentDojoNameProvider).value ?? '';
    controller = TextEditingController(text: initialName);
    _selectedGraduationType =
        widget.ref
            .read(organizationPromotionConfigProvider)
            .value
            ?.graduationType ??
        OrganizationGraduationType.juniorDojo;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final primaryColor = themeColors.primaryAccent;
    final dialogBgColor = themeColors.cardBackground;
    final inputBgColor = themeColors.inputBackground;
    final textColor = themeColors.textColor;
    final subTextColor = themeColors.subTextColor;

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight = (screenHeight - keyboardHeight).clamp(
      0.0,
      screenHeight,
    );
    final maxSheetHeight = availableHeight * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
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
                  color: primaryColor,
                  fontSize: AppFontSize.header,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '選手を追加する前に、道場名または学校名を入力してください。',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: controller,
                autofocus: false,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: '道場名・学校名',
                  prefixIcon: Icon(Icons.account_balance, color: subTextColor),
                  border: OutlineInputBorder(borderRadius: AppRadius.capsule),
                  filled: true,
                  fillColor: inputBgColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<OrganizationGraduationType>(
                initialValue: _selectedGraduationType,
                dropdownColor: dialogBgColor,
                style: TextStyle(color: textColor, fontSize: AppFontSize.body),
                decoration: InputDecoration(
                  labelText: '組織種別（一括進級の卒業ライン）',
                  prefixIcon: Icon(Icons.school, color: subTextColor),
                  border: OutlineInputBorder(borderRadius: AppRadius.capsule),
                  filled: true,
                  fillColor: inputBgColor,
                ),
                items: OrganizationGraduationType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedGraduationType = val);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _selectedGraduationType.description,
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: subTextColor,
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
                        color: subTextColor,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: AppKendoColors.pureWhite,
                      shape: const StadiumBorder(),
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

                      final dojoId = widget.ref.read(currentDojoIdProvider);
                      final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
                      final firestore = widget.ref.read(firestoreProvider);

                      await firestore
                          .collection('organizations')
                          .doc(safeDojoId)
                          .set({
                            'name': newName,
                            'graduationType': _selectedGraduationType.id,
                          }, SetOptions(merge: true));

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
