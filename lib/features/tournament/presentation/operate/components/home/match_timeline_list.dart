import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
// ★ 適合修正: プロダクション環境で実績のあるKendoRuleEngine経由の計算ヘルパーをインポート
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart'; // ★ 追加
import '../bulk_rule_edit_sheet.dart';
import 'match_edit_sheet.dart';

import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'; // 検索プロバイダなどを参照するため
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'tournament_header_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

// ★ 画面間で共有する状態をここに集約
final categorySortProvider = StateProvider.autoDispose<bool>((ref) => true);
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final isSearchVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);
final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});
final timelinePlayerListProvider =
    StreamProvider.autoDispose<List<PlayerModel>>((ref) {
      return ref.watch(playerRepositoryProvider).getPlayers();
    });

// =========================================================================
// 🛡️ Webアプリ・リスト消失バグ完全修正パッチ
// 全件取得(matchListProvider)に依存していた timelineMatchesByCategoryProvider が
// Web環境でフリーズ・空配列になる問題を回避するため、対象大会のみを直接取得する
// 安全な専用プロバイダーを定義し、UI側へ供給します。
// =========================================================================
// ★ 修正: Record 型に hasError と errorMessage を追加
typedef SafeTimelineResult = ({
  List<MapEntry<String, List<MatchModel>>> entries,
  Set<String> matchedGroupNames,
  Set<String> matchedMatchIds,
  bool isLoading,
  bool hasError,
  String? errorMessage,
});

final safeTimelineProvider = Provider.family
    .autoDispose<SafeTimelineResult, String>((ref, String tournamentId) {
      // ★ 修正: ネイティブ(Isar)とWeb(Firestore)でデータソースを最適化し、完全な仕様一致(即時反映)を実現します
      List<MatchModel> matches = [];
      bool isLoading = false;
      bool hasError = false;
      String? errorMessage;

      if (kIsWeb) {
        final asyncMatches = ref.watch(
          matchListByTournamentProvider(tournamentId),
        );
        hasError = asyncMatches.hasError;
        errorMessage = asyncMatches.error?.toString();
        isLoading = asyncMatches.isLoading;
        matches = List<MatchModel>.from(asyncMatches.valueOrNull ?? []);
      } else {
        // ネイティブアプリ(iOS/Android)はIsarから0ミリ秒で同期取得
        matches = ref
            .watch(matchListProvider)
            .where((m) => m.tournamentId == tournamentId)
            .toList();
      }

      if (hasError) {
        debugPrint('🚨 [safeTimelineProvider] エラーを検知しました: $errorMessage');
      } else if (!isLoading) {
        debugPrint('📊 [safeTimelineProvider] 試合リスト抽出完了: ${matches.length} 件');
        if (matches.isEmpty) {
          debugPrint(
            '🤔 [safeTimelineProvider] 試合が0件です。クラウド側でデータが作成されていないか、検索クエリ・大会IDの不一致の可能性があります。',
          );
        }
      }

      matches.sort((a, b) => a.order.compareTo(b.order));

      final searchQuery = ref
          .watch(searchQueryProvider)
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
      final isSortAscending = ref.watch(categorySortProvider);

      final matchedGroupNames = <String>{};
      final matchedMatchIds = <String>{};

      if (searchQuery.isNotEmpty) {
        for (var m in matches) {
          final rName = m.redName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
          final wName = m.whiteName
              .replaceAll(RegExp(r'\s+'), '')
              .toLowerCase();
          if (rName.contains(searchQuery) || wName.contains(searchQuery)) {
            matchedMatchIds.add(m.id);
            if (m.groupName != null && m.groupName!.isNotEmpty) {
              matchedGroupNames.add(m.groupName!);
            }
          }
        }
      }

      final categoryMap = <String, List<MatchModel>>{};
      for (var m in matches) {
        if (searchQuery.isNotEmpty) {
          bool isMatch =
              matchedMatchIds.contains(m.id) ||
              (m.groupName != null && matchedGroupNames.contains(m.groupName!));
          if (!isMatch) continue;
        }
        final cat = (m.category != null && m.category!.isNotEmpty)
            ? m.category!
            : '未分類';
        categoryMap.putIfAbsent(cat, () => []).add(m);
      }

      final entries = categoryMap.entries.toList();
      entries.sort((a, b) {
        if (isSortAscending) {
          return a.key.compareTo(b.key);
        } else {
          return b.key.compareTo(a.key);
        }
      });

      return (
        entries: entries,
        matchedGroupNames: matchedGroupNames,
        matchedMatchIds: matchedMatchIds,
        isLoading: isLoading,
        hasError: hasError,
        errorMessage: errorMessage,
      );
    });

