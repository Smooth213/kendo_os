import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/providers/match_rule_provider.dart'; 
import 'package:kendo_os/models/match_rule.dart'; // ★ モデルを読み込む

void main() {
  group('MatchRuleProvider Tests', () {
    
    test('初期状態が正しくセットされているか', () {
      final container = ProviderContainer();
      addTearDown(container.dispose); 

      final initialState = container.read(matchRuleProvider);

      expect(initialState.matchTimeMinutes, 3, reason: '初期の試合時間は3分のはず');
      expect(initialState.isKachinuki, false, reason: '勝ち抜き戦フラグの初期値はfalseのはず');
      expect(initialState.renseikaiType, '一試合制', reason: '錬成会の初期値は一試合制のはず');
    });

    test('updateBaseOrderを呼ぶと、基本オーダーが正しく更新されるか', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final newOrder = ['先鋒の佐藤', '中堅の鈴木', '大将の田中'];
      container.read(matchRuleProvider.notifier).updateBaseOrder(newOrder);

      final updatedState = container.read(matchRuleProvider);

      expect(updatedState.baseOrder, newOrder, reason: '渡したオーダーリストで上書きされているはず');
    });
    
    test('updateRuleを呼ぶと、全体の設定が正しく上書きされるか', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // ★ 修正：MatchRuleに変更
      final newRule = MatchRule(
        matchTimeMinutes: 5,
        isRenseikai: true,
        teamName: 'テスト剣友会'
      );

      container.read(matchRuleProvider.notifier).updateRule(newRule);

      final updatedState = container.read(matchRuleProvider);
      expect(updatedState.matchTimeMinutes, 5);
      expect(updatedState.isRenseikai, true);
      expect(updatedState.teamName, 'テスト剣友会');
      expect(updatedState.isRunningTime, false, reason: '指定していないものは初期値(false)のままのはず');
    });

  });
}