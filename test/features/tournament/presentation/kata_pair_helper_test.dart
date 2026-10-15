import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/kata_pair_helper.dart';

void main() {
  group('[Unit] KataPairHelper 境界値・異常系・ペア分解結合テスト', () {
    test('isPair: 中黒を含む場合はtrue、含まない場合はfalseであること', () {
      expect(KataPairHelper.isPair('皿田 脩人・塚本 大道'), isTrue);
      expect(KataPairHelper.isPair('皿田 脩人'), isFalse);
      expect(KataPairHelper.isPair(null), isFalse);
      expect(KataPairHelper.isPair(''), isFalse);
    });

    test('extractPairNames: 空文字や不正値でも安全にフォールバックすること', () {
      expect(KataPairHelper.extractPairNames(''), ['選手', '選手']);
      expect(KataPairHelper.extractPairNames('選手'), ['選手', '選手']);
      expect(KataPairHelper.extractPairNames('選手・選手'), ['選手', '選手']);
      expect(KataPairHelper.extractPairNames('道上剣友会 : 皿田 脩人・塚本 大道'), [
        '皿田 脩人',
        '塚本 大道',
      ]);
      expect(KataPairHelper.extractPairNames('皿田 脩人・塚本 大道'), [
        '皿田 脩人',
        '塚本 大道',
      ]);
      // 単一選手のみの場合は2人目が「選手」で補完されること
      expect(KataPairHelper.extractPairNames('皿田 脩人'), ['皿田 脩人', '選手']);
    });

    test(
      'extractOpponentPairNames: shouldPreserve フラグに応じて相手ペア名が正確に抽出されること',
      () {
        const raw = '道上剣友会 : 皿田・塚本';
        // shouldPreserve = false の場合は空文字ペアが返ること
        expect(
          KataPairHelper.extractOpponentPairNames(raw, shouldPreserve: false),
          ['', ''],
        );
        // shouldPreserve = true の場合は選手名が抽出されること
        expect(
          KataPairHelper.extractOpponentPairNames(raw, shouldPreserve: true),
          ['皿田', '塚本'],
        );
        // プレースホルダー「選手」は空文字に正規化されること
        expect(
          KataPairHelper.extractOpponentPairNames(
            '道上剣友会 : 選手・選手',
            shouldPreserve: true,
          ),
          ['', ''],
        );
      },
    );

    test('buildCombinedPairName: 選手名結合と空欄補完が安全に行われること', () {
      expect(KataPairHelper.buildCombinedPairName(['皿田', '塚本']), '皿田・塚本');
      expect(KataPairHelper.buildCombinedPairName(['皿田', '']), '皿田・選手');
      expect(KataPairHelper.buildCombinedPairName(['', '']), '選手・選手');
      expect(KataPairHelper.buildCombinedPairName([]), '選手・選手');
    });

    test('parsePair: 木刀基本技の場合、元立ち・掛かり手として正しく分解できること', () {
      final members = KataPairHelper.parsePair(
        '皿田 脩人・塚本 大道',
        posName: '木刀による剣道基本技稽古法（5本）',
      );
      expect(members.length, 2);
      expect(members[0].role, '元立ち');
      expect(members[0].name, '皿田 脩人');
      expect(members[1].role, '掛かり手');
      expect(members[1].name, '塚本 大道');
    });

    test('parsePair: 日本剣道形の場合、打太刀・仕太刀として正しく分解できること', () {
      final members = KataPairHelper.parsePair('佐藤・鈴木', posName: '日本剣道形');
      expect(members.length, 2);
      expect(members[0].role, '打太刀');
      expect(members[0].name, '佐藤');
      expect(members[1].role, '仕太刀');
      expect(members[1].name, '鈴木');
    });

    test('updateMember: 指定インデックスの選手のみ更新し、他方やプレフィックスを維持すること', () {
      final updated1 = KataPairHelper.updateMember('皿田 脩人・塚本 大道', 0, '田中 太郎');
      expect(updated1, '田中 太郎・塚本 大道');

      final updated2 = KataPairHelper.updateMember('皿田 脩人・塚本 大道', 1, '山田 花子');
      expect(updated2, '皿田 脩人・山田 花子');

      final updatedPrefix = KataPairHelper.updateMember(
        '打太刀: 皿田 脩人・仕太刀: 塚本 大道',
        1,
        '山田 花子',
      );
      expect(updatedPrefix, '打太刀: 皿田 脩人・仕太刀: 山田 花子');

      // 範囲外インデックスの場合は文字列がそのまま返ること
      expect(KataPairHelper.updateMember('皿田・塚本', 99, '誰か'), '皿田・塚本');
    });

    test('generateNextMatches: 剣道形の次戦生成で正しくMatchModelが構築されること', () {
      const baseMatch = MatchModel(
        id: 'base_kata_1',
        matchType: '日本剣道形',
        category: '形の部',
        redName: '道上剣友会 : 皿田 脩人・塚本 大道',
        whiteName: '修道館 : 佐藤・高橋',
        rule: MatchRule(isKataMatch: true),
      );

      final ctrl1 = TextEditingController(text: '佐藤');
      final ctrl2 = TextEditingController(text: '鈴木');

      final matches = KataPairHelper.generateNextMatches(
        base: baseMatch,
        rule: const MatchRule(isKataMatch: true),
        isKata: true,
        isIndividual: false,
        isRenseikai: false,
        isOwnTeamRed: true,
        ownTeamName: '道上剣友会',
        oppTeam: '洗心道場',
        groupName: '道上剣友会 vs 洗心道場',
        fullNote: '第1試合場, 2試合目',
        positions: ['日本剣道形'],
        playerNames: ['皿田', '塚本'],
        opponentPlayerControllers: [ctrl1, ctrl2],
      );

      expect(matches.length, 1);
      final m = matches.first;
      expect(m.redName, '道上剣友会 : 皿田・塚本');
      expect(m.whiteName, '洗心道場 : 佐藤・鈴木');
      expect(m.rule?.isKataMatch, isTrue);
      expect(m.note, '第1試合場, 2試合目');

      ctrl1.dispose();
      ctrl2.dispose();
    });
  });
}
