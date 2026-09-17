import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_number_block.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_wheel_picker.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// ⏱️ タイマー表示カードの動作モード
enum TimerCardInputMode { normal, editMinutes, editSeconds, wheelPicker }

/// ⏱️ 分・秒セパレート直接手入力 ＆ 長押しその場ドラムロール変形 特大デジタルタイマーカード
class DockTimerDisplayCard extends StatefulWidget {
  final DockTimerState timerState;
  final bool isRunning;
  final bool isStopwatch;
  final bool isDark;
  final AppThemeColors themeColors;
  final void Function(int minutes, int seconds) onTimeChanged;

  const DockTimerDisplayCard({
    super.key,
    required this.timerState,
    required this.isRunning,
    required this.isStopwatch,
    required this.isDark,
    required this.themeColors,
    required this.onTimeChanged,
  });

  @override
  State<DockTimerDisplayCard> createState() => _DockTimerDisplayCardState();
}

class _DockTimerDisplayCardState extends State<DockTimerDisplayCard> {
  TimerCardInputMode _inputMode = TimerCardInputMode.normal;

  late TextEditingController _minTextController;
  late TextEditingController _secTextController;
  late FocusNode _minFocusNode;
  late FocusNode _secFocusNode;

  late FixedExtentScrollController _minScrollController;
  late FixedExtentScrollController _secScrollController;

  late int _wheelMinutes;
  late int _wheelSeconds;

  @override
  void initState() {
    super.initState();
    final totalSec = widget.timerState.remainingSeconds;
    _wheelMinutes = (totalSec ~/ 60).clamp(0, 59);
    _wheelSeconds = (totalSec % 60).clamp(0, 59);
    _minTextController = TextEditingController(
      text: _wheelMinutes.toString().padLeft(2, '0'),
    );
    _secTextController = TextEditingController(
      text: _wheelSeconds.toString().padLeft(2, '0'),
    );
    _minFocusNode = FocusNode();
    _secFocusNode = FocusNode();
    _minFocusNode.addListener(_onFocusChange);
    _secFocusNode.addListener(_onFocusChange);
    _minScrollController = FixedExtentScrollController(
      initialItem: _wheelMinutes,
    );
    _secScrollController = FixedExtentScrollController(
      initialItem: _wheelSeconds,
    );
  }

  void _onFocusChange() {
    if (!mounted) return;
    if (!_minFocusNode.hasFocus && !_secFocusNode.hasFocus) {
      if (_inputMode == TimerCardInputMode.editMinutes ||
          _inputMode == TimerCardInputMode.editSeconds) {
        _commitTextEditing();
      }
    }
  }

  @override
  void didUpdateWidget(covariant DockTimerDisplayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_inputMode == TimerCardInputMode.normal) {
      final totalSec = widget.timerState.remainingSeconds;
      _wheelMinutes = (totalSec ~/ 60).clamp(0, 59);
      _wheelSeconds = (totalSec % 60).clamp(0, 59);
      _minTextController.text = _wheelMinutes.toString().padLeft(2, '0');
      _secTextController.text = _wheelSeconds.toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _minFocusNode.removeListener(_onFocusChange);
    _secFocusNode.removeListener(_onFocusChange);
    _minTextController.dispose();
    _secTextController.dispose();
    _minFocusNode.dispose();
    _secFocusNode.dispose();
    _minScrollController.dispose();
    _secScrollController.dispose();
    super.dispose();
  }

