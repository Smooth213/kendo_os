import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_calendar_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_matches_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_standings_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_dock_calculator_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_animated_dock_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_gesture_detector.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_dock_items_order_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 部内戦専用フローティングドックボタン（画面上iPhone風ジグル並び替え・大会ホーム統一サイズ）
class BunaiksenDockButton extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isViewerMode;
  final bool initialDockedLeft;

  const BunaiksenDockButton({
    super.key,
    required this.tournamentId,
    this.isViewerMode = false,
    this.initialDockedLeft = false,
  });

  @override
  ConsumerState<BunaiksenDockButton> createState() =>
      _BunaiksenDockButtonState();
}

class _BunaiksenDockButtonState extends ConsumerState<BunaiksenDockButton>
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
  List<BunaiksenDockItemType>? _localItemsOrder;

  late AnimationController _expandAnimationController;
  late Animation<double> _expandAnimation;
  late AnimationController _jiggleController;
  bool _isInsideSheet = false;

  @override
  void initState() {
    super.initState();
    _isLeft = widget.initialDockedLeft;

    _expandAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandAnimationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _expandAnimationController.addStatusListener((status) {
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
    _expandAnimationController.dispose();
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
      _expandAnimationController.forward(from: 0.0);
    }
  }

  void _collapse() {
    if (_isEditMode) _endEditMode();
    if (_isExpanded) {
      _expandAnimationController.reverse().then((_) {
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
      _localItemsOrder = List<BunaiksenDockItemType>.from(
        ref.read(bunaiksenDockItemsOrderProvider),
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
      ref
          .read(bunaiksenDockItemsOrderProvider.notifier)
          .updateOrder(_localItemsOrder!);
    }
  }

  void _onItemTap(BunaiksenDockItemType item) {
    if (_isEditMode) return;
    _collapse();
    AppHaptics.light();

    switch (item) {
      case BunaiksenDockItemType.matches:
        BunaiksenDockMatchesSheet.show(
          context,
          tournamentId: widget.tournamentId,
        );
        break;
      case BunaiksenDockItemType.standings:
        BunaiksenDockStandingsSheet.show(
          context,
          tournamentId: widget.tournamentId,
        );
        break;
      case BunaiksenDockItemType.calendar:
        BunaiksenDockCalendarSheet.show(context);
        break;
      case BunaiksenDockItemType.quickMemo:
        QuickMemoBottomSheet.show(context, tournamentId: widget.tournamentId);
        break;
      case BunaiksenDockItemType.timer:
        DockTimerBottomSheet.show(context);
        break;
      case BunaiksenDockItemType.calculator:
        BunaiksenDockCalculatorSheet.show(context);
        break;
      case BunaiksenDockItemType.viewerQr:
        ViewerQrBottomSheet.show(
          context,
          tournamentId: widget.tournamentId,
          isViewerMode: widget.isViewerMode,
        );
        break;
      case BunaiksenDockItemType.settings:
        FloatingDockSheetManager.show(
          context: context,
          builder: (_) => SettingsScreen(
            isBottomSheet: true,
            onFullScreen: () {
              FloatingDockSheetManager.close(immediate: true);
              context.push('/settings');
            },
          ),
        );
        break;
    }
  }

  void _onItemPanUpdate({
    required int index,
    required DragUpdateDetails details,
    required bool isVertical,
    required double dirX,
    required double dirY,
    required int itemCount,
  }) {
    if (_itemDraggingIndex == null) return;
    setState(() {
      _itemDragDelta += details.delta;
      final curSlot = DockSlotLayoutCalculator.getBunaiksenSlotOffset(
        index: _itemDraggingIndex!,
        isVertical: isVertical,
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
            DockSlotLayoutCalculator.getBunaiksenSlotOffset(
              index: idx,
              isVertical: isVertical,
              dirX: dirX,
              dirY: dirY,
              step: _itemStep,
            ),
      );

      if (target != null) {
        final list = List<BunaiksenDockItemType>.from(
          _localItemsOrder ?? ref.read(bunaiksenDockItemsOrderProvider),
        );
        final moved = list.removeAt(_itemDraggingIndex!);
        list.insert(target, moved);
        _localItemsOrder = list;

        final targetSlot = DockSlotLayoutCalculator.getBunaiksenSlotOffset(
          index: target,
          isVertical: isVertical,
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
    if (widget.isViewerMode) return const SizedBox.shrink();
    final role = ref.watch(currentUserRoleProvider);
    if (role == UserRole.viewer || _isInsideSheet) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final globalOrder = ref.watch(bunaiksenDockItemsOrderProvider);
    final activeOrder = _isEditMode && _localItemsOrder != null
        ? _localItemsOrder!
        : globalOrder;
    final timerState = ref.watch(dockTimerProvider);

    final double buttonX = _isLeft
        ? (_isDocked ? -(_buttonSize - _dockedVisibleWidth) : AppSpacing.sm)
        : (_isDocked
              ? screenSize.width - _dockedVisibleWidth
              : screenSize.width - _buttonSize - AppSpacing.sm);

    final double buttonY = (_yOffset * screenSize.height - _buttonSize / 2)
        .clamp(screenSize.height * 0.15, screenSize.height * 0.85);

    final isNearBottom = _yOffset > 0.65;
    final isVerticalMode = !isNearBottom;
    final double dirX = _isLeft ? 1.0 : -1.0;
    final double dirY = _yOffset < 0.5 ? 1.0 : -1.0;

    if (!_isExpanded && _expandAnimationController.isDismissed) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        left: buttonX,
        top: buttonY,
        child: DockParentGestureDetector(
          isDark: isDark,
          themeColors: themeColors,
          timerBadge: timerState.isRunning ? timerState.formattedDisplay : null,
          buttonSize: _buttonSize,
          closeButtonSize: _closeButtonSize,
          isDocked: _isDocked,
          isLeft: _isLeft,
          yOffset: _yOffset,
          onTap: () {
            if (_isDocked) {
              setState(() => _isDocked = false);
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
                animation: _expandAnimation,
                builder: (context, _) => Container(
                  color: AppKendoColors.pureBlack.withValues(
                    alpha: 0.35 * _expandAnimation.value,
                  ),
                ),
              ),
            ),
          ),
          for (int i = 0; i < activeOrder.length; i++)
            BunaiksenAnimatedDockItem(
              index: i,
              item: activeOrder[i],
              buttonX: buttonX,
              buttonY: buttonY,
              itemStep: _itemStep,
              isVertical: isVerticalMode,
              dirX: dirX,
              dirY: dirY,
              themeColors: themeColors,
              isDark: isDark,
              itemCount: activeOrder.length,
              expandAnimation: _expandAnimation,
              jiggleController: _jiggleController,
              isEditMode: _isEditMode,
              isDragging: _itemDraggingIndex == i,
              dragDelta: _itemDraggingIndex == i ? _itemDragDelta : Offset.zero,
              isTimerRunning: timerState.isRunning,
              onTap: () => _onItemTap(activeOrder[i]),
              onLongPress: _startEditMode,
              onPanStart: () {
                setState(() {
                  _itemDraggingIndex = i;
                  _itemDragDelta = Offset.zero;
                });
              },
              onPanUpdate: (d) => _onItemPanUpdate(
                index: i,
                details: d,
                isVertical: isVerticalMode,
                dirX: dirX,
                dirY: dirY,
                itemCount: activeOrder.length,
              ),
              onPanEnd: () {
                setState(() {
                  _itemDraggingIndex = null;
                  _itemDragDelta = Offset.zero;
                });
                if (_localItemsOrder != null) {
                  ref
                      .read(bunaiksenDockItemsOrderProvider.notifier)
                      .updateOrder(_localItemsOrder!);
                }
              },
            ),
          Positioned(
            left: buttonX + ((_buttonSize - _closeButtonSize) / 2),
            top: buttonY + ((_buttonSize - _closeButtonSize) / 2),
            child: DockParentButton(
              isDark: isDark,
              themeColors: themeColors,
              unreadCount: 0,
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
      ),
    );
  }
}
