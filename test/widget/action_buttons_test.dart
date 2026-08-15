import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/widgets/action_buttons.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('🛡️ Action Buttons Test', () {
    testWidgets('HoldConfirmButton displays circular indicator on long press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldConfirmButton(
              label: 'メ',
              color: Colors.blue,
              textColor: Colors.white, // 必須引数を追加
              disabled: false, // 必須引数を追加
              onConfirm: () {},
            ),
          ),
        ),
      );

      // 長押しを開始
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldConfirmButton)),
      );
      await tester.pump(const Duration(milliseconds: 100)); // ゲージが出現するまでの時間

      // CircularProgressIndicator がツリーにあるか確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 指を離す
      await gesture.up();
      await tester.pumpAndSettle();

      // インジケーターが消滅したことを確認
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('HoldConfirmButton does not trigger when disabled', (
      WidgetTester tester,
    ) async {
      bool isConfirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldConfirmButton(
              label: 'メ',
              color: Colors.blue,
              textColor: Colors.white,
              disabled: true, // ★ 無効化
              onConfirm: () {
                isConfirmed = true;
              },
            ),
          ),
        ),
      );

      // 長押しを開始
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldConfirmButton)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 無効化されているのでインジケーターは出ないはず
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // アニメーション完了時間まで進めても発火しないことを確認
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(isConfirmed, isFalse, reason: '無効化されている場合はonConfirmが呼ばれてはいけません');
    });

    testWidgets('HoldConfirmButton triggers onConfirm after full duration', (
      WidgetTester tester,
    ) async {
      bool isConfirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldConfirmButton(
              label: 'メ',
              color: Colors.blue,
              textColor: Colors.white,
              disabled: false,
              onConfirm: () {
                isConfirmed = true;
              },
            ),
          ),
        ),
      );

      // 長押しを開始して、完了時間(350ms)まで一気に進める
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldConfirmButton)),
      );

      // ジェスチャーをWidgetツリーに認識させてアニメーションを開始させるためのpump
      await tester.pump();

      // 350msちょうどだとフレームの境界で完了判定にならないことがあるため、
      // アニメーションの完了時間を確実に超えるように余裕を持たせて時間を進める
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(); // Listenerの処理（onConfirmとsetState）を反映させる

      expect(isConfirmed, isTrue, reason: '長押し完了時にonConfirmが呼ばれる必要があります');

      await gesture.up(); // 指を離す
      await tester.pumpAndSettle();
    });

    testWidgets('ScoreActionPanel has no overlapping artifacts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              // ★ ScoreActionPanel のトップレベルが Expanded のため、Row または Column でラップしてエラーを回避
              body: Row(
                children: [
                  ScoreActionPanel(
                    matchId: 'test',
                    side: Side.white,
                    color: Colors.blue,
                    isLocked: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 監査基準: 部位ボタン(Stack構造)の中に、不正なOpacityや重なりがないか
      // 特定のボタン型が「重複して」存在していないことを確認する
      final buttonFinders = find.byType(HoldConfirmButton);
      expect(buttonFinders, findsWidgets);

      // もしボタンの背後に「別の要素（Ghostや残像）」が意図せず隠れている場合、
      // それはWidgetツリー上に「隠れているはずのない要素」として表出する
      // 今回の不具合は「うっすら別のボタンが見える」ため、Stackの要素数を監査する
      final stacks = find.byType(Stack);
      for (final stack in tester.widgetList<Stack>(stacks)) {
        // スタック内の要素が2つ以上（ボタンとゲージ以外）存在しないかを確認
        expect(
          stack.children.length,
          lessThanOrEqualTo(2),
          reason: "Stack内に意図しないレイヤー（残像）が含まれています",
        );
      }
    });

    testWidgets(
      'Text inside HoldConfirmButton is precisely centered vertically and horizontally',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: HoldConfirmButton(
                    label: 'メ',
                    color: Colors.blue,
                    textColor: Colors.white,
                    disabled: false,
                    onConfirm: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        final buttonFinder = find.byType(HoldConfirmButton);
        final textFinder = find.text('メ');

        final buttonCenter = tester.getCenter(buttonFinder);
        final textCenter = tester.getCenter(textFinder);

        // 許容誤差範囲（丸め処理等による1px未満の極小のズレを考慮し、微小誤差の範囲でアサート）
        expect(
          (textCenter.dx - buttonCenter.dx).abs(),
          lessThan(1.0),
          reason: '横方向の位置が中心からずれています',
        );
        expect(
          (textCenter.dy - buttonCenter.dy).abs(),
          lessThan(1.0),
          reason: '縦方向の位置が中心からずれています',
        );
      },
    );

    testWidgets(
      '【入力完了ロック時グレーアウト検証】disabled: true の時、ダークモードで白飛び(0xFFFFFFFF)せず適切な暗灰色(0xFF2C2C2E)でグレーアウトすること',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: HoldConfirmButton(
                    label: 'メ',
                    color: const Color(0xFFE53935),
                    textColor: Colors.white,
                    disabled: true, // 入力完了・ロック状態
                    onConfirm: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final containerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  const Color(0xFF2C2C2E),
        );

        expect(
          containerFinder,
          findsOneWidget,
          reason: 'ダークモード時のdisabledボタン背景が暗灰色(0xFF2C2C2E)でグレーアウトされていること',
        );

        final textWidget = tester.widget<Text>(find.text('メ'));
        expect(textWidget.style?.color, equals(const Color(0x66FFFFFF)));
      },
    );
  });
}
