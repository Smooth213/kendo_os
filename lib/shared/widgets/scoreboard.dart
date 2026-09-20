import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_ui_assist_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/application/services/kendo_haptics.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

final scoreboardMatchIdProvider = Provider<String>(
  (ref) => throw UnimplementedError(),
);
final scoreboardNameTapProvider = Provider<void Function(String side)?>(
  (ref) => null,
);
final scoreboardMatchProvider = Provider<MatchModel?>((ref) => null);

Map<String, dynamic> _sanitizeWebFirestoreData(Map<String, dynamic> data) {
  final Map<String, dynamic> result = {};
  data.forEach((key, value) {
    if (value is Timestamp) {
      result[key] = value.toDate().toIso8601String();
    } else if (value is Map) {
      result[key] = _sanitizeWebFirestoreData(Map<String, dynamic>.from(value));
    } else if (value is List) {
      result[key] = value.map((e) {
        if (e is Map) {
          return _sanitizeWebFirestoreData(Map<String, dynamic>.from(e));
        }
        if (e is Timestamp) {
          return e.toDate().toIso8601String();
        }
        return e;
      }).toList();
    } else if ((key == 'order' ||
            key == 'matchTimeMinutes' ||
            key == 'extensionTimeMinutes' ||
            key == 'enchoTimeMinutes') &&
        value is num) {
      result[key] = value.toDouble();
    } else if ((key == 'redScore' ||
            key == 'whiteScore' ||
            key == 'matchOrder') &&
        value is num) {
      result[key] = value.toInt();
    } else {
      result[key] = value;
    }
  });
  return result;
}

final webScoreboardMatchProvider = StreamProvider.family
    .autoDispose<MatchModel?, String>((ref, matchId) {
      final dojoId = ref.watch(currentDojoIdProvider);
      final activeTournamentId = ref.watch(currentTournamentIdProvider);
      final webTournamentId = ref.watch(webCurrentTournamentIdProvider);
      final tournamentId = activeTournamentId.isNotEmpty
          ? activeTournamentId
          : (webTournamentId ?? '');

      if (dojoId.isNotEmpty && tournamentId.isNotEmpty) {
        return FirebaseFirestore.instance
            .collection('organizations')
            .doc(dojoId)
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc(matchId)
            .snapshots()
            .map((doc) {
              if (!doc.exists || doc.data() == null) return null;
              final data = doc.data()!;
              data['id'] = doc.id;
              return MatchModel.fromJson(_sanitizeWebFirestoreData(data));
            });
      }

      return FirebaseFirestore.instance
          .collectionGroup('matches')
          .where('id', isEqualTo: matchId)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return null;
            final doc = snapshot.docs.first;
            final data = doc.data();
            data['id'] = doc.id;
            return MatchModel.fromJson(_sanitizeWebFirestoreData(data));
          });
    });

class MatchScoreboard extends ConsumerWidget {
  final String? matchId;
  final MatchModel? match;
  final void Function(String side)? onNameTap;

