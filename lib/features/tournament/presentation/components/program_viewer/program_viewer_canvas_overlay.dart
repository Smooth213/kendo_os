import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_stroke_eraser.dart';
import 'package:kendo_os/features/tournament/presentation/painters/program_viewer_painters.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';

/// プログラムビューワーのストローク描画・消去キャンバスオーバーレイ
class ProgramViewerCanvasOverlay extends ConsumerStatefulWidget {
  final String programId;
  final int pageIndex;
  final double penWidth;
  final bool isDrawingMode;
  final String selectedTool;
  final Color activePenColor;
  final bool activeIsShared;
  final bool canUseSharedPen;
  final ValueChanged<List<StrokeModel>>? onSharedStrokesUpdated;
  final ValueChanged<List<LocalStrokeModel>>? onPrivateStrokesUpdated;

  const ProgramViewerCanvasOverlay({
    super.key,
    required this.programId,
    required this.pageIndex,
    required this.penWidth,
    required this.isDrawingMode,
    required this.selectedTool,
    required this.activePenColor,
    required this.activeIsShared,
    required this.canUseSharedPen,
    this.onSharedStrokesUpdated,
    this.onPrivateStrokesUpdated,
  });

  @override
  ConsumerState<ProgramViewerCanvasOverlay> createState() =>
      _ProgramViewerCanvasOverlayState();
}

class _ProgramViewerCanvasOverlayState
    extends ConsumerState<ProgramViewerCanvasOverlay> {
  List<Offset> _currentPoints = [];
  List<StrokeModel> _cachedSharedStrokes = [];
  List<LocalStrokeModel> _cachedPrivateStrokes = [];

  String get _effectiveProgramId => widget.pageIndex == 0
      ? widget.programId
      : '${widget.programId}_p${widget.pageIndex}';

  Future<void> _eraseStrokeAt(Offset touchPoint) async {
    const double threshold = 25.0;

    if (widget.canUseSharedPen) {
      for (final stroke in _cachedSharedStrokes) {
        if (ProgramViewerStrokeEraser.isNearStroke(
          touchPoint,
          stroke.points,
          threshold,
        )) {
          await ref.read(strokeRepositoryProvider).deleteStroke(stroke.id);
          return;
        }
      }
    }

    for (final stroke in _cachedPrivateStrokes) {
      if (ProgramViewerStrokeEraser.isNearLocalStroke(
        touchPoint,
        stroke.pointsX,
        stroke.pointsY,
        threshold,
      )) {
        await ref
            .read(localStrokeRepositoryProvider)
            .deleteStroke(stroke.id, firestoreId: stroke.firestoreId);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: StreamBuilder<List<StrokeModel>>(
              stream: ref
                  .watch(strokeRepositoryProvider)
                  .watchStrokes(widget.programId),
              builder: (context, sharedSnapshot) {
                final allShared = sharedSnapshot.data ?? [];
                final sharedStrokes = allShared
                    .where((s) => s.pageIndex == widget.pageIndex)
                    .toList();
                _cachedSharedStrokes = sharedStrokes;
                widget.onSharedStrokesUpdated?.call(sharedStrokes);

                return StreamBuilder<List<LocalStrokeModel>>(
                  stream: ref
                      .watch(localStrokeRepositoryProvider)
                      .watchStrokes(_effectiveProgramId),
                  builder: (context, privateSnapshot) {
                    final privateStrokes = privateSnapshot.data ?? [];
                    _cachedPrivateStrokes = privateStrokes;
                    widget.onPrivateStrokesUpdated?.call(privateStrokes);

                    final isMarker = widget.selectedTool == 'marker';
                    final paintColor = isMarker
                        ? widget.activePenColor.withAlpha(90)
                        : widget.activePenColor;
                    final paintWidth = isMarker
                        ? widget.penWidth * 3.0
                        : widget.penWidth;

                    return CustomPaint(
                      painter: StrokePainter(
                        sharedStrokes: sharedStrokes,
                        privateStrokes: privateStrokes,
                        currentPoints: _currentPoints,
                        currentLineColor: paintColor,
                        activePenWidth: paintWidth,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (widget.isDrawingMode)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                if (widget.selectedTool == 'eraser') {
                  _eraseStrokeAt(event.localPosition);
                } else {
                  setState(() => _currentPoints = [event.localPosition]);
                }
              },
              onPointerMove: (event) {
                if (widget.selectedTool == 'eraser') {
                  _eraseStrokeAt(event.localPosition);
                } else {
                  setState(() => _currentPoints.add(event.localPosition));
                }
              },
              onPointerUp: (event) async {
                if (widget.selectedTool == 'eraser') {
                  return;
                }
                if (_currentPoints.isNotEmpty) {
                  final pointsToSave = List<Offset>.from(_currentPoints);
                  setState(() => _currentPoints.clear());

                  final isMarker = widget.selectedTool == 'marker';
                  final savedColor = isMarker
                      ? widget.activePenColor.withAlpha(90)
                      : widget.activePenColor;
                  final savedWidth = isMarker
                      ? widget.penWidth * 3.0
                      : widget.penWidth;

                  if (widget.activeIsShared && widget.canUseSharedPen) {
                    final newStroke = StrokeModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      programId: widget.programId,
                      points: pointsToSave,
                      color: savedColor,
                      strokeWidth: savedWidth,
                      isShared: widget.activeIsShared,
                      pageIndex: widget.pageIndex,
                    );
                    await ref
                        .read(strokeRepositoryProvider)
                        .addStroke(newStroke);
                  } else {
                    final newLocalStroke = LocalStrokeModel()
                      ..programId = _effectiveProgramId
                      ..pointsX = pointsToSave.map((p) => p.dx).toList()
                      ..pointsY = pointsToSave.map((p) => p.dy).toList()
                      ..colorValue = savedColor.toARGB32()
                      ..strokeWidth = savedWidth
                      ..createdAt = DateTime.now();
                    await ref
                        .read(localStrokeRepositoryProvider)
                        .addStroke(newLocalStroke);
                  }
                }
              },
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}
