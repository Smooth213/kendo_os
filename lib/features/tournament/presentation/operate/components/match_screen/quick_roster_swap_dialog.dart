import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 選手オーダー情報用内部クラス
class _RosterEntry {
  final MatchModel match;
  String playerName;
  final String teamPrefix;

  _RosterEntry({
    required this.match,
    required this.playerName,
    required this.teamPrefix,
  });
}

/// 【Phase 3: 指導者向け】「＝」ドラッグ＆ドロップによる瞬速ポジション並び替えシート
class QuickRosterSwapDialog extends ConsumerStatefulWidget {
  final MatchModel currentMatch;
  final List<MatchModel> teamMatches;
  final bool isRedSide;

  const QuickRosterSwapDialog({
    super.key,
    required this.currentMatch,
    required this.teamMatches,
    this.isRedSide = true,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel currentMatch,
    required List<MatchModel> teamMatches,
    bool isRedSide = true,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => QuickRosterSwapDialog(
        currentMatch: currentMatch,
        teamMatches: teamMatches,
        isRedSide: isRedSide,
      ),
    );
  }

  @override
  ConsumerState<QuickRosterSwapDialog> createState() =>
      _QuickRosterSwapDialogState();
}

class _QuickRosterSwapDialogState extends ConsumerState<QuickRosterSwapDialog> {
  late List<_RosterEntry> _entries;
  late List<String> _positionLabels;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final sorted = List<MatchModel>.from(widget.teamMatches)
      ..sort((a, b) => a.order.compareTo(b.order));

    _positionLabels = sorted.map((m) {
      return m.matchType.isNotEmpty
          ? m.matchType
          : '第${(m.order + 1).toInt()}試合';
    }).toList();

    _entries = sorted.map((match) {
      final rawName = widget.isRedSide ? match.redName : match.whiteName;
      final teamPrefix = rawName.contains(':')
          ? rawName.split(':').first.trim()
          : '';
      final playerName = rawName.contains(':')
          ? rawName.split(':').last.trim()
          : rawName.trim();

      return _RosterEntry(
        match: match,
        playerName: playerName,
        teamPrefix: teamPrefix,
      );
    }).toList();
  }

  Future<void> _handleSaveOrder() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final sorted = List<MatchModel>.from(widget.teamMatches)
        ..sort((a, b) => a.order.compareTo(b.order));

      for (int i = 0; i < sorted.length; i++) {
        final originalMatch = sorted[i];
        final newEntry = _entries[i];

        final newFullName = newEntry.teamPrefix.isNotEmpty
            ? '${newEntry.teamPrefix} : ${newEntry.playerName}'
            : newEntry.playerName;

        final updatedMatch = widget.isRedSide
            ? originalMatch.copyWith(redName: newFullName)
            : originalMatch.copyWith(whiteName: newFullName);

        await ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // loading pop
      Navigator.pop(context); // sheet pop
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = context.appColors.cardBackground;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    final sideName = widget.isRedSide ? '赤 (自チーム)' : '白 (相手チーム)';
    final sideColor = widget.isRedSide
        ? AppKendoColors.hansokuRed
        : (isDark ? AppKendoColors.pureWhite : AppKendoColors.black);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: subTextColor.withValues(alpha: 0.3),
                borderRadius: AppRadius.compact,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.swap_vert_circle_rounded, color: sideColor, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'オーダー並び替え ($sideName)',
                style: TextStyle(
                  fontSize: AppFontSize.header,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '右端の「＝」をドラッグして選手を希望のポジションへ並び替えてください。',
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false, // ★ 自前のドラッグハンドルを優先して明示的に描画
              itemCount: _entries.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _entries.removeAt(oldIndex);
                  _entries.insert(newIndex, item);
                });
              },
              itemBuilder: (context, idx) {
                final entry = _entries[idx];
                final posLabel = idx < _positionLabels.length
                    ? _positionLabels[idx]
                    : '第${idx + 1}試合';

                return Container(
                  key: ValueKey('roster_entry_${entry.match.id}_$idx'),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF38383A)
                          : context.appColors.separatorColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ポジションバッジ（先鋒、次鋒など）
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? context.appColors.textColor.withValues(
                                  alpha: 0.12,
                                )
                              : const Color(0xFFE5E5EA),
                          borderRadius: AppRadius.small,
                        ),
                        child: Text(
                          posLabel,
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // 選手名
                      Expanded(
                        child: Text(
                          entry.playerName.isNotEmpty
                              ? entry.playerName
                              : '（選手名なし）',
                          style: TextStyle(
                            fontSize: AppFontSize.bodyMedium,
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      // ★ 右端のドラッグハンドル「＝」（クッキリ表示＆タッチ領域確保）
                      ReorderableDragStartListener(
                        index: idx,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3A3A3C)
                                : const Color(0xFFE0E0E6),
                            borderRadius: AppRadius.small,
                          ),
                          child: Icon(
                            Icons.drag_handle, // ★ 確実な標準マテリアルアイコン
                            color: textColor.withValues(alpha: 0.85),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _handleSaveOrder,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'このオーダーで一括保存',
              style: TextStyle(
                fontSize: AppFontSize.bodyMedium,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppKendoColors.ipponGold,
              foregroundColor: AppKendoColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              elevation: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}
