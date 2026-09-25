import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_edit_form_fields.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 大会情報の編集ボトムシート（ドック仕様準拠）
class TournamentEditBottomSheet extends ConsumerStatefulWidget {
  final TournamentModel tournament;
  final Color? cardColor, textColor, subTextColor, borderColor;

  const TournamentEditBottomSheet({
    super.key,
    required this.tournament,
    this.cardColor,
    this.textColor,
    this.subTextColor,
    this.borderColor,
  });

  static Future<void> show({
    required BuildContext context,
    required TournamentModel tournament,
    Color? cardColor,
    Color? textColor,
    Color? subTextColor,
    Color? borderColor,
  }) => showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppKendoColors.transparent,
    builder: (ctx) => TournamentEditBottomSheet(
      tournament: tournament,
      cardColor: cardColor,
      textColor: textColor,
      subTextColor: subTextColor,
      borderColor: borderColor,
    ),
  );

  @override
  ConsumerState<TournamentEditBottomSheet> createState() =>
      _TournamentEditBottomSheetState();
}

class _TournamentEditBottomSheetState
    extends ConsumerState<TournamentEditBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tournament.name);
    _venueController = TextEditingController(text: widget.tournament.venue);
    _notesController = TextEditingController(text: widget.tournament.notes);
    _selectedDate = widget.tournament.date;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    Color effectiveTextColor,
    Color effectiveCardColor,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppKendoColors.indigo,
            onPrimary: AppKendoColors.pureWhite,
            onSurface: effectiveTextColor,
          ),
          dialogTheme: DialogThemeData(backgroundColor: effectiveCardColor),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.showError(context, '大会名を入力してください');
      return;
    }

    setState(() => _isSaving = true);
    AppHaptics.medium();

    try {
      await ref
          .read(tournamentRepositoryProvider)
          .updateTournamentDetails(
            widget.tournament.id,
            name: name,
            venue: _venueController.text.trim(),
            notes: _notesController.text.trim(),
            date: _selectedDate,
          );

      AppHaptics.success();
      if (mounted) {
        AppSnackBar.showSuccess(context, '大会情報を更新しました');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, '更新に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveCardColor = widget.cardColor ?? themeColors.cardBackground;
    final effectiveTextColor = widget.textColor ?? themeColors.textColor;
    final effectiveSubTextColor =
        widget.subTextColor ?? themeColors.subTextColor;
    final effectiveBorderColor =
        widget.borderColor ?? themeColors.separatorColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: effectiveCardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.largeValue),
            ),
            boxShadow: [
              BoxShadow(
                color: AppKendoColors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // ドラッグハンドル
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      margin: const EdgeInsets.only(
                        top: AppSpacing.compact,
                        bottom: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveBorderColor.withValues(alpha: 0.8),
                        borderRadius: AppRadius.capsule,
                      ),
                    ),
                  ),

                  // ヘッダーバー（タイトル・保存ボタン・閉じるボタン）
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppKendoColors.indigo.withValues(alpha: 0.1),
                            borderRadius: AppRadius.small,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: AppKendoColors.indigo,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '大会情報の編集',
                            style: TextStyle(
                              fontSize: AppFontSize.subhead,
                              fontWeight: AppFontWeight.bold,
                              color: effectiveTextColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: effectiveSubTextColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                          ),
                          child: const Text('キャンセル'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppKendoColors.indigo,
                            foregroundColor: AppKendoColors.pureWhite,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.small,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppKendoColors.pureWhite,
                                  ),
                                )
                              : const Text(
                                  '保存',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: effectiveBorderColor.withValues(alpha: 0.5),
                  ),

                  // スクロール可能なフォームコンテンツ
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.roundValue,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TournamentEditBasicFields(
                            nameController: _nameController,
                            venueController: _venueController,
                            selectedDate: _selectedDate,
                            effectiveTextColor: effectiveTextColor,
                            effectiveSubTextColor: effectiveSubTextColor,
                            effectiveBorderColor: effectiveBorderColor,
                            onPickDate: () => _pickDate(
                              context,
                              effectiveTextColor,
                              effectiveCardColor,
                            ),
                          ),

                          // 大会メモ入力（可変長・複数行対応）
                          Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 18,
                                color: effectiveSubTextColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '大会メモ（任意・TimeTreeや諸連絡など）',
                                style: TextStyle(
                                  fontSize: AppFontSize.bodySmall,
                                  fontWeight: AppFontWeight.bold,
                                  color: effectiveSubTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : effectiveCardColor,
                              borderRadius: AppRadius.small,
                              border: Border.all(
                                color: effectiveBorderColor.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: AppTextField(
                              controller: _notesController,
                              minLines: 4,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: TextStyle(
                                color: effectiveTextColor,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: '連絡事項、タイムスケジュール、駐車場や注意事項などを記入・推敲できます',
                                hintStyle: TextStyle(
                                  color: effectiveSubTextColor.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: AppFontSize.bodySmall,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // 下部固定アクションボタン
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppKendoColors.pureWhite,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: const Text(
                                '大会情報を保存する',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.body,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppKendoColors.indigo,
                                foregroundColor: AppKendoColors.pureWhite,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.medium,
                                ),
                              ),
                              onPressed: _isSaving ? null : _save,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
