import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/painters/program_viewer_painters.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

/// 🥋 プログラム（PDF・画像）プレビューの上に保存済み手書きストローク（ペン・ハイライト）を重畳表示するレイヤー
class ProgramStrokeLayer extends ConsumerWidget {
  final String programId;
  final int pageIndex;
  final double penWidth;

  const ProgramStrokeLayer({
    super.key,
    required this.programId,
    this.pageIndex = 0,
    this.penWidth = 12.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveProgramId = pageIndex == 0
        ? programId
        : '${programId}_p$pageIndex';

    Stream<List<StrokeModel>> sharedStream;
    try {
      final strokeRepo = ref.watch(strokeRepositoryProvider);
      sharedStream = strokeRepo.watchStrokes(programId);
    } catch (_) {
      sharedStream = const Stream.empty();
    }

    Stream<List<LocalStrokeModel>> privateStream;
    try {
      final localStrokeRepo = ref.watch(localStrokeRepositoryProvider);
      privateStream = localStrokeRepo.watchStrokes(effectiveProgramId);
    } catch (_) {
      privateStream = const Stream.empty();
    }

    return StreamBuilder<List<StrokeModel>>(
      stream: sharedStream,
      builder: (context, sharedSnapshot) {
        final allShared = sharedSnapshot.data ?? [];
        final sharedStrokes = allShared
            .where((s) => s.pageIndex == pageIndex)
            .toList();

        return StreamBuilder<List<LocalStrokeModel>>(
          stream: privateStream,
          builder: (context, privateSnapshot) {
            final privateStrokes = privateSnapshot.data ?? [];

            if (sharedStrokes.isEmpty && privateStrokes.isEmpty) {
              return const SizedBox.shrink();
            }

            return IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: StrokePainter(
                  sharedStrokes: sharedStrokes,
                  privateStrokes: privateStrokes,
                  currentLineColor: AppKendoColors.transparent,
                  activePenWidth: penWidth,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
