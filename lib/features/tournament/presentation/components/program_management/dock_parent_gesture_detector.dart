import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 折りたたみ時ドック親ボタンのドラッグ移動＆ドッキング・タップ制御ラッパー
class DockParentGestureDetector extends StatefulWidget {
  final bool isDark;
  final AppThemeColors themeColors;
  final int unreadCount;
  final String? timerBadge;
  final double buttonSize;
  final double closeButtonSize;
  final bool isDocked;
  final bool isLeft;
  final double yOffset;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(double newYOffset, bool isLeft, bool isDocked)
  onPositionChanged;

  const DockParentGestureDetector({
    super.key,
    required this.isDark,
    required this.themeColors,
    this.unreadCount = 0,
    this.timerBadge,
    this.buttonSize = 58.0,
    this.closeButtonSize = 46.0,
    required this.isDocked,
    required this.isLeft,
    required this.yOffset,
    required this.onTap,
    required this.onLongPress,
    required this.onPositionChanged,
  });

  @override
  State<DockParentGestureDetector> createState() =>
      _DockParentGestureDetectorState();
}

class _DockParentGestureDetectorState extends State<DockParentGestureDetector> {
  double _horizontalDragDistance = 0.0;
  bool _isDragging = false;
  late bool _currentLeft;
  late bool _currentDocked;
  late double _currentYOffset;

  @override
  void initState() {
    super.initState();
    _currentLeft = widget.isLeft;
    _currentDocked = widget.isDocked;
    _currentYOffset = widget.yOffset;
  }

  @override
  void didUpdateWidget(DockParentGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _currentLeft = widget.isLeft;
      _currentDocked = widget.isDocked;
      _currentYOffset = widget.yOffset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        setState(() {
          _isDragging = true;
          _horizontalDragDistance = 0.0;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _currentYOffset =
              (_currentYOffset + details.delta.dy / screenSize.height).clamp(
                0.18,
                0.82,
              );
          _horizontalDragDistance += details.delta.dx;
          if (_currentLeft) {
            if (details.delta.dx < -5) _currentDocked = true;
            if (details.delta.dx > 5) _currentDocked = false;
          } else {
            if (details.delta.dx > 5) _currentDocked = true;
            if (details.delta.dx < -5) _currentDocked = false;
          }
        });
        widget.onPositionChanged(_currentYOffset, _currentLeft, _currentDocked);
      },
      onPanEnd: (details) {
        final vx = details.velocity.pixelsPerSecond.dx;
        setState(() {
          _isDragging = false;
          if (!_currentDocked) {
            if (!_currentLeft &&
                (vx < -200 || _horizontalDragDistance < -40.0)) {
              _currentLeft = true;
              AppHaptics.selection();
            } else if (_currentLeft &&
                (vx > 200 || _horizontalDragDistance > 40.0)) {
              _currentLeft = false;
              AppHaptics.selection();
            }
          }
          _horizontalDragDistance = 0.0;
        });
        widget.onPositionChanged(_currentYOffset, _currentLeft, _currentDocked);
      },
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: DockParentButton(
        isDark: widget.isDark,
        themeColors: widget.themeColors,
        unreadCount: widget.unreadCount,
        isExpanded: false,
        isDocked: _currentDocked,
        buttonSize: widget.buttonSize,
        closeButtonSize: widget.closeButtonSize,
        timerBadge: widget.timerBadge,
        onTap: widget.onTap,
      ),
    );
  }
}
