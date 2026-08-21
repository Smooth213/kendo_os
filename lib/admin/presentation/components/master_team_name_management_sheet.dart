import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/security_level_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// チーム名管理ボトムシート
class MasterTeamNameManagementSheet extends ConsumerStatefulWidget {
  final String orgName;

  const MasterTeamNameManagementSheet({super.key, required this.orgName});

  static void show(BuildContext context, String orgName) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => MasterTeamNameManagementSheet(orgName: orgName),
    );
  }

  @override
  ConsumerState<MasterTeamNameManagementSheet> createState() =>
      _MasterTeamNameManagementSheetState();
}

class _MasterTeamNameManagementSheetState
    extends ConsumerState<MasterTeamNameManagementSheet> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppKendoColors.purpleAccent
        : context.appColors.primaryAccent;

    final keyboardHeight = kIsWeb
        ? 0.0
        : MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            'チーム名の管理',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: primaryColor,
              fontSize: AppFontSize.header,
            ),
          ),
          const Text(
            '試合作成時にボタンで選べる「自チーム名」を登録します。',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: AppKendoColors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 入力エリア
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _nameController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: '例：〇〇剣友会A',
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
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton(
                onPressed: () async {
                  final name = TextSanitizer.clean(_nameController.text);
                  if (name.isNotEmpty) {
                    await ref
                        .read(teamNameHistoryProvider.notifier)
                        .addName(name, widget.orgName);
                    _nameController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: AppKendoColors.pureWhite,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                ),
                child: const Text('追加'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // リスト表示
          Flexible(
            child: Consumer(
              builder: (context, ref, child) {
                final names = ref.watch(teamNameHistoryProvider);

                if (names.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Text(
                        '登録されたチーム名はありません',
                        style: TextStyle(
                          color: AppKendoColors.grey,
                          fontSize: AppFontSize.bodySmall,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: names.length,
                  itemBuilder: (context, index) => Card(
                    elevation: 0,
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : context.appColors.cardBackground,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      title: Text(
                        names[index],
                        style: const TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.body,
                        ),
                      ),
                      trailing:
                          FeatureGate.canManageMaster(
                            ref.watch(currentUserRoleProvider),
                            ref.watch(securityLevelProvider),
                          )
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppKendoColors.redAccent,
                                size: 20,
                              ),
                              onPressed: () => ref
                                  .read(teamNameHistoryProvider.notifier)
                                  .deleteName(names[index], widget.orgName),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          if (!kIsWeb && isKeyboardVisible) SizedBox(height: keyboardHeight),
        ],
      ),
    );
  }
}
