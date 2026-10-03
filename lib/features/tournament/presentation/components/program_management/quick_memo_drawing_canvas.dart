import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_toolbar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_paper_view.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_zoom_controls.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 クイックメモの手書き描画キャンバス＆ツールバー領域
/// 写真・画像アプリのように用紙（キャンバス）自体がボトムシートや画面いっぱいに
/// ダイナミックに拡大・縮小（1.0x〜4.0x）＆パン移動します。
/// スマホ（タッチ/ピンチ）だけでなく、PC（トラックパッド/ホイール）にも完全対応。
class QuickMemoDrawingCanvas extends StatefulWidget {
  /// 📐 全端末共通の基準キャンバス論理サイズ（PC/iPad/iPhone共通ピクセル空間）
  static const Size baseCanvasSize = Size(800, 1000);

  final List<MemoStroke> strokes;
  final List<Offset> currentPoints;
  final Color selectedColor;
  final double selectedWidth;
  final bool isEraser;
  final bool isDark;
  final AppThemeColors themeColors;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onToggleWidth;
  final VoidCallback onToggleEraser;

  const QuickMemoDrawingCanvas({
    super.key,
    required this.strokes,
    required this.currentPoints,
    required this.selectedColor,
    required this.selectedWidth,
    required this.isEraser,
    required this.isDark,
    required this.themeColors,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onColorChanged,
    required this.onToggleWidth,
    required this.onToggleEraser,
  });

  @override
  State<QuickMemoDrawingCanvas> createState() => _QuickMemoDrawingCanvasState();
}

class _QuickMemoDrawingCanvasState extends State<QuickMemoDrawingCanvas> {
  // ユーザー操作による用紙のズーム倍率（1.0x 〜 4.0x）と平行移動オフセット
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;

  // ピンチ開始時の基準値
  double _baseZoomScale = 1.0;
  Offset _basePanOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  // 1本指描画と2本指ズームの厳格な分離
  bool _isTransforming = false;
  bool _showZoomBadge = false;
  Timer? _badgeTimer;

