import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // kIsWeb用
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart'; // ★ 追加: UseCaseの参照
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart'; // ★ Phase 3: ViewStateの参照
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart'; // ★ 追加: matchListProvider

// ★ 追加: Scoreboard を const として扱うための Provider
final scoreboardMatchIdProvider = Provider<String>(
  (ref) => throw UnimplementedError(),
);
final scoreboardNameTapProvider = Provider<void Function(String side)?>(
  (ref) => null,
);
// ★ 追加: 親ウィジェットから直接最新のMatchModelを注入するためのProvider
final scoreboardMatchProvider = Provider<MatchModel?>((ref) => null);

// ★ 追加: Firestoreから受信したデータを確実にMatchModelにパースするための再帰的サニタイズ関数
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

// ★ 追加: Web環境（Viewer）で直接Firestoreから特定の試合データを取得するストリームプロバイダ
final webScoreboardMatchProvider = StreamProvider.family
    .autoDispose<MatchModel?, String>((ref, matchId) {
      return FirebaseFirestore.instance
          .collectionGroup('matches')
          .where('id', isEqualTo: matchId)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return null;
            final doc = snapshot.docs.first;
            final data = doc.data();
            data['id'] = doc.id;
            final sanitized = _sanitizeWebFirestoreData(data);
            return MatchModel.fromJson(sanitized);
          });
    });

class MatchScoreboard extends ConsumerWidget {
  const MatchScoreboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchId = ref.watch(scoreboardMatchIdProvider);
    final onNameTap = ref.watch(scoreboardNameTapProvider);

    // ★ 修正: 親から直接最新 of MatchModelが注入されていればそれを優先使用する (Webでの入力遅延防止)
    MatchModel? match = ref.watch(scoreboardMatchProvider);

    match ??= kIsWeb
        ? ref.watch(webScoreboardMatchProvider(matchId)).value
        : ref.watch(
            matchListProvider.select(
              (list) => list.where((m) => m.id == matchId).firstOrNull,
            ),
          );
    if (match == null) return const SizedBox.shrink();

    final calculatePointDisplays = ref.watch(
      calculatePointDisplaysUseCaseProvider,
    );
    final ptsMap = calculatePointDisplays.execute(match);
    final viewState = ref.watch(matchViewStateProvider(matchId));

    final scoreboardRow = SizedBox(
      width: 800,
      height: 320, // ★ 高さの無駄な余白を詰めるため 380 から 320 に圧縮
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScoreColumn(
            context,
            Side.red,
            match,
            ptsMap,
            viewState,
            onNameTap,
          ),
          _buildScoreColumn(
            context,
            Side.white,
            match,
            ptsMap,
            viewState,
            onNameTap,
          ),
        ],
      ),
    );

    // ★修正：二段（結果バッジが上、スコアボードが下）になるようにColumnで配置し、上に被らないようにする
    final showResult = viewState.winner != null || viewState.isTie;

    return FittedBox(
      fit: BoxFit.contain,
      child: showResult
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResultOverlay(context, viewState),
                const SizedBox(height: 16),
                scoreboardRow,
              ],
            )
          : scoreboardRow,
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
    final pts = allPts[side] ?? [];

    // ★ 修正: 計算を削除し ViewState に依存
    final isWinner = viewState.winner == side.name;
    final isFinished = match.status == 'approved' || match.status == 'finished';

    final nameColor = side == Side.red
        ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
        : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800);

    return SizedBox(
      width: 380, // 左右均等な幅を明示的に確保
      height: 320, // ★ 380 から 320 に圧縮
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center, // 垂直中央ロックの前提
        children: [
          const SizedBox(height: 16), // ★ 余白圧縮 (24 -> 16)
          GestureDetector(
            onTap: onNameTap != null ? () => onNameTap(side.name) : null,
            child: Container(
              height: 54, // ★ 選手名表示サイズに合わせて高さを拡張
              alignment: side == Side.red
                  ? Alignment
                        .centerRight // 赤側は右寄せで中央に対比
                  : Alignment.centerLeft, // 白側は左寄せで中央に対比
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown, // 🌟 基本は40ptで表示、長い名前の時だけ自動縮小
                alignment: side == Side.red
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  side == Side.red
                      ? viewState.redCleanName
                      : viewState.whiteCleanName,
                  style: TextStyle(
                    fontSize: 40, // 🌟 視認性をさらに高める40ptへサイズアップ
                    fontWeight: FontWeight.w900, // 力強い超太字 (w900)
                    color: nameColor,
                    height: 1.2,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // 🛡️ 究極のレイアウト崩れ防衛
                  textAlign: side == Side.red
                      ? TextAlign.right
                      : TextAlign.left,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10), // ★ 余白圧縮 (16 -> 10)
          // ポイントアイコンの拡大
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
                  width: 130, // ★ 内側の技マーク配置エリアを大幅に拡張 (100 -> 130)
                  height: 130,
                  child: Stack(
                    children: [
                      if (pts.isNotEmpty)
                        Positioned(
                          top: 6, // ★ 130x130の円周にあわせ配置調整
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
                          bottom: 6, // ★ 130x130の円周にあわせ配置調整
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
                          top: 35, // ★ 中央に配置
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

          // 反則表示 (▲)
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
              if (hansokuCount == 0)
                return const SizedBox.shrink(); // ★ 反則なし時は完全に高さを0にして余白を消滅させる
              return Container(
                height: 36,
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  List.filled(hansokuCount, '▲').join(''),
                  style: const TextStyle(fontSize: 24, color: Colors.amber),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ★ 改善: _cleanName を削除。UI側で文字列操作（ビジネス/プレゼンテーションロジック）を持たないようにする。
  // (※呼び出し元の _buildScoreColumn 内で Text() に渡す値も修正します)
  Widget _buildPoint(
    BuildContext context,
    PointDisplay pd,
    bool isDark,
    Color color,
  ) {
    const double fs = 38; // ★ 技マークフォントサイズを大幅に大きく (26 -> 38)
    Widget pointWidget;

    if (pd.isFirstMatchPoint) {
      pointWidget = Container(
        width: 60, // ★ 技マークバッジの直径を大きく拡張 (42 -> 60)
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.7 : 1.0),
            width: 3.5, // ★ 枠線も視認性を高める太さに変更 (2.5 -> 3.5)
          ),
        ),
        child: Text(
          pd.mark,
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.0,
          ),
        ),
      );
    } else {
      pointWidget = SizedBox(
        width: 60, // ★ 技マークバッジの大きさを大きく拡張 (42 -> 60)
        height: 60,
        child: Center(
          child: Text(
            pd.mark,
            style: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.0,
            ),
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.1, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
        );
      },
      child: pointWidget,
    );
  }

  Widget _buildResultOverlay(BuildContext context, MatchViewState viewState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String resultText = '引き分け';
    if (viewState.winner == 'red') resultText = '赤 の勝ち';
    if (viewState.winner == 'white') resultText = '白 の勝ち';

    return Container(
      height: 60, // ★ 二段配置になったため、重なりを気にせず視認性の高い60pxまで拡大
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 40), // ★ 横幅にゆとりを持たせる
      decoration: BoxDecoration(
        color: isDark ? Colors.indigo.shade900 : Colors.indigo.shade700,
        borderRadius: BorderRadius.circular(30), // ★ 角丸を調整
        border: isDark
            ? Border.all(color: Colors.indigo.shade400, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        // ★ 文字が絶対にはみ出さないようガード
        child: Text(
          resultText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 28, // ★ 堂々とした28pt特大サイズへ拡大
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
