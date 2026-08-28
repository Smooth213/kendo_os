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

  group('OfficialRecordExpeditionSummaryCard UI & Share Tests', () {
    testWidgets('① 成績サマリーのレイアウト維持: タイトル行右端にLINE・共有ボタン、実施カテゴリのみ表示されること', (
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

      // 1. タイトルとLINE・共有ボタンの存在確認
      expect(find.text('成績サマリー'), findsOneWidget);
      expect(find.text('LINE・共有'), findsOneWidget);

      // 2. 実施された本戦(団体)のみが表示され、未実施の錬成会や申し合わせが表示されないこと
      expect(find.text('本戦 (団体)'), findsOneWidget);
      expect(find.text('1勝 0敗'), findsOneWidget);
      expect(find.text('錬成会 (団体)'), findsNothing);
      expect(find.text('申し合わせ'), findsNothing);

      // 3. 詳細分析ボタンの存在確認
      expect(find.text('詳細分析 ›'), findsOneWidget);
    });

    testWidgets('② 共有ボタンをタップした際にクリップボード格納および共有コールバックが正しく呼び出されること', (
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

    testWidgets('③ 「詳細分析 ›」をタップした際に詳細モーダルが開き、対戦カード履歴が表示されること', (tester) async {
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

      // 詳細分析ボタンをタップ
      await tester.tap(find.text('詳細分析 ›'));
      await tester.pumpAndSettle();

      // モーダルが開いて「対戦カード履歴」が表示され、「全剣連基準」が含まれていないことを検証
      expect(find.text('有効打突・取得技内訳'), findsOneWidget);
      expect(find.text('対戦カード履歴'), findsOneWidget);
      expect(find.textContaining('全剣連基準'), findsNothing);
    });
  });
}
