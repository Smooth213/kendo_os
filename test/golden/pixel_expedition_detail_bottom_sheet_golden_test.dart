import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 遠征詳細モーダル視覚ピクセルテスト', () {
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

      // ライトモードでのボトムシート表示
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

      await tester.pumpAndSettle();

      expect(find.textContaining('成績 詳細分析 (東京剣道会)'), findsOneWidget);
      expect(find.text('有効打突・取得技内訳'), findsOneWidget);
      expect(find.text('総取得本数: 7本'), findsOneWidget);
      expect(find.text('総失本数: 2本'), findsOneWidget);
      expect(find.text('得失差: +5'), findsOneWidget);
      expect(find.textContaining('道場B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
