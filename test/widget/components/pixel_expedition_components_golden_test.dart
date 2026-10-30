import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_expedition_summary_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 遠征記録サマリー ＆ 詳細モーダル 視覚ピクセル統合テスト', () {
    testWidgets('ライトモードおよびダークモードにおいて遠征打突内訳と勝敗結果が美しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cardResults = [
        ExpeditionCardResult(
          cardTitle: '1回戦',
          opponentTeamName: '道場B',
          myWins: 3,
          oppWins: 1,
          myPoints: 5,
          oppPoints: 2,
          resultType: '勝',
          isWin: true,
          isDraw: false,
          scene: '本戦',
        ),
      ];

      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      ExpeditionDetailBottomSheet.show(
        context: capturedContext,
        isDark: false,
        teamName: '東京剣道会',
        teamMen: 3,
        teamKote: 2,
        teamDou: 1,
        teamTsuki: 0,
        teamHansoku: 1,
        teamOther: 0,
        totalScored: 7,
        totalConceded: 2,
        cardResults: cardResults,
      );

      await tester.pump();

      expect(find.textContaining('成績 詳細分析 (東京剣道会)'), findsOneWidget);
      expect(find.text('有効打突・取得技内訳'), findsOneWidget);
      expect(find.text('総取得本数: 7本'), findsOneWidget);
      expect(find.text('総失本数: 2本'), findsOneWidget);
      expect(find.text('得失差: +5'), findsOneWidget);
      expect(find.textContaining('道場B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    final sampleMatches = [
      MatchModel(
        id: 'exp_m1',
        tournamentId: 't1',
        matchType: '団体戦',
        redName: '錬心館: 佐藤',
        whiteName: '修道館: 鈴木',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      ),
      MatchModel(
        id: 'exp_m2',
        tournamentId: 't1',
        matchType: '団体戦',
        redName: '錬心館: 田中',
        whiteName: '修道館: 高橋',
        redScore: 1,
        whiteScore: 2,
        status: 'finished',
      ),
      MatchModel(
        id: 'exp_m3',
        tournamentId: 't1',
        matchType: '団体戦',
        redName: '錬心館: 伊藤',
        whiteName: '修道館: 渡辺',
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      ),
    ];

    Widget buildSummaryWrapper({
      required bool isDark,
      required bool initiallyExpanded,
    }) {
      final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
      return ProviderScope(
        child: AppThemeModeWrapper(
          mode: isDark ? 'dark' : 'normal',
          child: MaterialApp(
            theme: isDark
                ? ThemeData.dark().copyWith(extensions: [themeColors])
                : ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: OfficialRecordExpeditionSummaryCard(
                  matches: sampleMatches,
                  isDark: isDark,
                  registeredTeamNames: const {'錬心館', '修道館'},
                  registeredPlayerNames: const {'佐藤', '田中', '伊藤'},
                  initiallyExpanded: initiallyExpanded,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('スマホ幅(390px) ライトモード: 展開状態の勝率・勝数・本数サマリー描画が正しく検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildSummaryWrapper(isDark: false, initiallyExpanded: true),
      );
      await tester.pump();

      expect(find.text('成績サマリー'), findsOneWidget);
      expect(find.text('詳細分析 ›'), findsOneWidget);
      expect(find.text('本戦 (団体)'), findsOneWidget);
      expect(find.textContaining('選手別成績'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('タブレット幅(800px) ダークモード: 折りたたみ状態のピクセル完全性が正しく検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildSummaryWrapper(isDark: true, initiallyExpanded: false),
      );
      await tester.pump();

      expect(find.text('成績サマリー'), findsOneWidget);
      expect(find.text('詳細分析 ›'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
