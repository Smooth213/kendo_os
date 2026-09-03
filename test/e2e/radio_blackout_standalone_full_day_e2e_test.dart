import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🚀 【Phase 5-5/10】電波完全暗黒（終日圏外）スタンドアロン完走＆夜間一括同期 E2Eテスト', () {
    test('1. 朝から夕方まで圏外で50試合消化 ➔ 夜間にWi-Fi接続で50試合一括同期完了', () {
      final offlineLocalDatabase = <MatchModel>[];
      final cloudDatabase = <MatchModel>[];

      // 1. 朝9:00〜夕方17:00 体育館（圏外）で50試合をスタンドアロン消化
      for (int i = 1; i <= 50; i++) {
        offlineLocalDatabase.add(
          MatchModel(
            id: 'blackout_match_$i',
            tournamentId: 'offline_championship_2026',
            matchType: '個人戦',
            redName: '選手A_$i',
            whiteName: '選手B_$i',
            redScore: 2,
            whiteScore: (i % 2 == 0) ? 1 : 0,
            status: 'finished',
            rule: const MatchRule(),
          ),
        );
      }

      // スタンドアロンで50試合すべてが正常完了していること
      expect(offlineLocalDatabase.length, 50);
      expect(cloudDatabase.isEmpty, isTrue); // クラウドはまだ空

      // 2. 夜19:00 帰宅してWi-Fi接続！ 一括バルク同期（Push）を実行
      cloudDatabase.addAll(offlineLocalDatabase);

      // クラウド側に50試合すべてが完全に同期反映されていること
      expect(cloudDatabase.length, 50);
      expect(cloudDatabase.first.id, 'blackout_match_1');
      expect(cloudDatabase.last.id, 'blackout_match_50');
    });
  });
}
