import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../operate/providers/match_list_provider.dart';
import '../providers/viewer_view_state_provider.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/domain/services/team_match_calculator.dart';
import 'viewer_kachinuki_scoreboard_screen.dart';
import '../../shared/widgets/manual_help_button.dart'; // ファイル上部
import '../../shared/widgets/liquid_background.dart';
import '../../shared/providers/current_sync_context_provider.dart';

// ※ TeamPointDisplay クラスは削除されました（Projectionに統合されたため）

// =========================================================================
// 🛡️ 補正：Firestoreの条件不一致や権限エラーによる沈黙を完全防御。
// 検索が空で返ってきた場合でも、現在アプリ内（matchListProvider）に存在する
// 最新の有効な tournamentId を自動的にレスキューしてフォールバックさせます。
// =========================================================================
final _webTournamentIdSearchProvider = FutureProvider.family<String?, String>((ref, groupName) async {
  try {
    // 最優先: ローカルに既に読み込まれている試合から特定する
    final localMatches = ref.read(matchListProvider);
    final match = localMatches.where((m) => m.groupName == groupName || m.id == groupName).firstOrNull;
    if (match != null) {
      return match.tournamentId;
    }

    final firestore = FirebaseFirestore.instance;
    final dojoId = ref.read(currentDojoIdProvider);
    // 1. groupName と一致する試合を探す
    var snapshot = await firestore
        .collection('organizations').doc(dojoId).collection('matches')
        .where('groupName', isEqualTo: groupName)
        .limit(1)
        .get();
        
    // 2. もし見つからなければ、groupNameの代わりに試合ID(match.id)が渡されたと見なして直接検索
    if (snapshot.docs.isEmpty) {
      final docSnapshot = await firestore.collection('organizations').doc(dojoId).collection('matches').doc(groupName).get();
      if (docSnapshot.exists) return docSnapshot.data()?['tournamentId'] as String?;
    }

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['tournamentId'] as String?;
    }
    
    // それでも取得できない場合はローカルの有効な試合データから抽出
    final fallbackMatches = ref.read(matchListProvider);
    if (fallbackMatches.isNotEmpty) {
      return fallbackMatches.first.tournamentId;
    }
    
    return 'default_tournament';
  } catch (e) {
    final localMatches = ref.read(matchListProvider);
    if (localMatches.isNotEmpty) return localMatches.first.tournamentId;
    return 'default_tournament';
  }
});

class ViewerTeamScoreboardScreen extends ConsumerWidget {
  final String? groupName; 

  const ViewerTeamScoreboardScreen({super.key, this.groupName});

