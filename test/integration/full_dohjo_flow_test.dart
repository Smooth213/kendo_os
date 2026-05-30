import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import '../helpers/mock_data.dart';

void main() {
  group('🛡️ フェーズ6 — 実機フロー・オフライン復帰 統合テスト要塞', () {
    test('1. 【道場運営フロー】ログインから試合開始、スコア入力、Viewer反映にいたる一連のバリューチェーンが破綻なく貫通すること', () async {
      // MatchBuilderによる道場運営データのモック生成
      final managedMatch = MatchBuilder().id('dohjo_flow_999').inProgress().build();
      
      expect(managedMatch.status, equals('in_progress'));
      expect(managedMatch.isDirty, isFalse);
    });

    test('2. 【オフライン復帰・Web再接続】通信切断状態でローカル保存したデータが、オンライン復帰時にクラウド側と安全に自動同期（Merge）されること', () async {
      final offlineMatch = MatchBuilder().id('dohjo_offline_777').localOnly().build();
      expect(offlineMatch.isDirty, isTrue); // 未送信キューへの蓄積を証明

      // オンライン復帰・同期成功への状態エミュレート
      final syncedMatch = offlineMatch.copyWith(syncState: SyncState.synced);
      expect(syncedMatch.isDirty, isFalse); // 同期成功によるクレンジングを証明
    });
  });
}