  void _startEditing(bool isMinutes) {
    if (widget.isRunning || widget.isStopwatch) return;

    // 切り替え前の入力内容を安全に反映
    if (_inputMode == TimerCardInputMode.editMinutes ||
        _inputMode == TimerCardInputMode.editSeconds) {
      final currentTotal = widget.timerState.remainingSeconds;
      final m = int.tryParse(_minTextController.text) ?? (currentTotal ~/ 60);
      final s = int.tryParse(_secTextController.text) ?? (currentTotal % 60);
      widget.onTimeChanged(m.clamp(0, 59), s.clamp(0, 59));
    }

    AppHaptics.selection();
    final targetFocus = isMinutes ? _minFocusNode : _secFocusNode;
    final controller = isMinutes ? _minTextController : _secTextController;
    controller.clear();
    targetFocus.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
    setState(() {
      _inputMode = isMinutes
          ? TimerCardInputMode.editMinutes
          : TimerCardInputMode.editSeconds;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !targetFocus.hasFocus) {
        targetFocus.requestFocus();
      }
    });
  }

  void _onTextChanged() {
    if (widget.isRunning || widget.isStopwatch) return;
    final m = int.tryParse(_minTextController.text);
    final s = int.tryParse(_secTextController.text);
    if (m != null || s != null) {
      final currentTotal = widget.timerState.remainingSeconds;
      final newM = (m ?? (currentTotal ~/ 60)).clamp(0, 59);
      final newS = (s ?? (currentTotal % 60)).clamp(0, 59);
      if (newM > 0 || newS > 0) {
        widget.onTimeChanged(newM, newS);
      }
    }
  }

  void _commitTextEditing() {
    if (!widget.isRunning && !widget.isStopwatch) {
      final currentTotal = widget.timerState.remainingSeconds;
      final m = int.tryParse(_minTextController.text) ?? (currentTotal ~/ 60);
      final s = int.tryParse(_secTextController.text) ?? (currentTotal % 60);
      final clampedM = m.clamp(0, 59);
      final clampedS = s.clamp(0, 59);
      _minTextController.text = clampedM.toString().padLeft(2, '0');
      _secTextController.text = clampedS.toString().padLeft(2, '0');
      widget.onTimeChanged(clampedM, clampedS);
    }
    if (mounted) {
      setState(() {
        _inputMode = TimerCardInputMode.normal;
      });
    }
    _minFocusNode.unfocus();
    _secFocusNode.unfocus();
  }

  void _startWheelMode() {
    if (widget.isRunning || widget.isStopwatch) return;
    AppHaptics.medium();
    final totalSec = widget.timerState.remainingSeconds;
    _wheelMinutes = (totalSec ~/ 60).clamp(0, 59);
    _wheelSeconds = (totalSec % 60).clamp(0, 59);
    setState(() => _inputMode = TimerCardInputMode.wheelPicker);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_minScrollController.hasClients) {
        _minScrollController.jumpToItem(_wheelMinutes);
      }
      if (_secScrollController.hasClients) {
        _secScrollController.jumpToItem(_wheelSeconds);
      }
    });
  }

  void _commitWheelMode() {
    AppHaptics.selection();
    widget.onTimeChanged(_wheelMinutes, _wheelSeconds);
    setState(() => _inputMode = TimerCardInputMode.normal);
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = widget.timerState.isFinished;
    final isRunning = widget.isRunning;
    final themeColors = widget.themeColors;
    final isEditing = _inputMode != TimerCardInputMode.normal;

    return Center(
      child: GestureDetector(
        onLongPress: _startWheelMode,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isFinished
                ? AppKendoColors.hansokuRed.withValues(alpha: 0.15)
                : themeColors.cardBackground,
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isFinished
                  ? AppKendoColors.hansokuRed
                  : (isRunning || isEditing
                        ? AppKendoColors.orangeAccent
                        : themeColors.separatorColor.withValues(alpha: 0.4)),
              width: (isRunning || isEditing) ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFinished)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '⏰ TIME UP !',
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.hansokuRed,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _inputMode == TimerCardInputMode.wheelPicker
                    ? _buildWheelPickerContent()
                    : _buildDigitalDisplayContent(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _buildGuideText(),
              ),
              if (!widget.isStopwatch)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.small,
                    child: LinearProgressIndicator(
                      value: widget.timerState.progress,
                      minHeight: 6,
                      backgroundColor: themeColors.separatorColor.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFinished
                            ? AppKendoColors.hansokuRed
                            : AppKendoColors.orangeAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalDisplayContent() {
    final parts = widget.timerState.formattedDisplay.split(':');
    final minStr = parts.isNotEmpty ? parts[0] : '00';
    final secStr = parts.length > 1 ? parts[1] : '00';
    final color = widget.timerState.isFinished
        ? AppKendoColors.hansokuRed
        : (widget.isRunning
              ? AppKendoColors.orangeAccent
              : widget.themeColors.textColor);

    return Row(
      key: const ValueKey('digital_display'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DockTimerNumberBlock(
          text: minStr,
          controller: _minTextController,
          focusNode: _minFocusNode,
          isEditing: _inputMode == TimerCardInputMode.editMinutes,
          isMinutes: true,
          isRunning: widget.isRunning,
          isStopwatch: widget.isStopwatch,
          color: color,
          themeColors: widget.themeColors,
          onTap: () => _startEditing(true),
          onTextChanged: _onTextChanged,
          onSubmitted: () => _startEditing(false),
        ),
        Text(
          ' : ',
          style: TextStyle(
            fontSize: AppFontSize.scoreboardTimer,
            fontWeight: AppFontWeight.bold,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
        DockTimerNumberBlock(
          text: secStr,
          controller: _secTextController,
          focusNode: _secFocusNode,
          isEditing: _inputMode == TimerCardInputMode.editSeconds,
          isMinutes: false,
          isRunning: widget.isRunning,
          isStopwatch: widget.isStopwatch,
          color: color,
          themeColors: widget.themeColors,
          onTap: () => _startEditing(false),
          onTextChanged: _onTextChanged,
          onSubmitted: _commitTextEditing,
        ),
        if (_inputMode == TimerCardInputMode.editMinutes ||
            _inputMode == TimerCardInputMode.editSeconds) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: _commitTextEditing,
            icon: const Icon(
              Icons.check_circle,
              color: AppKendoColors.orangeAccent,
              size: 28,
            ),
            tooltip: '確定',
          ),
        ],
      ],
    );
  }

  Widget _buildWheelPickerContent() {
    return DockTimerWheelPicker(
      themeColors: widget.themeColors,
      minScrollController: _minScrollController,
      secScrollController: _secScrollController,
      onMinutesChanged: (v) {
        _wheelMinutes = v;
        AppHaptics.selection();
      },
      onSecondsChanged: (v) {
        _wheelSeconds = v;
        AppHaptics.selection();
      },
      onCommit: _commitWheelMode,
    );
  }

  Widget _buildGuideText() {
    if (widget.isRunning || widget.isStopwatch) return const SizedBox.shrink();
    final text = switch (_inputMode) {
      TimerCardInputMode.editMinutes => '分を入力して確定（または秒をタップ）',
      TimerCardInputMode.editSeconds => '秒を入力して確定（または分をタップ）',
      TimerCardInputMode.wheelPicker => 'ダイヤルを回して「完了」をタップ',
      TimerCardInputMode.normal => 'タップで手入力 ｜ 長押しでダイヤル',
    };
    return Text(
      text,
      style: TextStyle(
        fontSize: AppFontSize.micro,
        color: _inputMode == TimerCardInputMode.normal
            ? widget.themeColors.subTextColor
            : AppKendoColors.orangeAccent,
        fontWeight: AppFontWeight.bold,
      ),
    );
  }
}
