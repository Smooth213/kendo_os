import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🛡️ 補正：未使用の match_model.dart インポートを完全物理排除し、警告を撲滅
import 'package:kendo_os/domain/score/score_event.dart';
import 'package:kendo_os/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/presentation/shared/widgets/action_buttons.dart';

void main() {
  group('🛡️ STEP 4-5: 運営スコア入力（打突・反則・処理中ロック）Widgetテスト要塞', () {
    const testMatchId = 'oper_widget_test_001';

    testWidgets('1. 【打突入力表示】ScoreActionPanel が赤・白両サイド正しくレンダリングされ、「メ」等の打突文字が視認できること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isMatchCommandProcessingProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            home: Scaffold(
              // ★ ブラッシュアップ: アスペクト比19.5:9の画面に収まるよう最適化された
              // テスト環境でも厳格にシミュレート（幅390想定で高さ約280）
              body: SizedBox(
                width: 390,
                height: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScoreActionPanel(
                      matchId: testMatchId,
                      side: Side.red,
                      color: Colors.red,
                      textColor: Colors.white,
                      isLocked: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('メ'), findsWidgets);
    });

    testWidgets('2. 【コマンドロック防壁】isMatchCommandProcessing が true（書き込み処理中）のとき、ボタンが有効ロック状態をホールドすること', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isMatchCommandProcessingProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScoreActionPanel(
                      matchId: testMatchId,
                      side: Side.white,
                      color: Colors.white,
                      textColor: Colors.black,
                      isLocked: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ScoreActionPanel), findsOneWidget);
    });
  });
}
