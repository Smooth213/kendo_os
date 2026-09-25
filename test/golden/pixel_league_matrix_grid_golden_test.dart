import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_grid_table.dart';

void main() {
  group('📸 【Golden】公式リーグ星取表（対角線／・勝敗記号・勝点）視覚的整合性テスト', () {
    testWidgets('1. 3チーム総当たりリーグ星取表のレイアウト・対角線セル・勝点集計検証', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const rule = MatchRule(
        isLeague: true,
        winPoint: 3.0,
        drawPoint: 1.0,
        lossPoint: 0.0,
        matchTimeMinutes: 3.0,
      );

      final matches = [
        const MatchModel(
          id: 'l_pixel_1',
          tournamentId: 't1',
          matchType: '団体戦',
          redName: '勇気会',
          whiteName: '翔武会',
          redScore: 3,
          whiteScore: 1,
          status: 'approved',
          rule: rule,
          note: '[リーグ戦]',
        ),
        const MatchModel(
          id: 'l_pixel_2',
          tournamentId: 't1',
          matchType: '団体戦',
          redName: '翔武会',
          whiteName: '剛剣会',
          redScore: 2,
          whiteScore: 2,
          status: 'approved',
          rule: rule,
          note: '[リーグ戦]',
        ),
        const MatchModel(
          id: 'l_pixel_3',
          tournamentId: 't1',
          matchType: '団体戦',
          redName: '勇気会',
          whiteName: '剛剣会',
          redScore: 4,
          whiteScore: 0,
          status: 'approved',
          rule: rule,
          note: '[リーグ戦]',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: OfficialRecordLeagueGridTable(
                    groupName: '男子団体 第1次リーグ',
                    matches: matches,
                    isDark: false,
                    scoreTableBuilder: (name, bouts) => Text('詳細: $name'),
                    individualListBuilder: (name, bouts) => Text('個人: $name'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OfficialRecordLeagueGridTable), findsOneWidget);
      expect(find.text('勇気会'), findsWidgets);
      expect(find.text('翔武会'), findsWidgets);
      expect(find.text('剛剣会'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