  // 現在のレイアウト計算キャッシュ（Viewport基準）
  Size _viewportSize = Size.zero;
  double _fitScale = 1.0;
  Offset _paperCenterOffset = Offset.zero;

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
      _showZoomBadge = false;
    });
  }

  void _triggerZoomBadge() {
    _badgeTimer?.cancel();
    setState(() {
      _showZoomBadge = true;
    });
    _badgeTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showZoomBadge = false;
        });
      }
    });
  }

  /// Viewport（表示エリア）のサイズから用紙の基準配置（中央フィット）を計算
  void _updateLayoutMetrics(Size viewportSize) {
    _viewportSize = viewportSize;
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    final fitScale = math.min(
      viewportSize.width / QuickMemoDrawingCanvas.baseCanvasSize.width,
      viewportSize.height / QuickMemoDrawingCanvas.baseCanvasSize.height,
    );
    _fitScale = fitScale;

    final initialPaperWidth =
        QuickMemoDrawingCanvas.baseCanvasSize.width * fitScale;
    final initialPaperHeight =
        QuickMemoDrawingCanvas.baseCanvasSize.height * fitScale;

    _paperCenterOffset = Offset(
      (viewportSize.width - initialPaperWidth) / 2,
      (viewportSize.height - initialPaperHeight) / 2,
    );
  }

  /// 画面上のタッチ座標（Viewport内）を用紙の論理座標系（0〜800, 0〜1000）へ逆変換
  Offset _toCanvasCoordinates(Offset localPosition) {
    final effectiveScale = _fitScale * _zoomScale;
    if (effectiveScale <= 0) return localPosition;
    final paperTopLeft = _paperCenterOffset + _panOffset;
    return (localPosition - paperTopLeft) / effectiveScale;
  }

  /// 用紙が表示エリアから過度に飛び出さないようパン移動をクランプ
  Offset _clampPanOffset(Offset panOffset, double zoomScale) {
    if (zoomScale <= 1.0) {
      return Offset.zero;
    }

    final paperWidth =
        QuickMemoDrawingCanvas.baseCanvasSize.width * _fitScale * zoomScale;
    final paperHeight =
        QuickMemoDrawingCanvas.baseCanvasSize.height * _fitScale * zoomScale;

    // 余白マージン80pxを持たせて端まで快適にドラッグ＆描画可能
    const margin = 80.0;

    final minX =
        _viewportSize.width - paperWidth - _paperCenterOffset.dx - margin;
    final maxX = -_paperCenterOffset.dx + margin;
    final minY =
        _viewportSize.height - paperHeight - _paperCenterOffset.dy - margin;
    final maxY = -_paperCenterOffset.dy + margin;

    return Offset(
      panOffset.dx.clamp(math.min(minX, maxX), math.max(minX, maxX)),
      panOffset.dy.clamp(math.min(minY, maxY), math.max(minY, maxY)),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      // 2本指検知: 用紙のズーム＆パン操作
      _isTransforming = true;
      _baseZoomScale = _zoomScale;
      _basePanOffset = _panOffset;
      _startFocalPoint = details.localFocalPoint;

      if (widget.currentPoints.isNotEmpty) {
        widget.onPanEnd(DragEndDetails());
      }
    } else if (details.pointerCount == 1) {
      // 1本指検知: ペン描画または消しゴム
      _isTransforming = false;
      final canvasPos = _toCanvasCoordinates(details.localFocalPoint);
      widget.onPanStart(
        DragStartDetails(
          localPosition: canvasPos,
          globalPosition: details.focalPoint,
        ),
      );
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      // 2本指操作中（または途中で2本指になった）
      if (!_isTransforming) {
        if (widget.currentPoints.isNotEmpty) {
          widget.onPanEnd(DragEndDetails());
        }
        _isTransforming = true;
        _baseZoomScale = _zoomScale;
        _basePanOffset = _panOffset;
        _startFocalPoint = details.localFocalPoint;
      }

      // 指の微小な間隔ブレ（±5%以内）は純粋なパン（平行移動）として扱い、意図しないズーム暴発を防止
      final scaleChange = (details.scale - 1.0).abs();
      final isDefinitePinch = scaleChange >= 0.05;

      final newZoomScale = isDefinitePinch
          ? (_baseZoomScale * details.scale).clamp(1.0, 4.0)
          : _baseZoomScale;

      Offset newPanOffset;
      if (isDefinitePinch) {
        // ピンチ操作: 開始時の中心点（_startFocalPoint）を軸にした用紙全体のズーム＆パン
        final effectiveBaseScale = _fitScale * _baseZoomScale;
        final focalInPaper =
            _startFocalPoint - _paperCenterOffset - _basePanOffset;
        final focalInCanvas = effectiveBaseScale > 0
            ? focalInPaper / effectiveBaseScale
            : Offset.zero;

        newPanOffset =
            details.localFocalPoint -
            _paperCenterOffset -
            (focalInCanvas * (_fitScale * newZoomScale));
      } else {
        // 純粋な2本指ドラッグ（パン移動）: 指の移動量に1:1で吸い付くように平行移動
        final focalDelta = details.localFocalPoint - _startFocalPoint;
        newPanOffset = _basePanOffset + focalDelta;
      }

      newPanOffset = _clampPanOffset(newPanOffset, newZoomScale);

      setState(() {
        _zoomScale = newZoomScale;
        _panOffset = newPanOffset;
      });

      if (isDefinitePinch) {
        _triggerZoomBadge();
      }
    } else if (details.pointerCount == 1) {
      // ズームセッション中の指離脱（片指残り）による誤描画を防止
      if (_isTransforming) {
        return;
      }

      final canvasPos = _toCanvasCoordinates(details.localFocalPoint);
      widget.onPanUpdate(
        DragUpdateDetails(
          localPosition: canvasPos,
          globalPosition: details.focalPoint,
        ),
      );
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isTransforming) {
      if (details.pointerCount == 0) {
        _isTransforming = false;
      }
    } else {
      widget.onPanEnd(DragEndDetails(velocity: details.velocity));
    }
  }

  /// PC/Web/Mac でのマウスホイール・トラックパッドスクロールによる拡大・パン対応
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Ctrlキー（またはCommandキー）押下時はズーム、それ以外は2本指スクロール（パン）
      final isCtrlOrMeta =
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isCtrlOrMeta) {
        final zoomDelta = -event.scrollDelta.dy * 0.005;
        final newZoomScale = (_zoomScale + zoomDelta).clamp(1.0, 4.0);

        final focal = event.localPosition;
        final effectiveBaseScale = _fitScale * _zoomScale;
        final focalInPaper = focal - _paperCenterOffset - _panOffset;
        final focalInCanvas = effectiveBaseScale > 0
            ? focalInPaper / effectiveBaseScale
            : Offset.zero;

        var newPanOffset =
            focal -
            _paperCenterOffset -
            (focalInCanvas * (_fitScale * newZoomScale));
        newPanOffset = _clampPanOffset(newPanOffset, newZoomScale);

        setState(() {
          _zoomScale = newZoomScale;
          _panOffset = newPanOffset;
        });
        _triggerZoomBadge();
      } else if (_zoomScale > 1.0) {
        // 拡大中のトラックパッド2本指スクロール（パン移動）
        var newPanOffset = _panOffset - event.scrollDelta;
        newPanOffset = _clampPanOffset(newPanOffset, _zoomScale);
        setState(() {
          _panOffset = newPanOffset;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZoomed = _zoomScale > 1.05 || _panOffset != Offset.zero;

    return Stack(
      children: [
        // 1. ノート用紙キャンバス表示領域（表示エリア外へのはみ出しを綺麗にクリップ）
        Positioned.fill(
          bottom: 74, // ツールバーの高さと余白
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _updateLayoutMetrics(constraints.biggest);

                  final totalScale = _fitScale * _zoomScale;
                  final paperTopLeft = _paperCenterOffset + _panOffset;

                  return Listener(
                    onPointerSignal: _handlePointerSignal,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 📄 用紙そのものを画像のようにズーム＆パン
                        QuickMemoPaperView(
                          paperTopLeft: paperTopLeft,
                          totalScale: totalScale,
                          baseCanvasSize: QuickMemoDrawingCanvas.baseCanvasSize,
                          isDark: widget.isDark,
                          themeColors: widget.themeColors,
                          strokes: widget.strokes,
                          currentPoints: widget.currentPoints,
                          selectedColor: widget.selectedColor,
                          selectedWidth: widget.selectedWidth,
                          isZoomed: isZoomed,
                        ),

                        // 👆 最前面のジェスチャー検出レイヤ（1本指描画 & 2本指ズーム/パン）
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: _handleScaleStart,
                            onScaleUpdate: _handleScaleUpdate,
                            onScaleEnd: _handleScaleEnd,
                          ),
                        ),

                        // 🔍 拡大中のみ表示される「100%（全体表示）に戻す」リセットボタン
                        if (isZoomed)
                          QuickMemoZoomResetButton(
                            isDark: widget.isDark,
                            themeColors: widget.themeColors,
                            onReset: _resetZoom,
                          ),

                        // 🔍 ピンチ操作中に表示される倍率バッジ（例: 150%）
                        QuickMemoZoomBadge(
                          isVisible: _showZoomBadge,
                          zoomScale: _zoomScale,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // 2. ツールバー（画面下部に固定）
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xs,
          child: QuickMemoDrawingToolbar(
            themeColors: widget.themeColors,
            isDark: widget.isDark,
            selectedColor: widget.selectedColor,
            selectedWidth: widget.selectedWidth,
            isEraser: widget.isEraser,
            onColorChanged: widget.onColorChanged,
            onToggleWidth: widget.onToggleWidth,
            onToggleEraser: widget.onToggleEraser,
          ),
        ),
      ],
    );
  }
}
