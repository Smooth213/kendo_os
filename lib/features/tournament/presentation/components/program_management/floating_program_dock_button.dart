import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_gesture_detector.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_items_builder.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_items_order_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 大会ホーム用フローティングドックボタン（画面上iPhone風ジグル並び替え対応）
class FloatingProgramDockButton extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isViewerMode;
  final bool initialDockedLeft;

  const FloatingProgramDockButton({
    super.key,
    required this.tournamentId,
    this.isViewerMode = false,
    this.initialDockedLeft = false,
  });

  @override
  ConsumerState<FloatingProgramDockButton> createState() =>
      _FloatingProgramDockButtonState();
}

class _FloatingProgramDockButtonState
    extends ConsumerState<FloatingProgramDockButton>
    with TickerProviderStateMixin {
  static const double _buttonSize = 58.0;
  static const double _closeButtonSize = 46.0;
  static const double _dockedVisibleWidth = 20.0;
  static const double _itemStep = 66.0;

  bool _isDocked = false;
  late bool _isLeft;
  double _yOffset = 0.70;

  bool _isExpanded = false;
  bool _isEditMode = false;
  int? _itemDraggingIndex;
  Offset _itemDragDelta = Offset.zero;
  List<DockItemType>? _localItemsOrder;

  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  late AnimationController _jiggleController;
  bool _isInsideSheet = false;

  @override
  void initState() {
    super.initState();
    _isLeft = widget.initialDockedLeft;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _isExpanded) {
        setState(() {
          _isExpanded = false;
          _isEditMode = false;
        });
      }
    });

    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isInsideSheet = DockSheetScope.of(context) != null;
  }

  @override
  void dispose() {
    if (!_isInsideSheet) {
      FloatingDockSheetManager.close(immediate: true);
    }
    _animController.dispose();
    _jiggleController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    AppHaptics.selection();
    if (_isExpanded) {
      if (_isEditMode) {
        _endEditMode();
      } else {
        _collapse();
      }
    } else {
      setState(() => _isExpanded = true);
      _animController.forward(from: 0.0);
    }
  }

  void _collapse() {
    if (_isEditMode) _endEditMode();
    if (_isExpanded) {
      _animController.reverse().then((_) {
        if (mounted && _isExpanded) {
          setState(() {
            _isExpanded = false;
            _isEditMode = false;
          });
        }
      });
    }
  }

  void _startEditMode() {
    if (_isEditMode) return;
    AppHaptics.medium();
    setState(() {
      _isEditMode = true;
      _localItemsOrder = List<DockItemType>.from(
        ref.read(dockItemsOrderProvider),
      );
    });
    _jiggleController.repeat();
  }

  void _endEditMode() {
    if (!_isEditMode) return;
    AppHaptics.light();
    _jiggleController.stop();
    setState(() {
      _isEditMode = false;
      _itemDraggingIndex = null;
      _itemDragDelta = Offset.zero;
    });
    if (_localItemsOrder != null) {
      ref.read(dockItemsOrderProvider.notifier).updateOrder(_localItemsOrder!);
    }
  }

  void _onItemPanUpdate({
    required int index,
    required DragUpdateDetails details,
    required DockLayoutMode layoutMode,
    required double dirX,
    required double dirY,
    required int itemCount,
  }) {
    if (_itemDraggingIndex == null) return;
    setState(() {
      _itemDragDelta += details.delta;
      final curSlot = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: _itemDraggingIndex!,
        layoutMode: layoutMode,
        dirX: dirX,
        dirY: dirY,
        step: _itemStep,
      );
      final currentPos = curSlot + _itemDragDelta;

      final target = DockSlotLayoutCalculator.findSwapTarget(
        currentPos: currentPos,
        currentDraggingIndex: _itemDraggingIndex!,
        itemCount: itemCount,
        step: _itemStep,
        slotOffsetGetter: (idx) =>
            DockSlotLayoutCalculator.getTournamentSlotOffset(
              index: idx,
              layoutMode: layoutMode,
              dirX: dirX,
              dirY: dirY,
              step: _itemStep,
            ),
      );

      if (target != null) {
        final list = List<DockItemType>.from(
          _localItemsOrder ?? ref.read(dockItemsOrderProvider),
        );
        final moved = list.removeAt(_itemDraggingIndex!);
        list.insert(target, moved);
        _localItemsOrder = list;

        final targetSlot = DockSlotLayoutCalculator.getTournamentSlotOffset(
          index: target,
          layoutMode: layoutMode,
          dirX: dirX,
          dirY: dirY,
          step: _itemStep,
        );
        _itemDragDelta = currentPos - targetSlot;
        _itemDraggingIndex = target;
        AppHaptics.selection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInsideSheet) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final screenSize = MediaQuery.of(context).size;

    final globalOrder = ref.watch(dockItemsOrderProvider);
    final activeOrder = _isEditMode && _localItemsOrder != null
        ? _localItemsOrder!
        : globalOrder;
    final timerState = ref.watch(dockTimerProvider);

    final double safeTop = MediaQuery.of(context).padding.top + 60.0;
    final double rawSafeBottom =
        screenSize.height - MediaQuery.of(context).padding.bottom - 100.0;
    final double safeBottom = rawSafeBottom < safeTop ? safeTop : rawSafeBottom;
    final double currentY = (_yOffset * screenSize.height).clamp(
      safeTop,
      safeBottom,
    );

    final double targetX = _isLeft
        ? (_isDocked ? -(_buttonSize - _dockedVisibleWidth) : AppSpacing.md)
        : (_isDocked
              ? screenSize.width - _dockedVisibleWidth
              : screenSize.width - _buttonSize - AppSpacing.md);

    final unreadAsync = ref.watch(
      unreadAnnouncementCountProvider((
        tournamentId: widget.tournamentId,
        isStaffRoom: !widget.isViewerMode,
      )),
    );
    final unreadCount = unreadAsync.valueOrNull ?? 0;
    final items = FloatingDockItemsBuilder.build(
      context: context,
      tournamentId: widget.tournamentId,
      isViewerMode: widget.isViewerMode,
      themeColors: themeColors,
      unreadCount: unreadCount,
      onCollapse: _collapse,
      onLongPress: _startEditMode,
      customOrder: activeOrder,
      timerDisplay: timerState.formattedDisplay,
      isTimerRunning: timerState.isRunning,
    );

    final double dirX = _isLeft ? 1.0 : -1.0;
    final double verticalRange = safeBottom - safeTop;
    final double normalizedY = verticalRange > 0
        ? ((currentY - safeTop) / verticalRange).clamp(0.0, 1.0)
        : 0.5;
    final double dirY = normalizedY < 0.5 ? 1.0 : -1.0;

    final double availableSpace = dirY < 0
        ? (currentY - safeTop)
        : (safeBottom - currentY);
    final double requiredSpace = items.length * _itemStep;
    final bool isNearEdge =
        (normalizedY < 0.20 || normalizedY > 0.80) ||
        (availableSpace < requiredSpace);
    final DockLayoutMode layoutMode = isNearEdge
        ? DockLayoutMode.lShape
        : DockLayoutMode.vertical;

    if (!_isExpanded && _animController.isDismissed) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        left: targetX,
        top: currentY,
        child: DockParentGestureDetector(
          isDark: isDark,
          themeColors: themeColors,
          unreadCount: unreadCount,
          timerBadge: timerState.isRunning ? timerState.formattedDisplay : null,
          buttonSize: _buttonSize,
          closeButtonSize: _closeButtonSize,
          isDocked: _isDocked,
          isLeft: _isLeft,
          yOffset: _yOffset,
          onTap: () {
            if (_isDocked) {
              setState(() => _isDocked = false);
            } else if (FloatingDockSheetManager.isOpen) {
              FloatingDockSheetManager.close();
            } else {
              _toggleExpand();
            }
          },
          onLongPress: () {
            if (!_isDocked) {
              _toggleExpand();
              _startEditMode();
            }
          },
          onPositionChanged: (newY, isLeft, isDocked) {
            setState(() {
              _yOffset = newY;
              _isLeft = isLeft;
              _isDocked = isDocked;
            });
          },
        ),
      );
    }

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isEditMode ? _endEditMode : _collapse,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) => Container(
                  color: AppKendoColors.pureBlack.withValues(
                    alpha: 0.28 * _animController.value,
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final progress = _expandAnimation.value;
              return Stack(
                children: [
                  for (int i = 0; i < items.length; i++)
                    DockSpeedDialItemWidget(
                      item: items[i],
                      index: i,
                      progress: progress,
                      originX: targetX,
                      originY: currentY,
                      dirX: dirX,
                      dirY: dirY,
                      isDark: isDark,
                      themeColors: themeColors,
                      layoutMode: layoutMode,
                      buttonSize: _buttonSize,
                      subSize: _buttonSize,
                      step: _itemStep,
                      isEditMode: _isEditMode,
                      isDragging: _itemDraggingIndex == i,
                      dragDelta: _itemDraggingIndex == i
                          ? _itemDragDelta
                          : Offset.zero,
                      jiggleAnimation: _jiggleController,
                      onPanStart: (_) {
                        setState(() {
                          _itemDraggingIndex = i;
                          _itemDragDelta = Offset.zero;
                        });
                      },
                      onPanUpdate: (details) => _onItemPanUpdate(
                        index: i,
                        details: details,
                        layoutMode: layoutMode,
                        dirX: dirX,
                        dirY: dirY,
                        itemCount: items.length,
                      ),
                      onPanEnd: (_) {
                        setState(() {
                          _itemDraggingIndex = null;
                          _itemDragDelta = Offset.zero;
                        });
                        if (_localItemsOrder != null) {
                          ref
                              .read(dockItemsOrderProvider.notifier)
                              .updateOrder(_localItemsOrder!);
                        }
                      },
                    ),
                  Positioned(
                    left:
                        targetX +
                        ((_buttonSize - _closeButtonSize) / 2 * progress),
                    top:
                        currentY +
                        ((_buttonSize - _closeButtonSize) / 2 * progress),
                    child: DockParentButton(
                      isDark: isDark,
                      themeColors: themeColors,
                      unreadCount: unreadCount,
                      isExpanded: true,
                      isDocked: false,
                      isEditMode: _isEditMode,
                      buttonSize: _buttonSize,
                      closeButtonSize: _closeButtonSize,
                      timerBadge: timerState.isRunning
                          ? timerState.formattedDisplay
                          : null,
                      onTap: () {
                        if (_isEditMode) {
                          _endEditMode();
                        } else {
                          _toggleExpand();
                        }
                      },
                      onLongPress: () {
                        if (!_isEditMode) _startEditMode();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
