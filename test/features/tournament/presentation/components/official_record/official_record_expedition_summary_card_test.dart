import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_expedition_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String? mockClipboardText;

  setUpAll(() async {
    await initializeDateFormatting('ja');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            mockClipboardText = args?['text'] as String?;
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': mockClipboardText};
          }
          return null;
        });
  });

  group('[Widget] OfficialRecordExpeditionSummaryCard UI & Share テスト', () {
    testWidgets('成績サマリーのレイアウト維持: タイトル行右端にLINE・共有ボタン、実施カテゴリのみ表示されること', (
      tester,
    ) async {
      final matches = [
        const MatchModel(
          id: 'm1',
          groupName: 'group_1',
          redName: '道上剣友会 : 山田',
          whiteName: 'ライバル道場 : 相手1',
          matchType: '先鋒',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          matchScene: 'honsen',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OfficialRecordExpeditionSummaryCard(
                  matches: matches,
                  isDark: false,
                  registeredTeamNames: const {'道上剣友会'},
                  registeredPlayerNames: const {'山田'},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. タイトルとLINE・共有ボタン、開くボタンの存在確認
      expect(find.text('成績サマリー'), findsOneWidget);
      expect(find.text('LINE・共有'), findsOneWidget);
      expect(find.text('開く'), findsOneWidget);

      // カードを展開
      await tester.tap(find.byKey(const Key('btn_toggle_expedition_summary')));
      await tester.pumpAndSettle();

      // 2. 展開後に実施された本戦(団体)のみが表示され、未実施の錬成会や申し合わせが表示されないこと
      expect(find.text('閉じる'), findsOneWidget);
      expect(find.text('本戦 (団体)'), findsOneWidget);
      expect(find.text('1勝 0敗'), findsOneWidget);
      expect(find.text('錬成会 (団体)'), findsNothing);
      expect(find.text('申し合わせ'), findsNothing);

      // 3. 詳細分析ボタンの存在確認
      expect(find.text('詳細分析 ›'), findsOneWidget);
    });

    testWidgets('共有ボタンをタップした際にクリップボード格納および共有コールバックが正しく呼び出されること', (
      tester,
    ) async {
      final matches = [
        const MatchModel(
          id: 'm1',
          groupName: 'group_1',
          redName: '道上剣友会 : 山田',
          whiteName: 'ライバル道場 : 相手1',
          matchType: '先鋒',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      String? capturedText;
      String? capturedSubject;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OfficialRecordExpeditionSummaryCard(
                  matches: matches,
                  isDark: false,
                  registeredTeamNames: const {'道上剣友会'},
                  registeredPlayerNames: const {'山田'},
                  onShare: (text, subject, origin) async {
                    capturedText = text;
                    capturedSubject = subject;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // LINE・共有ボタンをタップ
      await tester.tap(find.text('LINE・共有'));
      await tester.pumpAndSettle();

      // クリップボードにテキストが格納されたことを検証
      expect(mockClipboardText, isNotNull);
      expect(mockClipboardText!.contains('結果速報'), isTrue);
      expect(mockClipboardText!.contains('【団体戦】'), isTrue);
      expect(mockClipboardText!.contains('Kendo_Sync より配信'), isTrue);

      // onShare に渡された内容を検証
      expect(capturedText, isNotNull);
      expect(capturedText!.contains('【遠征・試合 結果速報】'), isTrue);
      expect(capturedText!.contains('Kendo_Sync より配信'), isTrue);
      expect(capturedSubject, '【遠征・試合 結果速報】');
    });

    testWidgets('「詳細分析 ›」をタップした際に詳細モーダルが開き、対戦カード履歴が表示されること', (tester) async {
      final matches = [
        const MatchModel(
          id: 'm1',
          groupName: 'group_1',
          redName: '道上剣友会 : 山田',
          whiteName: '相手チーム : 選手1',
          matchType: '先鋒',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OfficialRecordExpeditionSummaryCard(
                  matches: matches,
                  isDark: false,
                  registeredTeamNames: const {'道上剣友会'},
                  registeredPlayerNames: const {'山田'},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // サマリーカードを展開
      await tester.tap(find.byKey(const Key('btn_toggle_expedition_summary')));
      await tester.pumpAndSettle();

      // 詳細分析ボタンをタップ
      await tester.tap(find.text('詳細分析 ›'));
      await tester.pumpAndSettle();

      // モーダルが開いて「対戦カード履歴」が表示され、「全剣連基準」が含まれていないことを検証
      expect(find.text('有効打突・取得技内訳'), findsOneWidget);
      expect(find.text('対戦カード履歴'), findsOneWidget);
      expect(find.textContaining('全剣連基準'), findsNothing);
    });

    testWidgets('カード展開および選手別成績アコーディオンの折りたたみが正しく動作すること', (tester) async {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: 'A道場 : 佐藤',
        whiteName: 'B道場 : 鈴木',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        matchType: '団体戦',
        matchScene: 'honsen',
        groupName: '第1試合場',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OfficialRecordExpeditionSummaryCard(
                matches: [match],
                isDark: false,
                registeredTeamNames: const {'A道場'},
                registeredPlayerNames: const {'佐藤'},
              ),
            ),
          ),
        ),
      );

      expect(find.text('成績サマリー'), findsOneWidget);
      expect(find.text('開く'), findsOneWidget);
      expect(find.text('閉じる'), findsNothing);

      // カードを展開
      await tester.tap(find.byKey(const Key('btn_toggle_expedition_summary')));
      await tester.pumpAndSettle();

      expect(find.text('閉じる'), findsOneWidget);
      expect(find.text('本戦 (団体)'), findsOneWidget);
      expect(find.text('詳細分析 ›'), findsOneWidget);
      expect(find.text('選手別成績 (1名)'), findsOneWidget);
      expect(find.text('表示する'), findsOneWidget);

      // 選手別成績のアコーディオンをタップして展開
      await tester.tap(find.text('選手別成績 (1名)'));
      await tester.pumpAndSettle();

      expect(find.text('佐藤: 1勝0敗'), findsOneWidget);

      // もう一度タップして選手別成績を折りたたみ
      await tester.tap(find.text('選手別成績 (1名)'));
      await tester.pumpAndSettle();

      expect(find.text('表示する'), findsOneWidget);

      // カード全体の「閉じる」をタップしてサマリーを折りたたむ
      await tester.tap(find.byKey(const Key('btn_toggle_expedition_summary')));
      await tester.pumpAndSettle();

      expect(find.text('開く'), findsOneWidget);
    });

    test('ExpeditionStatsCalculator computes wins accuratelyこと', () {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: 'A道場 : 佐藤',
        whiteName: 'B道場 : 鈴木',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        matchType: '団体戦',
        matchScene: 'renseikai',
        groupName: '第1試合場',
      );

      final data = ExpeditionStatsCalculator.calculate(
        matches: [match],
        registeredTeamNames: const {'A道場'},
        registeredPlayerNames: const {'佐藤'},
        selectedSummaryTeam: '全体',
      );

      expect(data.renseikaiWin, equals(1));
      expect(data.renseikaiLoss, equals(0));
      expect(data.teamsList, contains('A道場'));
    });
  });
}
