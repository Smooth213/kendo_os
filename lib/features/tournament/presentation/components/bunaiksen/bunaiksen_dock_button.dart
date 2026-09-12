import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_calendar_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_items_reorder_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_matches_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_standings_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_sub_item_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_dock_items_order_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 部内戦専用フローティングドックボタン
/// 画面端に常駐し、タップでスピードダイヤル展開、長押しで並び替えボトムシートが起動。
/// 観戦専用ビュアー（Viewer）には一切描画されません。
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

  bool _isDocked = false;
  late bool _isLeft;
  bool _isDragging = false;
  double _yOffset = 0.70;
  double _horizontalDragDistance = 0.0;

  bool _isExpanded = false;
  late AnimationController _expandAnimationController;
  late Animation<double> _expandAnimation;

  // iPhone風 Wiggle（揺れる）アニメーション用
  late AnimationController _wiggleController;
  late Animation<double> _wiggleAnimation;
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
        setState(() => _isExpanded = false);
      }
    });

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _wiggleAnimation = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isInsideSheet = DockSheetScope.of(context) != null;
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    AppHaptics.selection();
    if (_isExpanded) {
      _wiggleController.stop();
      _expandAnimationController.reverse();
    } else {
      setState(() => _isExpanded = true);
      _expandAnimationController.forward();
    }
  }

  void _collapse() {
    if (_isExpanded) {
      _wiggleController.stop();
      _expandAnimationController.reverse().then((_) {
        if (mounted && _isExpanded) {
          setState(() => _isExpanded = false);
        }
      });
    }
  }

  void _onItemTap(BunaiksenDockItemType item) {
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

  void _onItemLongPress() {
    AppHaptics.heavy();
    _wiggleController.repeat(reverse: true);
    // iPhone風の並び替えボトムシートを起動
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _collapse();
        BunaiksenDockItemsReorderBottomSheet.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ ガバナンス第6条: 観戦専用ビュアー（Viewer）には100%非表示
    if (widget.isViewerMode) return const SizedBox.shrink();
    final role = ref.watch(currentUserRoleProvider);
    if (role == UserRole.viewer) return const SizedBox.shrink();

    // ボトムシートの内部にある場合は背景二重描画を防止
    if (_isInsideSheet) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final orderedItems = ref.watch(bunaiksenDockItemsOrderProvider);

    final double buttonX;
    if (_isDragging) {
      final base = _isLeft
          ? AppSpacing.sm
          : (screenSize.width - _buttonSize - AppSpacing.sm);
      buttonX = (base + _horizontalDragDistance).clamp(
        AppSpacing.sm,
        screenSize.width - _buttonSize - AppSpacing.sm,
      );
    } else if (_isDocked) {
      buttonX = _isLeft
          ? -(_buttonSize - _dockedVisibleWidth)
          : screenSize.width - _dockedVisibleWidth;
    } else {
      buttonX = _isLeft
          ? AppSpacing.sm
          : screenSize.width - _buttonSize - AppSpacing.sm;
    }

    final double buttonY = (_yOffset * screenSize.height - _buttonSize / 2)
        .clamp(screenSize.height * 0.15, screenSize.height * 0.85);

    final isNearBottom = _yOffset > 0.65;
    final isVerticalMode = !isNearBottom;

    // 折りたたみ時は AnimatedPositioned を返して他操作を一切邪魔しない
    if (!_isExpanded && _expandAnimationController.isDismissed) {
      return AnimatedPositioned(
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        left: buttonX,
        top: buttonY,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            setState(() {
              _isDragging = true;
              _horizontalDragDistance = 0.0;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _yOffset = (_yOffset + details.delta.dy / screenSize.height)
                  .clamp(0.18, 0.82);
              _horizontalDragDistance += details.delta.dx;
              if (_isLeft) {
                if (details.delta.dx < -5) _isDocked = true;
                if (details.delta.dx > 5) _isDocked = false;
              } else {
                if (details.delta.dx > 5) _isDocked = true;
                if (details.delta.dx < -5) _isDocked = false;
              }
            });
          },
          onPanEnd: (details) {
            final vx = details.velocity.pixelsPerSecond.dx;
            setState(() {
              _isDragging = false;
              if (!_isDocked) {
                if (!_isLeft &&
                    (vx < -200 || _horizontalDragDistance < -40.0)) {
                  _isLeft = true;
                  AppHaptics.selection();
                } else if (_isLeft &&
                    (vx > 200 || _horizontalDragDistance > 40.0)) {
                  _isLeft = false;
                  AppHaptics.selection();
                }
              }
              _horizontalDragDistance = 0.0;
            });
          },
          onTap: () {
            if (_isDocked) {
              AppHaptics.light();
              setState(() => _isDocked = false);
            } else {
              _toggleExpand();
            }
          },
          onLongPress: () {
            if (!_isDocked) {
              _onItemLongPress();
            }
          },
          child: DockParentButton(
            isDark: isDark,
            themeColors: themeColors,
            unreadCount: 0,
            isExpanded: false,
            isDocked: _isDocked,
            buttonSize: _buttonSize,
            closeButtonSize: _closeButtonSize,
            onTap: () {
              if (_isDocked) {
                AppHaptics.light();
                setState(() => _isDocked = false);
              } else {
                _toggleExpand();
              }
            },
            onLongPress: () {
              if (!_isDocked) {
                _onItemLongPress();
              }
            },
          ),
        ),
      );
    }

    // 展開時: 画面全体の透明バリアを展開し、任意箇所タップで吸い込み収納
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
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
          ...orderedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return _buildAnimatedDialItem(
              context: context,
              index: index,
              totalItems: orderedItems.length,
              item: item,
              buttonX: buttonX,
              buttonY: buttonY,
              isVerticalMode: isVerticalMode,
              themeColors: themeColors,
              isDark: isDark,
            );
          }),
          Positioned(
            left: buttonX,
            top: buttonY,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleExpand,
              child: DockParentButton(
                isDark: isDark,
                themeColors: themeColors,
                unreadCount: 0,
                isExpanded: true,
                isDocked: false,
                buttonSize: _buttonSize,
                closeButtonSize: _closeButtonSize,
                onTap: _toggleExpand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDialItem({
    required BuildContext context,
    required int index,
    required int totalItems,
    required BunaiksenDockItemType item,
    required double buttonX,
    required double buttonY,
    required bool isVerticalMode,
    required AppThemeColors themeColors,
    required bool isDark,
  }) {
    const double subSize = 52.0;
    const double step = 64.0;
    final double centerDiff = (_buttonSize - subSize) / 2;
    final double dirX = _isLeft ? 1.0 : -1.0;
    final double dirY = _yOffset < 0.5 ? 1.0 : -1.0;

    double targetDx = 0.0;
    double targetDy = 0.0;

    if (isVerticalMode) {
      targetDy = dirY * step * (index + 1);
      targetDx = 0.0;
    } else {
      switch (index) {
        case 0:
          targetDy = dirY * step * 1.0;
          targetDx = 0.0;
          break;
        case 1:
          targetDy = dirY * step * 2.0;
          targetDx = 0.0;
          break;
        case 2:
          targetDy = dirY * step * 3.0;
          targetDx = 0.0;
          break;
        case 3:
          targetDx = dirX * step * 1.0;
          targetDy = 0.0;
          break;
        case 4:
          targetDx = dirX * step * 2.0;
          targetDy = 0.0;
          break;
        case 5:
          targetDx = dirX * step * 3.0;
          targetDy = 0.0;
          break;
        default:
          targetDy = dirY * step * ((index % 3) + 1);
          targetDx = dirX * step * ((index ~/ 3) + 1);
          break;
      }
    }

    final double targetX = buttonX + centerDiff + targetDx;
    final double targetY = buttonY + centerDiff + targetDy;
    final double originX = buttonX + centerDiff;
    final double originY = buttonY + centerDiff;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final animProgress = _expandAnimation.value;
        final currentX = originX + (targetX - originX) * animProgress;
        final currentY = originY + (targetY - originY) * animProgress;

        return Positioned(
          left: currentX,
          top: currentY,
          child: Opacity(
            opacity: animProgress.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.4 + (0.6 * animProgress.clamp(0.0, 1.0)),
              child: child,
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _wiggleAnimation,
        builder: (context, child) {
          final angle = _wiggleController.isAnimating
              ? _wiggleAnimation.value * (index.isEven ? 1 : -1)
              : 0.0;
          return Transform.rotate(angle: angle, child: child);
        },
        child: BunaiksenSubItemButton(
          icon: item.icon,
          color: item.defaultColor,
          themeColors: themeColors,
          isDark: isDark,
          onTap: () => _onItemTap(item),
          onLongPress: _onItemLongPress,
        ),
      ),
    );
  }
}
