import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';

void main() {
  group('[Unit] MatchFormatSaveHelper 単体テスト', () {
    testWidgets('設定コミット時にコートとノートが結合され履歴とプロバイダに保存されること', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const Scaffold(body: Text('設定'));
              },
            ),
          ),
        ),
      );

      final rule = MatchFormatSaveHelper.commitAndSaveRule(
        ref: capturedRef,
        courtText: '第1試合場',
        userNote: '決勝トーナメント 準決勝',
        registeredTeams: [],
        selectedTeamId: null,
        matchType: '個人戦',
        category: '一般男子',
        matchTime: 4.0,
        isRunningTime: false,
        isRenseikai: false,
        hasExtension: true,
        hasHantei: false,
        extCount: 1,
        extTime: 3.0,
        kachinukiUnlimitedType: 'none',
        hasLeagueDaihyo: false,
        renseikaiType: 'none',
        isDaihyoIpponShobu: false,
        winPointText: '3',
        lossPointText: '0',
        drawPointText: '1',
        overallTimeText: '30',
        selectedRuleScene: '標準',
      );

      // コート名とノートが改行結合されていること
      expect(rule.note, '第1試合場\n決勝トーナメント 準決勝');

      // noteHistoryProvider に単語が履歴登録されていること
      final history = capturedRef.read(noteHistoryProvider);
      expect(history, contains('決勝トーナメント'));
      expect(history, contains('準決勝'));

      // lastUsedSettingsProvider に保存されていること
      final lastUsed = capturedRef.read(lastUsedSettingsProvider);
      expect(lastUsed['matchType'], '個人戦');
      expect(lastUsed['matchTime'], 4.0);

      // matchRuleProvider に反映されていること
      final providerRule = capturedRef.read(matchRuleProvider);
      expect(providerRule.matchTimeMinutes, 4.0);
    });
  });
}
