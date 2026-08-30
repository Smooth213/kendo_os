import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_ui_assist_provider.dart';
import 'package:kendo_os/shared/application/services/kendo_haptics.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 試合操作画面用：5秒カウントダウン付きスマートUndoフローティングバー
class SmartUndoFloatingBar extends ConsumerStatefulWidget {
  final String matchId;
  final bool isDark;

  const SmartUndoFloatingBar({
    super.key,
    required this.matchId,
    required this.isDark,
  });

  @override
  ConsumerState<SmartUndoFloatingBar> createState() =>
      _SmartUndoFloatingBarState();
}

class _SmartUndoFloatingBarState extends ConsumerState<SmartUndoFloatingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _formatEventDescription(ScoreEvent event) {
    final sideStr = event.side == Side.red ? '赤' : '白';
    String typeStr;
    switch (event.type) {
      case PointType.men:
        typeStr = '面';
        break;
      case PointType.kote:
        typeStr = '小手';
        break;
      case PointType.doIdo:
        typeStr = '胴';
        break;
      case PointType.tsuki:
        typeStr = '突き';
        break;
      case PointType.hansoku:
        typeStr = '反則';
        break;
      case PointType.hantei:
        typeStr = '判定';
        break;
      case PointType.fusen:
        typeStr = event.isRetirement ? '途中棄権' : '不戦勝';
        break;
      default:
        typeStr = '操作';
        break;
    }
    return '【$sideStr・$typeStr】';
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(pendingSmartUndoProvider(widget.matchId));

    if (pendingState == null) {
      _progressController.reset();
      return const SizedBox.shrink();
    }

    _progressController.forward(from: 0.0);

    final event = pendingState.event;
    final isRed = event.side == Side.red;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey('${event.id}_${event.timestamp.millisecondsSinceEpoch}'),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFF1F2937),
          borderRadius: AppRadius.medium,
          boxShadow: [
            BoxShadow(
              color: AppKendoColors.pureBlack.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isRed
                ? AppKendoColors.hansokuRed.withValues(alpha: 0.8)
                : AppKendoColors.pureWhite.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // カウントダウンプログレスバー
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: 1.0 - _progressController.value,
                    minHeight: 3,
                    backgroundColor: AppKendoColors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isRed
                          ? AppKendoColors.hansokuRed
                          : AppKendoColors.pureWhite,
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isRed
                          ? AppKendoColors.hansokuRed
                          : AppKendoColors.pureWhite,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '記録: ${_formatEventDescription(event)}',
                        style: const TextStyle(
                          color: AppKendoColors.pureWhite,
                          fontSize: AppFontSize.bodyMedium,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppKendoColors.hansokuRed,
                        foregroundColor: AppKendoColors.pureWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.small,
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await KendoHaptics.undoEvent();
                        ref
                            .read(
                              pendingSmartUndoProvider(widget.matchId).notifier,
                            )
                            .clear();
                        await ref
                            .read(matchCommandProvider)
                            .undoLastEvent(widget.matchId);
                      },
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text(
                        '今のを取消',
                        style: TextStyle(
                          fontSize: AppFontSize.small,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppKendoColors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        ref
                            .read(
                              pendingSmartUndoProvider(widget.matchId).notifier,
                            )
                            .clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
