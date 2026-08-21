import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// タイムライン画面用チーム名修正・統合ボトムシート
class TimelineRenameTeamSheet extends StatelessWidget {
  final String tournamentId;
  final String oldName;
  final WidgetRef ref;

  const TimelineRenameTeamSheet({
    super.key,
    required this.tournamentId,
    required this.oldName,
    required this.ref,
  });

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String tournamentId,
    required String oldName,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TimelineRenameTeamSheet(
        tournamentId: tournamentId,
        oldName: oldName,
        ref: ref,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: oldName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.appColors.primaryAccent;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: AppRadius.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'チーム名の修正・統合',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: primaryColor,
              fontSize: AppFontSize.headline,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '名前を修正すると、この大会内のすべての試合データが自動で書き換わり、同じ名前のチームと合流します。',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: AppKendoColors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '新しいチーム名',
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty || newName == oldName) {
                  Navigator.pop(context);
                  return;
                }
                await ref
                    .read(matchCommandProvider)
                    .renameTeamBulk(
                      tournamentId: tournamentId,
                      oldTeamName: oldName,
                      newTeamName: newName,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  AppSnackBar.showSuccess(context, 'チーム名を一括更新しました ✨');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
              child: const Text(
                '一括修正して統合する',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
