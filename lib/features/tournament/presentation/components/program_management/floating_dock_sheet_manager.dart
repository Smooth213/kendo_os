import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 ドックから開くボトムシート専用のフローティングマネージャー（Googleマップ型・背面操作可能）
/// モーダルルート（Navigator.push）を使わず OverlayEntry に直接展開することで、
/// シート展開中も背後の画面（スコア入力、対戦表、タイムライン）の自由なスクロール＆操作を完全保証します。
class FloatingDockSheetManager {
  FloatingDockSheetManager._();

  static OverlayEntry? _currentEntry;
  static _FloatingDockSheetHostState? _currentHostState;
  static VoidCallback? _onClosedCallback;

  /// 現在フローティングシートが開いているかどうか
  static bool get isOpen => _currentEntry != null;

  /// フローティングシートを展開
  static void show({
    required BuildContext context,
    required WidgetBuilder builder,
    VoidCallback? onClosed,
  }) {
    AppHaptics.selection();

    // 既に開いているシートがある場合は閉じてから切り替え
    if (_currentEntry != null) {
      close(immediate: true);
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _onClosedCallback = onClosed;

    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      container = null;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        Widget buildSheet(BuildContext ctx, {SettingsModel? settings}) {
          final bool isDark;
          final bool isSunshine;
          if (settings != null) {
            if (settings.themeMode == 'dark') {
              isDark = true;
            } else if (settings.themeMode == 'light' ||
                settings.themeMode == 'sunshine') {
              isDark = false;
            } else {
              isDark = MediaQuery.platformBrightnessOf(ctx) == Brightness.dark;
            }
            isSunshine = settings.themeMode == 'sunshine';
          } else {
            isDark = Theme.of(ctx).brightness == Brightness.dark;
            isSunshine = false;
          }

          final themeColors = AppThemeColors.ofMode(
            isDark: isDark,
            mode: isSunshine ? 'sunshine' : 'normal',
          );

          final theme = ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: isDark
                ? AppKendoColors.pureBlack
                : (isSunshine
                      ? AppKendoColors.pureWhite
                      : const Color(0xFFF2F2F7)),
            canvasColor: isDark
                ? const Color(0xFF1E1E20)
                : AppKendoColors.pureWhite,
            extensions: [themeColors],
          );

          return Theme(
            data: theme,
            child: _FloatingDockSheetHost(
              onHostCreated: (state) {
                _currentHostState = state;
              },
              onCloseRequested: () {
                close();
              },
              child: builder(overlayContext),
            ),
          );
        }

        if (container != null) {
          return UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (ctx, ref, _) {
                SettingsModel? settings;
                try {
                  settings = ref.watch(settingsProvider);
                } catch (_) {
                  settings = null;
                }
                return buildSheet(ctx, settings: settings);
              },
            ),
          );
        }
        return buildSheet(overlayContext);
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// フローティングシートを閉じる
  static Future<void> close({bool immediate = false}) async {
    final entry = _currentEntry;
    final hostState = _currentHostState;
    final callback = _onClosedCallback;

    _currentEntry = null;
    _currentHostState = null;
    _onClosedCallback = null;
    _temporaryHideCount = 0;

    if (entry == null) return;

    if (!immediate && hostState != null && hostState.mounted) {
      await hostState.slideOut();
    }

    try {
      entry.remove();
      entry.dispose();
    } catch (_) {
      // 既にツリーから外れている場合の安全保護
    }

    callback?.call();
  }

  static int _temporaryHideCount = 0;

  /// 子モーダル（ダイアログやサブボトムシート）表示中にドックシートを安全に一時退避
  /// ※ タップジェスチャー処理中の同期的な消失（Offstage破壊）を防ぐため、次フレームでIgnorePointerと透明化を適用します。
  static void hideTemporarily() {
    _temporaryHideCount++;
    if (_temporaryHideCount == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_temporaryHideCount > 0) {
          _currentHostState?.setTemporarilyHidden(true);
        }
      });
    }
  }

  /// 子モーダル終了時にドックシートの表示と操作を即座に復帰
  static void restoreVisibility() {
    if (_temporaryHideCount > 0) {
      _temporaryHideCount--;
      if (_temporaryHideCount == 0) {
        _currentHostState?.setTemporarilyHidden(false);
      }
    }
  }
}

/// 🥋 フローティングシートのスライドイン・アウトおよび背面タップ透過ホスト
class _FloatingDockSheetHost extends StatefulWidget {
  final Widget child;
  final void Function(_FloatingDockSheetHostState state) onHostCreated;
  final VoidCallback onCloseRequested;

  const _FloatingDockSheetHost({
    required this.child,
    required this.onHostCreated,
    required this.onCloseRequested,
  });

  @override
  State<_FloatingDockSheetHost> createState() => _FloatingDockSheetHostState();
}

class _FloatingDockSheetHostState extends State<_FloatingDockSheetHost>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  bool _isTemporarilyHidden = false;

  @override
  void initState() {
    super.initState();
    widget.onHostCreated(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// 子モーダル表示時の透過＆タッチ透過切り替え
  void setTemporarilyHidden(bool hidden) {
    if (mounted && _isTemporarilyHidden != hidden) {
      setState(() {
        _isTemporarilyHidden = hidden;
      });
    }
  }

  /// 下へのスライドアウト退場アニメーション
  Future<void> slideOut() async {
    if (!mounted) return;
    try {
      await _animController.reverse().orCancel;
    } catch (_) {
      // アニメーション中断時の安全保護
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 重要: Stack全体に背景バリア（ModalBarrier）を一切敷かない。
    // シートから外れた領域はウィジェットが存在しないため、ヒットテストが
    // 100% 自然に背後の本ページ（スコア入力、対戦表、タイムライン）へ届く。
    // また、子モーダル（ダイアログ等）表示中は IgnorePointer & 透明化により背後モーダルへ 100% タップが届く。
    return IgnorePointer(
      ignoring: _isTemporarilyHidden,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _isTemporarilyHidden ? 0.0 : 1.0,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
