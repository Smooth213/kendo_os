import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_player_select_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_rule_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_sheet.dart';

void main() {
  group('[Widget] 部内戦クイックマッチ統合テスト', () {
    group('クイックマッチシート基本動作テスト', () {
      testWidgets('部内戦クイックマッチシートが正しく描画され操作が処理できること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BunaiksenQuickMatchSheet(dateId: 'bunaiksen_20260820'),
              ),
            ),
          ),
        );

        // Header & description
        expect(find.text('クイック対戦'), findsOneWidget);
        expect(find.text('赤・白の選手を選択して「試合スタート」を押すとすぐに計測が始まります'), findsOneWidget);

        // Initial players
        expect(find.text('選手A'), findsOneWidget);
        expect(find.text('選手B'), findsOneWidget);
        expect(find.text('VS'), findsOneWidget);

        // Match time stepper
        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('2分'), findsOneWidget);

        // Add match time
        final addBtn = find.byIcon(Icons.add);
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pump();
        expect(find.text('2.5分'), findsOneWidget);

        // Match format chips
        expect(find.text('3本勝負'), findsOneWidget);
        expect(find.text('1本勝負'), findsOneWidget);

        // Tap 1本勝負
        await tester.tap(find.text('1本勝負'));
        await tester.pump();

        // Start button
        expect(find.text('試合スタート'), findsOneWidget);
      });
    });

    group('クイックマッチUIコンポーネントテスト', () {
      testWidgets('部内戦クイックマッチ選手選択セクションが正しく描画されること', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) =>
                      BunaiksenQuickMatchPlayerSelectSection(
                        redPlayer: '選手A',
                        whitePlayer: '選手B',
                        onRedPlayerSelected: (_) {},
                        onWhitePlayerSelected: (_) {},
                        ref: ref,
                      ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('選手A'), findsOneWidget);
        expect(find.text('選手B'), findsOneWidget);
      });

      testWidgets('部内戦クイックマッチルールセクションが正しく描画されること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenQuickMatchRuleSection(
                selectedMatchTime: 3.0,
                selectedIsIpponShobu: false,
                onMatchTimeChanged: (_) {},
                onIsIpponShobuChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('3分'), findsOneWidget);
        expect(find.text('3本勝負'), findsOneWidget);
      });
    });
  });
}
