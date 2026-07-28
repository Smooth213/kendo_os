// 試合作成画面「現在適用中のルール」表示のテスト
//
// setup_match_format_screen.dart の _buildPage2RuleSummaryAndDetails に対応する
// 純粋なロジックのユニットテスト。
//
// テスト対象の不具合：
//   - 勝負方式（一本/三本）・反則数が表示されていなかった
//   - 錬成会の1対戦時間が表示されていなかった
//   - 団体戦の代表戦詳細（時間・延長・判定）が表示されていなかった
//   - 勝ち抜き戦の大将VS大将 / 大将VS他ポジション説明が不正確だった
//   - リーグ戦の代表戦詳細が表示されていなかった
//
// _applyMatchRuleToState に相当するロジックを純粋関数として再現し、
// MatchRule からどのような表示状態になるかを検証します。

import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

// --------------------------------------------------------------------------
// テスト対象のロジックを抽出したヘルパー
// （setup_match_format_screen.dart の状態変数・表示フラグと同一）
// --------------------------------------------------------------------------

/// _applyMatchRuleToState + _buildPage2RuleSummaryAndDetails の
/// 表示状態を表す値オブジェクト
class SetupRuleDisplayState {
  // 試合ルール基本
  final String matchType;
  final double matchTime;
  final bool isRunningTime;
  final bool isIpponShobu;
  final int ipponLimit;
  final int hansokuLimit;
  final bool hasExtension;
  final double extTime;
  final int extCount;
  final bool hasHantei;
  // 錬成会
  final bool isRenseikai;
  final String renseikaiType;
  final int overallTimeMinutes;
  // 勝ち抜き
  final String kachinukiUnlimitedType;
  // 団体・代表戦
  final bool hasLeagueDaihyo;
  final bool isDaihyoIpponShobu;
  final double daihyoMatchTime;
  final bool daihyoHasExtension;
  final double daihyoEnchoTime;
  final int daihyoEnchoCount;
  final bool daihyoHasHantei;
  // リーグ
  final double winPoint;
  final double lossPoint;
  final double drawPoint;

  const SetupRuleDisplayState({
    required this.matchType,
    required this.matchTime,
    required this.isRunningTime,
    required this.isIpponShobu,
    required this.ipponLimit,
    required this.hansokuLimit,
    required this.hasExtension,
    required this.extTime,
    required this.extCount,
    required this.hasHantei,
    required this.isRenseikai,
    required this.renseikaiType,
    required this.overallTimeMinutes,
    required this.kachinukiUnlimitedType,
    required this.hasLeagueDaihyo,
    required this.isDaihyoIpponShobu,
    required this.daihyoMatchTime,
    required this.daihyoHasExtension,
    required this.daihyoEnchoTime,
    required this.daihyoEnchoCount,
    required this.daihyoHasHantei,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
  });
}

/// _applyMatchRuleToState の等価関数
/// MatchRule + matchType から SetupRuleDisplayState を生成する
SetupRuleDisplayState applyRuleToState(MatchRule rule, String matchType) {
  final hasExtension = rule.enchoCount > 0 || rule.isEnchoUnlimited;
  final extCount = rule.isEnchoUnlimited ? -2 : rule.enchoCount;

  return SetupRuleDisplayState(
    matchType: matchType,
    matchTime: rule.matchTimeMinutes,
    isRunningTime: rule.isRunningTime,
    isIpponShobu: rule.isIpponShobu,
    ipponLimit: rule.ipponLimit,
    hansokuLimit: rule.hansokuLimit,
    hasExtension: hasExtension,
    extTime: rule.enchoTimeMinutes,
    extCount: extCount,
    hasHantei: rule.hasHantei,
    isRenseikai: rule.isRenseikai,
    renseikaiType: rule.renseikaiType,
    overallTimeMinutes: rule.overallTimeMinutes,
    kachinukiUnlimitedType: rule.kachinukiUnlimitedType,
    hasLeagueDaihyo: rule.hasLeagueDaihyo,
    isDaihyoIpponShobu: rule.isDaihyoIpponShobu,
    daihyoMatchTime: rule.daihyoMatchTimeMinutes,
    daihyoHasExtension: rule.daihyoHasExtension,
    daihyoEnchoTime: rule.daihyoEnchoTimeMinutes,
    daihyoEnchoCount: rule.daihyoEnchoCount,
    daihyoHasHantei: rule.daihyoHasHantei,
    winPoint: rule.winPoint,
    lossPoint: rule.lossPoint,
    drawPoint: rule.drawPoint,
  );
}

