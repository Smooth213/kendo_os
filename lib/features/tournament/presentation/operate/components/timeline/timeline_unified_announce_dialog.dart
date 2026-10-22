import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_announce_court_picker.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_announce_input_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_announce_quick_chips.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_target_chip.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// タイムライン用 公式アナウンス・コメントの一斉発信シート
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
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
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
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  String selectedTarget = 'all';

  // 🏟️ 試合会場・試合順Picker状態
  int? _fromCourt;
  int? _fromOrder;
  int? _toCourt;
  int? _toOrder;
  bool _hasDestination = false;

  // ⌫ タイトル変更履歴（バックスペース不要のアンドゥ用）
  final List<String> _titleHistory = [];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    bodyController = TextEditingController();
    _titleFocusNode.addListener(_onFocusChange);
    _bodyFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _saveHistory() {
    _titleHistory.add(titleController.text);
    if (_titleHistory.length > 20) {
      _titleHistory.removeAt(0);
    }
  }

  void _onUndo() {
    if (_titleHistory.isNotEmpty) {
      final prev = _titleHistory.removeLast();
      titleController.text = prev;
      setState(() {});
    }
  }

  String? _lastAppliedHeading;

  void _onClearTitle() {
    _saveHistory();
    titleController.clear();
    _lastAppliedHeading = null;
    setState(() {});
  }

  void _updateHeadingRealtime() {
    final newHeading = TimelineAnnounceCourtPicker.formatHeading(
      fromCourt: _fromCourt,
      fromOrder: _fromOrder,
      toCourt: _toCourt,
      toOrder: _toOrder,
      hasDestination: _hasDestination,
    );

    final currentBody = bodyController.text;

    // 前回の見出しが本文内に含まれているなら、その部分だけを最新値に即時置換！
    if (_lastAppliedHeading != null && _lastAppliedHeading!.isNotEmpty) {
      if (currentBody.contains(_lastAppliedHeading!)) {
        if (newHeading.isNotEmpty) {
          bodyController.text = currentBody.replaceFirst(
            _lastAppliedHeading!,
            newHeading,
          );
        } else {
          bodyController.text = currentBody
              .replaceFirst(_lastAppliedHeading!, '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }
        _lastAppliedHeading = newHeading.isEmpty ? null : newHeading;
        setState(() {});
        return;
      }
    }

    if (newHeading.isEmpty) {
      setState(() {});
      return;
    }

    // 初回または前回の見出しが見つからない場合は、本文の先頭または既存パターンを置換
    final comprehensiveRegex = RegExp(
      r'(?:第\s*\d+\s*(?:試合場|会場|コート))?\s*(?:(?:\d+)\s*試合目|第\s*\d+\s*試合(?!場|会場))?'
      r'(?:\s*(?:➔|->|→)\s*(?:第\s*\d+\s*(?:試合場|会場|コート))?\s*(?:(?:\d+)\s*試合目|第\s*\d+\s*試合(?!場|会場))?)?',
    );
    final trimmedBody = currentBody.trim();
    final match = comprehensiveRegex.stringMatch(trimmedBody);
    if (trimmedBody.isNotEmpty && match != null && match.trim().isNotEmpty) {
      bodyController.text = trimmedBody.replaceFirst(
        comprehensiveRegex,
        newHeading,
      );
    } else if (trimmedBody.isEmpty) {
      bodyController.text = newHeading;
    } else {
      bodyController.text = '$newHeading $trimmedBody';
    }

    _lastAppliedHeading = newHeading;
    setState(() {});
  }

  void _onChipSelected(String chipText) {
    _saveHistory();
    // コート移動や試合順変更のチップの場合は、会場Pickerの変更先スロットも開く
    if (chipText == 'コート移動' || chipText == '会場変更' || chipText == '試合順変更') {
      if (!_hasDestination) {
        _hasDestination = true;
      }
    }

    // タイトルを自動で【〇〇】形式に整形
    final currentTitle = titleController.text.trim();
    final isPriorityChip = chipText.startsWith('【') && chipText.endsWith('】');

    if (isPriorityChip) {
      // 【緊急】や【重要】など重要度プレフィックスの場合
      final rawTitle = currentTitle.replaceAll(RegExp(r'【.*?】\s*'), '');
      titleController.text = rawTitle.isEmpty
          ? chipText
          : '$chipText $rawTitle';
    } else {
      // 通常のチップ（昼休憩、コート移動など）の場合、自動で【】をつける
      final priorityMatch = RegExp(r'^(【.*?】)').firstMatch(currentTitle);
      if (priorityMatch != null) {
        titleController.text = '${priorityMatch.group(1)} $chipText';
      } else {
        titleController.text = '【$chipText】';
      }

      // 昼休憩・休憩のときは本文が空ならデフォルト文言を親切に補完
      if (chipText == '昼休憩' && bodyController.text.trim().isEmpty) {
        bodyController.text = '昼休憩に入ります。';
      } else if (chipText == '休憩' && bodyController.text.trim().isEmpty) {
        bodyController.text = '休憩に入ります。';
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onFocusChange);
    _bodyFocusNode.removeListener(_onFocusChange);
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
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
    final cardBgColor = isDark
        ? const Color(0xFF1C1C1E)
        : context.appColors.cardBackground;

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight = (screenHeight - keyboardHeight).clamp(
      0.0,
      screenHeight,
    );
    final maxSheetHeight = availableHeight * 0.90;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlargeValue),
          ),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ドラッグハンドルバー
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.2)
                        : const Color(0x33000000),
                    borderRadius: AppRadius.medium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // ヘッダー行
              Row(
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
              const SizedBox(height: AppSpacing.xs),

              // 🏟️ 1. 試合会場・試合順Picker（段階的展開）
              TimelineAnnounceCourtPicker(
                fromCourt: _fromCourt,
                fromOrder: _fromOrder,
                toCourt: _toCourt,
                toOrder: _toOrder,
                hasDestination: _hasDestination,
                isDark: isDark,
                onFromCourtChanged: (v) {
                  _fromCourt = v;
                  _updateHeadingRealtime();
                },
                onFromOrderChanged: (v) {
                  _fromOrder = v;
                  _updateHeadingRealtime();
                },
                onToCourtChanged: (v) {
                  _toCourt = v;
                  _updateHeadingRealtime();
                },
                onToOrderChanged: (v) {
                  _toOrder = v;
                  _updateHeadingRealtime();
                },
                onToggleDestination: () {
                  setState(() {
                    _hasDestination = !_hasDestination;
                    if (!_hasDestination) {
                      _toCourt = null;
                      _toOrder = null;
                    }
                  });
                  _updateHeadingRealtime();
                },
                onClearAll: () {
                  _saveHistory();
                  if (_lastAppliedHeading != null) {
                    bodyController.text = bodyController.text
                        .replaceFirst(_lastAppliedHeading!, '')
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim();
                    _lastAppliedHeading = null;
                  }
                  setState(() {
                    _fromCourt = null;
                    _fromOrder = null;
                    _toCourt = null;
                    _toOrder = null;
                    _hasDestination = false;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              // 🏷️ 2. クイック入力チップ（横並びカテゴリタブ ＆ アコーディオン開閉）
              TimelineAnnounceQuickChips(
                isDark: isDark,
                onChipSelected: _onChipSelected,
              ),
              const SizedBox(height: AppSpacing.xs),

              // 📝 3. タイトル・本文入力セクション（Undo ＆ Clearボタン付き）
              TimelineAnnounceInputSection(
                titleController: titleController,
                bodyController: bodyController,
                titleFocusNode: _titleFocusNode,
                bodyFocusNode: _bodyFocusNode,
                hasHistory: _titleHistory.isNotEmpty,
                onUndo: _onUndo,
                onClearTitle: _onClearTitle,
                themeColors: themeColors,
              ),
              const SizedBox(height: AppSpacing.sm),

              // 通知範囲選択チップ
              TimelineAnnounceTargetSelector(
                selectedTarget: selectedTarget,
                isDark: isDark,
                onTargetChanged: (val) => setState(() => selectedTarget = val),
              ),
              const SizedBox(height: AppSpacing.sm),

              // アクションボタン（キャンセル / 保存ボタン）
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.small,
                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    String title = titleController.text.trim();
    final String body = bodyController.text.trim();
    if (body.isEmpty && title.isEmpty) return;

    // タイトル空欄時の自動見出し補完（会場・試合順が含まれる場合は専用見出し）
    if (title.isEmpty) {
      if (body.contains('試合場') || body.contains('試合目')) {
        title = '【会場・進行連絡】';
      }
    }

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
      await TimelineAnnounceSender.send(
        // ignore: use_build_context_synchronously
        parentContext: parentCtx,
        ref: ref,
        tournamentId: tournamentId,
        category: category,
        groupName: groupName,
        matchGroupId: matchGroupId,
        order: order,
        title: title,
        body: body,
        target: currentTarget,
      );
    });
  }
}
