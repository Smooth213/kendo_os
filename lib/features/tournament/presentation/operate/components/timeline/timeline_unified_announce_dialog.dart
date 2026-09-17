import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// タイムライン用 公式アナウンス・コメントの一斉発信ダイアログ
class TimelineUnifiedAnnounceDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
    String category,
    String groupName,
    double order, {
    String? matchGroupId,
  }) {
    showAppDialog(
      context: context,
      builder: (dialogCtx) => _UnifiedAnnounceDialog(
        parentContext: context,
        ref: ref,
        tournamentId: tournamentId,
        category: category,
        groupName: groupName,
        order: order,
        matchGroupId: matchGroupId,
      ),
    );
  }
}

class _UnifiedAnnounceDialog extends StatefulWidget {
  final BuildContext parentContext;
  final WidgetRef ref;
  final String tournamentId;
  final String category;
  final String groupName;
  final double order;
  final String? matchGroupId;

  const _UnifiedAnnounceDialog({
    required this.parentContext,
    required this.ref,
    required this.tournamentId,
    required this.category,
    required this.groupName,
    required this.order,
    this.matchGroupId,
  });

  @override
  State<_UnifiedAnnounceDialog> createState() => _UnifiedAnnounceDialogState();
}

class _UnifiedAnnounceDialogState extends State<_UnifiedAnnounceDialog> {
  late final TextEditingController titleController;
  late final TextEditingController bodyController;
  String selectedTarget = 'all';

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    bodyController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isBunaiksen = widget.tournamentId.startsWith('bunaiksen_');
    final themeColors = AppThemeColors.ofMode(
      isDark: isDark,
      mode: isBunaiksen ? 'bunaiksen' : 'normal',
    );

    return AppDialog(
      backgroundColor: isDark
          ? const Color(0xFF1C1C1E)
          : context.appColors.inputBackground,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      titleWidget: Row(
        children: [
          const Icon(Icons.add_alert, color: Color(0xFFFF69B4)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '公式アナウンス・コメントの一斉発信',
              style: TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: context.appColors.textColor,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: titleController,
              style: TextStyle(color: context.appColors.textColor),
              decoration: const InputDecoration(
                labelText: 'タイトル（例：【緊急】会場変更）',
                hintText: '空欄の場合は自動で見出しになります',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: bodyController,
              maxLines: 3,
              style: TextStyle(color: context.appColors.textColor),
              decoration: const InputDecoration(
                labelText: 'アナウンス本文内容',
                hintText: '例：3会場へ移動になりました。選手は速やかに移動してください。',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF242426)
                    : const Color(0xFFF2F2F7),
                borderRadius: AppRadius.medium,
              ),
              child: Row(
                children: [
                  _TargetChip(
                    chipKey: const Key('timeline_target_all_chip'),
                    label: '全員に通知',
                    icon: Icons.campaign,
                    activeColor: const Color(0xFFFF69B4),
                    isSelected: selectedTarget == 'all',
                    isDark: isDark,
                    onTap: () => setState(() => selectedTarget = 'all'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _TargetChip(
                    chipKey: const Key('timeline_target_staff_chip'),
                    label: 'スタッフ限定',
                    icon: Icons.lock_outline,
                    activeColor: AppKendoColors.deepOrange,
                    isSelected: selectedTarget == 'staff',
                    isDark: isDark,
                    onTap: () => setState(() => selectedTarget = 'staff'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _TargetChip(
                    chipKey: const Key('timeline_target_none_chip'),
                    label: '通知なし',
                    icon: Icons.notifications_off_outlined,
                    activeColor: AppKendoColors.blue,
                    isSelected: selectedTarget == 'none',
                    isDark: isDark,
                    onTap: () => setState(() => selectedTarget = 'none'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'キャンセル',
            style: TextStyle(color: AppKendoColors.grey),
          ),
        ),
        ElevatedButton.icon(
          key: const Key('timeline_submit_announce_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColors.primaryAccent,
            foregroundColor: AppKendoColors.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
          ),
          onPressed: _onSubmit,
          icon: Icon(
            selectedTarget == 'none'
                ? Icons.chat_bubble_outline
                : Icons.campaign,
            size: 18,
          ),
          label: Text(
            selectedTarget == 'none' ? 'コメントを保存' : '一斉発信して保存',
            style: const TextStyle(fontWeight: AppFontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _onSubmit() {
    final String title = titleController.text.trim();
    final String body = bodyController.text.trim();
    if (body.isEmpty && title.isEmpty) return;

    final String commentText = title.isNotEmpty
        ? (body.isNotEmpty ? '$title\n$body' : title)
        : body;

    final currentTarget = selectedTarget;
    final parentCtx = widget.parentContext;
    final ref = widget.ref;
    final tournamentId = widget.tournamentId;
    final category = widget.category;
    final groupName = widget.groupName;
    final matchGroupId = widget.matchGroupId;
    final order = widget.order;

    if (context.mounted) {
      Navigator.pop(context);
    }

    Future(() async {
      try {
        if (currentTarget != 'none') {
          FirebaseFirestore firestore;
          try {
            firestore = ref.read(firestoreProvider);
          } catch (_) {
            firestore = FirebaseFirestore.instance;
          }

          final String finalTitle = title.isNotEmpty ? title : '大会本部からのお知らせ';

          final String announceId = firestore
              .collection('announcements')
              .doc()
              .id;

          registerMySentAnnounceId(announceId);

          await firestore.collection('announcements').doc(announceId).set({
            'id': announceId,
            'tournamentId': tournamentId,
            'title': finalTitle,
            'body': body.isNotEmpty ? body : finalTitle,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'emergency',
            'target': currentTarget,
            'isRead': false,
            'createdBy': () {
              try {
                return FirebaseAuth.instance.currentUser?.uid;
              } catch (_) {
                return null;
              }
            }(),
          });
        }

        // タイムラインコメント保存
        await ref
            .read(commentCommandProvider)
            .addComment(
              tournamentId: tournamentId,
              category: category,
              groupName: groupName,
              matchGroupId: matchGroupId,
              text: commentText,
              order: order,
            );

        if (parentCtx.mounted) {
          if (currentTarget == 'none') {
            AppSnackBar.showSuccess(parentCtx, 'タイムラインにコメントを追加しました（通知なし）');
          } else if (currentTarget == 'staff') {
            AppSnackBar.showSuccess(parentCtx, 'スタッフ限定業務連絡を発信しました');
          } else {
            AppSnackBar.showSuccess(parentCtx, '全員向け緊急アナウンスを一斉配信しました');
          }
        }
      } catch (e) {
        debugPrint('🚨 [AnnounceDialog] 送信エラー: $e');
        if (parentCtx.mounted) {
          AppSnackBar.showError(parentCtx, '処理に失敗しました: ${e.toString()}');
        }
      }
    });
  }
}

class _TargetChip extends StatelessWidget {
  final Key? chipKey;
  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TargetChip({
    this.chipKey,
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        key: chipKey,
        onTap: onTap,
        borderRadius: AppRadius.small,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
                : AppKendoColors.transparent,
            borderRadius: AppRadius.small,
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark
                        ? AppKendoColors.pureWhite.withValues(alpha: 0.1)
                        : AppKendoColors.pureBlack.withValues(alpha: 0.12)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? activeColor : AppKendoColors.grey,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: isSelected
                        ? AppFontWeight.bold
                        : AppFontWeight.regular,
                    color: isSelected
                        ? (isDark
                              ? AppKendoColors.pureWhite
                              : AppKendoColors.pureBlack)
                        : AppKendoColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
