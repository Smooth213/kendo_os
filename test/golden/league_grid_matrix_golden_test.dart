import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_grid_table.dart';

void main() {
  group('📸 【Golden 4/5】公式星取り表（リーグ性格子マトリクス）視覚的境界整合性テスト', () {
    testWidgets('1. 3チーム総当たりリーグ戦 格子マトリクスの描画整合性（Lightモード）', (
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
          id: 'l3_1',
          tournamentId: 't1',
          matchType: '団体戦',
          redName: '神武館',
          whiteName: '修道館',
          redScore: 3,
          whiteScore: 1,
          status: 'approved',
          rule: rule,
          note: '[リーグ戦]',
        ),
        const MatchModel(
          id: 'l3_2',
          tournamentId: 't1',
          matchType: '団体戦',
          redName: '修道館',
          whiteName: '正気館',
          redScore: 2,
          whiteScore: 2,
          status: 'approved',
          rule: rule,
          note: '[リーグ戦]',
        ),
        const MatchModel(
          id: 'l3_3',
          tournamentId: 't1',
          matchType: '団体戦',
          redName: '神武館',
          whiteName: '正気館',
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
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 900,
                  height: 450,
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
      expect(find.text('神武館'), findsWidgets);
      expect(find.text('修道館'), findsWidgets);
      expect(find.text('正気館'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. 4チームリーグ戦 格子マトリクスの描画整合性（Darkモード）', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const rule = MatchRule(isLeague: true, matchTimeMinutes: 3.0);

      final teams = ['東京A', '大阪B', '愛知C', '福岡D'];
      final matches = <MatchModel>[];
      int idCount = 1;
      for (int i = 0; i < teams.length; i++) {
        for (int j = i + 1; j < teams.length; j++) {
          matches.add(
            MatchModel(
              id: 'l4_${idCount++}',
              tournamentId: 't1',
              matchType: '団体戦',
              redName: teams[i],
              whiteName: teams[j],
              redScore: 2,
              whiteScore: 1,
              status: 'approved',
              rule: rule,
              note: '[リーグ戦]',
            ),
          );
        }
      }

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 1050,
                  height: 550,
                  child: OfficialRecordLeagueGridTable(
                    groupName: '4チーム決勝リーグ',
                    matches: matches,
                    isDark: true,
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
      for (var team in teams) {
        expect(find.text(team), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
