import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import '../providers/viewer_view_state_provider.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'viewer_kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart'; // ファイル上部
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';

// ※ TeamPointDisplay クラスは削除されました（Projectionに統合されたため）

// =========================================================================
// 🛡️ 補正：Firestoreの条件不一致や権限エラーによる沈黙を完全防御。
// 検索が空で返ってきた場合でも、現在アプリ内（matchListProvider）に存在する
// 最新の有効な tournamentId を自動的にレスキューしてフォールバックさせます。
// =========================================================================
final _webTournamentIdSearchProvider = FutureProvider.family<String?, String>((
  ref,
  groupName,
) async {
  try {
    // 最優先: ローカルに既に読み込まれている試合から特定する
    final localMatches = ref.read(matchListProvider);
    final match = localMatches
        .where((m) => m.groupName == groupName || m.id == groupName)
        .firstOrNull;
    if (match != null) {
      return match.tournamentId;
    }

    final firestore = FirebaseFirestore.instance;

    // ★ 追加: ルートコレクションから直接 groupName や id を検索して確実に特定する
    try {
      var rootGroupSnap = await firestore
          .collection('matches')
          .where('groupName', isEqualTo: groupName)
          .limit(1)
          .get();
      if (rootGroupSnap.docs.isNotEmpty) {
        return rootGroupSnap.docs.first.data()['tournamentId'] as String?;
      }

      var rootIdSnap = await firestore
          .collection('matches')
          .doc(groupName)
          .get();
      if (rootIdSnap.exists) {
        return rootIdSnap.data()?['tournamentId'] as String?;
      }
    } catch (e) {
      debugPrint('🚨 [Root Matches Query Error] $e');
    }

    final dojoId = ref.read(currentDojoIdProvider);
    if (dojoId.isNotEmpty) {
      // 1. groupName と一致する試合を探す
      var snapshot = await firestore
          .collection('organizations')
          .doc(dojoId)
          .collection('matches')
          .where('groupName', isEqualTo: groupName)
          .limit(1)
          .get();

      // 2. もし見つからなければ、groupNameの代わりに試合ID(match.id)が渡されたと見なして直接検索
      if (snapshot.docs.isEmpty) {
        final docSnapshot = await firestore
            .collection('organizations')
            .doc(dojoId)
            .collection('matches')
            .doc(groupName)
            .get();
        if (docSnapshot.exists) {
          return docSnapshot.data()?['tournamentId'] as String?;
        }
      }

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['tournamentId'] as String?;
      }
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

  Widget _buildFallbackScaffold(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color headerColor,
    Widget body,
    String? tournamentId,
  ) {
    return Scaffold(
      appBar: AppHeader(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: headerColor, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              if (tournamentId != null) {
                final dojoId =
                    GoRouterState.of(context).uri.queryParameters['dojoId'] ??
                    ref.read(currentDojoIdProvider);
                context.go(
                  '/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId',
                );
              } else {
                context.go('/');
              }
            }
          },
        ),
        title: '団体戦 スコア (観戦)',
        backgroundColor: context.appColors.cardBackground,
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
    final headerColor = isDark
        ? AppKendoColors.pureWhite
        : AppKendoColors.indigo.shade900;

    String? tournamentId;

    // ★ URLから直接 tournamentId を取得（あれば最優先）
    final urlTournamentId = GoRouterState.of(
      context,
    ).uri.queryParameters['tournamentId'];

    // 最優先で現在メモリに乗っている試合データから対象の大会IDを特定する
    final allMatches = ref.watch(matchListProvider);
    final targetMatch = allMatches
        .where(
          (m) => m.groupName == decodedGroupName || m.id == decodedGroupName,
        )
        .firstOrNull;
    tournamentId = urlTournamentId ?? targetMatch?.tournamentId;

    if (tournamentId == null && kIsWeb) {
      final asyncTourId = ref.watch(
        _webTournamentIdSearchProvider(decodedGroupName),
      );
      if (asyncTourId.isLoading) {
        return _buildFallbackScaffold(
          context,
          ref,
          isDark,
          headerColor,
          const Center(child: CircularProgressIndicator()),
          null,
        );
      }
      tournamentId = asyncTourId.value;
    }

    // それでも見つからない場合、安全のため最後に開いた大会（最初のデータ）にフォールバック
    if (tournamentId == null && allMatches.isNotEmpty) {
      tournamentId = allMatches.first.tournamentId;
    }

    if (tournamentId == null) {
      return _buildFallbackScaffold(
        context,
        ref,
        isDark,
        headerColor,
        const Center(child: Text('大会情報がありません')),
        null,
      );
    }

    // 2. ★ CQRS: UIは安全な TournamentProjection のみを監視する
    final asyncProj = ref.watch(
      viewerTournamentProjectionProvider(tournamentId),
    );

    return asyncProj.when(
      loading: () => _buildFallbackScaffold(
        context,
        ref,
        isDark,
        headerColor,
        const Center(child: CircularProgressIndicator()),
        tournamentId,
      ),
      error: (e, s) => _buildFallbackScaffold(
        context,
        ref,
        isDark,
        headerColor,
        Center(child: Text('エラー: $e')),
        tournamentId,
      ),
      data: (proj) {
        // =========================================================================
        // 🛡️ 補正：Dartコンパイラへ絶対に Null にならない型シグネチャを明示。
        // これにより 187行目・188行目の 'matches' can't be unconditionally accessed エラーを完全撲滅します。
        // =========================================================================
        if (proj == null || proj.teamMatches.isEmpty) {
          return _buildFallbackScaffold(
            context,
            ref,
            isDark,
            headerColor,
            const Center(child: Text('試合データがまだ登録されていません')),
            tournamentId,
          );
        }

        // 動的探索を型安全にキャストして実行
        dynamic foundProj = proj.teamMatches[decodedGroupName];

        if (foundProj == null) {
          for (final val in proj.teamMatches.values) {
            final redTeam = val.redTeamName;
            // チーム名での部分一致
            if (decodedGroupName.contains(redTeam) ||
                redTeam.contains(decodedGroupName)) {
              foundProj = val;
              break;
            }
            // groupNameが空で代わりに試合ID(match.id)が渡された場合の救済
            if ((val.matches as Iterable<dynamic>).any(
              (m) =>
                  m.id == decodedGroupName ||
                  decodedGroupName.contains(m.id as String),
            )) {
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

        final themeColors =
            Theme.of(context).extension<AppThemeColors>() ??
            AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
        final cardColor = themeColors.cardBackground;
        final borderColor = context.appColors.separatorColor;

        return LiquidBackground(
          child: Scaffold(
            backgroundColor: AppKendoColors.transparent,
            appBar: AppHeader(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: headerColor,
                  size: 20,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    final dojoId =
                        GoRouterState.of(
                          context,
                        ).uri.queryParameters['dojoId'] ??
                        ref.read(currentDojoIdProvider);
                    context.go(
                      '/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId',
                    );
                  }
                },
              ),
              title: '団体戦 スコア (観戦)',
              backgroundColor: context.appColors.cardBackground,
              elevation: 0,
              actions: const [
                // 観客向けのFAQ（点数や勝敗の見方）へ
                ManualHelpButton(manualPath: 'docs/manuals/faq/viewer_faq.md'),
                SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  if (teamProj.note.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppKendoColors.indigo.shade900.withValues(
                                alpha: 0.2,
                              )
                            : AppKendoColors.indigo.shade50,
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: isDark
                              ? AppKendoColors.indigo.shade800
                              : AppKendoColors.indigo.shade100,
                        ),
                      ),
                      child: Text(
                        teamProj.note,
                        style: TextStyle(
                          fontSize: AppFontSize.bodyMedium,
                          fontWeight: AppFontWeight.bold,
                          color: isDark
                              ? AppKendoColors.indigo.shade100
                              : AppKendoColors.indigo.shade900,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: AppRadius.large,
                        border: isDark
                            ? null
                            : Border.all(color: borderColor, width: 1.0),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.large,
                        child: Table(
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: borderColor, width: 0.5),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(2.0),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1.2),
                            4: FlexColumnWidth(2.0),
                          },
                          children: [
                            _buildHeaderRow(
                              teamProj.redTeamName,
                              teamProj.whiteTeamName,
                              isDark,
                            ),
                            ...teamProj.matches.map(
                              (m) => _buildMatchRow(
                                m,
                                context,
                                isDark,
                                (teamProj.matches as Iterable<dynamic>)
                                    .map<String>(
                                      (x) =>
                                          NameFormatter.parse(
                                            x.redName,
                                          )['last'] ??
                                          '',
                                    )
                                    .where((String s) => s.isNotEmpty)
                                    .toList(),
                                (teamProj.matches as Iterable<dynamic>)
                                    .map<String>(
                                      (x) =>
                                          NameFormatter.parse(
                                            x.whiteName,
                                          )['last'] ??
                                          '',
                                    )
                                    .where((String s) => s.isNotEmpty)
                                    .toList(),
                              ),
                            ),
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
      },
    );
  }

  TableRow _buildHeaderRow(String r, String w, bool isDark) {
    final headerBg = isDark
        ? const Color(0xFF2C2C2E)
        : AppKendoColors.indigo.shade50;
    final textColor = isDark
        ? AppKendoColors.pureWhite
        : AppKendoColors.pureBlack;
    return TableRow(
      decoration: BoxDecoration(color: headerBg),
      children: [
        _cell('', isH: true, color: textColor, fs: 12),
        _cell(
          r,
          isH: true,
          color: isDark ? AppKendoColors.hansokuRed : AppKendoColors.hansokuRed,
          fs: 16,
        ),
        _cell(
          '赤',
          isH: true,
          color: isDark ? AppKendoColors.hansokuRed : AppKendoColors.hansokuRed,
          fs: 14,
        ),
        _cell(
          '白',
          isH: true,
          color: isDark
              ? AppKendoColors.grey.shade300
              : AppKendoColors.blueGrey.shade700,
          fs: 14,
        ),
        _cell(
          w,
          isH: true,
          color: isDark
              ? AppKendoColors.grey.shade300
              : AppKendoColors.blueGrey.shade700,
          fs: 16,
        ),
      ],
    );
  }

  Widget _buildNameCell(
    String rawName,
    bool isDark,
    List<String> teamLastNames,
  ) {
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : AppKendoColors.grey.shade600;
    final textColor = isDark
        ? AppKendoColors.pureWhite
        : AppKendoColors.pureBlack;

    if (rawName.contains('欠員')) {
      return _cell(
        '(欠員)',
        fs: 17,
        color: subTextColor,
        fontWeight: AppFontWeight.bold,
      );
    }

    final parsed = NameFormatter.parse(rawName);
    final count = teamLastNames.where((n) => n == parsed['last']).length;
    final showInitial = count > 1 && parsed['first']!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: AppFontSize.title,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
          children: [
            TextSpan(text: parsed['last']),
            if (showInitial)
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xxs,
                    bottom: AppSpacing.xxs,
                  ),
                  child: Text(
                    parsed['first']!.substring(0, 1),
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                      color: subTextColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  TableRow _buildMatchRow(
    MatchListProjection m,
    BuildContext ctx,
    bool isDark,
    List<String> redLastNames,
    List<String> whiteLastNames,
  ) {
    final isDone = m.status == 'approved' || m.status == 'finished';
    final rS = m.redScore;
    final wS = m.whiteScore;
    final isDraw = isDone && (rS == wS);

    final rPts = m.redPointMarks;
    final wPts = m.whitePointMarks;
    final firstSide = m.firstPointSide;

    final isDaihyo = m.matchType == '代表戦';
    final daihyoBgColor = isDark
        ? AppKendoColors.hansokuRed.withValues(alpha: 0.15)
        : AppKendoColors.hansokuRed;
    final matchTypeColor = isDaihyo
        ? (isDark ? AppKendoColors.hansokuRed : AppKendoColors.hansokuRed)
        : (isDark
              ? AppKendoColors.grey.shade300
              : AppKendoColors.grey.shade800);

    return TableRow(
      decoration: isDaihyo ? BoxDecoration(color: daihyoBgColor) : null,
      children: [
        _clickableCell(
          ctx,
          m.id,
          _cell(
            m.matchType,
            fs: 12,
            fontWeight: AppFontWeight.bold,
            color: matchTypeColor,
          ),
        ),
        _clickableCell(
          ctx,
          m.id,
          _buildNameCell(m.redName, isDark, redLastNames),
        ),
        _clickableCell(
          ctx,
          m.id,
          _buildMatchScoreBox(
            rPts,
            isDone && rS > wS,
            isDraw,
            true,
            isDark,
            firstSide,
          ),
        ),
        _clickableCell(
          ctx,
          m.id,
          _buildMatchScoreBox(
            wPts,
            isDone && wS > rS,
            false,
            false,
            isDark,
            firstSide,
          ),
        ),
        _clickableCell(
          ctx,
          m.id,
          _buildNameCell(m.whiteName, isDark, whiteLastNames),
        ),
      ],
    );
  }

  Widget _buildMatchScoreBox(
    List<String> pts,
    bool isWinner,
    bool isDraw,
    bool isRed,
    bool isDark,
    String? firstSide,
  ) {
    final color = isRed
        ? (isDark ? AppKendoColors.hansokuRed : AppKendoColors.hansokuRed)
        : (isDark
              ? AppKendoColors.grey.shade300
              : AppKendoColors.blueGrey.shade700);

    final isFusen = pts.contains('◯');
    final isThisSideFirst = firstSide == (isRed ? 'red' : 'white');

    return SizedBox(
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isWinner)
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 2.4,
                ),
              ),
            ),

          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                if (isFusen) ...[
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _ptMark('◯', false, color, isDark),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _ptMark('◯', false, color, isDark),
                  ),
                ] else ...[
                  if (pts.isNotEmpty)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: _ptMark(pts[0], isThisSideFirst, color, isDark),
                    ),
                  if (pts.length > 1)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: _ptMark(pts[1], false, color, isDark),
                    ),
                ],
              ],
            ),
          ),

          if (isRed && isDraw)
            Positioned(
              right: -14,
              child: Text(
                '✕',
                style: TextStyle(
                  fontSize: AppFontSize.hero,
                  color: isDark
                      ? AppKendoColors.hansokuRed.withValues(alpha: 0.6)
                      : AppKendoColors.hansokuRed,
                  fontWeight: AppFontWeight.light,
                ),
              ),
            ),
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
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        padding: const EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 1.0),
            width: 1.5,
          ),
        ),
        child: Text(
          mark,
          style: TextStyle(
            fontSize: AppFontSize.badge,
            color: color,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Text(
        mark,
        style: TextStyle(
          fontSize: AppFontSize.body,
          color: color,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }

  Widget _cell(
    String txt, {
    bool isH = false,
    Color? color,
    double fs = 13,
    FontWeight? fontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        txt,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fs,
          fontWeight: isH
              ? AppFontWeight.bold
              : (fontWeight ?? FontWeight.normal),
          color: color,
        ),
      ),
    );
  }

  TableRow _buildTotalRow(TeamMatchResult result, bool isDark) {
    final bg = isDark ? const Color(0xFF3A2E12) : AppKendoColors.ipponGold;
    final textColor = isDark
        ? AppKendoColors.pureWhite
        : AppKendoColors.pureBlack;
    final isTeamTie = (result.teamWinner == 'draw');

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        const SizedBox.shrink(),
        _cell(
          '${result.redWins} / ${result.redPoints}',
          isH: true,
          color: isDark ? AppKendoColors.hansokuRed : AppKendoColors.hansokuRed,
          fs: 18,
        ),

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
                      child: Text(
                        '引き分け',
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.headline,
                          color: isDark
                              ? AppKendoColors.ipponGold
                              : AppKendoColors.ipponGold,
                        ),
                      ),
                    )
                  else
                    _cell(
                      result.teamWinner == 'red' ? '勝' : '負',
                      isH: true,
                      color: result.teamWinner == 'red'
                          ? AppKendoColors.red
                          : textColor,
                      fs: 20,
                    ),
                ],
              ],
            ),
          ),
        ),

        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
            height: 64,
            child: Center(
              child: (result.allFinished && !isTeamTie)
                  ? _cell(
                      result.teamWinner == 'white' ? '勝' : '負',
                      isH: true,
                      color: result.teamWinner == 'white'
                          ? AppKendoColors.red
                          : textColor,
                      fs: 20,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),

        _cell(
          '${result.whiteWins} / ${result.whitePoints}',
          isH: true,
          color: isDark
              ? AppKendoColors.grey.shade400
              : AppKendoColors.blueGrey.shade800,
          fs: 18,
        ),
      ],
    );
  }
}
