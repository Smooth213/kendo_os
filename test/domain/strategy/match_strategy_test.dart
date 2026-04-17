import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/domain/strategy/match_strategy.dart';

void main() {
  group('🛡️ MatchStrategy (試合ルールブック) の自動テスト', () {
    
    // ==========================================
    // 1. 個人戦のテスト
    // ==========================================
    group('🗡️ 個人戦 (IndividualMatchStrategy)', () {
      test('【延長あり/回数1回】0回目の同点は「延長戦(startExtension)」へ進むこと', () {
        const match = MatchModel(id: '1', matchType: '個人戦', redName: '赤', whiteName: '白', note: '');
        final strategy = MatchStrategyFactory.getStrategy(match);
        // ★ 修正：型を Map<String, dynamic> に明示
        final Map<String, dynamic> lastSettings = {'hasExtension': true, 'extensionCount': 1, 'hasHantei': true};
        
        final action = strategy.getNextActionOnTie(match: match, lastSettings: lastSettings);
        expect(action, NextMatchAction.startExtension);
      });

      test('【延長あり/回数1回】1回延長済みの同点は「判定(showHantei)」へ進むこと', () {
        const match = MatchModel(id: '2', matchType: '個人戦', redName: '赤', whiteName: '白', note: '延長1回目');
        final strategy = MatchStrategyFactory.getStrategy(match);
        final Map<String, dynamic> lastSettings = {'hasExtension': true, 'extensionCount': 1, 'hasHantei': true};
        
        final action = strategy.getNextActionOnTie(match: match, lastSettings: lastSettings);
        expect(action, NextMatchAction.showHantei);
      });
    });

    // ==========================================
    // 2. 団体戦のテスト
    // ==========================================
    group('🛡️ 団体戦 (TeamMatchStrategy)', () {
      test('通常のポジション（先鋒など）での同点は即「引き分け終了(finishMatch)」となること', () {
        const match = MatchModel(id: '3', matchType: '先鋒', groupName: 'G1', redName: '赤', whiteName: '白');
        final strategy = MatchStrategyFactory.getStrategy(match);
        final Map<String, dynamic> lastSettings = {'hasExtension': true}; 
        
        final action = strategy.getNextActionOnTie(match: match, lastSettings: lastSettings);
        expect(action, NextMatchAction.finishMatch);
      });

      test('代表戦での同点は決着がつくまで「延長戦(startExtension)」へ進むこと', () {
        const match = MatchModel(id: '4', matchType: '代表戦', groupName: 'G1', redName: '赤', whiteName: '白');
        final strategy = MatchStrategyFactory.getStrategy(match);
        final Map<String, dynamic> lastSettings = {}; 
        
        final action = strategy.getNextActionOnTie(match: match, lastSettings: lastSettings);
        expect(action, NextMatchAction.startExtension);
      });
    });

    // ==========================================
    // 3. 勝ち抜き戦のテスト
    // ==========================================
    group('⚔️ 勝ち抜き戦 (KachinukiStrategy)', () {
      test('大将同士ではない同点は、両者退場のため「引き分け終了(finishMatch)」となること', () {
        const match = MatchModel(id: '5', matchType: '勝ち抜き戦', isKachinuki: true, redName: '赤', whiteName: '白', redRemaining: [], whiteRemaining: ['白2']);
        final strategy = MatchStrategyFactory.getStrategy(match);
        final Map<String, dynamic> lastSettings = {'kachinukiUnlimitedType': '大将引き分け延長'};
        
        final action = strategy.getNextActionOnTie(match: match, lastSettings: lastSettings);
        expect(action, NextMatchAction.finishMatch);
      });

      test('大将同士の同点 ＆ 大将延長ルールの場合は「延長戦(startExtension)」へ進むこと', () {
        const match = MatchModel(id: '6', matchType: '勝ち抜き戦', isKachinuki: true, redName: '赤', whiteName: '白', redRemaining: [], whiteRemaining: []);
        final strategy = MatchStrategyFactory.getStrategy(match);
        final Map<String, dynamic> lastSettings = {'kachinukiUnlimitedType': '大将引き分け延長'};
        
        final action = strategy.getNextActionOnTie(match: match, lastSettings: lastSettings);
        expect(action, NextMatchAction.startExtension);
      });
    });

  });
}