/// _buildPage2RuleSummaryAndDetails 表示セクション可視性
class SetupSectionVisibility {
  /// 錬成会設定セクションを表示するか
  final bool showRenseikaiSection;

  /// 試合ルールセクションを表示するか（錬成会以外）
  final bool showMatchRuleSection;

  /// 勝ち抜き戦設定セクションを表示するか
  final bool showKachinukiSection;

  /// 団体戦・チーム設定セクションを表示するか
  final bool showTeamSection;

  /// 代表戦設定セクションを表示するか（通常団体戦）
  final bool showDaihyoSection;

  /// リーグ戦設定セクションを表示するか
  final bool showLeagueSection;

  /// リーグ同点代表戦の詳細を表示するか
  final bool showLeagueDaihyoDetail;

  const SetupSectionVisibility({
    required this.showRenseikaiSection,
    required this.showMatchRuleSection,
    required this.showKachinukiSection,
    required this.showTeamSection,
    required this.showDaihyoSection,
    required this.showLeagueSection,
    required this.showLeagueDaihyoDetail,
  });
}

/// _buildPage2RuleSummaryAndDetails の表示セクション可視性を計算
SetupSectionVisibility computeSectionVisibility(SetupRuleDisplayState s) {
  final isLeague = s.matchType.contains('リーグ');
  return SetupSectionVisibility(
    showRenseikaiSection: s.isRenseikai,
    showMatchRuleSection: !s.isRenseikai,
    showKachinukiSection: s.matchType == '勝ち抜き戦',
    showTeamSection: s.matchType == '団体戦',
    showDaihyoSection: s.matchType == '団体戦' && s.hasLeagueDaihyo,
    showLeagueSection: isLeague,
    showLeagueDaihyoDetail: s.matchType == 'リーグ団体戦' && s.hasLeagueDaihyo,
  );
}

