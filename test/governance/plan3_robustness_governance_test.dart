import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🛡️ 【ガバナンス監査 26/26】堅牢性・同期整合性・データ完全性 永続保証規約', () {
    test('Rule 1: match_timer_provider.dart におけるタイマー停止時ミリ秒端数の完全維持規約（天井秒逆算排除）', () {
      final file = File(
        'lib/features/tournament/presentation/operate/providers/match_timer_provider.dart',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'match_timer_provider.dart が存在すること',
      );
      final content = file.readAsStringSync();

      // toggleTimer の停止分岐で生ミリ秒の差分が直接加算されていること
      expect(
        content.contains(
          'now.difference(match.timerStartedAt!).inMilliseconds',
        ),
        isTrue,
        reason:
            'タイマー停止時は天井秒からの逆算を廃止し、now.difference(match.timerStartedAt!).inMilliseconds の生ミリ秒を加算しなければなりません。',
      );

      // toggleTimer 停止分岐において updateRemainingSeconds を呼ぶ逆算ロジックが排除されていること
      final togglePos = content.indexOf('Future<void> toggleTimer(');
      expect(togglePos, isNonNegative);
      final nextMethodPos = content.indexOf(
        'Future<void> updateRemainingSeconds',
        togglePos,
      );
      expect(nextMethodPos, isNonNegative);
      final toggleTimerBody = content.substring(togglePos, nextMethodPos);

      expect(
        toggleTimerBody.contains('.updateRemainingSeconds('),
        isFalse,
        reason:
            'toggleTimer 停止処理内で updateRemainingSeconds による逆算再設定を呼ぶことは禁止されています。',
      );
    });

    test(
      'Rule 2: server_clock_offset_service.dart ＆ system_time_source.dart による端末時計ズレ(Clock Skew)補正規約',
      () {
        final serviceFile = File(
          'lib/shared/time/server_clock_offset_service.dart',
        );
        expect(
          serviceFile.existsSync(),
          isTrue,
          reason: 'server_clock_offset_service.dart が存在すること',
        );
        final serviceContent = serviceFile.readAsStringSync();

        expect(
          serviceContent.contains('class ServerClockOffsetService'),
          isTrue,
          reason: 'ServerClockOffsetService クラスが存在すること',
        );
        expect(
          serviceContent.contains('Duration get offset'),
          isTrue,
          reason: 'offset ゲッターが存在すること',
        );

        final timeSourceFile = File('lib/shared/time/system_time_source.dart');
        expect(
          timeSourceFile.existsSync(),
          isTrue,
          reason: 'system_time_source.dart が存在すること',
        );
        final timeSourceContent = timeSourceFile.readAsStringSync();

        expect(
          timeSourceContent.contains('ServerClockOffsetService'),
          isTrue,
          reason:
              'SystemTimeSource は ServerClockOffsetService と連携してオフセットを適用すること',
        );
        expect(
          timeSourceContent.contains('.add(offset)'),
          isTrue,
          reason: 'now() は端末時刻に offset を加算して返却すること',
        );
      },
    );

    test(
      'Rule 3: sync_crdt_merger.dart における 3者（リモート確定・ローカル確定・ローカル未送信）マージ ＆ LWWタイマー調停規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart',
        );
        expect(
          file.existsSync(),
          isTrue,
          reason: 'sync_crdt_merger.dart が存在すること',
        );
        final content = file.readAsStringSync();

        // 3者のイベントが漏れなくマージされていること
        expect(
          content.contains('remoteMatch.events'),
          isTrue,
          reason: 'remoteMatch.events がマージ対象であること',
        );
        expect(
          content.contains('localMatch.events'),
          isTrue,
          reason: 'localMatch.events がマージ対象であること (確定イベント消失防止)',
        );
        expect(
          content.contains('localMatch.pendingEvents'),
          isTrue,
          reason: 'localMatch.pendingEvents がマージ対象であること',
        );

        // タイマー調停 (Last-Write-Wins または pendingEvents 考慮) が実装されていること
        expect(
          content.contains('preferLocal'),
          isTrue,
          reason: 'タイマー調停用の優先フラグ判定ロジックが存在すること',
        );
        expect(
          content.contains('chosenTimerStartedAt'),
          isTrue,
          reason: '調停されたタイマー開始時刻が適用されること',
        );
      },
    );

    test(
      'Rule 4: match_list_provider.dart における Web大会切替時ステート即時リセット ＆ 大会IDフィルタ規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/match_list_provider.dart',
        );
        expect(
          file.existsSync(),
          isTrue,
          reason: 'match_list_provider.dart が存在すること',
        );
        final content = file.readAsStringSync();

        // 大会切替時の即時リセット
        expect(
          content.contains('activeWebTournamentId != safeTournamentId'),
          isTrue,
          reason: '大会ID切替時に旧大会データを即時リセットする判定が存在すること',
        );

        // matchListProvider での大会IDフィルタ
        expect(
          content.contains('m.tournamentId == currentTournamentId'),
          isTrue,
          reason:
              'matchListProvider 内で tournamentId によるフィルタリングを行い、ゴースト表示を遮断すること',
        );
      },
    );

    test(
      'Rule 5: match_model.dart における FSM(MatchLifecycleState) 統合 ＆ transitionEvent 規約',
      () {
        final file = File('lib/features/match/domain/match_model.dart');
        expect(file.existsSync(), isTrue, reason: 'match_model.dart が存在すること');
        final content = file.readAsStringSync();

        // lifecycleState ゲッターの配備
        expect(
          content.contains('MatchLifecycleState get lifecycleState'),
          isTrue,
          reason: 'MatchModel に lifecycleState ゲッターが存在すること',
        );

        // transitionEvent メソッドの配備
        expect(
          content.contains(
            'MatchModel transitionEvent(StateTransitionEvent event)',
          ),
          isTrue,
          reason: 'FSMイベント遷移用の transitionEvent メソッドが存在すること',
        );
      },
    );
  });
}