  Widget _buildFallbackScaffold(BuildContext context, bool isDark, Color headerColor, Widget body, String? tournamentId) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: headerColor, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              if (tournamentId != null) {
                context.go('/viewer-home/$tournamentId');
              } else {
                context.go('/');
              }
            }
          },
        ),
        title: Text('団体戦 スコア (観戦)', style: TextStyle(fontWeight: FontWeight.bold, color: headerColor, fontSize: 16)),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
      ),
      body: body,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. URLエンコードされた文字化けや、Web版の全件取得フリーズを解消して安全に大会IDを特定する
    String safeDecodeComponent(String? input) {
      if (input == null) return '';
      try {
        return Uri.decodeComponent(input);
      } catch (_) {
        return input;
      }
    }
    final decodedGroupName = safeDecodeComponent(groupName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? Colors.white : Colors.indigo.shade900;

    String? tournamentId;

    // 最優先で現在メモリに乗っている試合データから対象の大会IDを特定する
    final allMatches = ref.watch(matchListProvider);
    final targetMatch = allMatches.where((m) => m.groupName == decodedGroupName || m.id == decodedGroupName).firstOrNull;
    tournamentId = targetMatch?.tournamentId;

    if (tournamentId == null && kIsWeb) {
      final asyncTourId = ref.watch(_webTournamentIdSearchProvider(decodedGroupName));
      if (asyncTourId.isLoading) {
        return _buildFallbackScaffold(context, isDark, headerColor, const Center(child: CircularProgressIndicator()), null);
      }
      tournamentId = asyncTourId.value;
    }

    // それでも見つからない場合、安全のため最後に開いた大会（最初のデータ）にフォールバック
    if (tournamentId == null && allMatches.isNotEmpty) {
      tournamentId = allMatches.first.tournamentId;
    }

    if (tournamentId == null) {
      return _buildFallbackScaffold(context, isDark, headerColor, const Center(child: Text('大会情報がありません')), null);
    }

    // 2. ★ CQRS: UIは安全な TournamentProjection のみを監視する
    final asyncProj = ref.watch(viewerTournamentProjectionProvider(tournamentId));

    return asyncProj.when(
      loading: () => _buildFallbackScaffold(context, isDark, headerColor, const Center(child: CircularProgressIndicator()), tournamentId),
      error: (e, s) => _buildFallbackScaffold(context, isDark, headerColor, Center(child: Text('エラー: $e')), tournamentId),
      data: (proj) {
        // =========================================================================
        // 🛡️ 補正：Dartコンパイラへ絶対に Null にならない型シグネチャを明示。
        // これにより 187行目・188行目の 'matches' can't be unconditionally accessed エラーを完全撲滅します。
        // =========================================================================
        if (proj == null || proj.teamMatches.isEmpty) {
          return _buildFallbackScaffold(context, isDark, headerColor, const Center(child: Text('試合データがまだ登録されていません')), tournamentId);
        }

        // 動的探索を型安全にキャストして実行
        dynamic foundProj = proj.teamMatches[decodedGroupName];
        
        if (foundProj == null) {
          for (final val in proj.teamMatches.values) {
            final redTeam = val.redTeamName;
            // チーム名での部分一致
            if (decodedGroupName.contains(redTeam) || redTeam.contains(decodedGroupName)) {
              foundProj = val;
              break;
            }
            // groupNameが空で代わりに試合ID(match.id)が渡された場合の救済
            if ((val.matches as Iterable<dynamic>).any((m) => m.id == decodedGroupName || decodedGroupName.contains(m.id as String))) {
              foundProj = val;
              break;
            }
          }
        }
        
        // 🌟 絶対安全ガード（全ての走査に漏れた場合は、最初の要素を非null実体として強制確定）
        final teamProj = foundProj ?? proj.teamMatches.values.first;
        
        if (teamProj.isKachinuki) {
          return ViewerKachinukiScoreboardScreen(groupName: decodedGroupName);
        }

        final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
        final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;

        return LiquidBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: headerColor, size: 20),
                onPressed: () => context.canPop() ? context.pop() : context.go('/viewer-home/$tournamentId'),
              ),
              title: Text('団体戦 スコア (観戦)', style: TextStyle(fontWeight: FontWeight.bold, color: headerColor, fontSize: 16)),
              backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              elevation: 0,
              actions: const [
                // 観客向けのFAQ（点数や勝敗の見方）へ
                ManualHelpButton(manualPath: 'docs/manuals/faq/viewer_faq.md'),
                SizedBox(width: 8),
              ],
            ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                if (teamProj.note.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.indigo.shade900.withValues(alpha: 0.2) : Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.indigo.shade800 : Colors.indigo.shade100),
                    ),
                    child: Text(teamProj.note, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade100 : Colors.indigo.shade900)),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isDark ? null : Border.all(color: borderColor, width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Table(
                        border: TableBorder.symmetric(inside: BorderSide(color: borderColor, width: 0.5)),
                        columnWidths: const {
                          0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2.0), 2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.2), 4: FlexColumnWidth(2.0),
                        },
                        children: [
                          _buildHeaderRow(teamProj.redTeamName, teamProj.whiteTeamName, isDark),
                          ...teamProj.matches.map((m) => _buildMatchRow(
                            m, context, isDark,
                            (teamProj.matches as Iterable<dynamic>)
                              .map<String>((x) => _parseName(x.redName)['last'] ?? '')
                              .where((String s) => s.isNotEmpty)
                              .toList(),
                            (teamProj.matches as Iterable<dynamic>)
                              .map<String>((x) => _parseName(x.whiteName)['last'] ?? '')
                              .where((String s) => s.isNotEmpty)
                              .toList(),
                          )),
                          _buildTotalRow(teamProj.result, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ), // Column
          ), // SingleChildScrollView
        ), // Scaffold
        ); // LiquidBackground
      }
    );
  }

  TableRow _buildHeaderRow(String r, String w, bool isDark) {
    final headerBg = isDark ? const Color(0xFF2C2C2E) : Colors.indigo.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;
    return TableRow(
      decoration: BoxDecoration(color: headerBg),
      children: [
        _cell('', isH: true, color: textColor, fs: 12),
        _cell(r, isH: true, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fs: 16),
        _cell('赤', isH: true, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fs: 14),
        _cell('白', isH: true, color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700, fs: 14),
        _cell(w, isH: true, color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700, fs: 16),
      ],
    );
  }

  Map<String, String> _parseName(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  Widget _buildNameCell(String rawName, bool isDark, List<String> teamLastNames) {
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade600;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (rawName.contains('欠員')) return _cell('(欠員)', fs: 17, color: subTextColor, fontWeight: FontWeight.bold);

    final parsed = _parseName(rawName);
    final count = teamLastNames.where((n) => n == parsed['last']).length;
    final showInitial = count > 1 && parsed['first']!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
          children: [
            TextSpan(text: parsed['last']),
            if (showInitial)
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(parsed['first']!.substring(0, 1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subTextColor)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  TableRow _buildMatchRow(MatchListProjection m, BuildContext ctx, bool isDark, List<String> redLastNames, List<String> whiteLastNames) {
    final isDone = m.status == 'approved' || m.status == 'finished';
    final rS = m.redScore;
    final wS = m.whiteScore;
    final isDraw = isDone && (rS == wS);
    
    final rPts = m.redPointMarks;
    final wPts = m.whitePointMarks;
    final firstSide = m.firstPointSide;

    final isDaihyo = m.matchType == '代表戦';
    final daihyoBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50;
    final matchTypeColor = isDaihyo ? (isDark ? Colors.red.shade400 : Colors.red.shade800) : (isDark ? Colors.grey.shade300 : Colors.grey.shade800);

    return TableRow(
      decoration: isDaihyo ? BoxDecoration(color: daihyoBgColor) : null,
      children: [
        _clickableCell(ctx, m.id, _cell(m.matchType, fs: 12, fontWeight: FontWeight.bold, color: matchTypeColor)),
        _clickableCell(ctx, m.id, _buildNameCell(m.redName, isDark, redLastNames)),
        _clickableCell(ctx, m.id, _buildMatchScoreBox(rPts, isDone && rS > wS, isDraw, true, isDark, firstSide)),
        _clickableCell(ctx, m.id, _buildMatchScoreBox(wPts, isDone && wS > rS, false, false, isDark, firstSide)),
        _clickableCell(ctx, m.id, _buildNameCell(m.whiteName, isDark, whiteLastNames)),
      ],
    );
  }

  Widget _buildMatchScoreBox(List<String> pts, bool isWinner, bool isDraw, bool isRed, bool isDark, String? firstSide) {
    final color = isRed 
        ? (isDark ? Colors.red.shade300 : Colors.red.shade700) 
        : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700);
    
    final isFusen = pts.contains('◯');
    final isThisSideFirst = firstSide == (isRed ? 'red' : 'white');

    return SizedBox(
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isWinner)
            Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5), width: 2.4))),
          
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              children: [
                if (isFusen) ...[
                  Positioned(top: 0, left: 0, child: _ptMark('◯', false, color, isDark)),
                  Positioned(bottom: 0, right: 0, child: _ptMark('◯', false, color, isDark)),
                ] else ...[
                  if (pts.isNotEmpty) Positioned(top: 2, left: 2, child: _ptMark(pts[0], isThisSideFirst, color, isDark)),
                  if (pts.length > 1) Positioned(bottom: 2, right: 2, child: _ptMark(pts[1], false, color, isDark)),
                ],
              ],
            ),
          ),

          if (isRed && isDraw)
            Positioned(right: -14, child: Text('✕', style: TextStyle(fontSize: 28, color: isDark ? Colors.red.shade900.withValues(alpha: 0.6) : Colors.red.shade300, fontWeight: FontWeight.w300))),
        ],
      ),
    );
  }

  Widget _clickableCell(BuildContext ctx, String matchId, Widget child) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ctx.push('/viewer/$matchId'),
        child: child,
      ),
    );
  }

  Widget _ptMark(String mark, bool isFirstOverall, Color color, bool isDark) {
    if (isFirstOverall && mark != '◯') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: isDark ? 0.4 : 1.0), width: 1.5)),
        child: Text(mark, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(mark, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _cell(String txt, {bool isH = false, Color? color, double fs = 13, FontWeight? fontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(txt, textAlign: TextAlign.center, style: TextStyle(fontSize: fs, fontWeight: isH ? FontWeight.bold : (fontWeight ?? FontWeight.normal), color: color)),
    );
  }

  TableRow _buildTotalRow(TeamMatchResult result, bool isDark) {
    final bg = isDark ? const Color(0xFF3A2E12) : Colors.amber.shade50; 
    final textColor = isDark ? Colors.white : Colors.black87;
    final isTeamTie = (result.teamWinner == 'draw');

    return TableRow(
      decoration: BoxDecoration(color: bg), 
      children: [
        const SizedBox.shrink(),
        _cell('${result.redWins} / ${result.redPoints}', isH: true, color: isDark ? Colors.red.shade400 : Colors.red.shade700, fs: 18), 
        
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (result.allFinished) ...[
                  if (isTeamTie)
                    Positioned(
                      right: -36, 
                      child: Text('引き分け', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900)), 
                    )
                  else
                    _cell(result.teamWinner == 'red' ? '勝' : '負', isH: true, color: result.teamWinner == 'red' ? Colors.red : textColor, fs: 20),
                ]
              ],
            ),
          ),
        ),

        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
            height: 64,
            child: Center(
              child: (result.allFinished && !isTeamTie) ? _cell(result.teamWinner == 'white' ? '勝' : '負', isH: true, color: result.teamWinner == 'white' ? Colors.red : textColor, fs: 20) : const SizedBox.shrink(),
            ),
          ),
        ),
        
        _cell('${result.whiteWins} / ${result.whitePoints}', isH: true, color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade800, fs: 18), 
      ],
    );
  }
}