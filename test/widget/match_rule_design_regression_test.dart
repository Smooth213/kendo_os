import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMatchDantai1 = MatchModel(
    id: 'm_dantai_1',
    tournamentId: 't_design_test',
    matchOrder: 1,
    category: '小学生の部',
    matchType: '団体戦',
    redName: '千代田A: 山田 太郎',
    whiteName: '中央B: 佐藤 次郎',
    status: 'pending',
    matchTimeMinutes: 3.0,
    hasExtension: false,
    hasHantei: false,
    rule: const MatchRule(
      matchTimeMinutes: 3.0,
      hasRepresentativeMatch: true,
      isDaihyoIpponShobu: true,
      daihyoMatchTimeMinutes: 0.0,
      daihyoHasExtension: true,
      daihyoEnchoTimeMinutes: 3.0,
      daihyoEnchoCount: -2,
    ),
  );

  final testMatchDantai2 = MatchModel(
    id: 'm_dantai_2',
    tournamentId: 't_design_test',
    matchOrder: 2,
    category: '小学生の部',
    matchType: '団体戦',
    redName: '千代田A: 鈴木 三郎',
    whiteName: '中央B: 高橋 四郎',
    status: 'pending',
    matchTimeMinutes: 3.0,
    hasExtension: false,
    hasHantei: false,
  );

  final testTournament = TournamentModel(
    id: 't_design_test',
    organizationId: 'org_1',
    name: 'デザイン検証大会',
    date: DateTime(2026, 9, 1),
    venue: '武道館',
    categoryRules: {
      '小学生の部': const CategoryRuleSet(
        matchType: '団体戦',
        normalRule: MatchRule(
          matchTimeMinutes: 3.0,
          hasRepresentativeMatch: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 0.0,
          daihyoHasExtension: true,
          daihyoEnchoCount: -2,
        ),
        renseikaiRule: MatchRule(
          matchScene: 'renseikai',
          isRenseikai: true,
          matchTimeMinutes: 2.0,
          isRunningTime: true,
          renseikaiType: '時間制',
          overallTimeMinutes: 30,
        ),
      ),
    },
  );

  group('🛡️ ルール設定デザイン回帰防止テスト要塞（スワイプ編集 ＆ ルール一括変更）', () {
    testWidgets(
      '1. MatchEditSheet（スワイプ編集）: ルールタブの全カード・トグル・チップがレイアウト崩れ無く表示・操作できること',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tournamentProvider(
                't_design_test',
              ).overrideWith((ref) => Stream.value(testTournament)),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                body: MatchEditSheet(
                  matches: [testMatchDantai1, testMatchDantai2],
                  tournamentId: 't_design_test',
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'normal',
                  ),
                  initialTabIndex: 2, // 直接ルールタブを開く
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. タブの表示確認
        expect(find.text('対戦・選手'), findsOneWidget);
        expect(find.text('コート・メモ'), findsOneWidget);
        expect(find.text('一括ルール'), findsOneWidget);

        // 2. ルール設定カード群の存在確認（デザインレイアウト検証）
        expect(find.text('🏷️ 試合ルール設定からワンタップ選択'), findsOneWidget);
        expect(find.text('⏱️ 試合時間 ＆ 基本形式'), findsOneWidget);
        expect(find.text('🔄 延長戦ルール'), findsOneWidget);
        expect(find.text('⚖️ 判定（ハンテイ）ルール'), findsOneWidget);

        // 3. 時間制切り替えによるレイアウト展開検証
        expect(find.text('一試合制 (デフォルト)'), findsOneWidget);
        expect(find.text('時間制'), findsOneWidget);
        await tester.tap(find.text('時間制'));
        await tester.pumpAndSettle();
        expect(find.text('全体の制限時間: 30分'), findsOneWidget);

        // 4. スクロールして代表戦・特殊形式を検証
        final kachinukiFinder = find.text('勝ち抜き戦形式');
        await tester.scrollUntilVisible(
          kachinukiFinder,
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        expect(find.text('🥋 団体戦・代表戦ルール'), findsOneWidget);
        expect(find.text('代表戦 詳細設定'), findsOneWidget);
        expect(find.text('代表戦の時間: 時間制限なし'), findsOneWidget);
        expect(find.text('代表戦は一本勝負'), findsOneWidget);
        expect(find.text('代表戦の延長戦を行う'), findsOneWidget);
        expect(find.text('代表戦延長の時間: 3分'), findsOneWidget);
        expect(find.text('代表戦延長は無制限（決着まで）'), findsOneWidget);
        expect(find.text('代表戦の判定を行う'), findsOneWidget);

        // 5. 勝ち抜き戦・リーグ戦のトグル展開検証
        expect(kachinukiFinder, findsOneWidget);
        await tester.tap(kachinukiFinder);
        await tester.pumpAndSettle();
        expect(find.text('大将対大将 (無制限)'), findsOneWidget);

        final leagueFinder = find.text('リーグ戦（勝点集計ルール）');
        expect(leagueFinder, findsOneWidget);
        await tester.tap(leagueFinder);
        await tester.pumpAndSettle();
        expect(find.text('勝ち（点）: 3.0'), findsOneWidget);
        expect(find.text('引き分け（点）: 1.0'), findsOneWidget);
        expect(find.text('負け（点）: 0.0'), findsOneWidget);

        // 6. 保存ボタンの描画確認
        expect(find.text('団体戦全体を一括保存'), findsOneWidget);
      },
    );

    testWidgets(
      '2. BulkRuleEditSheet（ルール一括変更）: フィルタ・プリセット・全ルール編集・下部実行バーが破綻無く動作すること',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tournamentProvider(
                't_design_test',
              ).overrideWith((ref) => Stream.value(testTournament)),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                body: BulkRuleEditSheet(
                  tournamentId: 't_design_test',
                  matches: [testMatchDantai1, testMatchDantai2],
                  themeColors: AppThemeColors.ofMode(
                    isDark: true,
                    mode: 'operate',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. タイトル＆ヘッダー確認
        expect(find.text('⚡ ルール一括変更'), findsOneWidget);

        // 2. STEP 1: 対象選択
        expect(find.text('STEP 1: 変更対象の試合を選択'), findsOneWidget);
        expect(find.text('[小学生の部] 団体戦'), findsOneWidget);

        // 3. STEP 2: 新ルール設定 ＆ プリセットカード
        expect(find.text('STEP 2: 新しいルールを設定'), findsOneWidget);
        expect(find.text('試合ルール設定から一括セット'), findsOneWidget);
        expect(find.text('小学生の部'), findsWidgets);

        // 4. 統一ルール設定フォームの描画確認
        expect(find.text('⏱️ 試合時間 ＆ 基本形式'), findsOneWidget);
        expect(find.text('🔄 延長戦ルール'), findsOneWidget);
        expect(find.text('⚖️ 判定（ハンテイ）ルール'), findsOneWidget);
        expect(find.text('🥋 団体戦・代表戦ルール'), findsOneWidget);
        expect(find.text('⚔️ 特殊形式 ＆ リーグ順位決定ルール'), findsOneWidget);

        // 5. 下部固定バー
        expect(find.text('選択した 1 件にルールを適用する'), findsOneWidget);
      },
    );

    testWidgets(
      '3. テーマ・レスポンシブ崩れ防止: 小画面（幅360px）でもOverflowエラー無くスクロール・操作可能であること',
      (tester) async {
        tester.view.physicalSize = const Size(720, 1280);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tournamentProvider(
                't_design_test',
              ).overrideWith((ref) => Stream.value(testTournament)),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                body: MatchEditSheet(
                  matches: [testMatchDantai1, testMatchDantai2],
                  tournamentId: 't_design_test',
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'normal',
                  ),
                  initialTabIndex: 2,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Overflowエラーが発生せず正常に描画されていること
        expect(tester.takeException(), isNull);

        // スクロール操作
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // スクロール後もOverflowエラーが無いこと
        expect(tester.takeException(), isNull);
      },
    );
  });
}
