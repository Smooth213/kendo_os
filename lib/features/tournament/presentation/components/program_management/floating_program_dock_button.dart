import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

export 'program_header_action.dart';

/// 🥋 画面端に常駐し、タップで流動的L字スピードダイヤルが飛び出すフローティングボタン
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
    with SingleTickerProviderStateMixin {
  static const double _buttonSize = 58.0;
  static const double _closeButtonSize = 46.0;
  static const double _dockedVisibleWidth = 20.0;

  bool _isDocked = false;
  late bool _isLeft;
  bool _isDragging = false;
  double _yOffset = 0.70;
  double _horizontalDragDistance = 0.0;

  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

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
        setState(() => _isExpanded = false);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleDock() {
    AppHaptics.selection();
    setState(() {
      _isDocked = !_isDocked;
    });
  }

  void _toggleExpand() {
    AppHaptics.selection();
    if (_isExpanded) {
      _collapse();
    } else {
      setState(() => _isExpanded = true);
      _animController.forward(from: 0.0);
    }
  }

  void _collapse() {
    if (_isExpanded) {
      _animController.reverse();
    }
  }

  List<DockSubItem> _buildItems({
    required BuildContext context,
    required AppThemeColors themeColors,
    required int unreadCount,
  }) {
    return [
      DockSubItem(
        icon: Icons.menu_book_rounded,
        color: themeColors.primaryAccent,
        label: 'プログラム',
        onTap: () {
          _collapse();
          ProgramBottomSheet.show(
            context,
            tournamentId: widget.tournamentId,
            isViewerMode: widget.isViewerMode,
          );
        },
      ),
      DockSubItem(
        icon: Icons.groups_rounded,
        color: AppKendoColors.indigo,
        label: '試合状況',
        onTap: () {
          _collapse();
          TeamMatchStatusScreen.showAsBottomSheet(
            context,
            tournamentId: widget.tournamentId,
            isViewerMode: widget.isViewerMode,
          );
        },
      ),
      DockSubItem(
        icon: Icons.scoreboard_rounded,
        color: AppKendoColors.ipponGold,
        label: '対戦表',
        onTap: () {
          _collapse();
          OfficialRecordScreen.showAsBottomSheet(
            context,
            tournamentId: widget.tournamentId,
            isViewerMode: widget.isViewerMode,
          );
        },
      ),
      DockSubItem(
        icon: Icons.brush_rounded,
        color: AppKendoColors.pink,
        label: 'クイックメモ',
        onTap: () {
          _collapse();
          QuickMemoBottomSheet.show(context, tournamentId: widget.tournamentId);
        },
      ),
      DockSubItem(
        icon: Icons.notifications_rounded,
        color: AppKendoColors.deepOrange,
        label: 'お知らせ',
        badgeCount: unreadCount,
        onTap: () {
          _collapse();
          AnnounceHistoryBottomSheet.show(
            context,
            widget.tournamentId,
            !widget.isViewerMode,
          );
        },
      ),
      DockSubItem(
        icon: Icons.help_outline_rounded,
        color: AppKendoColors.teal,
        label: 'ヘルプ',
        onTap: () {
          _collapse();
          ManualBottomSheet.show(context, isViewerMode: widget.isViewerMode);
        },
      ),
      DockSubItem(
        icon: Icons.settings_rounded,
        color: themeColors.subTextColor,
        label: '設定',
        onTap: () {
          _collapse();
          if (widget.isViewerMode) {
            ViewerSettingsBottomSheet.show(context);
          } else {
            SettingsScreen.showAsBottomSheet(context);
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final screenSize = MediaQuery.of(context).size;

    final double safeTop = MediaQuery.of(context).padding.top + 60.0;
    final double rawSafeBottom =
        screenSize.height - MediaQuery.of(context).padding.bottom - 100.0;
    final double safeBottom = rawSafeBottom < safeTop ? safeTop : rawSafeBottom;
    final double currentY = (_yOffset * screenSize.height).clamp(
      safeTop,
      safeBottom,
    );

    final double targetX;
    if (_isLeft) {
      targetX = _isDocked
          ? -(_buttonSize - _dockedVisibleWidth)
          : AppSpacing.md;
    } else {
      targetX = _isDocked
          ? screenSize.width - _dockedVisibleWidth
          : screenSize.width - _buttonSize - AppSpacing.md;
    }

    final double currentX = _isDragging && !_isDocked
        ? (targetX + _horizontalDragDistance).clamp(
            AppSpacing.md,
            screenSize.width - _buttonSize - AppSpacing.md,
          )
        : targetX;

    final unreadAsync = ref.watch(
      unreadAnnouncementCountProvider((
        tournamentId: widget.tournamentId,
        isStaffRoom: !widget.isViewerMode,
      )),
    );
    final unreadCount = unreadAsync.valueOrNull ?? 0;
    final items = _buildItems(
      context: context,
      themeColors: themeColors,
      unreadCount: unreadCount,
    );

    final double dirX = _isLeft ? 1.0 : -1.0;

    // 画面の垂直位置の正規化比率 (0.0: 上端 〜 1.0: 下端)
    final double verticalRange = safeBottom - safeTop;
    final double normalizedY = verticalRange > 0
        ? ((currentY - safeTop) / verticalRange).clamp(0.0, 1.0)
        : 0.5;

    // 展開する垂直方向: 画面中央より上なら下向き(+1.0)、中央より下なら上向き(-1.0)
    final double dirY = normalizedY < 0.5 ? 1.0 : -1.0;

    // 画面の上下端（上部20%以内または下部20%以内）ではコーナーに寄り添う「L字型」、
    // 画面の中央部（20%〜80%）ではスッキリ整然とした「縦1列」に流動的切り替え
    final bool isNearEdge = normalizedY < 0.20 || normalizedY > 0.80;
    final DockLayoutMode layoutMode = isNearEdge
        ? DockLayoutMode.lShape
        : DockLayoutMode.vertical;

    // 折りたたみ時は AnimatedPositioned を返して他操作を一切邪魔しない
    if (!_isExpanded && _animController.isDismissed) {
      return AnimatedPositioned(
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        left: currentX,
        top: currentY,
        child: _buildParentGestureDetector(
          context,
          isDark,
          themeColors,
          unreadCount,
          screenSize,
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
                      originX: currentX,
                      originY: currentY,
                      dirX: dirX,
                      dirY: dirY,
                      isDark: isDark,
                      themeColors: themeColors,
                      layoutMode: layoutMode,
                    ),
                  Positioned(
                    left:
                        currentX +
                        ((_buttonSize - _closeButtonSize) / 2 * progress),
                    top:
                        currentY +
                        ((_buttonSize - _closeButtonSize) / 2 * progress),
                    child: _buildParentButton(
                      isDark: isDark,
                      themeColors: themeColors,
                      unreadCount: unreadCount,
                      isExpanded: true,
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

  Widget _buildParentGestureDetector(
    BuildContext context,
    bool isDark,
    AppThemeColors themeColors,
    int unreadCount,
    Size screenSize,
  ) {
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
          _yOffset += details.delta.dy / screenSize.height;
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
            if (!_isLeft && (vx < -200 || _horizontalDragDistance < -40.0)) {
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
          _toggleDock();
        } else {
          _toggleExpand();
        }
      },
      child: _buildParentButton(
        isDark: isDark,
        themeColors: themeColors,
        unreadCount: unreadCount,
        isExpanded: false,
      ),
    );
  }

  Widget _buildParentButton({
    required bool isDark,
    required AppThemeColors themeColors,
    required int unreadCount,
    required bool isExpanded,
  }) {
    return DockParentButton(
      isDark: isDark,
      themeColors: themeColors,
      unreadCount: unreadCount,
      isExpanded: isExpanded,
      isDocked: _isDocked,
      buttonSize: _buttonSize,
      closeButtonSize: _closeButtonSize,
      onTap: _isDocked ? _toggleDock : _toggleExpand,
    );
  }
}
