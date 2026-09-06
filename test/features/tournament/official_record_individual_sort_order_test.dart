import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/tournament_own_info_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_table_sections.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  const tournamentId = 'test_tournament_sort';
  final ownInfo = const TournamentOwnInfo(
    ownTeamNames: {'小畠', '小畠剣道教室'},
    ownPlayerNames: {'山田', '佐藤'},
  );

  Widget buildOfficialWidget(List<MatchModel> matches) {
    return ProviderScope(
      overrides: [
        customTeamNamesProvider.overrideWith(
          (ref) => Stream.value(['小畠', '小畠剣道教室']),
        ),
        tournamentOwnInfoProvider(tournamentId).overrideWithValue(ownInfo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OfficialRecordIndividualMatchesList(
              groupName: '__merged_individual__',
              matches: matches,
              isDark: false,
              applySort: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildViewerWidget(List<MatchListProjection> matches) {
    return ProviderScope(
      overrides: [
        customTeamNamesProvider.overrideWith(
          (ref) => Stream.value(['小畠', '小畠剣道教室']),
        ),
        tournamentOwnInfoProvider(tournamentId).overrideWithValue(ownInfo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ViewerOfficialIndividualListCard(
              groupName: '__merged_individual__',
              matches: matches,
              isDark: false,
              applySort: true,
            ),
          ),
        ),
      ),
    );
  }

  group('個人戦の並び順保証テスト（本部公式記録＆閲覧ビュアー共通）', () {
    testWidgets('① 選手ごとのまとまり（初戦が早い順）＆ 選手内で時系列順に並ぶこと', (tester) async {
      // 山田: 2回戦(order 20), 1回戦(order 5) ※リストには順不同で追加
      // 佐藤: 1回戦(order 12)
      // 期待される順序: 山田1回戦(5) -> 山田2回戦(20) -> 佐藤1回戦(12)
      final matches = [
        const MatchModel(
          id: 'm_yamada_2',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 山田',
          whiteName: '外部: 中村',
          status: 'finished',
          order: 20,
          note: '山田2回戦',
        ),
        const MatchModel(
          id: 'm_sato_1',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 佐藤',
          whiteName: '外部: 鈴木',
          status: 'finished',
          order: 12,
          note: '佐藤1回戦',
        ),
        const MatchModel(
          id: 'm_yamada_1',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 山田',
          whiteName: '外部: 田中',
          status: 'finished',
          order: 5,
          note: '山田1回戦',
        ),
      ];

      await tester.pumpWidget(buildOfficialWidget(matches));
      await tester.pumpAndSettle();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .toList();

      final idxY1 = texts.indexWhere((t) => t.contains('山田1回戦'));
      final idxY2 = texts.indexWhere((t) => t.contains('山田2回戦'));
      final idxS1 = texts.indexWhere((t) => t.contains('佐藤1回戦'));

      expect(idxY1 != -1 && idxY2 != -1 && idxS1 != -1, isTrue);
      // 山田1回戦 -> 山田2回戦 -> 佐藤1回戦
      expect(idxY1 < idxY2, isTrue, reason: '同一選手内では時系列順（1回戦が先）');
      expect(idxY2 < idxS1, isTrue, reason: '初戦が早い山田がまとまって先');
    });

    testWidgets('② 赤・白の左右が入れ替わっても同一選手として正しくグルーピングされること', (tester) async {
      // 山田が赤の試合(order 5) と 白の試合(order 18)
      // 外部選手同士の試合(order 2)
      final matches = [
        const MatchModel(
          id: 'm_yamada_white',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '外部: 斉藤',
          whiteName: '小畠: 山田',
          status: 'finished',
          order: 18,
          note: '山田2回戦白側',
        ),
        const MatchModel(
          id: 'm_yamada_red',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 山田',
          whiteName: '外部: 田中',
          status: 'finished',
          order: 5,
          note: '山田1回戦赤側',
        ),
        const MatchModel(
          id: 'm_other',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '外部: 木村',
          whiteName: '外部: 高橋',
          status: 'finished',
          order: 2,
          note: '外部同士試合',
        ),
      ];

      await tester.pumpWidget(buildOfficialWidget(matches));
      await tester.pumpAndSettle();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .toList();

      final idxRed = texts.indexWhere((t) => t.contains('山田1回戦赤側'));
      final idxWhite = texts.indexWhere((t) => t.contains('山田2回戦白側'));
      final idxOther = texts.indexWhere((t) => t.contains('外部同士試合'));

      expect(idxRed != -1 && idxWhite != -1 && idxOther != -1, isTrue);
      expect(idxRed < idxWhite, isTrue, reason: '左右入替でも同一選手山田内で時系列順');
      expect(idxWhite < idxOther, isTrue, reason: '自チーム選手が外部同士より優先');
    });

    testWidgets('③ 同門決勝戦（同門対決）が一番上に飛び出さず、初戦順・時系列順に正しく並ぶこと', (tester) async {
      // 山田: 1回戦(order 5), 2回戦(order 18)
      // 佐藤: 1回戦(order 10), 2回戦(order 22)
      // 決勝: 山田 vs 佐藤 (order 35) ← リストの一番先頭で定義
      final matches = [
        const MatchModel(
          id: 'm_final',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 山田',
          whiteName: '小畠: 佐藤',
          status: 'finished',
          order: 35,
          note: '同門決勝戦',
        ),
        const MatchModel(
          id: 'm_sato_2',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 佐藤',
          whiteName: '外部: 渡辺',
          status: 'finished',
          order: 22,
          note: '佐藤2回戦',
        ),
        const MatchModel(
          id: 'm_yamada_1',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 山田',
          whiteName: '外部: 田中',
          status: 'finished',
          order: 5,
          note: '山田1回戦',
        ),
        const MatchModel(
          id: 'm_sato_1',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 佐藤',
          whiteName: '外部: 鈴木',
          status: 'finished',
          order: 10,
          note: '佐藤1回戦',
        ),
        const MatchModel(
          id: 'm_yamada_2',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 山田',
          whiteName: '外部: 中村',
          status: 'finished',
          order: 18,
          note: '山田2回戦',
        ),
      ];

      await tester.pumpWidget(buildOfficialWidget(matches));
      await tester.pumpAndSettle();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .toList();

      final idxY1 = texts.indexWhere((t) => t.contains('山田1回戦'));
      final idxY2 = texts.indexWhere((t) => t.contains('山田2回戦'));
      final idxFinal = texts.indexWhere((t) => t.contains('同門決勝戦'));
      final idxS1 = texts.indexWhere((t) => t.contains('佐藤1回戦'));
      final idxS2 = texts.indexWhere((t) => t.contains('佐藤2回戦'));

      expect(idxY1 != -1, isTrue);
      expect(idxY2 != -1, isTrue);
      expect(idxFinal != -1, isTrue);
      expect(idxS1 != -1, isTrue);
      expect(idxS2 != -1, isTrue);

      // 決勝戦がリストの最上位に飛び出さないこと
      expect(idxY1 < idxFinal, isTrue, reason: '決勝戦は初戦より前に来ない');
      expect(idxY2 < idxFinal, isTrue, reason: '山田2回戦の後に決勝戦');
      // 山田(初戦5)のグループの末尾に決勝(35)が入り、その後に佐藤(初戦10)の試合が続く
      expect(idxFinal < idxS1, isTrue, reason: '初戦が早い山田ブロックに決勝が帰属');
      expect(idxS1 < idxS2, isTrue, reason: '佐藤の1回戦の後に佐藤の2回戦');
    });

    testWidgets(
      '④ 閲覧専用ビュアー（ViewerOfficialIndividualListCard）でも同一の並び順が保証されること',
      (tester) async {
        final viewerMatches = [
          const MatchListProjection(
            id: 'v_final',
            tournamentId: tournamentId,
            matchOrder: 35,
            matchType: 'individual',
            status: 'finished',
            redName: '小畠: 山田',
            whiteName: '小畠: 佐藤',
            redScore: 2,
            whiteScore: 1,
            note: 'ビュアー同門決勝戦',
          ),
          const MatchListProjection(
            id: 'v_sato_1',
            tournamentId: tournamentId,
            matchOrder: 10,
            matchType: 'individual',
            status: 'finished',
            redName: '小畠: 佐藤',
            whiteName: '外部: 鈴木',
            redScore: 1,
            whiteScore: 0,
            note: 'ビュアー佐藤1回戦',
          ),
          const MatchListProjection(
            id: 'v_yamada_1',
            tournamentId: tournamentId,
            matchOrder: 5,
            matchType: 'individual',
            status: 'finished',
            redName: '小畠: 山田',
            whiteName: '外部: 田中',
            redScore: 2,
            whiteScore: 0,
            note: 'ビュアー山田1回戦',
          ),
          const MatchListProjection(
            id: 'v_other',
            tournamentId: tournamentId,
            matchOrder: 2,
            matchType: 'individual',
            status: 'finished',
            redName: '外部: 木村',
            whiteName: '外部: 高橋',
            redScore: 0,
            whiteScore: 1,
            note: 'ビュアー外部試合',
          ),
        ];

        await tester.pumpWidget(buildViewerWidget(viewerMatches));
        await tester.pumpAndSettle();

        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data ?? '')
            .toList();

        final idxY1 = texts.indexWhere((t) => t.contains('ビュアー山田1回戦'));
        final idxFinal = texts.indexWhere((t) => t.contains('ビュアー同門決勝戦'));
        final idxS1 = texts.indexWhere((t) => t.contains('ビュアー佐藤1回戦'));
        final idxOther = texts.indexWhere((t) => t.contains('ビュアー外部試合'));

        expect(idxY1 != -1, isTrue);
        expect(idxFinal != -1, isTrue);
        expect(idxS1 != -1, isTrue);
        expect(idxOther != -1, isTrue);

        // 山田1回戦 -> 同門決勝 -> 佐藤1回戦 -> 外部試合
        expect(idxY1 < idxFinal, isTrue, reason: 'ビュアーでも決勝戦が山田1回戦より後');
        expect(idxFinal < idxS1, isTrue, reason: 'ビュアーでも初戦が早い山田に同門決勝が帰属');
        expect(idxS1 < idxOther, isTrue, reason: 'ビュアーでも自チーム試合が外部試合より先');
      },
    );

    testWidgets('⑤ 後から追加された試合（初戦が遅い選手）が選手ごとのまとまりとして下に追加されていくこと', (
      tester,
    ) async {
      // 山田(初戦 order 5)
      // 佐藤(初戦 order 12)
      // 後から追加された自チーム選手「高橋」(初戦 order 28, 2回戦 order 32)
      final matches = [
        const MatchModel(
          id: 'm_yamada_1',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 山田',
          whiteName: '外部: 田中',
          status: 'finished',
          order: 5,
          note: '山田1回戦',
        ),
        const MatchModel(
          id: 'm_sato_1',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 佐藤',
          whiteName: '外部: 鈴木',
          status: 'finished',
          order: 12,
          note: '佐藤1回戦',
        ),
        const MatchModel(
          id: 'm_takahashi_1',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 高橋',
          whiteName: '外部: 伊藤',
          status: 'finished',
          order: 28,
          note: '高橋1回戦',
        ),
        const MatchModel(
          id: 'm_takahashi_2',
          tournamentId: tournamentId,
          matchType: 'individual',
          redName: '小畠: 高橋',
          whiteName: '外部: 渡辺',
          status: 'finished',
          order: 32,
          note: '高橋2回戦',
        ),
      ];

      // 高橋を ownPlayerNames に含めた ownInfo
      final extendedOwnInfo = const TournamentOwnInfo(
        ownTeamNames: {'小畠', '小畠剣道教室'},
        ownPlayerNames: {'山田', '佐藤', '高橋'},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith((ref) => Stream.value(['小畠'])),
            tournamentOwnInfoProvider(
              tournamentId,
            ).overrideWithValue(extendedOwnInfo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OfficialRecordIndividualMatchesList(
                  groupName: '__merged_individual__',
                  matches: matches,
                  isDark: false,
                  applySort: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .toList();

      final idxY1 = texts.indexWhere((t) => t.contains('山田1回戦'));
      final idxS1 = texts.indexWhere((t) => t.contains('佐藤1回戦'));
      final idxT1 = texts.indexWhere((t) => t.contains('高橋1回戦'));
      final idxT2 = texts.indexWhere((t) => t.contains('高橋2回戦'));

      expect(idxY1 != -1 && idxS1 != -1 && idxT1 != -1 && idxT2 != -1, isTrue);
      // 山田(5) -> 佐藤(12) -> 高橋1回戦(28) -> 高橋2回戦(32) の順序
      expect(idxY1 < idxS1, isTrue, reason: '山田(5)が佐藤(12)より上');
      expect(idxS1 < idxT1, isTrue, reason: '佐藤(12)が高橋(28)より上（あとから追加された選手は下へ）');
      expect(idxT1 < idxT2, isTrue, reason: '高橋のまとまり内でも1回戦->2回戦の時系列順');
    });
  });
}
