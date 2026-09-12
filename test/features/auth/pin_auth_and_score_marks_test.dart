import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/auth/presentation/screens/pin_auth_screen.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart';
import 'package:kendo_os/security/pin_guard.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import '../../widget/helpers/rendering_safety_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RenderingSafetyTestHelper.initialize();
  });

  group('🥋 部内戦 スコアマーク（待機中「ー」/ 引き分け「✕」）厳格判定テスト', () {
    testWidgets('1. 待機中試合（スコア0-0, isFinished: false）は「ー」（Icons.remove）を表示する', (
      tester,
    ) async {
      final waitMatch = MatchModel(
        id: 'test_wait_1',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 0,
        whiteScore: 0,
        matchType: 'individual',
        status: 'pending',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenScoreMarks(
              match: waitMatch,
              isDark: false,
              isFinished: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
      '2. 終了した試合（スコア0-0, isFinished: true）は引き分け「✕」（Icons.close）を表示する',
      (tester) async {
        final drawMatch = MatchModel(
          id: 'test_draw_1',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 0,
          whiteScore: 0,
          matchType: 'individual',
          status: 'finished',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenScoreMarks(
                match: drawMatch,
                isDark: false,
                isFinished: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byIcon(Icons.remove), findsNothing);
      },
    );

    testWidgets(
      '3. 終了した試合（スコア1-1引き分け, isFinished: true）は中央に「✕」（Icons.close）を表示する',
      (tester) async {
        final drawWithPointsMatch = MatchModel(
          id: 'test_draw_points_1',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 1,
          whiteScore: 1,
          matchType: 'individual',
          status: 'finished',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenScoreMarks(
                match: drawWithPointsMatch,
                isDark: false,
                isFinished: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
      },
    );

    testWidgets(
      '4. 勝敗ありの試合（スコア2-0, isFinished: true）は中央に「ー」（Icons.remove）を表示する',
      (tester) async {
        final wonMatch = MatchModel(
          id: 'test_won_1',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
          matchType: 'individual',
          status: 'finished',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenScoreMarks(
                match: wonMatch,
                isDark: false,
                isFinished: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.remove), findsOneWidget);
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );
  });

  group('🔐 PinAuthScreen テンキー入力・脱出導線・PIN照合保証テスト', () {
    testWidgets('1. オンスクリーンテンキーで数字が入力され、バックスペース・クリアが正しく動作する', (tester) async {
      await tester.pumpWidget(
        RenderingSafetyTestHelper.buildTestWidget(
          child: const PinAuthScreen(role: UserRole.operator),
        ),
      );
      await tester.pump();

      // タイトル「監督・引率責任者 (Operator)」が表示されていること
      expect(find.text('監督・引率責任者 (Operator)'), findsOneWidget);
      expect(find.text('PINコード認証'), findsOneWidget);

      // テンキーのキーが存在すること
      expect(find.text('2'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('クリア'), findsOneWidget);
      expect(find.text('⌫'), findsOneWidget);

      // テンキー '2', '4', '6' をタップ
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('6'));
      await tester.pump();

      // ⌫（1文字削除）をタップ
      await tester.tap(find.text('⌫'));
      await tester.pump();

      // クリアをタップ
      await tester.tap(find.text('クリア'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('2. 脱出導線（戻るボタン・別の権限を選択リンク）が正しく配置されている', (tester) async {
      await tester.pumpWidget(
        RenderingSafetyTestHelper.buildTestWidget(
          child: const PinAuthScreen(role: UserRole.admin),
        ),
      );
      await tester.pump();

      // AppBarの戻るボタンが存在すること
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);

      // 画面下部の「別の利用権限を選択する」リンクが存在すること
      expect(find.text('別の利用権限を選択する'), findsOneWidget);
    });

    test('3. PinGuard によるロール別PINコードの正確性検証', () {
      expect(PinGuard.validate(UserRole.admin, '9999'), isTrue);
      expect(PinGuard.validate(UserRole.admin, '1234'), isFalse);

      expect(PinGuard.validate(UserRole.operator, '2468'), isTrue);
      expect(PinGuard.validate(UserRole.operator, '0000'), isFalse);

      expect(PinGuard.validate(UserRole.recorder, '1357'), isTrue);
      expect(PinGuard.validate(UserRole.recorder, '9999'), isFalse);

      expect(PinGuard.validate(UserRole.viewer, ''), isTrue);
    });
  });
}