class MatchTimelineList extends ConsumerWidget {
  final String tournamentId;
  const MatchTimelineList({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permissions = ref.watch(permissionProvider);
    final bool isReadOnlyUI = permissions.isReadOnly;
    final bool canManageTournamentUI = permissions.canManageTournament;

    final comments = ref.watch(commentStreamProvider(tournamentId)).value ?? [];

    final sanitizedQuery = ref
        .watch(searchQueryProvider)
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
    final timelineResult = ref.watch(safeTimelineProvider(tournamentId));
    final matchedGroupNames = timelineResult.matchedGroupNames;
    final matchedMatchIds = timelineResult.matchedMatchIds;
    final allMatches = timelineResult.entries.expand((e) => e.value).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // ============================================================
        // ★ 移設: 大会ヘッダー（HomeScreen から移動。リストと一緒にスクロールさせる）
        // ============================================================
        ref
            .watch(tournamentProvider(tournamentId))
            .when(
              data: (tournament) => tournament != null
                  ? TournamentHeaderCard(tournament: tournament)
                  : const SizedBox.shrink(),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, s) => Text('大会情報の読み込みに失敗しました: $e'),
            ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!ref.watch(isSearchVisibleProvider))
                Text(
                  '試合リスト',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),

              if (ref.watch(isSearchVisibleProvider))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: '選手名・チーム名で検索...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.indigo.shade400,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              ref.read(searchQueryProvider.notifier).state = '';
                              ref.read(isSearchVisibleProvider.notifier).state =
                                  false;
                            },
                          ),
                        ),
                        onChanged: (val) =>
                            ref.read(searchQueryProvider.notifier).state = val,
                      ),
                    ),
                  ),
                ),

              if (!ref.watch(isSearchVisibleProvider))
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: isDark
                                ? Colors.indigo.shade300
                                : Colors.indigo.shade700,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              ref.read(isSearchVisibleProvider.notifier).state =
                                  true,
                        ),
                        const SizedBox(width: 12),
                        if (!isReadOnlyUI && allMatches.isNotEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: () => showBulkRuleEditSheet(
                              context,
                              tournamentId,
                              allMatches,
                              isBunaiksen: false,
                            ),
                            icon: Icon(
                              Icons.gavel,
                              size: 16,
                              color: isDark
                                  ? Colors.indigo.shade300
                                  : Colors.indigo.shade700,
                            ),
                            label: Text(
                              'ルール一括変更',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDark
                                    ? Colors.indigo.shade300
                                    : Colors.indigo.shade700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.indigo.shade300
                                  : Colors.indigo.shade700,
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF38383A)
                                    : Colors.indigo.shade200,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        OutlinedButton.icon(
                          onPressed: () =>
                              ref.read(categorySortProvider.notifier).state =
                                  !ref.read(categorySortProvider),
                          icon: Icon(
                            ref.watch(categorySortProvider)
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 16,
                          ),
                          label: Text(
                            ref.watch(categorySortProvider)
                                ? 'カテゴリ昇順'
                                : 'カテゴリ降順',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.indigo.shade300
                                : Colors.indigo.shade700,
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : Colors.indigo.shade200,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (timelineResult.hasError)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'データの取得に失敗しました',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade300 : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timelineResult.errorMessage ?? '通信状況を確認してください',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        if (timelineResult.entries.isEmpty && sanitizedQuery.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                '該当する試合が見つかりません',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        // ★ 追加: 検索もしておらず、エラーもなく、ただ純粋に試合が0件の場合のメッセージ
        if (timelineResult.entries.isEmpty &&
            !timelineResult.isLoading &&
            sanitizedQuery.isEmpty &&
            !timelineResult.hasError)
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Center(
              child: Text(
                'まだ試合がありません\n（またはクラウド同期待ちです）',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ),
          ),

        if (timelineResult.entries.isEmpty && timelineResult.isLoading)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        ...(() {
          if (timelineResult.entries.isEmpty) return <Widget>[];
          final sortedEntries = timelineResult.entries;
          return sortedEntries.map<Widget>((catEntry) {
            final categoryName = catEntry.key;
            final catMatches = catEntry.value;
            final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
            final matchesByTeam = <String, List<MatchModel>>{};

            final groupToOwnTeams = <String, Set<String>>{};
            final groupToRepresentativeTeam = <String, String>{};

            for (var m in catMatches) {
              if (m.groupName != null && m.groupName!.isNotEmpty) {
                String rTeam = m.redName.contains(':')
                    ? m.redName.split(':').first.trim()
                    : m.redName;
                String wTeam = m.whiteName.contains(':')
                    ? m.whiteName.split(':').first.trim()
                    : m.whiteName;
                final isRedOwnForM =
                    ownTeams.contains(rTeam) ||
                    (m.rule?.teamName.isNotEmpty == true &&
                        rTeam == m.rule!.teamName);
                final isWhiteOwnForM =
                    ownTeams.contains(wTeam) ||
                    (m.rule?.teamName.isNotEmpty == true &&
                        wTeam == m.rule!.teamName);
                if (isRedOwnForM) {
                  groupToOwnTeams
                      .putIfAbsent(m.groupName!, () => {})
                      .add(rTeam);
                }
                if (isWhiteOwnForM) {
                  groupToOwnTeams
                      .putIfAbsent(m.groupName!, () => {})
                      .add(wTeam);
                }

                // ★ 追加: グループの代表チームを決定し、同じリーグが引き裂かれるのを防ぐ
                if (!groupToRepresentativeTeam.containsKey(m.groupName!)) {
                  groupToRepresentativeTeam[m.groupName!] =
                      rTeam.isNotEmpty && !rTeam.contains('代表')
                      ? rTeam
                      : (wTeam.isNotEmpty && !wTeam.contains('代表')
                            ? wTeam
                            : '設定なし');
                }
              }
            }

            for (var m in catMatches) {
              String rTeam = m.redName.contains(':')
                  ? m.redName.split(':').first.trim()
                  : m.redName;
              String wTeam = m.whiteName.contains(':')
                  ? m.whiteName.split(':').first.trim()
                  : m.whiteName;

              bool isRedOwn =
                  ownTeams.contains(rTeam) ||
                  (m.rule?.teamName.isNotEmpty == true &&
                      rTeam == m.rule!.teamName);
              bool isWhiteOwn =
                  ownTeams.contains(wTeam) ||
                  (m.rule?.teamName.isNotEmpty == true &&
                      wTeam == m.rule!.teamName);

              if (m.groupName != null && m.groupName!.isNotEmpty) {
                if (groupToOwnTeams.containsKey(m.groupName!)) {
                  for (String team in groupToOwnTeams[m.groupName!]!) {
                    matchesByTeam.putIfAbsent(team, () => []).add(m);
                  }
                } else {
                  // ★ 追加: 自チームが含まれないグループは、代表チームをキーにして全試合を一極集中させる
                  final repTeam =
                      groupToRepresentativeTeam[m.groupName!] ?? '設定なし';
                  matchesByTeam.putIfAbsent(repTeam, () => []).add(m);
                }
              } else {
                if (isRedOwn) matchesByTeam.putIfAbsent(rTeam, () => []).add(m);
                if (isWhiteOwn && wTeam != rTeam) {
                  matchesByTeam.putIfAbsent(wTeam, () => []).add(m);
                }
                if (!isRedOwn && !isWhiteOwn) {
                  final keyTeam = rTeam.isNotEmpty && !rTeam.contains('代表')
                      ? rTeam
                      : (wTeam.isNotEmpty && !wTeam.contains('代表')
                            ? wTeam
                            : '設定なし');
                  matchesByTeam.putIfAbsent(keyTeam, () => []).add(m);
                }
              }
            }

            final sortedTeams = matchesByTeam.entries.toList();
            sortedTeams.sort((a, b) => a.key.compareTo(b.key));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.indigo.shade300
                          : Colors.indigo.shade800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                ...sortedTeams.map((teamEntry) {
                  final teamName = teamEntry.key;
                  final teamMatchesList = teamEntry.value;

                  String getMatchLabel(MatchModel m) {
                    final bool isLeague = m.note.contains('[リーグ戦]');
                    final bool isKachinuki = m.isKachinuki;
                    final bool isIndividual =
                        !isKachinuki &&
                        (m.matchType == 'individual' || m.matchType == '選手');
                    if (isLeague) return isIndividual ? '個人戦/リーグ戦' : '団体戦/リーグ戦';
                    if (isKachinuki) return '団体戦/勝ち抜き戦';
                    return isIndividual ? '個人戦' : '団体戦';
                  }

                  final catGroupedMatches = <String, List<MatchModel>>{};
                  final catIndividualMatches = <MatchModel>[];

                  for (var m in teamMatchesList) {
                    bool forceIndividual =
                        sanitizedQuery.isNotEmpty &&
                        matchedMatchIds.contains(m.id) &&
                        (m.groupName == null ||
                            !matchedGroupNames.contains(m.groupName!));
                    if (!forceIndividual &&
                        m.groupName != null &&
                        m.groupName!.isNotEmpty) {
                      catGroupedMatches
                          .putIfAbsent(m.groupName!, () => [])
                          .add(m);
                    } else {
                      catIndividualMatches.add(m);
                    }
                  }

                  final actualGroupedMatches = <String, List<MatchModel>>{};
                  for (var entry in catGroupedMatches.entries) {
                    final firstMatch = entry.value.first;
                    final bool isLeagueMatch = firstMatch.note.contains(
                      '[リーグ戦]',
                    );
                    final bool isPureIndividual =
                        !firstMatch.isKachinuki &&
                        (firstMatch.matchType == 'individual' ||
                            firstMatch.matchType == '選手' ||
                            firstMatch.matchType.contains('個人戦'));

                    if (!isPureIndividual &&
                        (entry.value.length > 1 || firstMatch.isKachinuki)) {
                      actualGroupedMatches[entry.key] = entry.value;
                    } else if (isLeagueMatch) {
                      actualGroupedMatches[entry.key] = entry.value;
                    } else {
                      catIndividualMatches.addAll(entry.value);
                    }
                  }

                  final matchesByPlayer = <String, List<MatchModel>>{};
                  for (var m in catIndividualMatches) {
                    String playerName = '選手名不明';
                    bool forceIndividual =
                        sanitizedQuery.isNotEmpty &&
                        matchedMatchIds.contains(m.id) &&
                        (m.groupName == null ||
                            !matchedGroupNames.contains(m.groupName!));
                    if (forceIndividual) {
                      String rPlayer = m.redName.contains(':')
                          ? m.redName.split(':').last.trim()
                          : m.redName;
                      String wPlayer = m.whiteName.contains(':')
                          ? m.whiteName.split(':').last.trim()
                          : m.whiteName;
                      if (rPlayer
                          .replaceAll(RegExp(r'\s+'), '')
                          .toLowerCase()
                          .contains(sanitizedQuery)) {
                        playerName = rPlayer;
                      } else if (wPlayer
                          .replaceAll(RegExp(r'\s+'), '')
                          .toLowerCase()
                          .contains(sanitizedQuery)) {
                        playerName = wPlayer;
                      } else {
                        playerName = m.redName.contains(teamName)
                            ? rPlayer
                            : wPlayer;
                      }
                    } else {
                      if (m.redName.contains(teamName) ||
                          ownTeams.any((ot) => m.redName.contains(ot)) ||
                          (m.rule?.teamName.isNotEmpty == true &&
                              m.redName.contains(m.rule!.teamName))) {
                        playerName = m.redName.contains(':')
                            ? m.redName.split(':').last.trim()
                            : m.redName;
                      } else if (m.whiteName.contains(teamName) ||
                          ownTeams.any((ot) => m.whiteName.contains(ot)) ||
                          (m.rule?.teamName.isNotEmpty == true &&
                              m.whiteName.contains(m.rule!.teamName))) {
                        playerName = m.whiteName.contains(':')
                            ? m.whiteName.split(':').last.trim()
                            : m.whiteName;
                      } else {
                        playerName = m.redName.contains(':')
                            ? m.redName.split(':').last.trim()
                            : m.redName;
                      }
                    }
                    matchesByPlayer.putIfAbsent(playerName, () => []).add(m);
                  }

                  final sortedGroups = actualGroupedMatches.entries.toList()
                    ..sort(
                      (a, b) =>
                          a.value.first.order.compareTo(b.value.first.order),
                    );
                  final sortedPlayers = matchesByPlayer.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

                  return Container(
                    margin: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 24,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161618) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.indigo.shade900.withValues(alpha: 0.3)
                                : Colors.indigo.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? const Color(0xFF38383A)
                                    : Colors.indigo.shade100,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: isDark
                                    ? Colors.indigo.shade300
                                    : Colors.indigo.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  teamName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.indigo.shade900,
                                  ),
                                ),
                              ),

                              if (!isReadOnlyUI) ...[
                                IconButton(
                                  icon: Icon(
                                    Icons.add_comment,
                                    color: isDark
                                        ? Colors.indigo.shade400
                                        : Colors.indigo.shade300,
                                    size: 20,
                                  ),
                                  tooltip: '見出し（コメント）を追加',
                                  onPressed: () {
                                    double topOrder = 0.0;
                                    double groupMin = sortedGroups.isEmpty
                                        ? double.infinity
                                        : sortedGroups.first.value.first.order;
                                    double playerMin = sortedPlayers.isEmpty
                                        ? double.infinity
                                        : sortedPlayers.first.value.first.order;
                                    double minOrder = groupMin < playerMin
                                        ? groupMin
                                        : playerMin;
                                    if (minOrder != double.infinity) {
                                      topOrder = minOrder - 100.0;
                                    }
                                    showUnifiedAnnounceDialog(
                                      context,
                                      ref,
                                      tournamentId,
                                      categoryName,
                                      teamName,
                                      topOrder,
                                    );
                                  },
                                ),
                                if (canManageTournamentUI)
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_note,
                                      color: isDark
                                          ? Colors.indigo.shade400
                                          : Colors.indigo.shade300,
                                      size: 20,
                                    ),
                                    tooltip: 'チーム名を修正して統合',
                                    onPressed: () => _showRenameTeamSheet(
                                      context,
                                      ref,
                                      tournamentId,
                                      teamName,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Builder(
                          builder: (context) {
                            final timelineItems = <ReorderableTimelineItem>[];
                            for (var entry in sortedGroups) {
                              final groupComments = comments
                                  .where(
                                    (c) =>
                                        c.category == categoryName &&
                                        c.groupName == teamName &&
                                        c.matchGroupId == entry.key,
                                  )
                                  .toList();
                              timelineItems.add(
                                MatchGroupTimelineItem(
                                  entry.key,
                                  entry.value,
                                  groupComments,
                                ),
                              );
                            }
                            // ★ 修正: アコーディオン内に属さない（matchGroupId == null）コメントだけをチーム全体のタイムラインに配置する
                            final teamComments = comments
                                .where(
                                  (c) =>
                                      c.category == categoryName &&
                                      c.groupName == teamName &&
                                      c.matchGroupId == null,
                                )
                                .toList();
                            for (var c in teamComments) {
                              timelineItems.add(CommentTimelineItem(c));
                            }
                            timelineItems.sort(
                              (a, b) => a.order.compareTo(b.order),
                            );

                            return ReorderableListView(
                              shrinkWrap: true,
                              // ★ 修正: 閲覧専用の時はドラッグの物理的な動きを完全にロックし、誤タップによるブレを完全防止
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles:
                                  !isReadOnlyUI, // ★ 追加: 閲覧モードの時はドラッグ用のハンドルをつまませない
                              onReorderItem: (oldIndex, newIndex) =>
                                  _onReorderTimeline(
                                    timelineItems,
                                    oldIndex,
                                    newIndex,
                                    ref,
                                  ),
                              children: (() {
                                String lastGroupLabel = '';
                                return timelineItems
                                    .map<Widget?>((item) {
                                      if (item is CommentTimelineItem) {
                                        final c = item.comment;
                                        final commentWidget = Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2C2C2E)
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF38383A)
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.label_outline,
                                                color: isDark
                                                    ? Colors.grey.shade500
                                                    : Colors.grey.shade600,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  c.text,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.grey.shade300
                                                        : Colors.grey.shade800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        return Container(
                                          key: ValueKey('comment_${c.id}'),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          child: Slidable(
                                            key: ValueKey(
                                              'slidable_comment_${c.id}',
                                            ),
                                            endActionPane: ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) =>
                                                      _showEditCommentDialog(
                                                        context,
                                                        ref,
                                                        c,
                                                      ),
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.edit,
                                                  label: '編集',
                                                ),
                                                SlidableAction(
                                                  onPressed: (context) async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        backgroundColor: isDark
                                                            ? const Color(
                                                                0xFF1C1C1E,
                                                              )
                                                            : Colors.white,
                                                        title: Text(
                                                          '見出しの削除',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                        ),
                                                        content: Text(
                                                          'この見出しを削除しますか？\n(取り消せません)',
                                                          style: TextStyle(
                                                            color: isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'キャンセル',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              '削除',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      await ref
                                                          .read(
                                                            commentCommandProvider,
                                                          )
                                                          .deleteComment(
                                                            c.id,
                                                            c.tournamentId ??
                                                                tournamentId,
                                                          );
                                                    }
                                                  },
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.delete,
                                                  borderRadius:
                                                      const BorderRadius.horizontal(
                                                        right: Radius.circular(
                                                          8,
                                                        ),
                                                      ),
                                                  label: '削除',
                                                ),
                                              ],
                                            ),
                                            child: commentWidget,
                                          ),
                                        );
                                      } else if (item
                                          is MatchGroupTimelineItem) {
                                        final entry = MapEntry(
                                          item.groupId,
                                          item.matches,
                                        );
                                        final groupList = entry.value;
                                        final firstMatch = groupList.first;
                                        final label = getMatchLabel(firstMatch);

                                        Widget? headerWidget;
                                        if (label != lastGroupLabel) {
                                          headerWidget = Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16,
                                              top: 12,
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.groups,
                                                  color: isDark
                                                      ? Colors.indigo.shade300
                                                      : Colors.indigo.shade700,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.indigo.shade300
                                                        : Colors
                                                              .indigo
                                                              .shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          lastGroupLabel = label;
                                        }

                                        final rTeam =
                                            firstMatch.redName.contains(':')
                                            ? firstMatch.redName
                                                  .split(':')
                                                  .first
                                                  .trim()
                                            : firstMatch.redName;
                                        final wTeam =
                                            firstMatch.whiteName.contains(':')
                                            ? firstMatch.whiteName
                                                  .split(':')
                                                  .first
                                                  .trim()
                                            : firstMatch.whiteName;

                                        final hasInProgress = groupList.any(
                                          (m) => m.status == 'in_progress',
                                        );
                                        final allFinished = groupList.every(
                                          (m) =>
                                              m.status == 'finished' ||
                                              m.status == 'approved',
                                        );
                                        final Color titleColor = allFinished
                                            ? (isDark
                                                  ? Colors.grey.shade600
                                                  : Colors.grey.shade500)
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.black87);
                                        final Color subTitleColor = allFinished
                                            ? (isDark
                                                  ? Colors.grey.shade700
                                                  : Colors.grey.shade500)
                                            : (isDark
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade600);

                                        return Container(
                                          key: ValueKey(entry.key),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ?headerWidget,
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                child: Slidable(
                                                  key: ValueKey(
                                                    'group_${entry.key}',
                                                  ),
                                                  enabled:
                                                      canManageTournamentUI,
                                                  endActionPane: ActionPane(
                                                    motion:
                                                        const ScrollMotion(),
                                                    children: [
                                                      SlidableAction(
                                                        onPressed: (context) =>
                                                            _showEditGroupNoteDialog(
                                                              context,
                                                              ref,
                                                              groupList,
                                                            ),
                                                        backgroundColor:
                                                            Colors.blueAccent,
                                                        foregroundColor:
                                                            Colors.white,
                                                        icon: Icons.edit,
                                                        label: '編集',
                                                      ),
                                                      SlidableAction(
                                                        onPressed: (context) async {
                                                          final confirm = await showDialog<bool>(
                                                            context: context,
                                                            builder: (ctx) => AlertDialog(
                                                              backgroundColor:
                                                                  isDark
                                                                  ? const Color(
                                                                      0xFF1C1C1E,
                                                                    )
                                                                  : Colors
                                                                        .white,
                                                              title: Text(
                                                                '試合グループの削除',
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: isDark
                                                                      ? Colors
                                                                            .white
                                                                      : Colors
                                                                            .black87,
                                                                ),
                                                              ),
                                                              content: Text(
                                                                'このグループに含まれる全試合を\n削除しますか？\n(取り消せません)',
                                                                style: TextStyle(
                                                                  color: isDark
                                                                      ? Colors
                                                                            .white
                                                                      : Colors
                                                                            .black87,
                                                                ),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        ctx,
                                                                        false,
                                                                      ),
                                                                  child: const Text(
                                                                    'キャンセル',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        ctx,
                                                                        true,
                                                                      ),
                                                                  child: const Text(
                                                                    '削除する',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .red,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          if (confirm == true) {
                                                            for (var m
                                                                in groupList) {
                                                              await ref
                                                                  .read(
                                                                    matchCommandProvider,
                                                                  )
                                                                  .deleteMatch(
                                                                    m.id,
                                                                  );
                                                            }
                                                          }
                                                        },
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                        foregroundColor:
                                                            Colors.white,
                                                        icon: Icons.delete,
                                                        borderRadius:
                                                            const BorderRadius.horizontal(
                                                              right:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                        label: '削除',
                                                      ),
                                                    ],
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      // ★ 修正: color: cardBg, を削除
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF38383A,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                        width: 1,
                                                      ),
                                                      boxShadow: hasInProgress
                                                          ? [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .blue
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      4,
                                                                    ),
                                                              ),
                                                            ]
                                                          : [],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            11,
                                                          ),
                                                      child: ExpansionTileTheme(
                                                        data: ExpansionTileThemeData(
                                                          backgroundColor:
                                                              isDark
                                                              ? const Color(
                                                                  0xFF1C1C1E,
                                                                )
                                                              : Colors.white,
                                                          collapsedBackgroundColor:
                                                              isDark
                                                              ? const Color(
                                                                  0xFF161618,
                                                                )
                                                              : Colors.white,
                                                          iconColor: isDark
                                                              ? Colors
                                                                    .indigo
                                                                    .shade300
                                                              : Colors
                                                                    .indigo
                                                                    .shade700,
                                                          collapsedIconColor:
                                                              Colors.grey,
                                                          textColor: isDark
                                                              ? Colors.white
                                                              : Colors.black87,
                                                          collapsedTextColor:
                                                              isDark
                                                              ? Colors.white70
                                                              : Colors.black54,
                                                        ),
                                                        child: ExpansionTile(
                                                          key: ValueKey(
                                                            'group_${entry.key}',
                                                          ),
                                                          shape: const Border(),
                                                          collapsedShape:
                                                              const Border(),
                                                          childrenPadding:
                                                              EdgeInsets.zero,
                                                          tilePadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                              ),
                                                          title: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              // 🔼 【1行目】: 運営系ボタン・ステータスライン（コントロール右寄せ）
                                                              Row(
                                                                children: [
                                                                  const Spacer(),
                                                                  // 簡易入力ボタン
                                                                  if (!isReadOnlyUI &&
                                                                      !allFinished &&
                                                                      !label.contains(
                                                                        '個人戦',
                                                                      ) &&
                                                                      !label.contains(
                                                                        '勝ち抜き戦',
                                                                      ) &&
                                                                      !label.contains(
                                                                        'リーグ戦',
                                                                      ) &&
                                                                      !(ref
                                                                                  .read(
                                                                                    customTeamNamesProvider,
                                                                                  )
                                                                                  .value ??
                                                                              [])
                                                                          .contains(
                                                                            groupList.first.redName
                                                                                .split(
                                                                                  ':',
                                                                                )
                                                                                .first
                                                                                .trim(),
                                                                          ) &&
                                                                      !(ref
                                                                                  .read(
                                                                                    customTeamNamesProvider,
                                                                                  )
                                                                                  .value ??
                                                                              [])
                                                                          .contains(
                                                                            groupList.first.whiteName
                                                                                .split(
                                                                                  ':',
                                                                                )
                                                                                .first
                                                                                .trim(),
                                                                          )) ...[
                                                                    SizedBox(
                                                                      height:
                                                                          26,
                                                                      child: OutlinedButton.icon(
                                                                        onPressed: () => _showSummaryInputDialog(
                                                                          context,
                                                                          ref,
                                                                          groupList,
                                                                        ),
                                                                        icon: Icon(
                                                                          Icons
                                                                              .flash_on,
                                                                          size:
                                                                              12,
                                                                          color: Colors
                                                                              .amber
                                                                              .shade700,
                                                                        ),
                                                                        label: Text(
                                                                          '簡易入力',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                9,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                titleColor,
                                                                          ),
                                                                        ),
                                                                        style: OutlinedButton.styleFrom(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                6,
                                                                          ),
                                                                          side: BorderSide(
                                                                            color: titleColor.withValues(
                                                                              alpha: 0.2,
                                                                            ),
                                                                          ),
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                  ],
                                                                  // ℹ️詳細マーク
                                                                  if (!allFinished)
                                                                    Padding(
                                                                      padding:
                                                                          const EdgeInsets.only(
                                                                            right:
                                                                                6,
                                                                          ),
                                                                      child: InkWell(
                                                                        onTap: () => _showRuleInfoSheet(
                                                                          context,
                                                                          firstMatch,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.all(
                                                                            4.0,
                                                                          ),
                                                                          child: Icon(
                                                                            Icons.info_outline,
                                                                            color:
                                                                                isDark
                                                                                ? Colors.grey.shade600
                                                                                : Colors.grey.shade400,
                                                                            size:
                                                                                16,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  // 🛠️オーダー編集ボタン（団体戦・勝ち抜き戦・リーグ団体戦すべて共通）
                                                                  if (!isReadOnlyUI &&
                                                                      !allFinished &&
                                                                      firstMatch
                                                                              .groupName !=
                                                                          null &&
                                                                      firstMatch
                                                                          .groupName!
                                                                          .isNotEmpty) ...[
                                                                    SizedBox(
                                                                      height:
                                                                          26,
                                                                      width: 26,
                                                                      child: IconButton(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        icon: Icon(
                                                                          Icons
                                                                              .swap_vert,
                                                                          size:
                                                                              18,
                                                                          color:
                                                                              isDark
                                                                              ? Colors.blue.shade300
                                                                              : Colors.blue.shade700,
                                                                        ),
                                                                        onPressed: () => _showOrderReorderSheet(
                                                                          context,
                                                                          ref,
                                                                          groupList,
                                                                        ),
                                                                        tooltip:
                                                                            'オーダー編集',
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                  ],
                                                                  // 📊スコアボタン
                                                                  if (!label
                                                                      .contains(
                                                                        'リーグ戦',
                                                                      )) ...[
                                                                    SizedBox(
                                                                      height:
                                                                          26,
                                                                      child: OutlinedButton(
                                                                        onPressed: () {
                                                                          final target =
                                                                              (firstMatch.groupName !=
                                                                                      null &&
                                                                                  firstMatch.groupName!.isNotEmpty)
                                                                              ? firstMatch.groupName!
                                                                              : firstMatch.id;
                                                                          final encodedTarget = Uri.encodeComponent(
                                                                            target,
                                                                          );
                                                                          final tId =
                                                                              firstMatch.tournamentId ??
                                                                              '';
                                                                          context.push(
                                                                            firstMatch.isKachinuki
                                                                                ? '/kachinuki-scoreboard/$encodedTarget?tournamentId=$tId'
                                                                                : '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                                                                          );
                                                                        },
                                                                        style: OutlinedButton.styleFrom(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                8,
                                                                          ),
                                                                          side: BorderSide(
                                                                            color: titleColor.withValues(
                                                                              alpha: 0.2,
                                                                            ),
                                                                          ),
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          'スコア',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                titleColor,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                  ],
                                                                  // 状態バナー
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          hasInProgress
                                                                          ? Colors.blue.shade600
                                                                          : (allFinished
                                                                                ? (isDark
                                                                                      ? Colors.grey.shade800
                                                                                      : Colors.grey.shade300)
                                                                                : (isDark
                                                                                      ? const Color(
                                                                                          0xFF2C2C2E,
                                                                                        )
                                                                                      : Colors.grey.shade200)),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            4,
                                                                          ),
                                                                    ),
                                                                    child: Text(
                                                                      hasInProgress
                                                                          ? '進行中'
                                                                          : (allFinished
                                                                                ? '終了'
                                                                                : '待機中'),
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            hasInProgress
                                                                            ? Colors.white
                                                                            : (allFinished
                                                                                  ? (isDark
                                                                                        ? Colors.grey.shade400
                                                                                        : Colors.grey.shade600)
                                                                                  : (isDark
                                                                                        ? Colors.grey.shade400
                                                                                        : Colors.grey.shade700)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              if (firstMatch
                                                                  .note
                                                                  .isNotEmpty) ...[
                                                                const SizedBox(
                                                                  height: 6,
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            2,
                                                                      ),
                                                                  child: Text(
                                                                    firstMatch
                                                                        .note,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color:
                                                                          subTitleColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              // 🔽 【3行目】: チーム合計スコア勝数(本数)ライン
                                                              Builder(
                                                                builder: (context) {
                                                                  // 団体戦グループ内の全ポジションから勝数・本数をリアルタイムに合算算出
                                                                  int redWins =
                                                                      0;
                                                                  int redPts =
                                                                      0;
                                                                  int
                                                                  whiteWins = 0;
                                                                  int whitePts =
                                                                      0;

                                                                  for (var m
                                                                      in groupList) {
                                                                    if (m.matchType ==
                                                                        '代表戦') {
                                                                      continue; // ★ 代表戦のスコアは合計に含めない
                                                                    }
                                                                    final r = m
                                                                        .redScore;
                                                                    final w = m
                                                                        .whiteScore;
                                                                    redPts +=
                                                                        (r as num)
                                                                            .toInt();
                                                                    whitePts +=
                                                                        (w as num)
                                                                            .toInt();
                                                                    final mFinished =
                                                                        m.status ==
                                                                            'finished' ||
                                                                        m.status ==
                                                                            'approved';
                                                                    if (mFinished) {
                                                                      if (r >
                                                                          w) {
                                                                        redWins++;
                                                                      } else if (w >
                                                                          r) {
                                                                        whiteWins++;
                                                                      }
                                                                    }
                                                                  }

                                                                  final ruleTeamName =
                                                                      groupList
                                                                          .firstOrNull
                                                                          ?.rule
                                                                          ?.teamName;
                                                                  final isRedOwn =
                                                                      ownTeams
                                                                          .contains(
                                                                            rTeam,
                                                                          ) ||
                                                                      (ruleTeamName?.isNotEmpty ==
                                                                              true &&
                                                                          rTeam ==
                                                                              ruleTeamName);
                                                                  final isWhiteOwn =
                                                                      ownTeams
                                                                          .contains(
                                                                            wTeam,
                                                                          ) ||
                                                                      (ruleTeamName?.isNotEmpty ==
                                                                              true &&
                                                                          wTeam ==
                                                                              ruleTeamName);

                                                                  // ★ 修正: リーグ戦と通常の団体戦のRow構造を完全分離し、はみ出しを100%防止
                                                                  if (label
                                                                      .contains(
                                                                        'リーグ戦',
                                                                      )) {
                                                                    return Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: Text(
                                                                            _generateDescriptiveLeagueTitle(
                                                                              groupList,
                                                                              ownTeams,
                                                                            ),
                                                                            style: TextStyle(
                                                                              fontSize: 13,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: titleColor,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis, // 268pxの極小画面でも絶対に溢れず綺麗に省略
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  } else {
                                                                    final showLeftTeam =
                                                                        rTeam;
                                                                    final showRightTeam =
                                                                        wTeam;
                                                                    final showLeftWins =
                                                                        redWins;
                                                                    final showLeftPts =
                                                                        redPts;
                                                                    final showRightWins =
                                                                        whiteWins;
                                                                    final showRightPts =
                                                                        whitePts;
                                                                    final showLeftOwn =
                                                                        isRedOwn;
                                                                    final showRightOwn =
                                                                        isWhiteOwn;

                                                                    return Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        // 左チーム名
                                                                        Expanded(
                                                                          child: Text(
                                                                            showLeftTeam,
                                                                            style: TextStyle(
                                                                              fontSize: 15,
                                                                              fontWeight: showLeftOwn
                                                                                  ? FontWeight.w900
                                                                                  : FontWeight.bold,
                                                                              color: showLeftOwn
                                                                                  ? Colors.amber.shade600
                                                                                  : titleColor,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.end,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        // 中央合計スコア掲示（例: 3(5) - 1(2)）
                                                                        Padding(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                16,
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Text(
                                                                                '$showLeftWins',
                                                                                style: TextStyle(
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: isDark
                                                                                      ? Colors.red.shade300
                                                                                      : Colors.red.shade700,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                '($showLeftPts)',
                                                                                style: TextStyle(
                                                                                  fontSize: 11,
                                                                                  color: isDark
                                                                                      ? Colors.grey.shade400
                                                                                      : Colors.grey.shade600,
                                                                                ),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.symmetric(
                                                                                  horizontal: 6,
                                                                                ),
                                                                                child: Text(
                                                                                  'ー',
                                                                                  style: TextStyle(
                                                                                    fontSize: 14,
                                                                                    color: Colors.grey.shade400,
                                                                                    fontWeight: FontWeight.bold,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                '$showRightWins',
                                                                                style: TextStyle(
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: isDark
                                                                                      ? Colors.white
                                                                                      : Colors.black87,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                '($showRightPts)',
                                                                                style: TextStyle(
                                                                                  fontSize: 11,
                                                                                  color: isDark
                                                                                      ? Colors.grey.shade400
                                                                                      : Colors.grey.shade600,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        // 右チーム名
                                                                        Expanded(
                                                                          child: Text(
                                                                            showRightTeam,
                                                                            style: TextStyle(
                                                                              fontSize: 15,
                                                                              fontWeight: showRightOwn
                                                                                  ? FontWeight.w900
                                                                                  : FontWeight.bold,
                                                                              color: showRightOwn
                                                                                  ? Colors.amber.shade600
                                                                                  : titleColor,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.start,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                          children: (() {
                                                            final List<Widget>
                                                            childrenWidgets =
                                                                [];
                                                            final normalMatches =
                                                                groupList
                                                                    .where(
                                                                      (m) => !m
                                                                          .note
                                                                          .contains(
                                                                            '[順位決定戦]',
                                                                          ),
                                                                    )
                                                                    .toList();
                                                            final tieBreakMatches =
                                                                groupList
                                                                    .where(
                                                                      (m) => m
                                                                          .note
                                                                          .contains(
                                                                            '[順位決定戦]',
                                                                          ),
                                                                    )
                                                                    .toList();
                                                            final normalItems = item
                                                                .sortedInnerItems
                                                                .where((i) {
                                                                  if (i
                                                                      is MatchModel) {
                                                                    return !i
                                                                        .note
                                                                        .contains(
                                                                          '[順位決定戦]',
                                                                        );
                                                                  }
                                                                  return true;
                                                                })
                                                                .toList();

                                                            if (label.contains(
                                                                  'リーグ戦',
                                                                ) &&
                                                                allFinished &&
                                                                !label.contains(
                                                                  '個人戦',
                                                                ) &&
                                                                tieBreakMatches
                                                                    .isEmpty) {
                                                              final rule =
                                                                  firstMatch
                                                                      .rule ??
                                                                  ref.read(
                                                                    matchRuleProvider,
                                                                  );
                                                              final tieGroups =
                                                                  <
                                                                    List<
                                                                      dynamic
                                                                    >
                                                                  >[];
                                                              // ★ 適合修正: 強制アンラップ (!) を排し、if による無害なヌルガードを緊縛して Lint 警告を完全消滅させます
                                                              if (rule !=
                                                                  null) {
                                                                final stats =
                                                                    KendoRuleEngine.calculateLeagueStandings(
                                                                      normalMatches,
                                                                      rule,
                                                                    );
                                                                if (stats
                                                                        .length >
                                                                    1) {
                                                                  List<dynamic>
                                                                  currentTie = [
                                                                    stats.first,
                                                                  ];
                                                                  for (
                                                                    int i = 1;
                                                                    i <
                                                                        stats
                                                                            .length;
                                                                    i++
                                                                  ) {
                                                                    final prev =
                                                                        stats[i -
                                                                            1];
                                                                    final curr =
                                                                        stats[i];
                                                                    bool isTie =
                                                                        (prev.customPoints -
                                                                                    curr.customPoints)
                                                                                .abs() <
                                                                            0.001 &&
                                                                        prev.matchWins ==
                                                                            curr.matchWins &&
                                                                        prev.individualWinners ==
                                                                            curr.individualWinners &&
                                                                        prev.totalPointsScored ==
                                                                            curr.totalPointsScored;
                                                                    if (isTie) {
                                                                      currentTie
                                                                          .add(
                                                                            curr,
                                                                          );
                                                                    } else {
                                                                      if (currentTie
                                                                              .length >
                                                                          1) {
                                                                        tieGroups.add(
                                                                          List.from(
                                                                            currentTie,
                                                                          ),
                                                                        );
                                                                      }
                                                                      currentTie =
                                                                          [curr];
                                                                    }
                                                                  }
                                                                  if (currentTie
                                                                          .length >
                                                                      1) {
                                                                    tieGroups.add(
                                                                      currentTie,
                                                                    );
                                                                  }
                                                                }

                                                                if (tieGroups
                                                                    .isNotEmpty) {
                                                                  childrenWidgets.add(
                                                                    Container(
                                                                      margin:
                                                                          const EdgeInsets.all(
                                                                            12,
                                                                          ),
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            12,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            isDark
                                                                            ? Colors.orange.shade900.withValues(
                                                                                alpha: 0.2,
                                                                              )
                                                                            : Colors.orange.shade50,
                                                                        border: Border.all(
                                                                          color: Colors
                                                                              .orange
                                                                              .shade300,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                      ),
                                                                      child: Column(
                                                                        children: tieGroups.map((
                                                                          group,
                                                                        ) {
                                                                          return ElevatedButton.icon(
                                                                            onPressed: () => _showTieBreakDialog(
                                                                              context,
                                                                              ref,
                                                                              firstMatch,
                                                                              group,
                                                                              rule,
                                                                            ),
                                                                            icon: const Icon(
                                                                              Icons.add_circle,
                                                                            ),
                                                                            label: const Text(
                                                                              '順位決定戦を作成',
                                                                            ),
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor: Colors.orange.shade700,
                                                                              foregroundColor: Colors.white,
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            }

                                                            if (label.contains(
                                                              'リーグ戦',
                                                            )) {
                                                              if (label
                                                                  .contains(
                                                                    '個人戦',
                                                                  )) {
                                                                childrenWidgets.add(
                                                                  ReorderableListView(
                                                                    shrinkWrap:
                                                                        true,
                                                                    physics:
                                                                        const NeverScrollableScrollPhysics(),
                                                                    buildDefaultDragHandles:
                                                                        !isReadOnlyUI,
                                                                    onReorderItem:
                                                                        (
                                                                          oldIndex,
                                                                          newIndex,
                                                                        ) => _onReorderInnerTimeline(
                                                                          normalItems,
                                                                          oldIndex,
                                                                          newIndex,
                                                                          ref,
                                                                        ),
                                                                    children: normalItems
                                                                        .map<
                                                                          Widget?
                                                                        >((i) {
                                                                          if (i
                                                                              is MatchModel) {
                                                                            // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                            return Container(
                                                                              key: ValueKey(
                                                                                i.id,
                                                                              ),
                                                                              child: MatchListTileCard(
                                                                                initialMatch: i,
                                                                                isDeletable: true,
                                                                              ),
                                                                            );
                                                                          } else if (i
                                                                              is MatchCommentModel) {
                                                                            return Container(
                                                                              key: ValueKey(
                                                                                'inner_comment_${i.id}',
                                                                              ),
                                                                              child: _buildInnerCommentWidget(
                                                                                context,
                                                                                ref,
                                                                                i,
                                                                                permissions,
                                                                                isDark,
                                                                              ),
                                                                            );
                                                                          }
                                                                          return null;
                                                                        })
                                                                        .whereType<
                                                                          Widget
                                                                        >()
                                                                        .toList(),
                                                                  ),
                                                                );
                                                              } else {
                                                                final boutsByMatchup =
                                                                    <
                                                                      String,
                                                                      List<
                                                                        MatchModel
                                                                      >
                                                                    >{};
                                                                final matchupOrder =
                                                                    <String>[];
                                                                for (var m
                                                                    in normalMatches) {
                                                                  final matchupName =
                                                                      '${m.redName.split(':').first.trim()} vs ${m.whiteName.split(':').first.trim()}';
                                                                  if (!boutsByMatchup
                                                                      .containsKey(
                                                                        matchupName,
                                                                      )) {
                                                                    matchupOrder
                                                                        .add(
                                                                          matchupName,
                                                                        );
                                                                    boutsByMatchup[matchupName] =
                                                                        [];
                                                                  }
                                                                  boutsByMatchup[matchupName]!
                                                                      .add(m);
                                                                }

                                                                final combinedItems =
                                                                    <dynamic>[];
                                                                for (var name
                                                                    in matchupOrder) {
                                                                  combinedItems.add({
                                                                    'type':
                                                                        'matchup',
                                                                    'name':
                                                                        name,
                                                                    'matches':
                                                                        boutsByMatchup[name]!,
                                                                    'order': boutsByMatchup[name]!
                                                                        .first
                                                                        .order,
                                                                  });
                                                                }
                                                                for (var i
                                                                    in normalItems) {
                                                                  if (i
                                                                      is MatchCommentModel) {
                                                                    combinedItems.add({
                                                                      'type':
                                                                          'comment',
                                                                      'comment':
                                                                          i,
                                                                      'order': i
                                                                          .order,
                                                                    });
                                                                  }
                                                                }
                                                                combinedItems.sort(
                                                                  (a, b) =>
                                                                      (a['order']
                                                                              as double)
                                                                          .compareTo(
                                                                            b['order']
                                                                                as double,
                                                                          ),
                                                                );

                                                                childrenWidgets.add(
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .stretch,
                                                                    children: combinedItems.map<Widget>((
                                                                      cItem,
                                                                    ) {
                                                                      if (cItem['type'] ==
                                                                          'comment') {
                                                                        final c =
                                                                            cItem['comment']
                                                                                as MatchCommentModel;
                                                                        return Container(
                                                                          key: ValueKey(
                                                                            'inner_comment_${c.id}',
                                                                          ),
                                                                          child: _buildInnerCommentWidget(
                                                                            context,
                                                                            ref,
                                                                            c,
                                                                            permissions,
                                                                            isDark,
                                                                          ),
                                                                        );
                                                                      }
                                                                      final name =
                                                                          cItem['name']
                                                                              as String;
                                                                      final bouts =
                                                                          cItem['matches']
                                                                              as List<
                                                                                MatchModel
                                                                              >;
                                                                      final bool
                                                                      boutsInProgress = bouts.any(
                                                                        (m) =>
                                                                            m.status ==
                                                                            'in_progress',
                                                                      );
                                                                      final bool
                                                                      boutsAllFinished = bouts.every(
                                                                        (m) =>
                                                                            m.status ==
                                                                                'finished' ||
                                                                            m.status ==
                                                                                'approved',
                                                                      );
                                                                      final t1 =
                                                                          name.split(
                                                                            ' vs ',
                                                                          )[0];
                                                                      final t2 =
                                                                          name.split(
                                                                            ' vs ',
                                                                          )[1];
                                                                      final Color
                                                                      mTitleColor =
                                                                          boutsAllFinished
                                                                          ? (isDark
                                                                                ? Colors.grey.shade600
                                                                                : Colors.grey.shade500)
                                                                          : (isDark
                                                                                ? Colors.white
                                                                                : Colors.black87);

                                                                      return Container(
                                                                        key: ValueKey(
                                                                          'league_team_$name',
                                                                        ),
                                                                        margin: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              8,
                                                                          vertical:
                                                                              4,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                8,
                                                                              ),
                                                                          border: Border.all(
                                                                            color:
                                                                                isDark
                                                                                ? const Color(
                                                                                    0xFF38383A,
                                                                                  )
                                                                                : Colors.grey.shade300,
                                                                            width:
                                                                                1,
                                                                          ),
                                                                          boxShadow:
                                                                              boutsInProgress
                                                                              ? [
                                                                                  BoxShadow(
                                                                                    color: Colors.blue.withValues(
                                                                                      alpha: 0.1,
                                                                                    ),
                                                                                    blurRadius: 4,
                                                                                    offset: const Offset(
                                                                                      0,
                                                                                      2,
                                                                                    ),
                                                                                  ),
                                                                                ]
                                                                              : [],
                                                                        ),
                                                                        child: ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                7,
                                                                              ),
                                                                          child: ExpansionTileTheme(
                                                                            data: ExpansionTileThemeData(
                                                                              backgroundColor: isDark
                                                                                  ? const Color(
                                                                                      0xFF1C1C1E,
                                                                                    )
                                                                                  : Colors.white,
                                                                              collapsedBackgroundColor: isDark
                                                                                  ? const Color(
                                                                                      0xFF161618,
                                                                                    )
                                                                                  : Colors.white,
                                                                              iconColor: isDark
                                                                                  ? Colors.indigo.shade300
                                                                                  : Colors.indigo.shade700,
                                                                              collapsedIconColor: Colors.grey,
                                                                              textColor: isDark
                                                                                  ? Colors.white
                                                                                  : Colors.black87,
                                                                              collapsedTextColor: isDark
                                                                                  ? Colors.white70
                                                                                  : Colors.black54,
                                                                            ),
                                                                            child: ExpansionTile(
                                                                              key: ValueKey(
                                                                                'tile_league_team_$name',
                                                                              ),
                                                                              backgroundColor: isDark
                                                                                  ? const Color(
                                                                                      0xFF1C1C1E,
                                                                                    )
                                                                                  : Colors.white,
                                                                              collapsedBackgroundColor: isDark
                                                                                  ? const Color(
                                                                                      0xFF161618,
                                                                                    )
                                                                                  : Colors.white,
                                                                              iconColor: isDark
                                                                                  ? Colors.indigo.shade300
                                                                                  : Colors.indigo.shade700,
                                                                              collapsedIconColor: Colors.grey,
                                                                              textColor: isDark
                                                                                  ? Colors.white
                                                                                  : Colors.black87,
                                                                              collapsedTextColor: isDark
                                                                                  ? Colors.white70
                                                                                  : Colors.black54,
                                                                              shape: const Border(),
                                                                              collapsedShape: const Border(),
                                                                              childrenPadding: EdgeInsets.zero,
                                                                              tilePadding: const EdgeInsets.symmetric(
                                                                                horizontal: 16,
                                                                              ),
                                                                              title: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  // 🔼 【中枠1行目】: コントロールボタン集約ライン
                                                                                  Row(
                                                                                    children: [
                                                                                      Text(
                                                                                        '${bouts.length}ポジション',
                                                                                        style: const TextStyle(
                                                                                          fontSize: 11,
                                                                                          color: Colors.grey,
                                                                                          fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                      ),
                                                                                      const Spacer(),
                                                                                      // 簡易入力
                                                                                      Builder(
                                                                                        builder:
                                                                                            (
                                                                                              context,
                                                                                            ) {
                                                                                              final ownT =
                                                                                                  ref
                                                                                                      .read(
                                                                                                        customTeamNamesProvider,
                                                                                                      )
                                                                                                      .value ??
                                                                                                  [];
                                                                                              final rT = bouts.first.redName
                                                                                                  .split(
                                                                                                    ':',
                                                                                                  )
                                                                                                  .first
                                                                                                  .trim();
                                                                                              final wT = bouts.first.whiteName
                                                                                                  .split(
                                                                                                    ':',
                                                                                                  )
                                                                                                  .first
                                                                                                  .trim();
                                                                                              if (!isReadOnlyUI &&
                                                                                                  !boutsAllFinished &&
                                                                                                  !(ownT.contains(
                                                                                                        rT,
                                                                                                      ) ||
                                                                                                      bouts.first.redName.contains(
                                                                                                        '自チーム',
                                                                                                      )) &&
                                                                                                  !(ownT.contains(
                                                                                                        wT,
                                                                                                      ) ||
                                                                                                      bouts.first.whiteName.contains(
                                                                                                        '自チーム',
                                                                                                      ))) {
                                                                                                return Padding(
                                                                                                  padding: const EdgeInsets.only(
                                                                                                    right: 6,
                                                                                                  ),
                                                                                                  child: SizedBox(
                                                                                                    height: 24,
                                                                                                    child: OutlinedButton.icon(
                                                                                                      onPressed: () => _showSummaryInputDialog(
                                                                                                        context,
                                                                                                        ref,
                                                                                                        bouts,
                                                                                                      ),
                                                                                                      icon: Icon(
                                                                                                        Icons.flash_on,
                                                                                                        size: 11,
                                                                                                        color: Colors.amber.shade700,
                                                                                                      ),
                                                                                                      label: Text(
                                                                                                        '簡易入力',
                                                                                                        style: TextStyle(
                                                                                                          fontSize: 9,
                                                                                                          fontWeight: FontWeight.bold,
                                                                                                          color: mTitleColor,
                                                                                                        ),
                                                                                                      ),
                                                                                                      style: OutlinedButton.styleFrom(
                                                                                                        padding: const EdgeInsets.symmetric(
                                                                                                          horizontal: 6,
                                                                                                        ),
                                                                                                        side: BorderSide(
                                                                                                          color: mTitleColor.withValues(
                                                                                                            alpha: 0.2,
                                                                                                          ),
                                                                                                        ),
                                                                                                        shape: RoundedRectangleBorder(
                                                                                                          borderRadius: BorderRadius.circular(
                                                                                                            6,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                );
                                                                                              }
                                                                                              return const SizedBox.shrink();
                                                                                            },
                                                                                      ),
                                                                                      // スコアボタン
                                                                                      Padding(
                                                                                        padding: const EdgeInsets.only(
                                                                                          right: 6,
                                                                                        ),
                                                                                        child: SizedBox(
                                                                                          height: 24,
                                                                                          child: OutlinedButton(
                                                                                            onPressed: () {
                                                                                              final target =
                                                                                                  (bouts.first.groupName !=
                                                                                                          null &&
                                                                                                      bouts.first.groupName!.isNotEmpty)
                                                                                                  ? bouts.first.groupName!
                                                                                                  : bouts.first.id;
                                                                                              final encodedTarget = Uri.encodeComponent(
                                                                                                target,
                                                                                              );
                                                                                              final tId =
                                                                                                  bouts.first.tournamentId ??
                                                                                                  '';
                                                                                              context.push(
                                                                                                '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                                                                                              );
                                                                                            },
                                                                                            style: OutlinedButton.styleFrom(
                                                                                              padding: const EdgeInsets.symmetric(
                                                                                                horizontal: 8,
                                                                                              ),
                                                                                              side: BorderSide(
                                                                                                color: mTitleColor.withValues(
                                                                                                  alpha: 0.2,
                                                                                                ),
                                                                                              ),
                                                                                              shape: RoundedRectangleBorder(
                                                                                                borderRadius: BorderRadius.circular(
                                                                                                  6,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            child: Text(
                                                                                              'スコア',
                                                                                              style: TextStyle(
                                                                                                fontSize: 10,
                                                                                                fontWeight: FontWeight.bold,
                                                                                                color: mTitleColor,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      // 状態バナー
                                                                                      Container(
                                                                                        padding: const EdgeInsets.symmetric(
                                                                                          horizontal: 6,
                                                                                          vertical: 2,
                                                                                        ),
                                                                                        decoration: BoxDecoration(
                                                                                          color: boutsInProgress
                                                                                              ? Colors.blue.shade600
                                                                                              : (boutsAllFinished
                                                                                                    ? (isDark
                                                                                                          ? Colors.grey.shade800
                                                                                                          : Colors.grey.shade300)
                                                                                                    : (isDark
                                                                                                          ? const Color(
                                                                                                              0xFF2C2C2E,
                                                                                                            )
                                                                                                          : Colors.grey.shade200)),
                                                                                          borderRadius: BorderRadius.circular(
                                                                                            4,
                                                                                          ),
                                                                                        ),
                                                                                        child: Text(
                                                                                          boutsInProgress
                                                                                              ? '進行中'
                                                                                              : (boutsAllFinished
                                                                                                    ? '終了'
                                                                                                    : '待機中'),
                                                                                          style: TextStyle(
                                                                                            fontSize: 10,
                                                                                            fontWeight: FontWeight.bold,
                                                                                            color: boutsInProgress
                                                                                                ? Colors.white
                                                                                                : (boutsAllFinished
                                                                                                      ? (isDark
                                                                                                            ? Colors.grey.shade400
                                                                                                            : Colors.grey.shade600)
                                                                                                      : (isDark
                                                                                                            ? Colors.grey.shade400
                                                                                                            : Colors.grey.shade700)),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                  const SizedBox(
                                                                                    height: 8,
                                                                                  ),
                                                                                  // 🔽 【中枠2行目】: リーグ内チーム対抗勝数(本数)掲示ライン
                                                                                  Builder(
                                                                                    builder:
                                                                                        (
                                                                                          context,
                                                                                        ) {
                                                                                          int redWins = 0;
                                                                                          int redPts = 0;
                                                                                          int whiteWins = 0;
                                                                                          int whitePts = 0;
                                                                                          for (var m in bouts) {
                                                                                            final r = m.redScore;
                                                                                            final w = m.whiteScore;
                                                                                            redPts +=
                                                                                                (r
                                                                                                        as num)
                                                                                                    .toInt();
                                                                                            whitePts +=
                                                                                                (w
                                                                                                        as num)
                                                                                                    .toInt();
                                                                                            if (m.status ==
                                                                                                    'finished' ||
                                                                                                m.status ==
                                                                                                    'approved') {
                                                                                              if (r >
                                                                                                  w) {
                                                                                                redWins++;
                                                                                              } else if (w >
                                                                                                  r) {
                                                                                                whiteWins++;
                                                                                              }
                                                                                            }
                                                                                          }
                                                                                          final ruleTeamName = bouts.firstOrNull?.rule?.teamName;
                                                                                          final isRedOwn =
                                                                                              ownTeams.contains(
                                                                                                t1,
                                                                                              ) ||
                                                                                              (ruleTeamName?.isNotEmpty ==
                                                                                                      true &&
                                                                                                  t1 ==
                                                                                                      ruleTeamName);
                                                                                          final isWhiteOwn =
                                                                                              ownTeams.contains(
                                                                                                t2,
                                                                                              ) ||
                                                                                              (ruleTeamName?.isNotEmpty ==
                                                                                                      true &&
                                                                                                  t2 ==
                                                                                                      ruleTeamName);

                                                                                          final showLeftTeam = t1;
                                                                                          final showRightTeam = t2;
                                                                                          final showLeftWins = redWins;
                                                                                          final showLeftPts = redPts;
                                                                                          final showRightWins = whiteWins;
                                                                                          final showRightPts = whitePts;
                                                                                          final showLeftOwn = isRedOwn;
                                                                                          final showRightOwn = isWhiteOwn;

                                                                                          return Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            children: [
                                                                                              Expanded(
                                                                                                child: Text(
                                                                                                  showLeftTeam,
                                                                                                  style: TextStyle(
                                                                                                    fontSize: 14,
                                                                                                    fontWeight: showLeftOwn
                                                                                                        ? FontWeight.w900
                                                                                                        : FontWeight.bold,
                                                                                                    color: showLeftOwn
                                                                                                        ? Colors.amber.shade600
                                                                                                        : mTitleColor,
                                                                                                  ),
                                                                                                  textAlign: TextAlign.end,
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ),
                                                                                              ),
                                                                                              Padding(
                                                                                                padding: const EdgeInsets.symmetric(
                                                                                                  horizontal: 12,
                                                                                                ),
                                                                                                child: Row(
                                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      '$showLeftWins',
                                                                                                      style: TextStyle(
                                                                                                        fontSize: 15,
                                                                                                        fontWeight: FontWeight.bold,
                                                                                                        color: isDark
                                                                                                            ? Colors.red.shade300
                                                                                                            : Colors.red.shade700,
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      '($showLeftPts)',
                                                                                                      style: TextStyle(
                                                                                                        fontSize: 10,
                                                                                                        color: Colors.grey.shade500,
                                                                                                      ),
                                                                                                    ),
                                                                                                    Padding(
                                                                                                      padding: const EdgeInsets.symmetric(
                                                                                                        horizontal: 6,
                                                                                                      ),
                                                                                                      child: Text(
                                                                                                        'ー',
                                                                                                        style: TextStyle(
                                                                                                          fontSize: 13,
                                                                                                          color: Colors.grey.shade400,
                                                                                                          fontWeight: FontWeight.bold,
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      '$showRightWins',
                                                                                                      style: TextStyle(
                                                                                                        fontSize: 15,
                                                                                                        fontWeight: FontWeight.bold,
                                                                                                        color: isDark
                                                                                                            ? Colors.white
                                                                                                            : Colors.black87,
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      '($showRightPts)',
                                                                                                      style: TextStyle(
                                                                                                        fontSize: 10,
                                                                                                        color: Colors.grey.shade500,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Expanded(
                                                                                                child: Text(
                                                                                                  showRightTeam,
                                                                                                  style: TextStyle(
                                                                                                    fontSize: 14,
                                                                                                    fontWeight: showRightOwn
                                                                                                        ? FontWeight.w900
                                                                                                        : FontWeight.bold,
                                                                                                    color: showRightOwn
                                                                                                        ? Colors.amber.shade600
                                                                                                        : mTitleColor,
                                                                                                  ),
                                                                                                  textAlign: TextAlign.start,
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          );
                                                                                        },
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                              children: bouts
                                                                                  .map(
                                                                                    (
                                                                                      m,
                                                                                    ) => MatchListTileCard(
                                                                                      initialMatch: m,
                                                                                      isDeletable: false,
                                                                                    ),
                                                                                  )
                                                                                  .toList(),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                  ),
                                                                );
                                                              }
                                                            } else {
                                                              if (label
                                                                      .contains(
                                                                        '個人戦',
                                                                      ) ||
                                                                  label
                                                                      .contains(
                                                                        '選手',
                                                                      )) {
                                                                childrenWidgets.add(
                                                                  ReorderableListView(
                                                                    shrinkWrap:
                                                                        true,
                                                                    physics:
                                                                        const NeverScrollableScrollPhysics(),
                                                                    buildDefaultDragHandles:
                                                                        !isReadOnlyUI,
                                                                    onReorderItem:
                                                                        (
                                                                          oldIndex,
                                                                          newIndex,
                                                                        ) => _onReorderInnerTimeline(
                                                                          normalItems,
                                                                          oldIndex,
                                                                          newIndex,
                                                                          ref,
                                                                        ),
                                                                    children: normalItems
                                                                        .map<
                                                                          Widget?
                                                                        >((i) {
                                                                          if (i
                                                                              is MatchModel) {
                                                                            // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                            return Container(
                                                                              key: ValueKey(
                                                                                i.id,
                                                                              ),
                                                                              child: MatchListTileCard(
                                                                                initialMatch: i,
                                                                                isDeletable: false,
                                                                              ),
                                                                            );
                                                                          } else if (i
                                                                              is MatchCommentModel) {
                                                                            return Container(
                                                                              key: ValueKey(
                                                                                'inner_comment_${i.id}',
                                                                              ),
                                                                              child: _buildInnerCommentWidget(
                                                                                context,
                                                                                ref,
                                                                                i,
                                                                                permissions,
                                                                                isDark,
                                                                              ),
                                                                            );
                                                                          }
                                                                          return null;
                                                                        })
                                                                        .whereType<
                                                                          Widget
                                                                        >()
                                                                        .toList(),
                                                                  ),
                                                                );
                                                              } else {
                                                                childrenWidgets.add(
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .stretch,
                                                                    children: normalItems.map<Widget>((
                                                                      i,
                                                                    ) {
                                                                      if (i
                                                                          is MatchModel) {
                                                                        return Container(
                                                                          key: ValueKey(
                                                                            i.id,
                                                                          ),
                                                                          child: MatchListTileCard(
                                                                            initialMatch:
                                                                                i,
                                                                            isDeletable:
                                                                                false,
                                                                          ),
                                                                        );
                                                                      } else if (i
                                                                          is MatchCommentModel) {
                                                                        return Container(
                                                                          key: ValueKey(
                                                                            'inner_comment_${i.id}',
                                                                          ),
                                                                          child: _buildInnerCommentWidget(
                                                                            context,
                                                                            ref,
                                                                            i,
                                                                            permissions,
                                                                            isDark,
                                                                          ),
                                                                        );
                                                                      }
                                                                      return const SizedBox.shrink();
                                                                    }).toList(),
                                                                  ),
                                                                );
                                                              }
                                                            }

                                                            if (tieBreakMatches
                                                                .isNotEmpty) {
                                                              childrenWidgets.add(
                                                                const Divider(),
                                                              );
                                                              childrenWidgets.add(
                                                                const Padding(
                                                                  padding:
                                                                      EdgeInsets.all(
                                                                        8,
                                                                      ),
                                                                  child: Text(
                                                                    '【順位決定戦】',
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .orange,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                              if (label
                                                                      .contains(
                                                                        '個人戦',
                                                                      ) ||
                                                                  label
                                                                      .contains(
                                                                        '選手',
                                                                      )) {
                                                                childrenWidgets.add(
                                                                  ReorderableListView(
                                                                    shrinkWrap:
                                                                        true,
                                                                    physics:
                                                                        const NeverScrollableScrollPhysics(),
                                                                    buildDefaultDragHandles:
                                                                        !isReadOnlyUI,
                                                                    onReorderItem:
                                                                        (
                                                                          oldIndex,
                                                                          newIndex,
                                                                        ) => _onReorderMatches(
                                                                          tieBreakMatches,
                                                                          oldIndex,
                                                                          newIndex,
                                                                          ref,
                                                                        ),
                                                                    // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                    children: tieBreakMatches
                                                                        .map(
                                                                          (
                                                                            m,
                                                                          ) => Container(
                                                                            key: ValueKey(
                                                                              m.id,
                                                                            ),
                                                                            child: MatchListTileCard(
                                                                              initialMatch: m,
                                                                              isDeletable: true,
                                                                            ),
                                                                          ),
                                                                        )
                                                                        .toList(),
                                                                  ),
                                                                );
                                                              } else {
                                                                final tieBoutsByMatchup =
                                                                    <
                                                                      String,
                                                                      List<
                                                                        MatchModel
                                                                      >
                                                                    >{};
                                                                final tieMatchupOrder =
                                                                    <String>[];
                                                                for (var m
                                                                    in tieBreakMatches) {
                                                                  final matchupName =
                                                                      '${m.redName.split(':').first.trim()} vs ${m.whiteName.split(':').first.trim()}';
                                                                  if (!tieBoutsByMatchup
                                                                      .containsKey(
                                                                        matchupName,
                                                                      )) {
                                                                    tieMatchupOrder
                                                                        .add(
                                                                          matchupName,
                                                                        );
                                                                    tieBoutsByMatchup[matchupName] =
                                                                        [];
                                                                  }
                                                                  tieBoutsByMatchup[matchupName]!
                                                                      .add(m);
                                                                }
                                                                childrenWidgets.add(
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .stretch,
                                                                    children: tieMatchupOrder.map<Widget>((
                                                                      name,
                                                                    ) {
                                                                      final bouts =
                                                                          tieBoutsByMatchup[name]!;
                                                                      // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                                      return Container(
                                                                        key: ValueKey(
                                                                          'tie_$name',
                                                                        ),
                                                                        child: Column(
                                                                          children: bouts
                                                                              .map(
                                                                                (
                                                                                  m,
                                                                                ) => MatchListTileCard(
                                                                                  initialMatch: m,
                                                                                  isDeletable: false,
                                                                                ),
                                                                              )
                                                                              .toList(),
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                            return childrenWidgets;
                                                          })(),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return null;
                                    })
                                    .whereType<Widget>()
                                    .toList();
                              })(),
                            );
                          },
                        ),

                        if (sortedPlayers.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 4,
                              bottom: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  sanitizedQuery.isNotEmpty
                                      ? Icons.manage_search
                                      : Icons.person,
                                  color: Colors.orange.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sanitizedQuery.isNotEmpty
                                      ? '抽出された個別試合'
                                      : '個人戦',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...sortedPlayers.map((playerEntry) {
                            final playerName = playerEntry.key;
                            final playerMatches = playerEntry.value;

                            // ★ 追加: 個人戦アコーディオン内部のコメントを取得し、試合と統合・ソートする
                            final playerComments = comments
                                .where(
                                  (c) =>
                                      c.category == categoryName &&
                                      c.groupName == teamName &&
                                      c.matchGroupId == playerName,
                                )
                                .toList();
                            final playerMixedItems = <TimelineItem>[
                              ...playerMatches,
                              ...playerComments,
                            ];
                            playerMixedItems.sort(
                              (a, b) =>
                                  a.timelineOrder.compareTo(b.timelineOrder),
                            );

                            final firstMatch = playerMatches.first;
                            final label =
                                (!firstMatch.isKachinuki &&
                                    (firstMatch.matchType == 'individual' ||
                                        firstMatch.matchType == '選手'))
                                ? (firstMatch.note.contains('[リーグ戦]')
                                      ? '個人戦/リーグ戦'
                                      : '個人戦')
                                : (firstMatch.isKachinuki
                                      ? '団体戦/勝ち抜き戦'
                                      : (firstMatch.note.contains('[リーグ戦]')
                                            ? '団体戦/リーグ戦'
                                            : '団体戦'));
                            final bool pInProgress = playerMatches.any(
                              (m) => m.status == 'in_progress',
                            );
                            final bool pAllFinished = playerMatches.every(
                              (m) =>
                                  m.status == 'finished' ||
                                  m.status == 'approved',
                            );
                            final Color pTitleColor = pAllFinished
                                ? (isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade500)
                                : (isDark ? Colors.white : Colors.black87);
                            final Color pSubTitleColor = pAllFinished
                                ? (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade500)
                                : (isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600);

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF38383A)
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: pInProgress
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: ExpansionTileTheme(
                                  data: ExpansionTileThemeData(
                                    backgroundColor: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : Colors.white,
                                    collapsedBackgroundColor: isDark
                                        ? const Color(0xFF161618)
                                        : Colors.white,
                                    iconColor: isDark
                                        ? Colors.indigo.shade300
                                        : Colors.indigo.shade700,
                                    collapsedIconColor: Colors.grey,
                                    textColor: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    collapsedTextColor: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                  child: ExpansionTile(
                                    key: ValueKey('player_$playerName'),
                                    shape: const Border(),
                                    collapsedShape: const Border(),
                                    childrenPadding: EdgeInsets.zero,
                                    tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: pAllFinished
                                          ? (isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade300)
                                          : Colors.orange.shade100,
                                      child: Text(
                                        playerName[0],
                                        style: TextStyle(
                                          color: pAllFinished
                                              ? (isDark
                                                    ? Colors.grey.shade500
                                                    : Colors.grey.shade600)
                                              : Colors.orange.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      playerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: pTitleColor,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          '$label • ${playerMatches.length}試合',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: pSubTitleColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pInProgress
                                                ? Colors.blue.shade600
                                                : (pAllFinished
                                                      ? (isDark
                                                            ? Colors
                                                                  .grey
                                                                  .shade800
                                                            : Colors
                                                                  .grey
                                                                  .shade300)
                                                      : (isDark
                                                            ? const Color(
                                                                0xFF2C2C2E,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade200)),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            pInProgress
                                                ? '進行中'
                                                : (pAllFinished ? '終了' : '待機中'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: pInProgress
                                                  ? Colors.white
                                                  : (pAllFinished
                                                        ? (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade600)
                                                        : (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade700)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      // ★ 修正: playerMatches のみのリストから、playerMixedItems（コメント混在リスト）に変更し、_onReorderInnerTimeline に接続
                                      ReorderableListView(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        buildDefaultDragHandles: !isReadOnlyUI,
                                        onReorderItem: (oldIndex, newIndex) =>
                                            _onReorderInnerTimeline(
                                              playerMixedItems,
                                              oldIndex,
                                              newIndex,
                                              ref,
                                            ),
                                        children: playerMixedItems
                                            .map<Widget?>((i) {
                                              if (i is MatchModel) {
                                                // ★関数から独立型Widgetカードクラスへ100%完全同期置換
                                                return Container(
                                                  key: ValueKey(i.id),
                                                  child: MatchListTileCard(
                                                    initialMatch: i,
                                                    isDeletable: true,
                                                  ),
                                                );
                                              } else if (i
                                                  is MatchCommentModel) {
                                                return Container(
                                                  key: ValueKey(
                                                    'inner_comment_${i.id}',
                                                  ),
                                                  child:
                                                      _buildInnerCommentWidget(
                                                        context,
                                                        ref,
                                                        i,
                                                        permissions,
                                                        isDark,
                                                      ),
                                                );
                                              }
                                              return null;
                                            })
                                            .whereType<Widget>()
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }),
              ],
            );
          }).toList();
        })(),
      ],
    );
  }
} // ★ ここで MatchTimelineList クラスを安全にクローズ（閉じ括弧）します。

// ============================================================================
// 🛡️ ファイル内トップレベル共有関数防衛要塞
// クラスのメンバーからファイル直下の関数へ大解放することで、双方のWidgetから100%安全に呼べるようになり、未定義エラーを完全粉砕します。
// ============================================================================

void _showRenameTeamSheet(
  BuildContext context,
  WidgetRef ref,
  String tournamentId,
  String oldName,
) {
  final controller = TextEditingController(text: oldName);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = isDark ? Colors.indigo.shade300 : Colors.indigo.shade700;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'チーム名の修正・統合',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '名前を修正すると、この大会内のすべての試合データが自動で書き換わり、同じ名前のチームと合流します。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '新しいチーム名',
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty || newName == oldName) {
                  Navigator.pop(ctx);
                  return;
                }
                await ref
                    .read(matchCommandProvider)
                    .renameTeamBulk(
                      tournamentId: tournamentId,
                      oldTeamName: oldName,
                      newTeamName: newName,
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('チーム名を一括更新しました ✨')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '一括修正して統合する',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _generateDescriptiveLeagueTitle(
  List<MatchModel> matches,
  List<String> ownTeams,
) {
  final participantsSet = <String>{};
  for (var m in matches) {
    participantsSet.add(m.redName.split(':').first.trim());
    participantsSet.add(m.whiteName.split(':').first.trim());
  }
  final int n = participantsSet.length;
  final int mCount = n * (n - 1) ~/ 2;
  final bool isIndiv = matches.any(
    (m) =>
        m.matchType == 'individual' ||
        m.matchType == '選手' ||
        m.matchType.contains('個人戦'),
  );

  String selfInfo = "";
  if (isIndiv) {
    final myMatch = matches.firstWhere(
      (m) => ownTeams.any(
        (ot) => m.redName.contains(ot) || m.whiteName.contains(ot),
      ),
      orElse: () => matches.first,
    );
    final isRedOwn = ownTeams.any((ot) => myMatch.redName.contains(ot));
    final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
    final team = rawName.split(':').first.trim();
    final name = rawName.contains(':')
        ? rawName.split(':').last.replaceAll(')', '').trim()
        : rawName;
    selfInfo = "$name（$team）";
  } else {
    selfInfo = participantsSet.firstWhere(
      (p) => ownTeams.contains(p),
      orElse: () => participantsSet.first,
    );
  }
  return "$selfInfo : ${isIndiv ? "$n人リーグ" : "$nチームリーグ"}（全$mCount試合）";
}

void _showRuleInfoSheet(BuildContext context, MatchModel match) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bool isBunaiksen =
      match.tournamentId?.startsWith('bunaiksen_') ?? false;
  final themeColors = AppThemeColors.ofMode(
    isDark: isDark,
    mode: isBunaiksen ? 'bunaiksen' : 'normal',
  );
  final rule = match.rule;

  final bool isLegacyLeague = match.note.contains('[リーグ戦]');
  final bool isLeague = (rule?.isLeague ?? false) || isLegacyLeague;
  final bool isIndividual =
      !match.isKachinuki &&
      (match.matchType == 'individual' ||
          match.matchType == '選手' ||
          match.matchType.contains('個人戦') ||
          (rule != null &&
              rule.positions.length == 1 &&
              (rule.positions.first == '選手' || rule.positions.first == '個人戦')));

  String formatText = isIndividual ? '個人戦' : '団体戦';
  if (rule?.isRenseikai ?? false) {
    formatText = '錬成会';
  } else if (match.isKachinuki || (rule?.isKachinuki ?? false)) {
    formatText = '勝ち抜き戦';
  } else if (isLeague) {
    formatText = 'リーグ戦（総当たり）';
  }

  final double matchTime =
      rule?.matchTimeMinutes ?? match.matchTimeMinutes.toDouble();
  final isRunningTime = rule?.isRunningTime ?? match.isRunningTime;
  String timeStr = matchTime == matchTime.toInt()
      ? '${matchTime.toInt()}分'
      : '${matchTime.toInt()}分${((matchTime % 1) * 60).toInt()}秒';
  final String timeDesc = '$timeStr (${isRunningTime ? "通し/空回し" : "都度ストップ"})';

  final bool enchoUnlimited = rule?.isEnchoUnlimited ?? false;
  final double enchoMins =
      rule?.enchoTimeMinutes ?? match.extensionTimeMinutes?.toDouble() ?? 0.0;
  final int enchoCount = rule?.enchoCount ?? match.extensionCount ?? 1;
  final bool enchoEnabled =
      match.hasExtension || enchoUnlimited || enchoMins > 0;

  String enchoDesc = 'なし';
  if (enchoEnabled) {
    if (enchoUnlimited) {
      enchoDesc = 'あり (無制限)';
    } else {
      String extTimeStr = enchoMins == enchoMins.toInt()
          ? '${enchoMins.toInt()}分'
          : '${enchoMins.toInt()}分${((enchoMins % 1) * 60).toInt()}秒';
      enchoDesc = 'あり ($extTimeStr・$enchoCount回)';
    }
  }

  final bool hanteiEnabled = rule?.hasHantei ?? match.hasHantei;
  String daihyoDesc = rule != null
      ? (rule.hasRepresentativeMatch
            ? (rule.isDaihyoIpponShobu ? 'あり (一本勝負)' : 'あり (三本勝負)')
            : 'なし')
      : '不明（古いデータ）';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.gavel_rounded,
                color: themeColors.primaryAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '試合レギュレーション',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (rule == null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'この試合はアップデート前に作成されたため、詳細なルールが保存されていません。新しく作成した試合では正しく表示されます。',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _buildRuleRow('試合形式', formatText, isDark),
          _buildRuleRow('試合時間', timeDesc, isDark),
          if (rule?.isRenseikai ?? false) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '錬成会設定',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColors.primaryAccent,
                ),
              ),
            ),
            _buildRuleRow('進行方式', rule!.renseikaiType, isDark),
            if (rule.renseikaiType == '時間制')
              _buildRuleRow('制限時間', '${rule.overallTimeMinutes} 分', isDark),
          ] else ...[
            _buildRuleRow('延長戦', enchoDesc, isDark),
            _buildRuleRow('判定', hanteiEnabled ? 'あり' : 'なし', isDark),
          ],
          if (match.isKachinuki || (rule?.isKachinuki ?? false)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '勝ち抜き戦設定',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColors.primaryAccent,
                ),
              ),
            ),
            _buildRuleRow(
              '無制限条件',
              rule?.kachinukiUnlimitedType ?? '大将対大将',
              isDark,
            ),
            if (rule != null && rule.positions.isNotEmpty)
              _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
          ],
          if (!isIndividual &&
              !(rule?.isRenseikai ?? false) &&
              !match.isKachinuki &&
              !(rule?.isKachinuki ?? false) &&
              !isLeague) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '団体戦・チーム設定',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColors.primaryAccent,
                ),
              ),
            ),
            _buildRuleRow('代表戦', daihyoDesc, isDark),
            if (rule != null && rule.positions.isNotEmpty)
              _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
          ],
          if (!isIndividual &&
              (rule?.isRenseikai ?? false) &&
              rule != null &&
              rule.positions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ポジション設定',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColors.primaryAccent,
                ),
              ),
            ),
            _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
          ],
          if (rule != null && rule.isLeague) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'リーグ戦設定',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            if (!isIndividual && rule.positions.isNotEmpty)
              _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            _buildRuleRow(
              '勝ち点設定',
              '勝: ${rule.winPoint} / 分: ${rule.drawPoint} / 負: ${rule.lossPoint}',
              isDark,
            ),
            _buildRuleRow('同点時代表戦', rule.hasLeagueDaihyo ? 'あり' : 'なし', isDark),
          ],
          if (match.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRuleRow('備考・メモ', match.note, isDark),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                foregroundColor: isDark ? Colors.white : Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '閉じる',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
        ],
      ),
    ),
  );
}

Widget _buildRuleRow(String label, String value, bool isDark) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showTieBreakDialog(
  BuildContext parentContext,
  WidgetRef ref,
  MatchModel firstMatch,
  List<dynamic> tieTeams,
  dynamic baseRule,
) {
  String? selectedMode;
  showDialog(
    context: parentContext,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        if (selectedMode == null) {
          return AlertDialog(
            title: const Text(
              '決定戦の形式を選択',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '同順位を解消するための形式を選んでください：',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                _buildTieOption(
                  ctx,
                  Icons.person,
                  '代表戦（1名）',
                  '1本勝負で順位を決定します',
                  () {
                    if (tieTeams.length <= 2) {
                      Navigator.pop(ctx);
                      _createTieBreakMatch(
                        parentContext,
                        ref,
                        firstMatch,
                        tieTeams,
                        baseRule,
                        isAll: false,
                        mode: 'daihyo',
                      );
                    } else {
                      setState(() => selectedMode = 'daihyo');
                    }
                  },
                ),
                _buildTieOption(
                  ctx,
                  Icons.groups,
                  'チーム再試合',
                  '全ポジションで再度対戦します',
                  () {
                    if (tieTeams.length <= 2) {
                      Navigator.pop(ctx);
                      _createTieBreakMatch(
                        parentContext,
                        ref,
                        firstMatch,
                        tieTeams,
                        baseRule,
                        isAll: false,
                        mode: 'rematch',
                      );
                    } else {
                      setState(() => selectedMode = 'rematch');
                    }
                  },
                ),
                const Divider(height: 24),
                _buildTieOption(
                  ctx,
                  Icons.close,
                  '何もしない',
                  '同点のままにします',
                  () => Navigator.pop(ctx),
                  isSub: true,
                ),
              ],
            ),
          );
        } else {
          final modeText = selectedMode == 'daihyo' ? '代表戦' : 'チーム再試合';
          return AlertDialog(
            title: Text(
              '$modeTextの作成',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    '作成する組み合わせを選んでください：',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildTieOption(
                    ctx,
                    Icons.auto_awesome,
                    '三つ巴を一括作成',
                    '総当たりの$modeTextをすべて作成します',
                    () {
                      Navigator.pop(ctx);
                      _createTieBreakMatch(
                        parentContext,
                        ref,
                        firstMatch,
                        tieTeams,
                        baseRule,
                        isAll: true,
                        mode: selectedMode!,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  const Text(
                    '個別に対戦を作成：',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(() {
                    final combos = <Widget>[];
                    for (int i = 0; i < tieTeams.length; i++) {
                      for (int j = i + 1; j < tieTeams.length; j++) {
                        combos.add(
                          _buildTieOption(
                            ctx,
                            Icons.compare_arrows,
                            '${tieTeams[i].name} vs ${tieTeams[j].name}',
                            '$modeTextを作成',
                            () {
                              Navigator.pop(ctx);
                              _createTieBreakMatch(
                                parentContext,
                                ref,
                                firstMatch,
                                [tieTeams[i], tieTeams[j]],
                                baseRule,
                                isAll: false,
                                mode: selectedMode!,
                              );
                            },
                            isSub: true,
                          ),
                        );
                      }
                    }
                    return combos;
                  })(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => selectedMode = null),
                child: const Text('形式選択に戻る'),
              ),
            ],
          );
        }
      },
    ),
  );
}

Widget _buildTieOption(
  BuildContext ctx,
  IconData icon,
  String title,
  String sub,
  VoidCallback onTap, {
  bool isSub = false,
}) {
  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    color: isSub ? Colors.transparent : Colors.orange.shade50,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: isSub ? Colors.grey.shade300 : Colors.orange.shade300,
      ),
    ),
    child: ListTile(
      leading: Icon(
        icon,
        color: isSub ? Colors.grey.shade600 : Colors.orange.shade800,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isSub ? Colors.black87 : Colors.orange.shade900,
        ),
      ),
      subtitle: Text(
        sub,
        style: TextStyle(
          fontSize: 10,
          color: isSub ? Colors.grey.shade600 : Colors.orange.shade700,
        ),
      ),
      onTap: onTap,
    ),
  );
}

Future<void> _createTieBreakMatch(
  BuildContext context,
  WidgetRef ref,
  MatchModel firstMatch,
  List<dynamic> teams,
  dynamic baseRule, {
  required bool isAll,
  String mode = 'daihyo',
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bool isBunaiksen =
      firstMatch.tournamentId?.startsWith('bunaiksen_') ?? false;
  final themeColors = AppThemeColors.ofMode(
    isDark: isDark,
    mode: isBunaiksen ? 'bunaiksen' : 'normal',
  );
  try {
    final List<Map<String, String>> matchups = [];
    if (isAll) {
      for (int i = 0; i < teams.length; i++) {
        for (int j = i + 1; j < teams.length; j++) {
          matchups.add({'red': teams[i].name, 'white': teams[j].name});
        }
      }
    } else {
      matchups.add({'red': teams[0].name, 'white': teams[1].name});
    }
    String? firstMatchId;

    for (int i = 0; i < matchups.length; i++) {
      final bool isDaihyo = mode == 'daihyo';
      final List<String> positions = isDaihyo
          ? ['代表']
          : List<String>.from(baseRule.positions);
      for (int p = 0; p < positions.length; p++) {
        final String mId =
            'tiebreak_${DateTime.now().millisecondsSinceEpoch}_${i}_$p';
        firstMatchId ??= mId;
        final newMatch = MatchModel(
          id: mId,
          tournamentId: firstMatch.tournamentId,
          category: firstMatch.category,
          groupName: firstMatch.groupName,
          redName: '${matchups[i]['red']} : 選手',
          whiteName: '${matchups[i]['white']} : 選手',
          matchType: isDaihyo ? '代表戦' : '順位決定戦',
          status: 'waiting',
          order: 999.0 + (i * 10) + p,
          note: '[順位決定戦] ${isDaihyo ? "代表戦" : "再試合"}',
          matchTimeMinutes: isDaihyo
              ? (baseRule.isDaihyoIpponShobu
                    ? 0.0
                    : baseRule.matchTimeMinutes.toDouble())
              : baseRule.matchTimeMinutes.toDouble(),
          hasExtension: baseRule.isEnchoUnlimited || baseRule.enchoCount > 0,
          rule: baseRule.copyWith(
            positions: [positions[p]],
            isKachinuki: false,
            isLeague: false,
          ),
        );
        await ref.read(matchCommandProvider).addMatch(newMatch);
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: themeColors.primaryAccent,
          duration: const Duration(seconds: 4),
          content: Text(isAll ? '三つ巴の決定戦を一括作成しました' : '決定戦を作成しました'),
          action: firstMatchId != null
              ? SnackBarAction(
                  label: '試合へ',
                  textColor: Colors.white,
                  onPressed: () => context.push('/match/$firstMatchId'),
                )
              : null,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
  }
}

void _showSummaryInputDialog(
  BuildContext context,
  WidgetRef ref,
  List<MatchModel> matches,
) {
  final normalMatches = matches
      .where((m) => m.matchType != '代表戦' && m.matchType != '順位決定戦')
      .toList();
  if (normalMatches.isEmpty) return;

  final int totalMatches = normalMatches.length;
  int rWins = 0, rPts = 0, wWins = 0, wPts = 0;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final rTeam = normalMatches.first.redName.split(':').first.trim();
  final wTeam = normalMatches.first.whiteName.split(':').first.trim();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        Widget buildCounter(
          String label,
          int value,
          VoidCallback onMinus,
          VoidCallback onPlus,
          Color color,
        ) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: color),
                    onPressed: value > 0
                        ? () {
                            onMinus();
                            setState(() {});
                          }
                        : null,
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: color),
                    onPressed: () {
                      onPlus();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          );
        }

        bool isValid =
            (rWins + wWins <= totalMatches) &&
            (rPts >= rWins && rPts <= rWins * 2) &&
            (wPts >= wWins && wPts <= wWins * 2);
        String errorMsg = '';
        if (rWins + wWins > totalMatches) {
          errorMsg = '勝者数の合計が試合数($totalMatches)を超えています';
        } else if (rPts < rWins) {
          errorMsg = '赤の本数が少なすぎます（1勝につき最低1本）';
        } else if (rPts > rWins * 2) {
          errorMsg = '赤の本数が多すぎます（1勝につき最大2本）';
        } else if (wPts < wWins) {
          errorMsg = '白の本数が少なすぎます';
        } else if (wPts > wWins * 2) {
          errorMsg = '白の本数が多すぎます';
        }

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '他コートの簡易入力',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '他チームの試合結果（勝者数と本数）だけを素早く記録します。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.shade900.withValues(alpha: 0.15)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        rTeam,
                        style: TextStyle(
                          color: isDark
                              ? Colors.red.shade400
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildCounter('勝者数', rWins, () => rWins--, () {
                        if (rWins + wWins < totalMatches) {
                          rWins++;
                        }
                      }, Colors.red),
                      buildCounter('取得本数', rPts, () => rPts--, () {
                        if (rPts < rWins * 2) {
                          rPts++;
                        }
                      }, Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.shade900.withValues(alpha: 0.15)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        wTeam,
                        style: TextStyle(
                          color: isDark
                              ? Colors.blue.shade400
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildCounter('勝者数', wWins, () => wWins--, () {
                        if (rWins + wWins < totalMatches) {
                          wWins++;
                        }
                      }, Colors.blue),
                      buildCounter('取得本数', wPts, () => wPts--, () {
                        if (wPts < wWins * 2) {
                          wPts++;
                        }
                      }, Colors.blue),
                    ],
                  ),
                ),
                if (errorMsg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      errorMsg,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!isValid) {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text('入力エラー'),
                        ],
                      ),
                      content: Text(
                        errorMsg,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('確認'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  int rw = rWins, rp = rPts, ww = wWins, wp = wPts;
                  for (var m in normalMatches) {
                    List<ScoreEvent> events = [];
                    int matchRedScore = 0;
                    int matchWhiteScore = 0;
                    final now = ref.read(timeSourceProvider).now();
                    if (rw > 0) {
                      rw--;
                      int p = (rp > rw) ? 2 : 1;
                      if (p > rp) p = rp;
                      rp -= p;
                      matchRedScore = p;
                      for (int i = 0; i < p; i++) {
                        events.add(
                          ScoreEventLegacyAdapter.fromLegacy(
                            id: const Uuid().v4(),
                            type: PointType.fusen,
                            side: Side.red,
                            timestamp: now,
                          ),
                        );
                      }
                    } else if (ww > 0) {
                      ww--;
                      int p = (wp > ww) ? 2 : 1;
                      if (p > wp) p = wp;
                      wp -= p;
                      matchWhiteScore = p;
                      for (int i = 0; i < p; i++) {
                        events.add(
                          ScoreEventLegacyAdapter.fromLegacy(
                            id: const Uuid().v4(),
                            type: PointType.fusen,
                            side: Side.white,
                            timestamp: now,
                          ),
                        );
                      }
                    }
                    final String newNote = m.note.contains('[SUMMARY]')
                        ? m.note
                        : '${m.note} [SUMMARY]'.trim();
                    final updated = m.copyWith(
                      status: 'approved',
                      note: newNote,
                      events: events,
                      redScore: matchRedScore,
                      whiteScore: matchWhiteScore,
                    );
                    await ref
                        .read(matchApplicationServiceProvider)
                        .saveMatch(updated);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('エラー: $e')));
                  }
                } finally {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                '記録を確定する',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );
}

void _onReorderInnerTimeline(
  List<TimelineItem> list,
  int oldIndex,
  int newIndex,
  WidgetRef ref,
) async {
  final permissions = ref.read(permissionProvider);
  if (permissions.isReadOnly) {
    return;
  }
  if (oldIndex == newIndex) {
    return;
  }

  final item = list[oldIndex];
  double newOrder;
  if (newIndex == 0) {
    newOrder = list.first.timelineOrder - 100.0;
  } else if (newIndex == list.length - 1) {
    newOrder = list.last.timelineOrder + 100.0;
  } else {
    final prevOrder =
        list[newIndex > oldIndex ? newIndex : newIndex - 1].timelineOrder;
    final nextOrder =
        list[newIndex > oldIndex ? newIndex + 1 : newIndex].timelineOrder;
    newOrder = (prevOrder + nextOrder) / 2.0;
  }
  if (newOrder == list[newIndex].timelineOrder) {
    newOrder += 0.001;
  }

  if (item is MatchCommentModel) {
    try {
      await ref.read(commentCommandProvider).updateCommentOrder(item, newOrder);
    } catch (e) {
      debugPrint('コメント並び替え保存エラー: $e');
    }
  } else if (item is MatchModel) {
    try {
      await ref.read(matchApplicationServiceProvider).saveMatchesBulk([
        item.copyWith(order: newOrder),
      ]);
    } catch (e) {
      debugPrint('試合並び替え保存エラー: $e');
    }
  }
}

void _onReorderMatches(
  List<MatchModel> list,
  int oldIndex,
  int newIndex,
  WidgetRef ref,
) async {
  final permissions = ref.read(permissionProvider);
  if (permissions.isReadOnly) return;
  if (oldIndex == newIndex) return;

  final item = list[oldIndex];
  double newOrder;
  if (newIndex == 0) {
    newOrder = list.first.order - 100.0;
  } else if (newIndex == list.length - 1) {
    newOrder = list.last.order + 100.0;
  } else {
    final prevOrder = list[newIndex > oldIndex ? newIndex : newIndex - 1].order;
    final nextOrder = list[newIndex > oldIndex ? newIndex + 1 : newIndex].order;
    newOrder = (prevOrder + nextOrder) / 2.0;
  }
  if (newOrder == list[newIndex].order) {
    newOrder += 0.001;
  }

  try {
    await ref.read(matchApplicationServiceProvider).saveMatchesBulk([
      item.copyWith(order: newOrder),
    ]);
  } catch (e) {
    debugPrint('並び替え保存エラー: $e');
  }
}

void _onReorderTimeline(
  List<ReorderableTimelineItem> list,
  int oldIndex,
  int newIndex,
  WidgetRef ref,
) async {
  final permissions = ref.read(permissionProvider);
  if (permissions.isReadOnly) return;
  if (oldIndex == newIndex) return;

  final item = list[oldIndex];
  double newOrder;
  if (newIndex == 0) {
    newOrder = list.first.order - 100.0;
  } else if (newIndex == list.length - 1) {
    newOrder = list.last.order + 100.0;
  } else {
    final prevOrder = list[newIndex > oldIndex ? newIndex : newIndex - 1].order;
    final nextOrder = list[newIndex > oldIndex ? newIndex + 1 : newIndex].order;
    newOrder = (prevOrder + nextOrder) / 2.0;
  }
  if (newOrder == list[newIndex].order) {
    newOrder += 0.001;
  }

  if (item is CommentTimelineItem) {
    try {
      await ref
          .read(commentCommandProvider)
          .updateCommentOrder(item.comment, newOrder);
    } catch (e) {
      debugPrint('コメント並び替え保存エラー: $e');
    }
  } else if (item is MatchGroupTimelineItem) {
    final offsetOrder = newOrder - item.order;
    final updatedMatches = item.matches
        .map((m) => m.copyWith(order: m.order + offsetOrder))
        .toList();
    try {
      await ref
          .read(matchApplicationServiceProvider)
          .saveMatchesBulk(updatedMatches);
    } catch (e) {
      debugPrint('グループ並び替え保存エラー: $e');
    }
  }
}

void showUnifiedAnnounceDialog(
  BuildContext context,
  WidgetRef ref,
  String tournamentId,
  String category,
  String groupName,
  double order, {
  String? matchGroupId,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bool isBunaiksen = tournamentId.startsWith('bunaiksen_');
  final themeColors = AppThemeColors.ofMode(
    isDark: isDark,
    mode: isBunaiksen ? 'bunaiksen' : 'normal',
  );
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  String selectedTarget = 'all'; // デフォルトは全員向け

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.add_alert,
                  color: Color(0xFFFF69B4),
                ), // 差し色：サクラピンク
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '公式アナウンス・コメントの一斉発信',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'タイトル（例：【緊急】会場変更）',
                      hintText: '空欄の場合は自動で見出しになります',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: 3,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'アナウンス本文内容',
                      hintText: '例：3会場へ移動になりました。選手は速やかに移動してください。',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🏢 全員向け / スタッフ限定 の完全送り分け選択UIセクション
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                '📢 全員に通知',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectedTarget == 'all'
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            selected: selectedTarget == 'all',
                            selectedColor: const Color(
                              0xFFFF69B4,
                            ).withValues(alpha: 0.2), // サクラピンクの淡い選択色
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() => selectedTarget = 'all');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                '🔒 スタッフ限定',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectedTarget == 'staff'
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            selected: selectedTarget == 'staff',
                            selectedColor: Colors.deepOrange.withValues(
                              alpha: 0.2,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() => selectedTarget = 'staff');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'キャンセル',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColors.primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final String title = titleController.text.trim();
                  final String body = bodyController.text.trim();
                  if (body.isEmpty) return;

                  final String finalTitle = title.isNotEmpty
                      ? title
                      : '大会本部からのお知らせ';

                  // 🌟 即座にダイアログを閉じることで、タップした瞬間にスッと画面が消える心地よいUXを実現
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }

                  // 🌟 非同期のFirestoreおよびIsarへの書き込み処理はバックグラウンドで実行
                  Future(() async {
                    // Firestore client instance safe logic inside test context
                    FirebaseFirestore firestore;
                    try {
                      firestore = ref.read(firestoreProvider);
                    } catch (_) {
                      firestore = FirebaseFirestore.instance;
                    }

                    final String announceId = firestore
                        .collection('announcements')
                        .doc()
                        .id;

                    // 🛡️ 防衛線：自分自身が送信したアナウンスが自分自身に対してポップアップ表示されるのを防ぐため、IDをローカル登録する
                    registerMySentAnnounceId(announceId);

                    try {
                      // 🚀 1連動：Firestoreの通知コレクションへ爆送書き込み（ステップ3, 4, 5が一斉リアルタイム着火）
                      await firestore
                          .collection('announcements')
                          .doc(announceId)
                          .set({
                            'id': announceId,
                            'tournamentId': tournamentId,
                            'title': finalTitle,
                            'body': body,
                            'timestamp': FieldValue.serverTimestamp(),
                            'type': 'emergency',
                            'target': selectedTarget, // all または staff を完全送り分け
                            'isRead': false,
                            'createdBy': () {
                              try {
                                return FirebaseAuth.instance.currentUser?.uid;
                              } catch (_) {
                                return null;
                              }
                            }(),
                          });

                      // 🚀 2連動：既存のタイムライン側への「見出しコメント」としての同時追記（Isar/Firestore同期）
                      final String commentText = title.isNotEmpty
                          ? '$title\n$body'
                          : body;
                      await ref
                          .read(commentCommandProvider)
                          .addComment(
                            tournamentId: tournamentId,
                            category: category,
                            groupName: groupName,
                            matchGroupId: matchGroupId,
                            text: commentText,
                            order: order,
                          );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              selectedTarget == 'staff'
                                  ? 'スタッフ限定業務連絡を発信しました'
                                  : '全員向け緊急アナウンスを一斉配信しました',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('🚨 [AnnounceDialog] 送信エラー: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('送信に失敗しました: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  });
                },
                child: const Text(
                  '一斉発信して保存',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showEditCommentDialog(
  BuildContext context,
  WidgetRef ref,
  dynamic comment,
) {
  final controller = TextEditingController(text: comment.text);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      title: Text(
        '見出し（コメント）の編集',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: '見出しやコメントを入力',
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            final text = controller.text.trim();
            if (text.isNotEmpty && text != comment.text) {
              try {
                await ref
                    .read(commentCommandProvider)
                    .updateComment(comment.copyWith(text: text));
              } catch (e) {
                debugPrint('コメントの更新に失敗しました: $e');
              }
            }
            if (ctx.mounted) {
              Navigator.pop(ctx);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: const Text(
            '保存',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

void _showEditGroupNoteDialog(
  BuildContext context,
  WidgetRef ref,
  List<MatchModel> groupList,
) {
  if (groupList.isEmpty) return;
  final firstMatch = groupList.first;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return MatchEditSheet(
        matches: groupList,
        tournamentId: firstMatch.tournamentId,
        themeColors: AppThemeColors.ofMode(
          isDark: Theme.of(context).brightness == Brightness.dark,
          mode: 'operate',
        ),
      );
    },
  );
}

Widget _buildInnerCommentWidget(
  BuildContext context,
  WidgetRef ref,
  MatchCommentModel c,
  AppPermissions permissions,
  bool isDark,
) {
  final commentWidget = Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300,
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.label_outline,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            c.text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
            ),
          ),
        ),
      ],
    ),
  );

  if (!permissions.canManageTournament) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: commentWidget,
    );
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Slidable(
      key: ValueKey('slidable_inner_comment_${c.id}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _showEditCommentDialog(context, ref, c),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '編集',
          ),
          SlidableAction(
            onPressed: (context) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  title: Text(
                    '内部見出しの削除',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  content: Text(
                    'この見出しを削除しますか？\n(取り消せません)',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        '削除',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref
                    .read(commentCommandProvider)
                    .deleteComment(c.id, c.tournamentId ?? '');
              }
            },
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(8),
            ),
            label: '削除',
          ),
        ],
      ),
      child: commentWidget,
    ),
  );
}

void _showEditNoteDialog(
  BuildContext context,
  WidgetRef ref,
  MatchModel match,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return MatchEditSheet(
        matches: [match],
        tournamentId: match.tournamentId,
        themeColors: AppThemeColors.ofMode(
          isDark: Theme.of(context).brightness == Brightness.dark,
          mode: 'operate',
        ),
      );
    },
  );
}

// ============================================================================
// ★ ⚙️ 最終適合修正③: Undoリアクティブ即時反映を完全保証する独立型子Widget要塞
// ============================================================================
class MatchListTileCard extends ConsumerWidget {
  final MatchModel initialMatch;
  final bool isDeletable;

  const MatchListTileCard({
    super.key,
    required this.initialMatch,
    this.isDeletable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ 自身の内部でグローバルな変化を強固に常時 watch 監視。
    // これにより、画面裏で Undo 操作（消去）が行われた瞬間、アコーディオンのキャッシュをぶち破って0ミリ秒で即座にタイルがリビルドされます。
    // ★ 修正: ネイティブ環境では最速の即時反映(matchListProvider)を使用し、Web環境でのみフォールバックさせます。
    MatchModel? maybeMatch = ref.watch(
      matchListProvider.select(
        (list) => list.where((m) => m.id == initialMatch.id).firstOrNull,
      ),
    );

    // Web では matchListProvider が初回に空を返すことがあるため、
    // 大会単位プロバイダをフォールバックとして参照して対象試合を探す
    if (maybeMatch == null &&
        kIsWeb &&
        (initialMatch.tournamentId != null &&
            initialMatch.tournamentId!.isNotEmpty)) {
      maybeMatch = ref.watch(
        matchListByTournamentProvider(initialMatch.tournamentId!).select(
          (res) => res.value?.where((m) => m.id == initialMatch.id).firstOrNull,
        ),
      );
    }

    final match = maybeMatch ?? initialMatch;

    final permissions = ref.watch(permissionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinished = match.status == 'finished' || match.status == 'approved';
    final isPlaying = match.status == 'in_progress';
    final bool isIndividual =
        !match.isKachinuki &&
        (match.matchType == '個人戦' || match.matchType == '選手');

    String displayNote = match.note;
    if (displayNote.contains('[SUMMARY]')) {
      displayNote = displayNote.replaceAll('[SUMMARY]', '').trim();
    }

    final Color bg = isFinished
        ? (isDark ? const Color(0xFF161618) : Colors.grey.shade50)
        : (isDark ? const Color(0xFF1E1E20) : Colors.white);
    final Color textC = isFinished
        ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
        : (isDark ? Colors.white : Colors.black87);
    final Color noteC = isFinished
        ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500)
        : Colors.grey.shade600;

    // 🛡️ 補正④: 細線独立カードモデリング化の意匠を適用
    final tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      // ★ 適合修正: ListTile が Material のエフェクトを正しく描画できるよう、Material で包囲する
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: Key('viewer_match_card_${match.id}'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔼 【1行目】: 運営ステータス＆ボタン一元集約（コントロール右寄せ）
              Row(
                children: [
                  const Spacer(),
                  // 簡易入力ボタン
                  Builder(
                    builder: (context) {
                      final ownTeams =
                          ref.watch(customTeamNamesProvider).value ?? [];
                      final rT = match.redName.split(':').first.trim();
                      final wT = match.whiteName.split(':').first.trim();
                      if (!permissions.isReadOnly &&
                          !isFinished &&
                          !isPlaying &&
                          !(ownTeams.contains(rT) ||
                              match.redName.contains('自チーム')) &&
                          !(ownTeams.contains(wT) ||
                              match.whiteName.contains('自チーム')) &&
                          isIndividual) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SizedBox(
                            height: 26,
                            child: OutlinedButton.icon(
                              onPressed: () => _showSummaryInputDialog(
                                context,
                                ref,
                                [match],
                              ),
                              icon: Icon(
                                Icons.flash_on,
                                size: 11,
                                color: Colors.amber.shade700,
                              ),
                              label: Text(
                                '簡易',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: textC,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                side: BorderSide(
                                  color: textC.withValues(alpha: 0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // ℹ️詳細マーク
                  if (isIndividual)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => _showRuleInfoSheet(context, match),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.info_outline,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  // 📊スコアボタン
                  if (isIndividual ||
                      match.note.contains('[順位決定戦]') ||
                      match.matchType == '代表戦')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        height: 26,
                        child: OutlinedButton(
                          onPressed: () {
                            final target =
                                (match.groupName != null &&
                                    match.groupName!.isNotEmpty)
                                ? match.groupName!
                                : match.id;
                            final encodedTarget = Uri.encodeComponent(target);
                            final tId = match.tournamentId ?? '';
                            context.push(
                              '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(
                              color: textC.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'スコア',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: textC,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // 状態バナー
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? Colors.blue.shade600
                          : (isFinished
                                ? (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300)
                                : (isDark
                                      ? const Color(0xFF2C2C2E)
                                      : Colors.grey.shade200)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPlaying ? '進行中' : (isFinished ? '終了' : '待機中'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPlaying
                            ? Colors.white
                            : (isFinished
                                  ? (isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600)
                                  : (isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700)),
                      ),
                    ),
                  ),
                ],
              ),
              if (displayNote.isNotEmpty || match.matchType.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (displayNote.isNotEmpty) TextSpan(text: displayNote),
                        if (displayNote.isNotEmpty &&
                            (match.matchType.isNotEmpty &&
                                match.matchType != '選手'))
                          const TextSpan(text: ' '),
                        if (match.matchType.isNotEmpty &&
                            match.matchType != '選手')
                          TextSpan(text: '【${match.matchType}】'),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: noteC,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // 🔽 【要塞型・全3行レイアウト大刷新】: チーム名を選手名の上に配置し、スコア圧迫による文字切れを100%防止
              Builder(
                builder: (context) {
                  final ownTeams =
                      ref.watch(customTeamNamesProvider).value ?? [];

                  String getTeamPart(String raw) {
                    if (raw.contains(':')) return raw.split(':').first.trim();
                    if (!isIndividual) {
                      return raw.trim(); // 団体戦でコロンがない場合は全体をチーム名とみなす
                    }
                    return '';
                  }

                  String getNamePart(String raw) {
                    if (raw.contains(':')) return raw.split(':').last.trim();
                    if (!isIndividual) {
                      return match.matchType; // 団体戦でコロンがない場合、選手名の代わりにポジション名を表示
                    }
                    return raw.trim();
                  }

                  final rTeam = getTeamPart(match.redName);
                  final rName = getNamePart(match.redName);
                  final wTeam = getTeamPart(match.whiteName);
                  final wName = getNamePart(match.whiteName);

                  final ptsMap = MatchCalculatorHelper.extractPointsFromModel(
                    match,
                  );
                  final redPoints = ptsMap['red'] ?? [];
                  final whitePoints = ptsMap['white'] ?? [];
                  final bool isDraw =
                      isFinished && match.redScore == match.whiteScore;
                  final bool hasValidPoints =
                      redPoints.isNotEmpty || whitePoints.isNotEmpty || isDraw;

                  Widget buildMarkItem(dynamic p, Color textColor) {
                    final String mark = p.mark == '✕' ? '×' : p.mark;
                    final bool isFirstOverall = p.isFirst;

                    if (mark == '◯' || mark == '×') {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          mark,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      );
                    }

                    if (isFirstOverall) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: textColor, width: 1.2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          mark,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.1,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        mark,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    );
                  }

                  final isRedOwn =
                      ownTeams.contains(rTeam) ||
                      match.redName.contains('自チーム');
                  final isWhiteOwn =
                      ownTeams.contains(wTeam) ||
                      match.whiteName.contains('自チーム');

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏢 【2行目】: 左右チーム名独立表示ライン（フォントサイズを抑え、フル幅を活用）
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rTeam.isNotEmpty ? rTeam : '（個人エントリー）',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Text(
                              wTeam.isNotEmpty ? wTeam : '（個人エントリー）',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 🥋 【3行目】: ピュア選手名＆中央掲示板式リアルタイムスコアライン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 赤選手名（100%の横幅をフルに活用して文字切れを完全に防御）
                          Expanded(
                            child: Text(
                              rName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRedOwn
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                color: isRedOwn
                                    ? Colors.amber.shade600
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 中央スコアマーク（スコアなし時は完全空欄）
                          if (!hasValidPoints)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(width: 12),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: redPoints
                                        .map(
                                          (p) => buildMarkItem(
                                            p,
                                            isDark
                                                ? Colors.red.shade300
                                                : Colors.red.shade700,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      isDraw ? '×' : 'ー',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: whitePoints
                                        .map(
                                          (p) => buildMarkItem(
                                            p,
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          // 白選手名
                          Expanded(
                            child: Text(
                              wName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isWhiteOwn
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                color: isWhiteOwn
                                    ? Colors.amber.shade600
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          onTap: () {
            final tId = match.tournamentId ?? '';
            if (permissions.isReadOnly) {
              context.push('/viewer/${match.id}?tournamentId=$tId');
            } else {
              context.push('/match/${match.id}?tournamentId=$tId');
            }
          },
        ),
      ),
    );

    if (!permissions.canManageTournament || !isDeletable) return tile;

    return Slidable(
      key: ValueKey(match.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _showEditNoteDialog(context, ref, match),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '編集',
          ),
          SlidableAction(
            onPressed: (context) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  title: Text(
                    '試合の削除',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  content: Text(
                    '削除しますか？\n(取り消せません)',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        '削除',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(matchCommandProvider).deleteMatch(match.id);
              }
            },
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '削除',
          ),
        ],
      ),
      child: tile,
    );
  }

  // 🛠️ 団体戦オーダー直前変更＆補欠交代用のボトムシート表示メソッド
}

void _showOrderReorderSheet(
  BuildContext context,
  WidgetRef ref,
  List<MatchModel> groupList,
) {
  final sortedMatches = List<MatchModel>.from(groupList)
    ..sort((a, b) => a.order.compareTo(b.order));

  if (sortedMatches.isEmpty) return;
  // firstMatch unused variable removed

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _OrderReorderBottomSheet(sortedMatches: sortedMatches);
    },
  );
}

// 🛠️ オーダー並び替え＆補欠交代用 StatefulWidget
class _OrderReorderBottomSheet extends ConsumerStatefulWidget {
  final List<MatchModel> sortedMatches;

  const _OrderReorderBottomSheet({required this.sortedMatches});

  @override
  ConsumerState<_OrderReorderBottomSheet> createState() =>
      _OrderReorderBottomSheetState();
}

class _OrderReorderBottomSheetState
    extends ConsumerState<_OrderReorderBottomSheet> {
  late List<String> _positions;
  late List<String> _currentPlayers;
  List<String> _reservePlayers = [];
  List<Map<String, String>> _unifiedList = [];

  String _ownTeamName = '';
  bool _isOwnTeamRed = true;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSyncData();
  }

  void _initializeSyncData() {
    final firstMatch = widget.sortedMatches.first;
    final ownTeams = ref.read(customTeamNamesProvider).value ?? [];
    final ruleTeamName = firstMatch.rule?.teamName;

    final rTeam = firstMatch.redName.contains(':')
        ? firstMatch.redName.split(':').first.trim()
        : firstMatch.redName;
    final wTeam = firstMatch.whiteName.contains(':')
        ? firstMatch.whiteName.split(':').first.trim()
        : firstMatch.whiteName;

    final isRedOwn =
        ownTeams.contains(rTeam) ||
        (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
    final isWhiteOwn =
        ownTeams.contains(wTeam) ||
        (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);

    if (isRedOwn) {
      _ownTeamName = rTeam;
      _isOwnTeamRed = true;
    } else if (isWhiteOwn) {
      _ownTeamName = wTeam;
      _isOwnTeamRed = false;
    } else {
      _ownTeamName = rTeam;
      _isOwnTeamRed = true;
    }

    _positions = [];
    _currentPlayers = [];
    for (var m in widget.sortedMatches) {
      final pos = m.matchType;
      final rawName = _isOwnTeamRed ? m.redName : m.whiteName;
      final name = rawName.contains(':')
          ? rawName.split(':').last.trim()
          : rawName;

      _positions.add(pos);
      _currentPlayers.add(name);
    }
  }

  void _buildUnifiedList() {
    _unifiedList = [];
    for (int i = 0; i < _positions.length; i++) {
      _unifiedList.add({
        'id': 'pos_$i',
        'type': 'position',
        'label': _positions[i],
        'name': _currentPlayers[i],
      });
    }
    for (int i = 0; i < _reservePlayers.length; i++) {
      final rp = _reservePlayers[i];
      _unifiedList.add({
        'id': 'reserve_${rp}_$i',
        'type': 'reserve',
        'label': '控え',
        'name': rp,
      });
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _unifiedList.removeAt(oldIndex);
      _unifiedList.insert(newIndex, item);

      final posCount = _positions.length;
      _currentPlayers = [];
      _reservePlayers = [];

      for (int i = 0; i < _unifiedList.length; i++) {
        final name = _unifiedList[i]['name']!;
        if (i < posCount) {
          _currentPlayers.add(name);
          _unifiedList[i]['type'] = 'position';
          _unifiedList[i]['label'] = _positions[i];
        } else {
          _reservePlayers.add(name);
          _unifiedList[i]['type'] = 'reserve';
          _unifiedList[i]['label'] = '控え';
        }
      }
    });
  }

  Future<void> _addNewPlayerToReserve(
    List<PlayerModel> allPlayers,
    List<TeamModel> allTeams,
  ) async {
    // 曖昧マッチで組織名が _ownTeamName にマッチする選手を抽出
    final teamPlayers = allPlayers
        .where((p) {
          final org = p.organization.trim();
          if (org.isEmpty) return false;
          return _ownTeamName.contains(org) || org.contains(_ownTeamName);
        })
        .map((p) => p.name)
        .toList();

    // 加えて、登録されたチーム（TeamModel）の選手も含める
    final matchedTeam = allTeams.firstWhere(
      (t) => t.teamName == _ownTeamName || _ownTeamName == t.teamName,
      orElse: () {
        return allTeams.firstWhere(
          (t) =>
              _ownTeamName.contains(t.teamName) ||
              t.teamName.contains(_ownTeamName),
          orElse: () => TeamModel(
            id: '',
            tournamentId: '',
            category: '',
            teamName: '',
            matchType: '',
            playerNames: [],
          ),
        );
      },
    );
    final teamRegisteredPlayerNames = matchedTeam.playerNames
        .where((name) => name.isNotEmpty)
        .toList();

    final Set<String> candidates = {
      ...teamRegisteredPlayerNames,
      ...teamPlayers,
    };

    final existingNames = _unifiedList.map((item) => item['name']!).toSet();
    final availablePlayers = candidates
        .where(
          (name) =>
              !existingNames.contains(name) && name != '未定' && name != '欠員',
        )
        .toList();

    if (!mounted) return;

    final String? selectedName = await showDialog<String>(
      context: context,
      builder: (context) =>
          _AddReservePlayerDialog(availablePlayers: availablePlayers),
    );

    if (selectedName != null) {
      setState(() {
        _reservePlayers.add(selectedName);
        _buildUnifiedList();
      });
    }
  }

  Future<void> _saveOrder() async {
    setState(() {
      _isSaving = true;
    });

    final List<MatchModel> updatedMatches = [];
    for (int i = 0; i < widget.sortedMatches.length; i++) {
      final originalMatch = widget.sortedMatches[i];
      final newPlayerName = _currentPlayers[i];

      final String updatedRedName;
      final String updatedWhiteName;

      if (_isOwnTeamRed) {
        updatedRedName = '$_ownTeamName : $newPlayerName';
        updatedWhiteName = originalMatch.whiteName;
      } else {
        updatedRedName = originalMatch.redName;
        updatedWhiteName = '$_ownTeamName : $newPlayerName';
      }

      final updatedMatch = originalMatch.copyWith(
        redName: updatedRedName,
        whiteName: updatedWhiteName,
      );
      updatedMatches.add(updatedMatch);
    }

    try {
      await ref
          .read(matchApplicationServiceProvider)
          .saveMatchesBulk(updatedMatches);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('オーダーを更新しました。')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('オーダーの更新に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (_isSaving) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final playersAsync = ref.watch(timelinePlayerListProvider);
    final tournamentId = widget.sortedMatches.first.tournamentId ?? '';
    final teamsAsync = ref.watch(registeredTeamsProvider(tournamentId));

    return playersAsync.when(
      loading: () => Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(child: Text('選手リストの読み込みに失敗しました: $err')),
      ),
      data: (allPlayers) {
        return teamsAsync.when(
          loading: () => Container(
            height: 300,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Container(
            height: 300,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Center(child: Text('チームリストの読み込みに失敗しました: $err')),
          ),
          data: (allTeams) {
            if (!_isInitialized) {
              // 1. チーム名が一致する TeamModel を探す
              final matchedTeam = allTeams.firstWhere(
                (t) => t.teamName == _ownTeamName || _ownTeamName == t.teamName,
                orElse: () {
                  // 部分一致で曖昧検索
                  return allTeams.firstWhere(
                    (t) =>
                        _ownTeamName.contains(t.teamName) ||
                        t.teamName.contains(_ownTeamName),
                    orElse: () => TeamModel(
                      id: '',
                      tournamentId: '',
                      category: '',
                      teamName: '',
                      matchType: '',
                      playerNames: [],
                    ),
                  );
                },
              );

              // 2. チーム登録データから選手名（補欠を含む）を収集
              final List<String> teamRegisteredPlayerNames = matchedTeam
                  .playerNames
                  .where((name) => name.isNotEmpty)
                  .toList();

              // 4. チーム登録された選手（補欠）を控え候補とする
              // ★ 改修: 初期控えには名簿全体（teamPlayers）を含めず、チーム登録された選手のみを対象とする
              final Set<String> candidates = {...teamRegisteredPlayerNames};

              // 5. 現在出場していない選手のみを控え選手プールとする
              _reservePlayers = candidates
                  .where(
                    (name) =>
                        !_currentPlayers.contains(name) &&
                        name != '未定' &&
                        name != '欠員',
                  )
                  .toList();

              _buildUnifiedList();
              _isInitialized = true;
            }

            return Container(
              margin: EdgeInsets.only(bottom: keyboardHeight),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'オーダー編集 : $_ownTeamName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '右側の三本線を長押し・ドラッグして並び替えます。上の5枠が出場選手になります。',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          itemCount: _unifiedList.length,
                          itemBuilder: (context, index) {
                            final item = _unifiedList[index];
                            final id = item['id']!;
                            final name = item['name']!;
                            final label = item['label']!;
                            final isPosition = item['type'] == 'position';

                            return Card(
                              key: ValueKey('unified_item_$id'),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isPosition
                                  ? (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.blue.shade50)
                                  : (isDark
                                        ? const Color(0xFF1C1C1E)
                                        : Colors.grey.shade100),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPosition
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: isPosition
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                trailing: const Icon(Icons.drag_handle),
                              ),
                            );
                          },
                          onReorderItem: _onReorder,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _addNewPlayerToReserve(allPlayers, allTeams),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              '控えを追加',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _saveOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('オーダーを確定'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AddReservePlayerDialog extends StatefulWidget {
  final List<String> availablePlayers;
  const _AddReservePlayerDialog({required this.availablePlayers});

  @override
  State<_AddReservePlayerDialog> createState() =>
      _AddReservePlayerDialogState();
}

class _AddReservePlayerDialogState extends State<_AddReservePlayerDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('控え選手の追加'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '助っ人（マスタ外）の名前を入力',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    onSubmitted: (val) {
                      final name = val.trim();
                      if (name.isNotEmpty) {
                        Navigator.pop(context, name);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = _textController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(context, name);
                    }
                  },
                  child: const Text('追加'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '所属名簿から選択：',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.availablePlayers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '未出場の所属選手はいません。',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availablePlayers.length,
                  itemBuilder: (context, index) {
                    final name = widget.availablePlayers[index];
                    return ListTile(
                      title: Text(name),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.pop(context, name),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
