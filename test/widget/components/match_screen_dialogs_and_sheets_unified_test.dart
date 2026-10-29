import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_finished_navigation_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_retirement_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_share_options_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/quick_roster_swap_dialog.dart';

void main() {
  group('[Widget] 試合操作画面ダイアログ＆シート群 統合テスト', () {
    // ─────────────────────────────────────────────────────────
    // 1. MatchFinishedNavigationDialog
    // ─────────────────────────────────────────────────────────
    group('MatchFinishedNavigationDialog', () {
      testWidgets('新規団体戦および試合追加のための明確に区別されたボタン一覧が表示されること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchFinishedNavigationDialog(
                isRenseikai: true,
                hasGroupName: false,
                isKachinuki: false,
                isDark: false,
                onQuickNextMatch: () {},
                onAddNextRenseikaiMatch: () {},
                onGoHome: () {},
              ),
            ),
          ),
        );

        // 上：別のチームと対戦（次の団体戦）
        expect(find.text('別のチームと対戦（次の団体戦）'), findsOneWidget);
        expect(find.byIcon(Icons.bolt), findsOneWidget);

        // 下：試合を追加（現在のチームと続行）
        expect(find.text('試合を追加（現在のチームと続行）'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      });

      testWidgets('本戦大会時（onQuickNextMatchがnull）に次の試合ボタンが表示されないこと', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchFinishedNavigationDialog(
                isRenseikai: false,
                hasGroupName: false,
                isKachinuki: false,
                isDark: false,
                onQuickNextMatch: null, // 本戦モード時は null
                onGoHome: () {},
              ),
            ),
          ),
        );

        // 本戦モードではクイック対戦ボタンが表示されないこと
        expect(find.text('別のチームと対戦（次の団体戦）'), findsNothing);
      });

      testWidgets('全ボタン一覧が表示されコールバックが正確に実行されること', (tester) async {
        bool addRenseikaiClicked = false;
        bool nextMatchClicked = false;
        bool goHomeClicked = false;
        bool scoreboardClicked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchFinishedNavigationDialog(
                isRenseikai: true,
                nextMatchId: 'm2',
                nextMatchType: '先鋒',
                tournamentId: 'tour_1',
                hasGroupName: true,
                isKachinuki: false,
                isDark: false,
                onAddNextRenseikaiMatch: () {
                  addRenseikaiClicked = true;
                },
                onGoToNextMatch: () {
                  nextMatchClicked = true;
                },
                onGoHome: () {
                  goHomeClicked = true;
                },
                onShowScoreboard: () {
                  scoreboardClicked = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('対戦終了'), findsOneWidget);
        expect(find.textContaining('試合を追加（現在のチームと続行）'), findsOneWidget);
        expect(find.textContaining('次の試合へ進む (先鋒)'), findsOneWidget);
        expect(find.text('大会ホームへ戻る'), findsOneWidget);
        expect(find.text('スコアボードを確認する'), findsOneWidget);

        await tester.tap(find.textContaining('試合を追加（現在のチームと続行）'));
        await tester.pump();
        expect(addRenseikaiClicked, isTrue);

        await tester.tap(find.textContaining('次の試合へ進む (先鋒)'));
        await tester.pump();
        expect(nextMatchClicked, isTrue);

        await tester.tap(find.text('大会ホームへ戻る'));
        await tester.pump();
        expect(goHomeClicked, isTrue);

        await tester.tap(find.text('スコアボードを確認する'));
        await tester.pump();
        expect(scoreboardClicked, isTrue);
      });

      testWidgets('tournamentId is 部内戦において 部内戦 home labelが正しく描画されること', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchFinishedNavigationDialog(
                isRenseikai: false,
                nextMatchId: null,
                tournamentId: 'bunaiksen_123',
                hasGroupName: false,
                isKachinuki: false,
                isDark: false,
                onGoHome: () {},
              ),
            ),
          ),
        );

        expect(find.text('部内戦ホームに戻る'), findsOneWidget);
        expect(find.textContaining('次の試合へ進む'), findsNothing);
        expect(find.text('スコアボードを確認する'), findsNothing);
      });
    });

    // ─────────────────────────────────────────────────────────
    // 2. MatchRetirementDialog
    // ─────────────────────────────────────────────────────────
    group('MatchRetirementDialog', () {
      const testMatch = MatchModel(
        id: 'test_match_1',
        matchType: '先鋒',
        redName: '竈門炭治郎',
        whiteName: '我妻善逸',
      );

      Widget createRetirementWidget({bool isDark = false}) {
        return ProviderScope(
          child: MaterialApp(
            theme: isDark ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      MatchRetirementDialog.show(
                        context,
                        match: testMatch,
                        currentUserId: 'tester',
                        isDark: isDark,
                      );
                    },
                    child: const Text('ダイアログを開く'),
                  );
                },
              ),
            ),
          ),
        );
      }

      testWidgets('ダイアログが正常に表示され、赤・白の棄権選択肢が表示されること', (tester) async {
        await tester.pumpWidget(createRetirementWidget());
        await tester.tap(find.text('ダイアログを開く'));
        await tester.safePumpAndSettle();

        expect(find.text('途中棄権の記録'), findsOneWidget);
        expect(find.text('赤 側が棄権'), findsOneWidget);
        expect(find.text('竈門炭治郎'), findsOneWidget);
        expect(find.text('白 側が棄権'), findsOneWidget);
        expect(find.text('我妻善逸'), findsOneWidget);
        expect(
          find.text('全日本剣道連盟ルールに基づき、相手側に不戦勝（2本）が付与され、試合が終了します。'),
          findsOneWidget,
        );

        // 初期状態では確定ボタンが無効であること
        final confirmBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '棄権を確定して終了'),
        );
        expect(confirmBtn.onPressed, isNull);
      });

      testWidgets('赤の棄権を選択すると確定ボタンが有効化されること', (tester) async {
        await tester.pumpWidget(createRetirementWidget());
        await tester.tap(find.text('ダイアログを開く'));
        await tester.safePumpAndSettle();

        // 赤をタップ
        await tester.tap(find.text('赤 側が棄権'));
        await tester.safePumpAndSettle();

        final confirmBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '棄権を確定して終了'),
        );
        expect(confirmBtn.onPressed, isNotNull);
      });

      testWidgets('キャンセルボタンでダイアログが閉じること', (tester) async {
        await tester.pumpWidget(createRetirementWidget());
        await tester.tap(find.text('ダイアログを開く'));
        await tester.safePumpAndSettle();

        await tester.tap(find.text('キャンセル'));
        await tester.safePumpAndSettle();

        expect(find.text('途中棄権の記録'), findsNothing);
      });
    });

    // ─────────────────────────────────────────────────────────
    // 3. QuickRosterSwapDialog
    // ─────────────────────────────────────────────────────────
    group('QuickRosterSwapDialog', () {
      testWidgets('QuickRosterSwapDialogにおいて ドラッグハンドル付きの並び替え可能な選手一覧が描画されること', (
        tester,
      ) async {
        final teamMatches = [
          const MatchModel(
            id: 'match-1',
            redName: '誠道館 : 山田',
            whiteName: 'ライバル : 田中',
            matchType: '先鋒',
            order: 0,
          ),
          const MatchModel(
            id: 'match-2',
            redName: '誠道館 : 佐藤',
            whiteName: 'ライバル : 鈴木',
            matchType: '次鋒',
            order: 1,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: QuickRosterSwapDialog(
                  currentMatch: teamMatches.first,
                  teamMatches: teamMatches,
                  isRedSide: true,
                ),
              ),
            ),
          ),
        );

        // タイトルと各要素の確認
        expect(find.textContaining('オーダー並び替え'), findsOneWidget);
        expect(find.text('先鋒'), findsOneWidget);
        expect(find.text('次鋒'), findsOneWidget);
        expect(find.text('山田'), findsOneWidget);
        expect(find.text('佐藤'), findsOneWidget);

        // ドラッグハンドル「＝」アイコンが2つ表示されていること
        expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

        // 保存ボタンが表示されていること
        final buttonFinder = find.widgetWithText(ElevatedButton, 'このオーダーで一括保存');
        expect(buttonFinder, findsOneWidget);
      });
    });

    // ─────────────────────────────────────────────────────────
    // 4. MatchShareOptionsBottomSheet
    // ─────────────────────────────────────────────────────────
    group('MatchShareOptionsBottomSheet', () {
      testWidgets(
        'MatchShareOptionsBottomSheetにおいて クラウド共有およびP2P配信の選択肢が正しく描画されること',
        (tester) async {
          const match = MatchModel(
            id: 'test-match-1',
            matchType: '先鋒',
            redName: '誠道館 : 山田',
            whiteName: 'ライバル : 田中',
          );

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: MatchShareOptionsBottomSheet(match: match),
                ),
              ),
            ),
          );

          expect(find.text('観戦の共有方法を選択'), findsOneWidget);
          expect(find.textContaining('LINE / クラウドで共有'), findsOneWidget);
          expect(find.textContaining('体育館ローカルP2P配信'), findsOneWidget);
          expect(find.text('圏外OK'), findsOneWidget);
        },
      );
    });
  });
}
