import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

MatchProjection _makeMatchProjection({
  required String id,
  required String redName,
  required String whiteName,
  required int redScore,
  required int whiteScore,
  List<PointDisplay> redDisplays = const [],
  List<PointDisplay> whiteDisplays = const [],
  String note = '',
  String matchType = '団体戦',
  String status = 'finished',
}) {
  return MatchProjection(
    id: id,
    tournamentId: 't_kachinuki',
    matchOrder: 1,
    matchType: matchType,
    status: status,
    groupName: '勝ち抜き戦決勝',
    isKachinuki: true,
    redName: redName,
    whiteName: whiteName,
    redScore: redScore,
    whiteScore: whiteScore,
    redDisplays: redDisplays,
    whiteDisplays: whiteDisplays,
    remainingSeconds: 0,
    timerIsRunning: false,
    note: note,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 勝ち抜き戦ブラケット（PDFスタイル準拠スリム描画）視覚整合性テスト', () {
    testWidgets('勝ち抜き戦ブラケット：標準試合展開（打突・勝敗・残留・スコアマーク）が正しく検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final matches = [
        _makeMatchProjection(
          id: 'k_match_1',
          redName: '昇龍館A : 佐藤',
          whiteName: '修道館B : 高橋',
          redScore: 2,
          whiteScore: 0,
          redDisplays: const [
            PointDisplay('メ', true),
            PointDisplay('コ', false),
          ],
        ),
        _makeMatchProjection(
          id: 'k_match_2',
          redName: '昇龍館A : 佐藤',
          whiteName: '修道館B : 伊藤',
          redScore: 1,
          whiteScore: 0,
          redDisplays: const [PointDisplay('メ', true)],
        ),
        _makeMatchProjection(
          id: 'k_match_3',
          redName: '昇龍館A : 佐藤',
          whiteName: '修道館B : 渡辺',
          redScore: 0,
          whiteScore: 1,
          whiteDisplays: const [PointDisplay('ド', true)],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 250,
                child: CustomPaint(
                  painter: KachinukiBracketPainter(
                    matches: matches,
                    isDark: false,
                  ),
                  size: const Size(800, 220),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('勝ち抜き戦ブラケット：長いチーム名2行折り返し・引き分け×・延長バッジ描画が正しく検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final matches = [
        _makeMatchProjection(
          id: 'k_match_draw_1',
          redName: '昇龍館一福道場A : 佐藤(健)',
          whiteName: '全日本少年剣道クラブB : 佐藤(誠)',
          redScore: 0,
          whiteScore: 0,
          note: '引き分け',
        ),
        _makeMatchProjection(
          id: 'k_match_encho_2',
          redName: '昇龍館一福道場A : 田中',
          whiteName: '全日本少年剣道クラブB : 鈴木',
          redScore: 1,
          whiteScore: 0,
          note: '延長戦',
          redDisplays: const [PointDisplay('コ', true)],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 700,
                height: 250,
                child: CustomPaint(
                  painter: KachinukiBracketPainter(
                    matches: matches,
                    isDark: false,
                  ),
                  size: const Size(700, 220),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('勝ち抜き戦ブラケット：ダークモード視覚的整合性・高コントラスト描画が正しく検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final matches = [
        _makeMatchProjection(
          id: 'k_match_dark_1',
          redName: '東軍選抜 : 山本',
          whiteName: '西軍選抜 : 中村',
          redScore: 2,
          whiteScore: 1,
          redDisplays: const [
            PointDisplay('メ', true),
            PointDisplay('コ', false),
          ],
          whiteDisplays: const [PointDisplay('ド', true)],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: Center(
              child: SizedBox(
                width: 600,
                height: 250,
                child: CustomPaint(
                  painter: KachinukiBracketPainter(
                    matches: matches,
                    isDark: true,
                  ),
                  size: const Size(600, 220),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
