import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

// ★ 画面間で共有する状態
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
      // ★ 修正: ネイティブ(Isar)とWeb(Firestore)でデータソースを最適化し、完全な仕様一致(即時反映)を実現
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