// --------------------------------------------------------------------------
// Tests
// --------------------------------------------------------------------------
void main() {
  group('🎯 SetupMatchFormat 現在適用中のルール 表示ロジック', () {
    // ─────────────────────────────────────────────────────────
    // _applyMatchRuleToState 相当: MatchRule → 状態変数への変換
    // ─────────────────────────────────────────────────────────
    group('📥 MatchRule → 状態変数変換 (_applyMatchRuleToState)', () {
      test('✅ 試合時間・計測方式が正しくロードされる', () {
        final rule = MatchRule(matchTimeMinutes: 4.0, isRunningTime: true);
        final s = applyRuleToState(rule, '個人戦');
        expect(s.matchTime, 4.0);
        expect(s.isRunningTime, isTrue);
      });

      test('✅ 勝負方式: 一本勝負', () {
        final rule = MatchRule(isIpponShobu: true, ipponLimit: 1);
        final s = applyRuleToState(rule, '個人戦');
        expect(s.isIpponShobu, isTrue);
        expect(s.ipponLimit, 1);
      });

      test('✅ 勝負方式: 三本勝負 (2本先取)', () {
        final rule = MatchRule(isIpponShobu: false, ipponLimit: 2);
        final s = applyRuleToState(rule, '個人戦');
        expect(s.isIpponShobu, isFalse);
        expect(s.ipponLimit, 2);
      });

      test('✅ 反則数が正しくロードされる', () {
        final rule = MatchRule(hansokuLimit: 3);
        final s = applyRuleToState(rule, '個人戦');
        expect(s.hansokuLimit, 3);
      });

      test('✅ 延長戦あり (3分・2回)', () {
        final rule = MatchRule(enchoCount: 2, enchoTimeMinutes: 3.0);
        final s = applyRuleToState(rule, '個人戦');
        expect(s.hasExtension, isTrue);
        expect(s.extCount, 2);
        expect(s.extTime, 3.0);
      });

      test('✅ 延長戦なし (enchoCount=0)', () {
        final rule = MatchRule(enchoCount: 0, enchoTimeMinutes: 0);
        final s = applyRuleToState(rule, '個人戦');
        expect(s.hasExtension, isFalse);
      });

      test('✅ 延長戦無制限: extCount=-2 にマップされる', () {
        final rule = MatchRule(isEnchoUnlimited: true);
        final s = applyRuleToState(rule, '個人戦');
        expect(s.hasExtension, isTrue);
        expect(s.extCount, -2);
      });

      test('✅ 判定フラグ', () {
        final rule = MatchRule(hasHantei: true);
        final s = applyRuleToState(rule, '個人戦');
        expect(s.hasHantei, isTrue);
      });

      test('✅ 錬成会フラグ・進行方式・全体時間', () {
        final rule = MatchRule(
          isRenseikai: true,
          renseikaiType: '時間制',
          overallTimeMinutes: 45,
        );
        final s = applyRuleToState(rule, '錬成会');
        expect(s.isRenseikai, isTrue);
        expect(s.renseikaiType, '時間制');
        expect(s.overallTimeMinutes, 45);
      });

      test('✅ 代表戦詳細: 時間・延長・判定が正しくロードされる', () {
        final rule = MatchRule(
          hasLeagueDaihyo: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 3.0,
          daihyoHasExtension: true,
          daihyoEnchoTimeMinutes: 2.0,
          daihyoEnchoCount: 1,
          daihyoHasHantei: true,
        );
        final s = applyRuleToState(rule, '団体戦');
        expect(s.hasLeagueDaihyo, isTrue);
        expect(s.isDaihyoIpponShobu, isTrue);
        expect(s.daihyoMatchTime, 3.0);
        expect(s.daihyoHasExtension, isTrue);
        expect(s.daihyoEnchoTime, 2.0);
        expect(s.daihyoEnchoCount, 1);
        expect(s.daihyoHasHantei, isTrue);
      });

      test('✅ 代表戦なし: hasLeagueDaihyo=false', () {
        final rule = MatchRule(hasLeagueDaihyo: false);
        final s = applyRuleToState(rule, '団体戦');
        expect(s.hasLeagueDaihyo, isFalse);
      });

      test('✅ リーグ勝ち点', () {
        final rule = MatchRule(winPoint: 2.0, lossPoint: 0.0, drawPoint: 1.0);
        final s = applyRuleToState(rule, 'リーグ個人戦');
        expect(s.winPoint, 2.0);
        expect(s.lossPoint, 0.0);
        expect(s.drawPoint, 1.0);
      });

      test('✅ 勝ち抜き戦: kachinukiUnlimitedType が正しくロードされる', () {
        final rule = MatchRule(
          isKachinuki: true,
          kachinukiUnlimitedType: '無制限',
        );
        final s = applyRuleToState(rule, '勝ち抜き戦');
        expect(s.kachinukiUnlimitedType, '無制限');
      });
    });

    // ─────────────────────────────────────────────────────────
    // セクション表示可視性
    // ─────────────────────────────────────────────────────────
    group('👁️ セクション表示可視性', () {
      test('✅ 個人戦: 試合ルールのみ表示', () {
        final s = applyRuleToState(MatchRule(), '個人戦');
        final v = computeSectionVisibility(s);
        expect(v.showMatchRuleSection, isTrue);
        expect(v.showRenseikaiSection, isFalse);
        expect(v.showKachinukiSection, isFalse);
        expect(v.showTeamSection, isFalse);
        expect(v.showDaihyoSection, isFalse);
        expect(v.showLeagueSection, isFalse);
      });

      test('✅ 団体戦 + 代表戦なし: 試合ルール + 団体戦設定のみ', () {
        final rule = MatchRule(
          hasLeagueDaihyo: false,
          hasRepresentativeMatch: false,
        );
        final s = applyRuleToState(rule, '団体戦');
        final v = computeSectionVisibility(s);
        expect(v.showMatchRuleSection, isTrue);
        expect(v.showTeamSection, isTrue);
        expect(v.showDaihyoSection, isFalse, reason: '代表戦なしなら代表戦設定セクションは非表示');
        expect(v.showLeagueSection, isFalse);
      });

      test('✅ 団体戦 + 代表戦あり: 試合ルール + 団体戦設定 + 代表戦設定', () {
        final rule = MatchRule(
          hasLeagueDaihyo: true,
          hasRepresentativeMatch: true,
        );
        final s = applyRuleToState(rule, '団体戦');
        final v = computeSectionVisibility(s);
        expect(v.showMatchRuleSection, isTrue);
        expect(v.showTeamSection, isTrue);
        expect(v.showDaihyoSection, isTrue, reason: '代表戦ありなら代表戦設定セクションを表示');
        expect(v.showLeagueSection, isFalse);
      });

      test('✅ 勝ち抜き戦: 試合ルール + 勝ち抜き戦設定', () {
        final rule = MatchRule(isKachinuki: true);
        final s = applyRuleToState(rule, '勝ち抜き戦');
        final v = computeSectionVisibility(s);
        expect(v.showMatchRuleSection, isTrue);
        expect(v.showKachinukiSection, isTrue);
        expect(v.showTeamSection, isFalse);
        expect(v.showDaihyoSection, isFalse);
      });

      test('✅ リーグ個人戦: 試合ルール + リーグ戦設定', () {
        final rule = MatchRule(isLeague: true);
        final s = applyRuleToState(rule, 'リーグ個人戦');
        final v = computeSectionVisibility(s);
        expect(v.showMatchRuleSection, isTrue);
        expect(v.showLeagueSection, isTrue);
        expect(v.showLeagueDaihyoDetail, isFalse, reason: 'リーグ個人戦には代表戦詳細なし');
        expect(v.showTeamSection, isFalse);
        expect(v.showDaihyoSection, isFalse);
      });

      test('✅ リーグ団体戦 + 同点代表戦なし: リーグ設定のみ、代表戦詳細なし', () {
        final rule = MatchRule(isLeague: true, hasLeagueDaihyo: false);
        final s = applyRuleToState(rule, 'リーグ団体戦');
        final v = computeSectionVisibility(s);
        expect(v.showLeagueSection, isTrue);
        expect(v.showLeagueDaihyoDetail, isFalse);
      });

      test('✅ リーグ団体戦 + 同点代表戦あり: 代表戦詳細を表示', () {
        final rule = MatchRule(isLeague: true, hasLeagueDaihyo: true);
        final s = applyRuleToState(rule, 'リーグ団体戦');
        final v = computeSectionVisibility(s);
        expect(v.showLeagueSection, isTrue);
        expect(
          v.showLeagueDaihyoDetail,
          isTrue,
          reason: 'リーグ団体戦 + 代表戦ありなら代表戦詳細を表示',
        );
      });

      test('✅ 錬成会: 錬成会設定のみ、試合ルールは非表示', () {
        final rule = MatchRule(isRenseikai: true);
        final s = applyRuleToState(rule, '錬成会');
        final v = computeSectionVisibility(s);
        expect(v.showRenseikaiSection, isTrue);
        expect(v.showMatchRuleSection, isFalse, reason: '錬成会は試合ルールセクションを表示しない');
        expect(v.showTeamSection, isFalse);
        expect(v.showDaihyoSection, isFalse);
      });
    });

    // ─────────────────────────────────────────────────────────
    // 勝ち抜き戦の大将VS挙動テキスト
    // ─────────────────────────────────────────────────────────
    group('⚔️ 勝ち抜き戦の大将VS挙動テキスト', () {
      String daishoDaishoBehavior(String kachinukiType) {
        if (kachinukiType == 'なし' || kachinukiType.isEmpty) return '引き分け';
        return '延長戦を行う';
      }

      String daishoVsOtherBehavior(String kachinukiType) {
        return kachinukiType == '無制限' ? '延長戦を行う' : '引き分け';
      }

      test('✅ 大将対大将: 大将VS大将=延長戦、大将VS他=引き分け', () {
        expect(daishoDaishoBehavior('大将対大将'), '延長戦を行う');
        expect(daishoVsOtherBehavior('大将対大将'), '引き分け');
      });

      test('✅ 無制限: 大将VS大将=延長戦、大将VS他=延長戦', () {
        expect(daishoDaishoBehavior('無制限'), '延長戦を行う');
        expect(daishoVsOtherBehavior('無制限'), '延長戦を行う');
      });

      test('✅ なし: 大将VS大将=引き分け、大将VS他=引き分け', () {
        expect(daishoDaishoBehavior('なし'), '引き分け');
        expect(daishoVsOtherBehavior('なし'), '引き分け');
      });

      test('✅ 空文字: 大将VS大将=引き分け', () {
        expect(daishoDaishoBehavior(''), '引き分け');
      });
    });

    // ─────────────────────────────────────────────────────────
    // 代表戦延長テキスト
    // ─────────────────────────────────────────────────────────
    group('🏆 代表戦延長テキスト', () {
      String daihyoEnchoText(bool hasExt, int count) {
        if (!hasExt) return 'なし';
        if (count == -2) return 'あり (無制限)';
        return 'あり (〇分・$count回)';
      }

      test('✅ 代表戦延長なし', () {
        expect(daihyoEnchoText(false, 0), 'なし');
      });

      test('✅ 代表戦延長あり (無制限)', () {
        expect(daihyoEnchoText(true, -2), 'あり (無制限)');
      });

      test('✅ 代表戦延長あり (2回)', () {
        expect(daihyoEnchoText(true, 2), 'あり (〇分・2回)');
      });
    });

    // ─────────────────────────────────────────────────────────
    // 代表戦時間テキスト
    // ─────────────────────────────────────────────────────────
    group('⏱️ 代表戦時間テキスト', () {
      String daihyoTimeText(double minutes) {
        if (minutes <= 0) return '無制限';
        final m = minutes.toInt();
        final s = ((minutes % 1) * 60).toInt();
        return s == 0 ? '$m分' : '$m分$s秒';
      }

      test('✅ 0分 → "無制限"', () {
        expect(daihyoTimeText(0.0), '無制限');
      });

      test('✅ 3分 → "3分"', () {
        expect(daihyoTimeText(3.0), '3分');
      });

      test('✅ 2分30秒 → "2分30秒"', () {
        expect(daihyoTimeText(2.5), '2分30秒');
      });
    });

    // ─────────────────────────────────────────────────────────
    // 代表戦 一本/三本勝負テキスト
    // ─────────────────────────────────────────────────────────
    group('🥋 代表戦勝負方式テキスト', () {
      String daihyoRuleText(bool isIpponShobu) =>
          isIpponShobu ? '一本勝負' : '三本勝負';

      test('✅ 一本勝負', () {
        expect(daihyoRuleText(true), '一本勝負');
      });

      test('✅ 三本勝負', () {
        expect(daihyoRuleText(false), '三本勝負');
      });
    });

    // ─────────────────────────────────────────────────────────
    // 錬成会の1対戦時間表示
    // ─────────────────────────────────────────────────────────
    group('🔄 錬成会の1対戦時間', () {
      test('✅ 錬成会のとき matchTime が1対戦の時間として使われる', () {
        final rule = MatchRule(
          isRenseikai: true,
          matchTimeMinutes: 2.0,
          renseikaiType: '一試合制',
        );
        final s = applyRuleToState(rule, '錬成会');
        // 錬成会設定セクションで matchTime を「1対戦の時間」として表示
        expect(s.matchTime, 2.0);
        expect(s.isRenseikai, isTrue);
        expect(s.renseikaiType, '一試合制');
      });

      test('✅ 錬成会 時間制のとき overallTimeMinutes が別途表示される', () {
        final rule = MatchRule(
          isRenseikai: true,
          matchTimeMinutes: 3.0,
          renseikaiType: '時間制',
          overallTimeMinutes: 60,
        );
        final s = applyRuleToState(rule, '錬成会');
        expect(s.matchTime, 3.0);
        expect(s.renseikaiType, '時間制');
        expect(s.overallTimeMinutes, 60);
      });
    });

    // ─────────────────────────────────────────────────────────
    // MatchRule からの完全な状態変換 (総合テスト)
    // ─────────────────────────────────────────────────────────
    group('🧩 完全な状態変換 (総合)', () {
      test('✅ 団体戦フル: 全ての代表戦詳細が正しく変換される', () {
        final rule = MatchRule(
          matchTimeMinutes: 4.0,
          isRunningTime: false,
          isIpponShobu: false,
          ipponLimit: 2,
          hansokuLimit: 2,
          enchoCount: 1,
          enchoTimeMinutes: 3.0,
          hasHantei: true,
          hasLeagueDaihyo: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 3.0,
          daihyoHasExtension: true,
          daihyoEnchoTimeMinutes: 2.0,
          daihyoEnchoCount: -2,
          daihyoHasHantei: false,
        );
        final s = applyRuleToState(rule, '団体戦');
        final v = computeSectionVisibility(s);

        // 試合ルール
        expect(s.matchTime, 4.0);
        expect(s.isIpponShobu, isFalse);
        expect(s.ipponLimit, 2);
        expect(s.hansokuLimit, 2);
        expect(s.hasExtension, isTrue);
        expect(s.extCount, 1);
        expect(s.hasHantei, isTrue);

        // 代表戦
        expect(s.hasLeagueDaihyo, isTrue);
        expect(s.isDaihyoIpponShobu, isTrue);
        expect(s.daihyoMatchTime, 3.0);
        expect(s.daihyoHasExtension, isTrue);
        expect(s.daihyoEnchoCount, -2);
        expect(s.daihyoHasHantei, isFalse);

        // 表示
        expect(v.showMatchRuleSection, isTrue);
        expect(v.showTeamSection, isTrue);
        expect(v.showDaihyoSection, isTrue);
        expect(v.showLeagueSection, isFalse);
      });

      test('✅ リーグ団体戦フル: 同点代表戦詳細も正しく変換される', () {
        final rule = MatchRule(
          isLeague: true,
          hasLeagueDaihyo: true,
          winPoint: 2.0,
          lossPoint: 0.0,
          drawPoint: 1.0,
          daihyoMatchTimeMinutes: 3.0,
          daihyoHasExtension: false,
          daihyoHasHantei: true,
        );
        final s = applyRuleToState(rule, 'リーグ団体戦');
        final v = computeSectionVisibility(s);

        expect(s.winPoint, 2.0);
        expect(s.drawPoint, 1.0);
        expect(s.hasLeagueDaihyo, isTrue);
        expect(s.daihyoMatchTime, 3.0);
        expect(s.daihyoHasExtension, isFalse);
        expect(s.daihyoHasHantei, isTrue);

        expect(v.showLeagueSection, isTrue);
        expect(v.showLeagueDaihyoDetail, isTrue);
        expect(v.showTeamSection, isFalse);
        expect(v.showDaihyoSection, isFalse);
      });
    });
  });
}
