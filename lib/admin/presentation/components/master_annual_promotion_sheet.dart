import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/presentation/components/master_annual_promotion_header.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/organization_graduation_type.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';

typedef ExecuteAnnualPromotionCallback =
    Future<AnnualPromotionSummary> Function({
      required OrganizationGraduationType graduationType,
      required Set<String> retainPlayerIds,
      required int graduationFiscalYear,
      required int promotionFiscalYear,
    });

/// 新年度の一括進級プレビュー・卒業ライン選択・例外残留設定シート
class MasterAnnualPromotionSheet extends ConsumerStatefulWidget {
  final ExecuteAnnualPromotionCallback onExecutePromotion;
  final DateTime? nowOverride;

  const MasterAnnualPromotionSheet({
    super.key,
    required this.onExecutePromotion,
    this.nowOverride,
  });

  static void show(
    BuildContext context, {
    required ExecuteAnnualPromotionCallback onExecutePromotion,
    DateTime? nowOverride,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (_) => MasterAnnualPromotionSheet(
        onExecutePromotion: onExecutePromotion,
        nowOverride: nowOverride,
      ),
    );
  }

  @override
  ConsumerState<MasterAnnualPromotionSheet> createState() =>
      _MasterAnnualPromotionSheetState();
}

class _MasterAnnualPromotionSheetState
    extends ConsumerState<MasterAnnualPromotionSheet> {
  OrganizationGraduationType? _selectedType;
  final Set<String> _retainPlayerIds = {};
  late int _graduationFiscalYear;
  bool _isSubmitting = false;

  DateTime get _now => widget.nowOverride ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _graduationFiscalYear = FiscalYearHelper.defaultGraduationFiscalYear(_now);
    final config = ref.read(organizationPromotionConfigProvider).value;
    _selectedType = config?.graduationType;
  }

  Future<void> _handleConfirmAndRun({
    required OrganizationGraduationType type,
    required int promotionFiscalYear,
    required bool alreadyPromoted,
    required int promotedCount,
    required int graduatedCount,
  }) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: alreadyPromoted ? Icons.warning_amber_rounded : Icons.school,
        iconColor: alreadyPromoted
            ? context.appColors.warningColor
            : context.appColors.primaryAccent,
        title: alreadyPromoted ? '今年度は進級実行済みです' : '一括進級の最終確認',
        content: Text(
          alreadyPromoted
              ? '$promotionFiscalYear年度の一括進級はすでに実行されています。\n'
                    'もう一度実行すると全選手（一般除く）がさらに1学年進級します。\n\n'
                    '進級：$promotedCount名 / 卒業（OB/OG）：$graduatedCount名\n'
                    '本当によろしいですか？'
              : '$promotionFiscalYear年度の新年度進級を実行します。\n'
                    '・進級：$promotedCount名\n'
                    '・卒業（$_graduationFiscalYear年度卒）：$graduatedCount名\n'
                    '・一般（維持）：対象外\n\n'
                    'よろしいですか？',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'キャンセル',
              style: TextStyle(color: context.appColors.subTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: alreadyPromoted
                  ? context.appColors.warningColor
                  : context.appColors.primaryAccent,
              foregroundColor: AppKendoColors.pureWhite,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text(
              alreadyPromoted ? '理解して再実行' : '実行する',
              style: const TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final summary = await widget.onExecutePromotion(
        graduationType: type,
        retainPlayerIds: Set<String>.from(_retainPlayerIds),
        graduationFiscalYear: _graduationFiscalYear,
        promotionFiscalYear: promotionFiscalYear,
      );
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.showSuccess(
        context,
        '一括進級が完了しました（進級 ${summary.promotedCount}名 / 卒業 ${summary.graduatedCount}名）🌸',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.showError(context, '一括進級に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playerListProvider);
    final configAsync = ref.watch(organizationPromotionConfigProvider);
    final config = configAsync.value ?? const OrganizationPromotionConfig();
    final activeType = _selectedType ?? config.graduationType;
    final promotionFiscalYear = FiscalYearHelper.targetPromotionFiscalYear(
      _now,
    );
    final alreadyPromoted = config.isAlreadyPromotedFor(promotionFiscalYear);
    final primaryColor = context.appColors.primaryAccent;

    return AppBottomSheetContent(
      showDragHandle: true,
      title: '新年度の一括進級',
      child: playersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: AppLoadingIndicator()),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('読み込みエラー: $err'),
        ),
        data: (allPlayers) {
          final activePlayers = allPlayers.where((p) => p.isActive).toList()
            ..sort((a, b) => a.grade.compareTo(b.grade));
          final candidates = activePlayers
              .where((p) => activeType.isGraduationCandidate(p))
              .toList();

          int promotedCount = 0;
          int graduatedCount = 0;
          int adultKeptCount = 0;
          for (final p in activePlayers) {
            final outcome = activeType.evaluatePromotion(
              p,
              retainInActive: _retainPlayerIds.contains(p.id),
              graduationFiscalYear: _graduationFiscalYear,
              now: _now,
            );
            switch (outcome.kind) {
              case PlayerPromotionKind.promoted:
                promotedCount++;
              case PlayerPromotionKind.graduated:
                graduatedCount++;
              case PlayerPromotionKind.unchanged:
                if (p.grade >= 17) adultKeptCount++;
            }
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    itemCount: candidates.isEmpty ? 2 : candidates.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return MasterAnnualPromotionHeader(
                          activeType: activeType,
                          config: config,
                          promotionFiscalYear: promotionFiscalYear,
                          graduationFiscalYear: _graduationFiscalYear,
                          defaultGraduationFiscalYear:
                              FiscalYearHelper.defaultGraduationFiscalYear(
                                _now,
                              ),
                          alreadyPromoted: alreadyPromoted,
                          promotedCount: promotedCount,
                          graduatedCount: graduatedCount,
                          adultKeptCount: adultKeptCount,
                          candidateCount: candidates.length,
                          onTypeChanged: (val) {
                            setState(() {
                              _selectedType = val;
                              _retainPlayerIds.clear();
                            });
                          },
                          onGraduationYearChanged: (val) {
                            setState(() => _graduationFiscalYear = val);
                          },
                        );
                      }

                      if (candidates.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: context.appColors.inputBackground,
                              borderRadius: AppRadius.medium,
                            ),
                            child: Text(
                              activeType.graduationGrade == null
                                  ? '「一貫道場・全年齢」では卒業アーカイブは行われず、大学4年後は一般へ進級します。'
                                  : '現在の名簿に卒業対象となる学年の選手はいません。',
                              style: TextStyle(
                                fontSize: AppFontSize.bodySmall,
                                color: context.appColors.subTextColor,
                              ),
                            ),
                          ),
                        );
                      }

                      final candidate = candidates[index - 1];
                      final isRetained = _retainPlayerIds.contains(
                        candidate.id,
                      );
                      final nextGradeName = PlayerModel(
                        id: '',
                        lastName: '',
                        firstName: '',
                        lastNameKana: '',
                        firstNameKana: '',
                        grade: candidate.grade >= 16 ? 99 : candidate.grade + 1,
                      ).gradeName;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Material(
                          color: context.appColors.inputBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                            side: BorderSide(
                              color: isRetained
                                  ? primaryColor
                                  : context.appColors.separatorColor,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SwitchListTile.adaptive(
                            value: isRetained,
                            activeTrackColor: primaryColor,
                            onChanged: (val) {
                              setState(() {
                                if (val) {
                                  _retainPlayerIds.add(candidate.id);
                                } else {
                                  _retainPlayerIds.remove(candidate.id);
                                }
                              });
                            },
                            title: Text(
                              candidate.name,
                              style: TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.bodyMedium,
                                color: context.appColors.textColor,
                              ),
                            ),
                            subtitle: Text(
                              isRetained
                                  ? '例外残留：現役のまま「$nextGradeName」へ進級'
                                  : '${candidate.gradeName} ➔ $_graduationFiscalYear年度卒（OB/OG）',
                              style: TextStyle(
                                fontSize: AppFontSize.small,
                                color: isRetained
                                    ? primaryColor
                                    : context.appColors.subTextColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text('キャンセル'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSubmitting ||
                                  (promotedCount == 0 && graduatedCount == 0)
                              ? null
                              : () => _handleConfirmAndRun(
                                  type: activeType,
                                  promotionFiscalYear: promotionFiscalYear,
                                  alreadyPromoted: alreadyPromoted,
                                  promotedCount: promotedCount,
                                  graduatedCount: graduatedCount,
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: alreadyPromoted
                                ? context.appColors.warningColor
                                : primaryColor,
                            foregroundColor: AppKendoColors.pureWhite,
                            shape: const StadiumBorder(),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppKendoColors.pureWhite,
                                  ),
                                )
                              : const Icon(Icons.school, size: 18),
                          label: Text(
                            alreadyPromoted ? '再実行を確認' : '一括進級を実行',
                            style: const TextStyle(
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
