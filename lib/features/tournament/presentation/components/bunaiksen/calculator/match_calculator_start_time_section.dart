import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_quick_time_chips.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_time_dial_picker.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_time_digit_box.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// ⏱️ 開始予定時刻の入力モード（通常・時直接入力・分直接入力・ダイヤルホイール）
enum StartTimeInputMode { normal, editHour, editMinute, wheel }

/// 🥋 開始予定時刻設定セクション（直接入力 ＆ ダイヤルホイールのハイブリッド）
class MatchCalculatorStartTimeSection extends StatefulWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;
  final AppThemeColors themeColors;
  final bool isDark;

  const MatchCalculatorStartTimeSection({
    super.key,
    required this.settings,
    required this.notifier,
    required this.themeColors,
    required this.isDark,
  });

  @override
  State<MatchCalculatorStartTimeSection> createState() =>
      _MatchCalculatorStartTimeSectionState();
}

class _MatchCalculatorStartTimeSectionState
    extends State<MatchCalculatorStartTimeSection> {
  StartTimeInputMode _inputMode = StartTimeInputMode.normal;

  late TextEditingController _hourTextController;
  late TextEditingController _minuteTextController;
  late FocusNode _hourFocusNode;
  late FocusNode _minuteFocusNode;

  late FixedExtentScrollController _hourScrollController;
  late FixedExtentScrollController _minuteScrollController;

  @override
  void initState() {
    super.initState();
    final startTime = widget.settings.startTime;
    _hourTextController = TextEditingController(
      text: startTime.hour.toString().padLeft(2, '0'),
    );
    _minuteTextController = TextEditingController(
      text: startTime.minute.toString().padLeft(2, '0'),
    );
    _hourFocusNode = FocusNode();
    _minuteFocusNode = FocusNode();
    _hourFocusNode.addListener(_onFocusChange);
    _minuteFocusNode.addListener(_onFocusChange);

    _hourScrollController = FixedExtentScrollController(
      initialItem: startTime.hour,
    );
    _minuteScrollController = FixedExtentScrollController(
      initialItem: startTime.minute,
    );
  }

  void _onFocusChange() {
    if (!mounted) return;
    if (!_hourFocusNode.hasFocus && !_minuteFocusNode.hasFocus) {
      if (_inputMode == StartTimeInputMode.editHour ||
          _inputMode == StartTimeInputMode.editMinute) {
        _commitTextEditing();
      }
    }
  }

  @override
  void didUpdateWidget(covariant MatchCalculatorStartTimeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_inputMode == StartTimeInputMode.normal) {
      final startTime = widget.settings.startTime;
      _hourTextController.text = startTime.hour.toString().padLeft(2, '0');
      _minuteTextController.text = startTime.minute.toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _hourFocusNode.removeListener(_onFocusChange);
    _minuteFocusNode.removeListener(_onFocusChange);
    _hourTextController.dispose();
    _minuteTextController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    _hourScrollController.dispose();
    _minuteScrollController.dispose();
    super.dispose();
  }

  void _startEditing(bool isHour) {
    AppHaptics.selection();
    final targetFocus = isHour ? _hourFocusNode : _minuteFocusNode;
    final controller = isHour ? _hourTextController : _minuteTextController;
    controller.clear();
    targetFocus.requestFocus();
    setState(() {
      _inputMode = isHour
          ? StartTimeInputMode.editHour
          : StartTimeInputMode.editMinute;
    });
  }

  void _commitTextEditing() {
    final current = widget.settings.startTime;
    final h = int.tryParse(_hourTextController.text) ?? current.hour;
    final m = int.tryParse(_minuteTextController.text) ?? current.minute;
    final clampedH = h.clamp(0, 23);
    final clampedM = m.clamp(0, 59);

    _hourTextController.text = clampedH.toString().padLeft(2, '0');
    _minuteTextController.text = clampedM.toString().padLeft(2, '0');
    widget.notifier.updateStartTime(
      TimeOfDay(hour: clampedH, minute: clampedM),
    );

    if (mounted) {
      setState(() {
        _inputMode = StartTimeInputMode.normal;
      });
    }
    _hourFocusNode.unfocus();
    _minuteFocusNode.unfocus();
  }

  void _startWheelMode() {
    AppHaptics.medium();
    final current = widget.settings.startTime;
    setState(() => _inputMode = StartTimeInputMode.wheel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hourScrollController.hasClients) {
        _hourScrollController.jumpToItem(current.hour);
      }
      if (_minuteScrollController.hasClients) {
        _minuteScrollController.jumpToItem(current.minute);
      }
    });
  }

  void _commitWheelMode() {
    AppHaptics.selection();
    setState(() => _inputMode = StartTimeInputMode.normal);
  }

  void _onQuickTimeSelected(TimeOfDay tod) {
    AppHaptics.selection();
    widget.notifier.updateStartTime(tod);
    _hourTextController.text = tod.hour.toString().padLeft(2, '0');
    _minuteTextController.text = tod.minute.toString().padLeft(2, '0');
    if (_hourScrollController.hasClients) {
      _hourScrollController.jumpToItem(tod.hour);
    }
    if (_minuteScrollController.hasClients) {
      _minuteScrollController.jumpToItem(tod.minute);
    }
  }

  void _setStartTimeNow() {
    AppHaptics.selection();
    final now = DateTime.now();
    final newTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _onQuickTimeSelected(newTime);
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = widget.themeColors;
    final primaryAccent = themeColors.primaryAccent;
    final startTime = widget.settings.startTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー部
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '開始予定時刻',
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.medium,
                    color: themeColors.textColor,
                  ),
                ),
                Text(
                  _inputMode == StartTimeInputMode.wheel
                      ? 'ダイヤルを回して時刻を調整'
                      : '数字タップで直接入力 / 長押しでダイヤル',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: themeColors.subTextColor,
                  ),
                ),
              ],
            ),
            // ダイヤル切替ボタン
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _inputMode == StartTimeInputMode.wheel
                    ? _commitWheelMode
                    : _startWheelMode,
                borderRadius: AppRadius.capsule,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: _inputMode == StartTimeInputMode.wheel
                        ? primaryAccent.withValues(alpha: 0.15)
                        : themeColors.surface,
                    borderRadius: AppRadius.capsule,
                    border: Border.all(
                      color: _inputMode == StartTimeInputMode.wheel
                          ? primaryAccent
                          : themeColors.subTextColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _inputMode == StartTimeInputMode.wheel
                            ? Icons.check_circle_outline
                            : Icons.tune_rounded,
                        size: 14,
                        color: _inputMode == StartTimeInputMode.wheel
                            ? primaryAccent
                            : themeColors.textColor,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        _inputMode == StartTimeInputMode.wheel ? '完了' : 'ダイヤル',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          color: _inputMode == StartTimeInputMode.wheel
                              ? primaryAccent
                              : themeColors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 直接入力 ＆ ダイヤルのハイブリッド表示エリア
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _inputMode == StartTimeInputMode.wheel
              ? MatchCalculatorTimeDialPicker(
                  themeColors: themeColors,
                  primaryAccent: primaryAccent,
                  hourScrollController: _hourScrollController,
                  minuteScrollController: _minuteScrollController,
                  onHourChanged: (h) {
                    AppHaptics.selection();
                    final cur = widget.settings.startTime;
                    widget.notifier.updateStartTime(
                      TimeOfDay(hour: h, minute: cur.minute),
                    );
                    _hourTextController.text = h.toString().padLeft(2, '0');
                  },
                  onMinuteChanged: (m) {
                    AppHaptics.selection();
                    final cur = widget.settings.startTime;
                    widget.notifier.updateStartTime(
                      TimeOfDay(hour: cur.hour, minute: m),
                    );
                    _minuteTextController.text = m.toString().padLeft(2, '0');
                  },
                )
              : _buildDirectInputContent(themeColors, primaryAccent, startTime),
        ),

        const SizedBox(height: AppSpacing.xs),

        // クイック選択カプセル
        MatchCalculatorQuickTimeChips(
          startTime: startTime,
          isDark: widget.isDark,
          themeColors: themeColors,
          primaryAccent: primaryAccent,
          onTimeSelected: _onQuickTimeSelected,
          onCurrentTimeSelected: _setStartTimeNow,
        ),
      ],
    );
  }

  /// 直接入力用デジタル時計ブロック（タップでキーボード入力）
  Widget _buildDirectInputContent(
    AppThemeColors themeColors,
    Color primaryAccent,
    TimeOfDay startTime,
  ) {
    final hourStr = startTime.hour.toString().padLeft(2, '0');
    final minuteStr = startTime.minute.toString().padLeft(2, '0');

    return GestureDetector(
      onLongPress: _startWheelMode,
      child: Container(
        key: const ValueKey('direct_input_container'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: themeColors.subTextColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 時ブロック
            MatchCalculatorTimeDigitBox(
              text: hourStr,
              controller: _hourTextController,
              focusNode: _hourFocusNode,
              isEditing: _inputMode == StartTimeInputMode.editHour,
              isHour: true,
              label: '時',
              themeColors: themeColors,
              primaryAccent: primaryAccent,
              onTap: () => _startEditing(true),
              onLongPress: _startWheelMode,
              onChanged: (val) {
                if (val.length >= 2) {
                  _startEditing(false);
                }
              },
              onSubmitted: (_) => _startEditing(false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: AppFontSize.heroLarge,
                  fontWeight: AppFontWeight.bold,
                  fontFamily: 'monospace',
                  color: themeColors.textColor,
                ),
              ),
            ),
            // 分ブロック
            MatchCalculatorTimeDigitBox(
              text: minuteStr,
              controller: _minuteTextController,
              focusNode: _minuteFocusNode,
              isEditing: _inputMode == StartTimeInputMode.editMinute,
              isHour: false,
              label: '分',
              themeColors: themeColors,
              primaryAccent: primaryAccent,
              onTap: () => _startEditing(false),
              onLongPress: _startWheelMode,
              onChanged: (_) {},
              onSubmitted: (_) => _commitTextEditing(),
            ),
            if (_inputMode == StartTimeInputMode.editHour ||
                _inputMode == StartTimeInputMode.editMinute) ...[
              const SizedBox(width: AppSpacing.md),
              IconButton(
                onPressed: _commitTextEditing,
                icon: Icon(Icons.check_circle, color: primaryAccent, size: 26),
                tooltip: '確定',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
