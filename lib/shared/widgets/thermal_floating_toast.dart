import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

/// 🌡️ 【非モーダル・試合操作を邪魔しない】サーマル冷却＆省電力フローティングトースト
///
/// 画面上部にスライドインし、3秒後に自動的にフェードアウトします。
/// タップイベントをブロックしないため、試合記録中の誤操作や遅延を一切発生させません。
class ThermalToastListener extends ConsumerStatefulWidget {
  final Widget child;

  const ThermalToastListener({super.key, required this.child});

  @override
  ConsumerState<ThermalToastListener> createState() =>
      _ThermalToastListenerState();
}

class _ThermalToastListenerState extends ConsumerState<ThermalToastListener> {
  StreamSubscription<ThermalToastEvent>? _subscription;
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToGovernor();
    });
  }

  void _subscribeToGovernor() {
    final governor = ref.read(thermalPowerGovernorProvider);
    _subscription = governor.toastStream.listen((event) {
      if (mounted) {
        _showToast(event);
      }
    });
  }

  void _showToast(ThermalToastEvent event) {
    _dismissTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ThermalFloatingToastView(
        event: event,
        onDismiss: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );

    overlay.insert(_overlayEntry!);

    // 3秒で自動消去
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _ThermalFloatingToastView extends StatefulWidget {
  final ThermalToastEvent event;
  final VoidCallback onDismiss;

  const _ThermalFloatingToastView({
    required this.event,
    required this.onDismiss,
  });

  @override
  State<_ThermalFloatingToastView> createState() =>
      _ThermalFloatingToastViewState();
}

class _ThermalFloatingToastViewState extends State<_ThermalFloatingToastView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + AppSpacing.sm,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Material(
            color: AppKendoColors.transparent,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: widget.event.color.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppKendoColors.pureBlack.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: widget.event.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.event.icon,
                        color: widget.event.color,
                        size: AppFontSize.subhead,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        widget.event.message,
                        style: const TextStyle(
                          color: AppKendoColors.pureWhite,
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    InkWell(
                      onTap: widget.onDismiss,
                      borderRadius: AppRadius.round,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        child: Icon(
                          Icons.close,
                          size: AppFontSize.caption,
                          color: AppKendoColors.pureWhite.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
