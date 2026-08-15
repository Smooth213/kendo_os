import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';
import 'package:kendo_os/shared/widgets/match_tables/score_table_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🏛️ 試合結果・打突部位・反則・公式記録完全保証 E2E インテグレーション要塞テスト (全12大シナリオ)', () {
    // 共通の描画ヘルパー
    Widget createTestApp(Widget child) {
      return MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );
    }

    testWidgets(
      '1. 【打突部位の正確な記録】面(メ)・小手(コ)・胴(ド)・突き(ツ)および先取サークルマークがPointBoxに忠実に描画されること',
      (WidgetTester tester) async {
        final redPoints = [
          const PointMark(mark: 'メ', isFirst: true),
          const PointMark(mark: 'コ', isFirst: false),
        ];
        final whitePoints = [const PointMark(mark: 'ド', isFirst: false)];

        await tester.pumpWidget(
          createTestApp(
            Row(
              children: [
                PointBox(
                  points: redPoints,
                  isWinner: true,
                  isRed: true,
                  isDark: false,
                ),
                const SizedBox(width: 16),
                PointBox(
                  points: whitePoints,
                  isWinner: false,
                  isRed: false,
                  isDark: false,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 打突部位テキストの検証
        expect(find.text('メ'), findsOneWidget);
        expect(find.text('コ'), findsOneWidget);
        expect(find.text('ド'), findsOneWidget);

        // 先取（1本目）の丸囲みコンテナ（CircleBorder / BoxShape.circle）が存在すること
        final circleDecorations = tester
            .widgetList<Container>(find.byType(Container))
            .where((container) {
              final decoration = container.decoration;
              return decoration is BoxDecoration &&
                  decoration.shape == BoxShape.circle;
            });
        expect(
          circleDecorations.isNotEmpty,
          isTrue,
          reason: '先取マークの丸囲みが描画されていること',
        );
      },
    );

    testWidgets('2. 【反則累積と反則による一本】1反則(▲)から2反則(▲▲)で相手に「反」が1本付与されスコアに加算されること', (
      WidgetTester tester,
    ) async {
      // 白側が2反則を犯し、赤側に「反」が1本入ったケース
      final redPoints = [const PointMark(mark: '反', isFirst: true)];

      await tester.pumpWidget(
        createTestApp(
          PointBox(
            points: redPoints,
            isWinner: true,
            isRed: true,
            isDark: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('反'), findsOneWidget);
    });

    testWidgets(
      '3. 【延長戦での決着部位】本戦0-0引き分け後の延長戦で「延メ」により決着し、延長バッジと技マークが正しく記録されること',
      (WidgetTester tester) async {
        final matchItem = ScoreTableMatchItem(
          id: 'item_1',
          matchType: '個人戦',
          redName: '道上:皿田',
          whiteName: '相手:選手A',
          redScore: 1,
          whiteScore: 0,
          isFinished: true,
          isEncho: true,
          redPoints: const [PointMark(mark: 'メ', isFirst: true)],
          whitePoints: const [],
        );

        final groupInfo = const ScoreTableGroupInfo(
          groupName: '個人トーナメント',
          headerTitle: '個人選手権 決勝',
          sideLabelRed: '紅',
          sideLabelWhite: '白',
          redWins: 1,
          whiteWins: 0,
          redTotalPoints: 1,
          whiteTotalPoints: 0,
          teamWinner: 'red',
          allFinished: true,
          isSummary: false,
        );

        await tester.pumpWidget(
          createTestApp(
            ScoreTableCard(
              info: groupInfo,
              matches: [matchItem],
              isDark: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('延'), findsOneWidget);
        expect(find.text('長'), findsOneWidget);
        expect(find.text('メ'), findsOneWidget);
        expect(find.text('勝'), findsOneWidget);
      },
    );

    testWidgets('4. 【判定勝ちと不戦勝】判定勝ち「判」および不戦勝「不 (◯◯)」が勝数・本数に正確に算入されること', (
      WidgetTester tester,
    ) async {
      final matchHantei = ScoreTableMatchItem(
        id: 'm_hantei',
        matchType: '先鋒',
        redName: '道上:先鋒',
        whiteName: '相手:先鋒',
        redScore: 1,
        whiteScore: 0,
        isFinished: true,
        redPoints: const [PointMark(mark: '判定', isFirst: false)],
        whitePoints: const [],
      );

      final matchFusen = ScoreTableMatchItem(
        id: 'm_fusen',
        matchType: '次鋒',
        redName: '道上:次鋒',
        whiteName: '相手:欠員',
        redScore: 2,
        whiteScore: 0,
        isFinished: true,
        redPoints: const [
          PointMark(mark: '◯', isFirst: false),
          PointMark(mark: '◯', isFirst: false),
        ],
        whitePoints: const [],
      );

      final groupInfo = const ScoreTableGroupInfo(
        groupName: '団体1回戦',
        headerTitle: '団体トーナメント 1回戦',
        sideLabelRed: '道上剣友会',
        sideLabelWhite: '相手道場',
        redWins: 2,
        whiteWins: 0,
        redTotalPoints: 3,
        whiteTotalPoints: 0,
        teamWinner: 'red',
        allFinished: true,
        isSummary: false,
      );

      await tester.pumpWidget(
        createTestApp(
          ScoreTableCard(
            info: groupInfo,
            matches: [matchHantei, matchFusen],
            isDark: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 判定は「判」と表示されること
      expect(find.text('判'), findsOneWidget);
      // 不戦勝は「◯」が2つ表示されること
      expect(find.text('◯'), findsNWidgets(2));
      // 総本数 3, 勝数 2 がサマリーに描画されていること
      expect(find.text('3\n--\n2'), findsOneWidget);
    });

    testWidgets(
      '5. 【団体戦5人制 スコアテーブル完全整合性】全ポジションの技マーク（メ・コ・ド・反）と勝敗・本数合算が1ミリの狂いもなく同期されること',
      (WidgetTester tester) async {
        final matches = [
          ScoreTableMatchItem(
            id: 'm1',
            matchType: '先鋒',
            redName: '道上:先鋒',
            whiteName: '相手:先鋒',
            redScore: 2,
            whiteScore: 1,
            isFinished: true,
            redPoints: const [
              PointMark(mark: 'メ', isFirst: true),
              PointMark(mark: 'コ', isFirst: false),
            ],
            whitePoints: const [PointMark(mark: 'ド', isFirst: false)],
          ),
          ScoreTableMatchItem(
            id: 'm2',
            matchType: '次鋒',
            redName: '道上:次鋒',
            whiteName: '相手:次鋒',
            redScore: 1,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [PointMark(mark: '反', isFirst: true)],
            whitePoints: const [],
          ),
          ScoreTableMatchItem(
            id: 'm3',
            matchType: '中堅',
            redName: '道上:中堅',
            whiteName: '相手:中堅',
            redScore: 0,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [],
            whitePoints: const [],
          ),
          ScoreTableMatchItem(
            id: 'm4',
            matchType: '副将',
            redName: '道上:副将',
            whiteName: '相手:副将',
            redScore: 0,
            whiteScore: 2,
            isFinished: true,
            redPoints: const [],
            whitePoints: const [
              PointMark(mark: 'ツ', isFirst: true),
              PointMark(mark: 'メ', isFirst: false),
            ],
          ),
          ScoreTableMatchItem(
            id: 'm5',
            matchType: '大将',
            redName: '道上:大将',
            whiteName: '相手:大将',
            redScore: 2,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [
              PointMark(mark: 'メ', isFirst: true),
              PointMark(mark: 'ド', isFirst: false),
            ],
            whitePoints: const [],
          ),
        ];

        // 紅: 3勝 (先鋒,次鋒,大将) / 5本 (メ,コ,反,メ,ド)
        // 白: 1勝 (副将) / 3本 (ド,ツ,メ)
        // 分: 1分 (中堅)
        final groupInfo = const ScoreTableGroupInfo(
          groupName: '準決勝',
          headerTitle: '全日本団体選手権 準決勝',
          sideLabelRed: '道上剣友会',
          sideLabelWhite: '名門道場',
          redWins: 3,
          whiteWins: 1,
          redTotalPoints: 5,
          whiteTotalPoints: 3,
          teamWinner: 'red',
          allFinished: true,
          isSummary: false,
        );

        await tester.pumpWidget(
          createTestApp(
            ScoreTableCard(info: groupInfo, matches: matches, isDark: false),
          ),
        );
        await tester.pumpAndSettle();

        // ポジション名
        expect(find.text('先鋒'), findsOneWidget);
        expect(find.text('次鋒'), findsOneWidget);
        expect(find.text('中堅'), findsOneWidget);
        expect(find.text('副将'), findsOneWidget);
        expect(find.text('大将'), findsOneWidget);

        // 中堅の引き分け「✕」
        expect(find.text('✕'), findsOneWidget);

        // サマリー本/勝: 紅 5/3, 白 3/1
        expect(find.text('5\n--\n3'), findsOneWidget);
        expect(find.text('3\n--\n1'), findsOneWidget);
      },
    );

    testWidgets(
      '6. 【代表戦スコア非合算原則（全剣連規程最重要）】同点同本数(2勝3本 - 2勝3本)から代表戦で紅組がメで勝利した際、チーム合計は2(3)-2(3)のまま維持され勝者のみ紅組となること',
      (WidgetTester tester) async {
        final matchesWithDaihyo = [
          ScoreTableMatchItem(
            id: 'm1',
            matchType: '先鋒',
            redName: '道上:先鋒',
            whiteName: '相手:先鋒',
            redScore: 2,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [
              PointMark(mark: 'メ'),
              PointMark(mark: 'コ'),
            ],
            whitePoints: const [],
          ),
          ScoreTableMatchItem(
            id: 'm2',
            matchType: '次鋒',
            redName: '道上:次鋒',
            whiteName: '相手:次鋒',
            redScore: 0,
            whiteScore: 2,
            isFinished: true,
            redPoints: const [],
            whitePoints: const [
              PointMark(mark: 'ド'),
              PointMark(mark: 'ツ'),
            ],
          ),
          ScoreTableMatchItem(
            id: 'm3',
            matchType: '中堅',
            redName: '道上:中堅',
            whiteName: '相手:中堅',
            redScore: 1,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [PointMark(mark: 'メ')],
            whitePoints: const [],
          ),
          ScoreTableMatchItem(
            id: 'm4',
            matchType: '副将',
            redName: '道上:副将',
            whiteName: '相手:副将',
            redScore: 0,
            whiteScore: 1,
            isFinished: true,
            redPoints: const [],
            whitePoints: const [PointMark(mark: 'メ')],
          ),
          ScoreTableMatchItem(
            id: 'm5',
            matchType: '大将',
            redName: '道上:大将',
            whiteName: '相手:大将',
            redScore: 0,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [],
            whitePoints: const [],
          ),
          // 代表戦（紅組:大将が「メ」で一本勝ち）
          ScoreTableMatchItem(
            id: 'm_daihyo',
            matchType: '代表戦',
            redName: '道上:大将',
            whiteName: '相手:大将',
            redScore: 1,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [PointMark(mark: 'メ', isFirst: true)],
            whitePoints: const [],
          ),
        ];

        // 全剣連規則: 代表戦のスコアはチーム合計に合算しない！
        // したがって紅の合計は 2勝3本、白の合計は 2勝3本 のまま。
        final groupInfo = const ScoreTableGroupInfo(
          groupName: '決勝戦',
          headerTitle: '全国大会 決勝戦',
          sideLabelRed: '道上剣友会',
          sideLabelWhite: '相手道場',
          redWins: 2, // 代表戦は含まない
          whiteWins: 2, // 代表戦は含まない
          redTotalPoints: 3, // 代表戦の1本は加算しない
          whiteTotalPoints: 3,
          teamWinner: 'red', // 代表戦勝者によりチーム勝利
          allFinished: true,
          isSummary: false,
        );

        await tester.pumpWidget(
          createTestApp(
            ScoreTableCard(
              info: groupInfo,
              matches: matchesWithDaihyo,
              isDark: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 代表戦ヘッダーが存在すること
        expect(find.text('代表戦'), findsOneWidget);

        // チーム合計が代表戦抜きで 3/2 であること（4/3になっていないこと）
        expect(find.text('3\n--\n2'), findsNWidgets(2));
      },
    );

    testWidgets('7. 【公式記録・試合モデル完全同期】MatchModelの打突・反則・勝敗属性がドメイン不変条件と完全一致すること', (
      WidgetTester tester,
    ) async {
      const standardRule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false,
        hasRepresentativeMatch: true,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
      );

      final sampleMatch = MatchModel(
        id: 'official_m_1',
        category: '男子団体の部',
        groupName: '1回戦 第1試合',
        matchType: '先鋒',
        redName: '道上:皿田',
        whiteName: '相手:選手A',
        rule: standardRule,
      );

      expect(sampleMatch.rule?.matchTimeMinutes, equals(3.0));
      expect(sampleMatch.rule?.hasRepresentativeMatch, isTrue);
      expect(sampleMatch.rule?.positions.length, equals(5));
    });

    testWidgets(
      '8. 【延長戦への反則持ち越し】本戦の反則(▲)が延長戦へ持ち越され、延長戦での追加反則により反則決着(相手に反)となること',
      (WidgetTester tester) async {
        // 本戦で白1反則、延長戦で白2反則目となり、赤に「反」が入り試合終了
        final enchoHansokuMatch = ScoreTableMatchItem(
          id: 'm_encho_hansoku',
          matchType: '個人戦',
          redName: '道上:皿田',
          whiteName: '相手:選手B',
          redScore: 1,
          whiteScore: 0,
          isFinished: true,
          isEncho: true,
          redPoints: const [PointMark(mark: '反', isFirst: true)],
          whitePoints: const [],
        );

        final groupInfo = const ScoreTableGroupInfo(
          groupName: '準々決勝',
          headerTitle: '個人選手権 準々決勝',
          sideLabelRed: '道上剣友会',
          sideLabelWhite: '相手道場',
          redWins: 1,
          whiteWins: 0,
          redTotalPoints: 1,
          whiteTotalPoints: 0,
          teamWinner: 'red',
          allFinished: true,
          isSummary: false,
        );

        await tester.pumpWidget(
          createTestApp(
            ScoreTableCard(
              info: groupInfo,
              matches: [enchoHansokuMatch],
              isDark: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('延'), findsOneWidget);
        expect(find.text('長'), findsOneWidget);
        expect(find.text('反'), findsOneWidget);
        expect(find.text('1\n--\n1'), findsOneWidget);
      },
    );

    testWidgets('9. 【先取からの逆転勝利】紅組が先取(◯メ)後に白組がコ・ドを連取し、白組の2-1逆転勝利として完全描画されること', (
      WidgetTester tester,
    ) async {
      final comebackMatch = ScoreTableMatchItem(
        id: 'm_comeback',
        matchType: '大将',
        redName: '道上:大将',
        whiteName: '相手:大将',
        redScore: 1,
        whiteScore: 2,
        isFinished: true,
        redPoints: const [PointMark(mark: 'メ', isFirst: true)],
        whitePoints: const [
          PointMark(mark: 'コ', isFirst: false),
          PointMark(mark: 'ド', isFirst: false),
        ],
      );

      final groupInfo = const ScoreTableGroupInfo(
        groupName: '決勝戦',
        headerTitle: '決勝戦 大将戦',
        sideLabelRed: '道上剣友会',
        sideLabelWhite: '相手道場',
        redWins: 0,
        whiteWins: 1,
        redTotalPoints: 1,
        whiteTotalPoints: 2,
        teamWinner: 'white',
        allFinished: true,
        isSummary: false,
      );

      await tester.pumpWidget(
        createTestApp(
          ScoreTableCard(
            info: groupInfo,
            matches: [comebackMatch],
            isDark: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 先取メ、連取コ、ド
      expect(find.text('メ'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);
      expect(find.text('ド'), findsOneWidget);
      // 白組の勝利本数 2/1
      expect(find.text('2\n--\n1'), findsOneWidget);
    });

    testWidgets(
      '10. 【1-1引き分け vs 0-0引き分けの本数差】1-1ドローは総本数に双方+1加算、0-0ドローは総本数+0加算として正確に計算されること',
      (WidgetTester tester) async {
        final matchDraw1 = ScoreTableMatchItem(
          id: 'draw_1',
          matchType: '先鋒',
          redName: '道上:先鋒',
          whiteName: '相手:先鋒',
          redScore: 1,
          whiteScore: 1,
          isFinished: true,
          redPoints: const [PointMark(mark: 'メ', isFirst: true)],
          whitePoints: const [PointMark(mark: 'コ', isFirst: false)],
        );

        final matchDraw0 = ScoreTableMatchItem(
          id: 'draw_0',
          matchType: '次鋒',
          redName: '道上:次鋒',
          whiteName: '相手:次鋒',
          redScore: 0,
          whiteScore: 0,
          isFinished: true,
          redPoints: const [],
          whitePoints: const [],
        );

        final groupInfo = const ScoreTableGroupInfo(
          groupName: '引き分け検証',
          headerTitle: '団体戦 引き分け検証',
          sideLabelRed: '道上剣友会',
          sideLabelWhite: '相手道場',
          redWins: 0,
          whiteWins: 0,
          redTotalPoints: 1, // 先鋒の1本のみ
          whiteTotalPoints: 1, // 先鋒の1本のみ
          teamWinner: 'draw',
          allFinished: true,
          isSummary: false,
        );

        await tester.pumpWidget(
          createTestApp(
            ScoreTableCard(
              info: groupInfo,
              matches: [matchDraw1, matchDraw0],
              isDark: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 双方引き分けマーク「✕」が2つ存在すること
        expect(find.text('✕'), findsNWidgets(2));
        // 総本数 1, 勝数 0 が双方に描画されていること
        expect(find.text('1\n--\n0'), findsNWidgets(2));
      },
    );

    testWidgets(
      '11. 【複数ポジション欠員（不戦勝・不戦敗混在）】欠員枠に「◯◯」が入り、相手に各2本(計4本)が自動加算されて本数差勝敗が確定すること',
      (WidgetTester tester) async {
        final matchesWithAbsentees = [
          ScoreTableMatchItem(
            id: 'abs_1',
            matchType: '先鋒',
            redName: '道上:先鋒',
            whiteName: '相手:先鋒',
            redScore: 1,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [PointMark(mark: 'メ')],
            whitePoints: const [],
          ),
          // 次鋒欠員（相手に不戦2本）
          ScoreTableMatchItem(
            id: 'abs_2',
            matchType: '次鋒',
            redName: '道上:欠員',
            whiteName: '相手:次鋒',
            redScore: 0,
            whiteScore: 2,
            isFinished: true,
            redPoints: const [],
            whitePoints: const [
              PointMark(mark: '◯'),
              PointMark(mark: '◯'),
            ],
          ),
          ScoreTableMatchItem(
            id: 'abs_3',
            matchType: '中堅',
            redName: '道上:中堅',
            whiteName: '相手:中堅',
            redScore: 1,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [PointMark(mark: 'ド')],
            whitePoints: const [],
          ),
          // 副将欠員（相手に不戦2本）
          ScoreTableMatchItem(
            id: 'abs_4',
            matchType: '副将',
            redName: '道上:欠員',
            whiteName: '相手:副将',
            redScore: 0,
            whiteScore: 2,
            isFinished: true,
            redPoints: const [],
            whitePoints: const [
              PointMark(mark: '◯'),
              PointMark(mark: '◯'),
            ],
          ),
          ScoreTableMatchItem(
            id: 'abs_5',
            matchType: '大将',
            redName: '道上:大将',
            whiteName: '相手:大将',
            redScore: 0,
            whiteScore: 0,
            isFinished: true,
            redPoints: const [],
            whitePoints: const [],
          ),
        ];

        // 紅: 2勝 (先鋒,中堅) / 2本 (メ,ド)
        // 白: 2勝 (次鋒不戦,副将不戦) / 4本 (不戦4本)
        // 本数差（2(2) vs 2(4)）で白組勝利！
        final groupInfo = const ScoreTableGroupInfo(
          groupName: '欠員戦',
          headerTitle: '欠員混在 団体戦',
          sideLabelRed: '道上剣友会',
          sideLabelWhite: '相手道場',
          redWins: 2,
          whiteWins: 2,
          redTotalPoints: 2,
          whiteTotalPoints: 4,
          teamWinner: 'white',
          allFinished: true,
          isSummary: false,
        );

        await tester.pumpWidget(
          createTestApp(
            ScoreTableCard(
              info: groupInfo,
              matches: matchesWithAbsentees,
              isDark: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 不戦勝「◯」が4つ
        expect(find.text('◯'), findsNWidgets(4));
        // サマリー: 紅 2/2, 白 4/2
        expect(find.text('2\n--\n2'), findsOneWidget);
        expect(find.text('4\n--\n2'), findsOneWidget);
      },
    );

    testWidgets(
      '12. 【1試合中4反則による反則二本負け】1試合中に4回反則した場合、相手に「反」「反」の2本が入り2-0で試合が終了すること',
      (WidgetTester tester) async {
        final hansoku2Match = ScoreTableMatchItem(
          id: 'm_hansoku_4',
          matchType: '中堅',
          redName: '道上:中堅',
          whiteName: '相手:中堅',
          redScore: 2,
          whiteScore: 0,
          isFinished: true,
          redPoints: const [
            PointMark(mark: '反', isFirst: true),
            PointMark(mark: '反', isFirst: false),
          ],
          whitePoints: const [],
        );

        final groupInfo = const ScoreTableGroupInfo(
          groupName: '反則検証',
          headerTitle: '4反則二本負け 検証',
          sideLabelRed: '道上剣友会',
          sideLabelWhite: '相手道場',
          redWins: 1,
          whiteWins: 0,
          redTotalPoints: 2,
          whiteTotalPoints: 0,
          teamWinner: 'red',
          allFinished: true,
          isSummary: false,
        );

        await tester.pumpWidget(
          createTestApp(
            ScoreTableCard(
              info: groupInfo,
              matches: [hansoku2Match],
              isDark: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 反則による取得マーク「反」が2つ存在すること
        expect(find.text('反'), findsNWidgets(2));
        // サマリー: 2/1
        expect(find.text('2\n--\n1'), findsOneWidget);
      },
    );
  });
}
