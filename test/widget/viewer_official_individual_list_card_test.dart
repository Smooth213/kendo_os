import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/tournament_own_info_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_table_sections.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  testWidgets(
    'ViewerOfficialIndividualListCard: 同門決勝が最上位に飛び出さず、初戦が早い順・時系列順に並ぶこと',
    (tester) async {
      // 山田（初戦 order 5）、佐藤（初戦 order 12）
      // 決勝戦（order 35）は山田 vs 佐藤（同門対決）
      // 鈴木（初戦 order 20, 他チーム同士）
      final matches = [
        const MatchListProjection(
          id: 'm1',
          tournamentId: 't1',
          matchOrder: 5,
          matchType: 'individual',
          status: 'finished',
          redName: '小畠:山田',
          whiteName: '外部:田中',
          redScore: 2,
          whiteScore: 0,
        ),
        const MatchListProjection(
          id: 'm2',
          tournamentId: 't1',
          matchOrder: 12,
          matchType: 'individual',
          status: 'finished',
          redName: '小畠:佐藤',
          whiteName: '外部:高橋',
          redScore: 1,
          whiteScore: 0,
        ),
        const MatchListProjection(
          id: 'm3_final',
          tournamentId: 't1',
          matchOrder: 35,
          matchType: 'individual',
          status: 'finished',
          redName: '小畠:山田',
          whiteName: '小畠:佐藤',
          redScore: 2,
          whiteScore: 1,
        ),
        const MatchListProjection(
          id: 'm4_other',
          tournamentId: 't1',
          matchOrder: 20,
          matchType: 'individual',
          status: 'finished',
          redName: '外部:鈴木',
          whiteName: '外部:加藤',
          redScore: 1,
          whiteScore: 0,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            tournamentOwnInfoProvider('t1').overrideWithValue(
              const TournamentOwnInfo(
                ownTeamNames: {'小畠', '小畠剣道教室'},
                ownPlayerNames: {'山田', '佐藤'},
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ViewerOfficialIndividualListCard(
                groupName: '__merged_individual__',
                matches: matches,
                isDark: false,
                applySort: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ヘッダー確認
      expect(find.text('【個人戦】'), findsOneWidget);

      // 表示順序の検証:
      // 自チーム試合（山田のまとまり: m1 (order 5), m3_final (order 35) -> 佐藤のまとまり: m2 (order 12)）
      // その後に他チーム試合（m4_other: 鈴木 vs 加藤 (order 20)）
      final cardFinder = find.byType(ViewerOfficialIndividualListCard);
      expect(cardFinder, findsOneWidget);

      final textWidgets = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();

      // '山田' の初出現が '佐藤' より先、かつ決勝戦（order 35）が m1 (order 5) より後ろにあること
      int indexM1 = textWidgets.indexWhere(
        (t) => t != null && t.contains('田中'),
      );
      int indexM2 = textWidgets.indexWhere(
        (t) => t != null && t.contains('高橋'),
      );
      int indexM4 = textWidgets.indexWhere(
        (t) => t != null && t.contains('鈴木'),
      );

      expect(indexM1 != -1, true);
      expect(indexM2 != -1, true);
      expect(indexM4 != -1, true);
      // 自チーム（山田・田中）が他チーム（鈴木）より前
      expect(indexM1 < indexM4, true);
    },
  );
}
