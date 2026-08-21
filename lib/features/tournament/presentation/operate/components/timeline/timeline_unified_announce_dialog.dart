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
import 'package:kendo_os/shared/widgets/app_chip.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isBunaiksen = tournamentId.startsWith('bunaiksen_');
    final themeColors = AppThemeColors.ofMode(
      isDark: isDark,
      mode: isBunaiksen ? 'bunaiksen' : 'normal',
    );
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedTarget = 'all';

    showAppDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            ? const Color(0xFF2C2C2E)
                            : context.appColors.cardBackground,
                        borderRadius: AppRadius.small,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  '📢 全員に通知',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedTarget == 'all'
                                        ? (context.appColors.textColor)
                                        : AppKendoColors.grey,
                                  ),
                                ),
                              ),
                              selected: selectedTarget == 'all',
                              customSelectedColor: const Color(
                                0xFFFF69B4,
                              ).withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() => selectedTarget = 'all');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: AppChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  '🔒 スタッフ限定',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedTarget == 'staff'
                                        ? (context.appColors.textColor)
                                        : AppKendoColors.grey,
                                  ),
                                ),
                              ),
                              selected: selectedTarget == 'staff',
                              customSelectedColor: AppKendoColors.deepOrange
                                  .withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(
                                    () => selectedTarget = 'staff',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: AppKendoColors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors.primaryAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.small,
                    ),
                  ),
                  onPressed: () {
                    final String title = titleController.text.trim();
                    final String body = bodyController.text.trim();
                    if (body.isEmpty) return;

                    final String finalTitle = title.isNotEmpty
                        ? title
                        : '大会本部からのお知らせ';

                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }

                    Future(() async {
                      FirebaseFirestore firestore;
                      try {
                        firestore = ref.read(firestoreProvider);
                      } catch (_) {
                        firestore = FirebaseFirestore.instance;
                      }

                      final String announceId = firestore
                          .collection('announcements')
                          .doc()
                          .id;

                      registerMySentAnnounceId(announceId);

                      try {
                        await firestore
                            .collection('announcements')
                            .doc(announceId)
                            .set({
                              'id': announceId,
                              'tournamentId': tournamentId,
                              'title': finalTitle,
                              'body': body,
                              'timestamp': FieldValue.serverTimestamp(),
                              'type': 'emergency',
                              'target': selectedTarget,
                              'isRead': false,
                              'createdBy': () {
                                try {
                                  return FirebaseAuth.instance.currentUser?.uid;
                                } catch (_) {
                                  return null;
                                }
                              }(),
                            });

                        final String commentText = title.isNotEmpty
                            ? '$title\n$body'
                            : body;
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

                        if (context.mounted) {
                          AppSnackBar.showSuccess(
                            context,
                            selectedTarget == 'staff'
                                ? 'スタッフ限定業務連絡を発信しました'
                                : '全員向け緊急アナウンスを一斉配信しました',
                          );
                        }
                      } catch (e) {
                        debugPrint('🚨 [AnnounceDialog] 送信エラー: $e');
                        if (context.mounted) {
                          AppSnackBar.showError(
                            context,
                            '送信に失敗しました: ${e.toString()}',
                          );
                        }
                      }
                    });
                  },
                  child: const Text(
                    '一斉発信して保存',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
