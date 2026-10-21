import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/kata_score_action_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/match_rule_setting_form.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('[Widget] KataRuleAndScoreboardComponents 統合テスト', () {
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

        expect(find.text('形競技・基本技判定ルール'), findsOneWidget);
        expect(
          find.textContaining(
            '形競技（日本剣道形・木刀による剣道基本技稽古法）は審判員3名による赤白旗判定によって勝敗を決定します。',
          ),
          findsOneWidget,
        );
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

        await tester.tap(find.text('Open Rule Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('試合レギュレーション確認'), findsOneWidget);
        expect(find.text('試合形式'), findsOneWidget);
        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('勝負形式'), findsOneWidget);
        expect(find.text('延長戦'), findsOneWidget);
        expect(find.text('判定'), findsOneWidget);

        expect(find.text('時間計測なし'), findsOneWidget);
        expect(find.text('審判員3名による赤白旗判定'), findsOneWidget);
        expect(find.text('旗判定 (3本・過半数で勝敗判定)'), findsOneWidget);
        expect(find.text('なし'), findsWidgets);
        expect(find.text('代表戦'), findsNothing);
      },
    );

    Widget buildScoreActionWidget({
      required String matchId,
      required bool isInputLocked,
      required bool isDark,
      required bool hasEvents,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: KataScoreActionSection(
              matchId: matchId,
              isInputLocked: isInputLocked,
              isDark: isDark,
              hasEvents: hasEvents,
            ),
          ),
        ),
      );
    }

    testWidgets('初期状態で各旗判定ボタンおよび不戦勝ボタンが正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScoreActionWidget(
          matchId: 'match_1',
          isInputLocked: false,
          isDark: false,
          hasEvents: false,
        ),
      );

      expect(find.text('赤 3 - 0 白'), findsOneWidget);
      expect(find.text('赤 2 - 1 白'), findsOneWidget);
      expect(find.text('赤 0 - 3 白'), findsOneWidget);
      expect(find.text('赤 1 - 2 白'), findsOneWidget);
      expect(find.text('赤 不戦勝'), findsOneWidget);
      expect(find.text('白 不戦勝'), findsOneWidget);
      expect(find.text('直前の判定を取り消す (Undo)'), findsNothing);
    });

    testWidgets('イベントが存在する場合でもUndoボタンが描画されないこと', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildScoreActionWidget(
          matchId: 'match_1',
          isInputLocked: false,
          isDark: false,
          hasEvents: true,
        ),
      );

      expect(find.text('直前の判定を取り消す (Undo)'), findsNothing);
    });

    testWidgets('isInputLockedがtrueのとき各ボタンが無効化されていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScoreActionWidget(
          matchId: 'match_1',
          isInputLocked: true,
          isDark: false,
          hasEvents: true,
        ),
      );

      final redFusenFinder = find.text('赤 不戦勝');
      expect(redFusenFinder, findsOneWidget);
    });

    testWidgets('形試合の場合にスコアボード中央に旗数判定が表示されること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testMatch = MatchModel(
        id: 'test_kata_match',
        tournamentId: 'tour_kata_1',
        category: '形・一般',
        redName: '山田・佐藤',
        whiteName: '鈴木・田中',
        matchType: '個人戦',
        status: 'finished',
        redScore: 2,
        whiteScore: 1,
        rule: const MatchRule(isKataMatch: true),
        events: [
          ScoreEvent(
            id: 'ev_kata_1',
            side: Side.red,
            timestamp: DateTime.now(),
            isHantei: true,
            redFlags: 2,
            whiteFlags: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'test_user_id'),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            matchListProvider.overrideWithValue([testMatch]),
            scoreboardMatchIdProvider.overrideWithValue('test_kata_match'),
            scoreboardMatchProvider.overrideWithValue(testMatch),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: const MaterialApp(home: Scaffold(body: MatchScoreboard())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('山田・佐藤'), findsOneWidget);
      expect(find.text('鈴木・田中'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('1'), findsWidgets);
    });
  });
}