  const MatchScoreboard({super.key, this.matchId, this.match, this.onNameTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String effectiveMatchId =
        match?.id ?? matchId ?? ref.watch(scoreboardMatchIdProvider);
    final effectiveOnNameTap =
        onNameTap ?? ref.watch(scoreboardNameTapProvider);

    MatchModel? currentMatch = match ?? ref.watch(scoreboardMatchProvider);
    currentMatch ??= kIsWeb
        ? ref.watch(webScoreboardMatchProvider(effectiveMatchId)).value
        : ref.watch(
            matchListProvider.select(
              (list) => list.where((m) => m.id == effectiveMatchId).firstOrNull,
            ),
          );
    if (currentMatch == null) return const SizedBox.shrink();
    final MatchModel targetMatch = currentMatch;

    final calculatePointDisplays = ref.watch(
      calculatePointDisplaysUseCaseProvider,
    );
    final ptsMap = calculatePointDisplays.execute(targetMatch);
    final viewState = ref.watch(matchViewStateProvider(effectiveMatchId));
    final isFlipped = ref.watch(isMatchViewFlippedProvider(effectiveMatchId));

    final redColumn = _buildScoreColumn(
      context,
      Side.red,
      targetMatch,
      ptsMap,
      viewState,
      effectiveOnNameTap,
    );
    final whiteColumn = _buildScoreColumn(
      context,
      Side.white,
      targetMatch,
      ptsMap,
      viewState,
      effectiveOnNameTap,
    );

    final scoreboardRow = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final isDone =
            targetMatch.status == 'finished' ||
            targetMatch.status == 'approved';
        if (!isDone) {
          final isRunning = targetMatch.timerIsRunning;
          await KendoHaptics.timerToggle(isStarting: !isRunning);
          ref.read(matchTimerProvider).toggleTimer(effectiveMatchId);
        }
      },
      child: SizedBox(
        width: 800,
        height: 320,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isFlipped
              ? [whiteColumn, redColumn]
              : [redColumn, whiteColumn],
        ),
      ),
    );

    final showResult = viewState.winner != null || viewState.isTie;

    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.contain,
        child: showResult
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResultOverlay(context, viewState),
                  const SizedBox(height: AppSpacing.lg),
                  scoreboardRow,
                ],
              )
            : scoreboardRow,
      ),
    );
  }

  Widget _buildScoreColumn(
    BuildContext context,
    Side side,
    MatchModel match,
    Map<Side, List<PointDisplay>> allPts,
    MatchViewState viewState,
    void Function(String)? onNameTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pts = (allPts[side] ?? []).where((p) => p.mark != '△').toList();
    final isWinner = viewState.winner == side.name;
    final isFinished = match.status == 'approved' || match.status == 'finished';
    final nameColor = side == Side.red
        ? context.appColors.errorColor
        : context.appColors.textColor;

    return SizedBox(
      width: 380,
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onNameTap != null ? () => onNameTap(side.name) : null,
            child: Container(
              height: 54,
              alignment: side == Side.red
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFF2F2F7),
                borderRadius: AppRadius.small,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: side == Side.red
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  side == Side.red
                      ? viewState.redCleanName
                      : viewState.whiteCleanName,
                  style: TextStyle(
                    fontSize: AppFontSize.scoreboardMedium,
                    fontWeight: AppFontWeight.bold,
                    color: nameColor,
                    height: 1.2,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: side == Side.red
                      ? TextAlign.right
                      : TextAlign.left,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isFinished && isWinner)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nameColor.withValues(alpha: 0.6),
                        width: 6,
                      ),
                    ),
                  ),
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    children: [
                      if (pts.isNotEmpty)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: _buildPoint(
                            context,
                            pts[0],
                            isDark,
                            nameColor,
                          ),
                        ),
                      if (pts.length > 1)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: _buildPoint(
                            context,
                            pts[1],
                            isDark,
                            nameColor,
                          ),
                        ),
                      if (pts.length > 2)
                        Positioned(
                          top: 35,
                          left: 35,
                          child: _buildPoint(
                            context,
                            pts[2],
                            isDark,
                            nameColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) {
              final engine = KendoRuleEngine();
              final activeEvents = engine.filterActiveEvents(match.events);
              final hansokuCount = activeEvents
                  .where(
                    (e) =>
                        e.side == side &&
                        (e.isHansoku || e.type == PointType.hansoku),
                  )
                  .length;
              if (hansokuCount == 0) return const SizedBox.shrink();
              return Container(
                height: 36,
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  List.filled(hansokuCount, '▲').join(''),
                  style: const TextStyle(
                    fontSize: AppFontSize.display,
                    color: AppKendoColors.ipponGold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPoint(
    BuildContext context,
    PointDisplay pd,
    bool isDark,
    Color color,
  ) {
    const double fs = 38;
    final pointWidget = pd.isFirstMatchPoint
        ? Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.7 : 1.0),
                width: 3.5,
              ),
            ),
            child: Text(
              pd.mark,
              style: TextStyle(
                fontSize: fs,
                fontWeight: AppFontWeight.bold,
                color: color,
                height: 1.0,
              ),
            ),
          )
        : SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: Text(
                pd.mark,
                style: TextStyle(
                  fontSize: fs,
                  fontWeight: AppFontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
            ),
          );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.1, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
      ),
      child: pointWidget,
    );
  }

  Widget _buildResultOverlay(BuildContext context, MatchViewState viewState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String resultText = '引き分け';
    if (viewState.winner == 'red') resultText = '赤 の勝ち';
    if (viewState.winner == 'white') resultText = '白 の勝ち';

    return Container(
      height: 60,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
      decoration: BoxDecoration(
        color: context.appColors.primaryAccent,
        borderRadius: AppRadius.full,
        border: isDark
            ? Border.all(color: const Color(0xFF3F51B5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppKendoColors.pureBlack.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        child: Text(
          resultText,
          style: const TextStyle(
            color: AppKendoColors.pureWhite,
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.hero,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
