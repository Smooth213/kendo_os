import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 シートの拡大・縮小状態やドラッグ操作を子ウィジェットに伝達するスコープ
class DockSheetScope extends InheritedWidget {
  final bool isExpanded;
  final VoidCallback expand;
  final VoidCallback half;
  final VoidCallback toggle;
  final VoidCallback close;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final void Function(DragEndDetails details) onDragEnd;

  const DockSheetScope({
    super.key,
    required this.isExpanded,
    required this.expand,
    required this.half,
    required this.toggle,
    required this.close,
    required this.onDragUpdate,
    required this.onDragEnd,
    required super.child,
  });

  static DockSheetScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DockSheetScope>();
  }

  @override
  bool updateShouldNotify(DockSheetScope oldWidget) {
    return isExpanded != oldWidget.isExpanded;
  }
}

/// 🥋 ドックから開くボトムシート共通の可動式シートラッパー
/// シート上部をドラッグして半分の高さ（0.58）と全開（0.95）をスムーズに切り替えられ、
/// 下へフリックすると素早く閉じる直感的なジェスチャー操作を提供します。
class DockDraggableSheet extends StatefulWidget {
  final Widget Function(BuildContext context, ScrollController scrollController)
  builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final Color? backgroundColor;
  final VoidCallback? onClose;

  const DockDraggableSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.58,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.95,
    this.backgroundColor,
    this.onClose,
  });

  @override
  State<DockDraggableSheet> createState() => _DockDraggableSheetState();
}

class _DockDraggableSheetState extends State<DockDraggableSheet>
    with SingleTickerProviderStateMixin {
  late double _currentHeightFactor;
  late AnimationController _animController;
  Animation<double>? _heightAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentHeightFactor = widget.initialChildSize;
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          if (_heightAnimation != null) {
            setState(() {
              _currentHeightFactor = _heightAnimation!.value;
            });
          }
        });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _heightAnimation = Tween<double>(begin: _currentHeightFactor, end: target)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward(from: 0.0);
  }

  void _expand() {
    AppHaptics.selection();
    _animateTo(widget.maxChildSize);
  }

  void _half() {
    AppHaptics.selection();
    _animateTo(widget.initialChildSize);
  }

  void _toggleExpand() {
    AppHaptics.selection();
    if (_currentHeightFactor > 0.70) {
      _animateTo(widget.initialChildSize);
    } else {
      _animateTo(widget.maxChildSize);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double screenHeight) {
    if (screenHeight <= 0) return;
    setState(() {
      final delta = -details.primaryDelta! / screenHeight;
      _currentHeightFactor = (_currentHeightFactor + delta).clamp(
        widget.minChildSize,
        widget.maxChildSize,
      );
    });
  }

  void _close() {
    AppHaptics.light();
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (FloatingDockSheetManager.isOpen) {
      FloatingDockSheetManager.close();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _onVerticalDragEnd(DragEndDetails details, double screenHeight) {
    final velocityY = details.primaryVelocity ?? 0.0;

    // 下向きの強いフリック、または閾値（40%未満）を下回ったら閉じる
    if (velocityY > 400 || _currentHeightFactor < 0.40) {
      _close();
      return;
    }

    // 上向きのフリック（-150以下）、または現在の高さが半分より高ければ全開へ
    if (velocityY < -150 || _currentHeightFactor > 0.62) {
      AppHaptics.selection();
      _animateTo(widget.maxChildSize);
      return;
    }

    // それ以外は初期の半分の高さへスナップ
    AppHaptics.selection();
    _animateTo(widget.initialChildSize);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final effectiveBgColor =
        widget.backgroundColor ??
        (isDark ? const Color(0xFF1E1E20) : themeColors.cardBackground);

    final screenSize = MediaQuery.of(context).size;
    final currentHeight = screenSize.height * _currentHeightFactor;
    final isExpanded = _currentHeightFactor > 0.70;

    return DockSheetScope(
      isExpanded: isExpanded,
      expand: _expand,
      half: _half,
      toggle: _toggleExpand,
      close: _close,
      onDragUpdate: (details) =>
          _onVerticalDragUpdate(details, screenSize.height),
      onDragEnd: (details) => _onVerticalDragEnd(details, screenSize.height),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Material(
            color: AppKendoColors.transparent,
            child: Container(
              height: currentHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: effectiveBgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.largeValue),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppKendoColors.pureBlack.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 👆 最上部のドラッグ感知エリア（ドラッグハンドル）
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) =>
                        _onVerticalDragUpdate(details, screenSize.height),
                    onVerticalDragEnd: (details) =>
                        _onVerticalDragEnd(details, screenSize.height),
                    onTap: _toggleExpand,
                    child: Container(
                      width: double.infinity,
                      height: 28,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: themeColors.separatorColor,
                            borderRadius: AppRadius.full,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // コンテンツエリア
                  Expanded(
                    child: Builder(
                      builder: (innerContext) =>
                          widget.builder(innerContext, _scrollController),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
