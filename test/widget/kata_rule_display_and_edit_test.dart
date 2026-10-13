import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/match_rule_setting_form.dart';

void main() {
  group('[Widget] 剣道形 ルール表示 ＆ 編集 網羅検証テスト', () {
    testWidgets(
      'MatchRuleSettingForm で isKataMatch が true の場合、形競技専用案内カードが表示されること',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MatchRuleSettingForm(
                  isKataMatch: true,
                  selectedSceneKey: 'honsen',
                  matchTime: 0.0,
                  isRunningTime: false,
                  isIpponShobu: false,
                  hasExtension: false,
                  enchoTime: 0.0,
                  enchoCount: 0,
                  isEnchoUnlimited: false,
                  hasHantei: true,
                  hasRepresentativeMatch: false,
                  isDaihyoIpponShobu: false,
                  primaryAccent: Colors.blue,
                  isDark: false,
                  onMatchTimeChanged: (_) {},
                  onRunningTimeChanged: (_) {},
                  onIpponShobuChanged: (_) {},
                  onExtensionChanged: (_) {},
                  onEnchoTimeChanged: (_) {},
                  onEnchoCountChanged: (_) {},
                  onEnchoUnlimitedChanged: (_) {},
                  onHanteiChanged: (_) {},
                  onRepresentativeMatchChanged: (_) {},
                  onDaihyoIpponShobuChanged: (_) {},
                  onDaihyoMatchTimeChanged: (_) {},
                  onDaihyoExtensionChanged: (_) {},
                  onDaihyoEnchoTimeChanged: (_) {},
                  onDaihyoEnchoCountChanged: (_) {},
                  onDaihyoEnchoUnlimitedChanged: (_) {},
                  onDaihyoHanteiChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        // 形競技専用案内カードのタイトルおよび文言が表示されていること
        expect(find.text('形競技・基本技判定ルール'), findsOneWidget);
        expect(
          find.textContaining(
            '形競技（日本剣道形・木刀による剣道基本技稽古法）は審判員3名による赤白旗判定によって勝敗を決定します。',
          ),
          findsOneWidget,
        );
        // 竹刀用の項目（試合時間 ＆ 基本形式 等）が表示されていないこと
        expect(find.text('試合時間 & 基本形式'), findsNothing);
        expect(find.text('延長戦ルール'), findsNothing);
      },
    );

    testWidgets(
      'showRuleInfoBottomSheet で形競技の試合情報を開いた際、形競技仕様で表示され絵文字が含まれないこと',
      (tester) async {
        final kataMatch = MatchModel(
          id: 'test_kata_match',
          tournamentId: 'test_tourney',
          matchType: '日本剣道形',
          category: '小学生高学年の部 - 日本剣道形',
          redName: '道場A: 山田 太郎・佐藤 次郎',
          whiteName: '道場B: 鈴木 一郎・田中 三郎',
          rule: const MatchRule(
            isKataMatch: true,
            matchTimeMinutes: 0.0,
            hasHantei: true,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () =>
                        showRuleInfoBottomSheet(context, kataMatch),
                    child: const Text('Open Rule Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // ボタンをタップしてシートを開く
        await tester.tap(find.text('Open Rule Sheet'));
        await tester.pumpAndSettle();

        // タイトル・行ラベル（絵文字なし）
        expect(find.text('試合レギュレーション確認'), findsOneWidget);
        expect(find.text('試合形式'), findsOneWidget);
        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('勝負形式'), findsOneWidget);
        expect(find.text('延長戦'), findsOneWidget);
        expect(find.text('判定'), findsOneWidget);

        // 形競技の内容
        expect(find.text('時間計測なし'), findsOneWidget);
        expect(find.text('審判員3名による赤白旗判定'), findsOneWidget);
        expect(find.text('旗判定 (3本・過半数で勝敗判定)'), findsOneWidget);
        expect(find.text('なし'), findsWidgets); // 延長戦: なし

        // 代表戦などの不要項目が表示されていないこと
        expect(find.text('代表戦'), findsNothing);
      },
    );
  });
}
