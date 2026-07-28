// 部門別ルール詳細表示のテスト
//
// 修正した不具合の再発防止テスト：
//   Bug 1: positions は CategoryRuleSet に保存されないため、
//           positions.length > 1 では団体戦判定が常に false になる。
//           → matchType フィールドで判定するべき。
//   Bug 2: 錬成会（isRenseikai=true）のとき matchType が '錬成会' に
//           ならず、内容が表示されなかった。
//   Bug 3: 団体戦で代表戦設定が表示されなかった（positions.length 判定バグ）。
//
// このテストでは「どの matchType のとき、どのセクションが表示されるか」という
// 純粋なロジックを検証します。

import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

// --------------------------------------------------------------------------
// テスト対象のロジックを抽出したヘルパー
// （category_rules_screen.dart の buildRuleSection 内のフラグ計算と同一）
// --------------------------------------------------------------------------
class RuleDisplayFlags {
  final bool isTeam;
  final bool isLeague;
  final bool isKachinuki;
  final bool isRenseikai;
  final bool showDaihyoSection;
  final String formatText;

  const RuleDisplayFlags({
    required this.isTeam,
    required this.isLeague,
    required this.isKachinuki,
    required this.isRenseikai,
    required this.showDaihyoSection,
    required this.formatText,
  });
}

/// CategoryRuleSet.matchType と MatchRule から表示フラグを計算する関数
/// （category_rules_screen.dart の buildRuleSection ロジックと等価）
RuleDisplayFlags computeDisplayFlags(CategoryRuleSet ruleSet) {
  final matchType = ruleSet.matchType;
  final rule = ruleSet.normalRule;

  final isTeam =
      matchType == '団体戦' ||
      matchType == '勝ち抜き戦' ||
      matchType == 'リーグ団体戦' ||
      matchType == '錬成会';
  final isLeague = matchType == 'リーグ団体戦' || matchType == 'リーグ個人戦';
  final isKachinuki = matchType == '勝ち抜き戦';
  final isRenseikai = matchType == '錬成会';
  final hasDaihyo = !isKachinuki && !isRenseikai && rule.hasRepresentativeMatch;
  final showDaihyoSection =
      isTeam && !isKachinuki && !isRenseikai && !isLeague && hasDaihyo;

  String formatText;
  if (isRenseikai) {
    formatText = '錬成会';
  } else if (isKachinuki) {
    formatText = '勝ち抜き戦';
  } else if (matchType == 'リーグ団体戦') {
    formatText = 'リーグ戦（団体）';
  } else if (matchType == 'リーグ個人戦') {
    formatText = 'リーグ戦（個人）';
  } else if (matchType == '団体戦') {
    formatText = '団体戦';
  } else {
    formatText = '個人戦';
  }

  return RuleDisplayFlags(
    isTeam: isTeam,
    isLeague: isLeague,
    isKachinuki: isKachinuki,
    isRenseikai: isRenseikai,
    showDaihyoSection: showDaihyoSection,
    formatText: formatText,
  );
}

/// _startEditing の matchType 復元ロジック（同一実装）
/// Bug2 修正: isRenseikai を最優先でチェック
String deriveMatchTypeFromRule(MatchRule rule, String savedMatchType) {
  if (rule.isRenseikai) return '錬成会';
  if (rule.isKachinuki) return '勝ち抜き戦';
  if (rule.isLeague) {
    return rule.hasLeagueDaihyo ? 'リーグ団体戦' : 'リーグ個人戦';
  }
  if (rule.hasLeagueDaihyo) return '団体戦';
  if (savedMatchType.isNotEmpty) return savedMatchType;
  return '個人戦';
}

void main() {
  group('📋 CategoryRuleSet 表示フラグ (matchType ベース)', () {
    // ────────────────────────────────────────────────────────
    // 試合形式テキスト
    // ────────────────────────────────────────────────────────
    group('試合形式テキスト (formatText)', () {
      test('✅ 個人戦 → "個人戦"', () {
        final ruleSet = CategoryRuleSet(
          matchType: '個人戦',
          normalRule: MatchRule(),
        );
        expect(computeDisplayFlags(ruleSet).formatText, '個人戦');
      });

      test('✅ 団体戦 → "団体戦"', () {
        final ruleSet = CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(hasLeagueDaihyo: true),
        );
        expect(computeDisplayFlags(ruleSet).formatText, '団体戦');
      });

      test('✅ 勝ち抜き戦 → "勝ち抜き戦"', () {
        final ruleSet = CategoryRuleSet(
          matchType: '勝ち抜き戦',
          normalRule: MatchRule(isKachinuki: true),
        );
        expect(computeDisplayFlags(ruleSet).formatText, '勝ち抜き戦');
      });

      test('✅ リーグ団体戦 → "リーグ戦（団体）"', () {
        final ruleSet = CategoryRuleSet(
          matchType: 'リーグ団体戦',
          normalRule: MatchRule(isLeague: true, hasLeagueDaihyo: true),
        );
        expect(computeDisplayFlags(ruleSet).formatText, 'リーグ戦（団体）');
      });

      test('✅ リーグ個人戦 → "リーグ戦（個人）"', () {
        final ruleSet = CategoryRuleSet(
          matchType: 'リーグ個人戦',
          normalRule: MatchRule(isLeague: true),
        );
        expect(computeDisplayFlags(ruleSet).formatText, 'リーグ戦（個人）');
      });

      test('✅ 錬成会 → "錬成会"', () {
        final ruleSet = CategoryRuleSet(
          matchType: '錬成会',
          normalRule: MatchRule(isRenseikai: true),
        );
        expect(computeDisplayFlags(ruleSet).formatText, '錬成会');
      });
    });

    // ────────────────────────────────────────────────────────
    // セクション表示フラグ
    // ────────────────────────────────────────────────────────
    group('セクション表示フラグ', () {
      test(
        '✅ 個人戦: isTeam=false, isLeague=false, isKachinuki=false, isRenseikai=false',
        () {
          final flags = computeDisplayFlags(
            CategoryRuleSet(matchType: '個人戦', normalRule: MatchRule()),
          );
          expect(flags.isTeam, isFalse);
          expect(flags.isLeague, isFalse);
          expect(flags.isKachinuki, isFalse);
          expect(flags.isRenseikai, isFalse);
          expect(flags.showDaihyoSection, isFalse);
        },
      );

      test(
        '✅ 団体戦: isTeam=true, 代表戦セクション=true (hasRepresentativeMatch=true)',
        () {
          final flags = computeDisplayFlags(
            CategoryRuleSet(
              matchType: '団体戦',
              normalRule: MatchRule(
                hasLeagueDaihyo: true,
                hasRepresentativeMatch: true,
              ),
            ),
          );
          expect(flags.isTeam, isTrue);
          expect(flags.isLeague, isFalse);
          expect(flags.isKachinuki, isFalse);
          expect(flags.isRenseikai, isFalse);
          expect(
            flags.showDaihyoSection,
            isTrue,
            reason: '団体戦で hasRepresentativeMatch=true なら代表戦設定を表示',
          );
        },
      );

      test('✅ 団体戦: 代表戦セクション=false (hasRepresentativeMatch=false)', () {
        final flags = computeDisplayFlags(
          CategoryRuleSet(
            matchType: '団体戦',
            normalRule: MatchRule(
              hasLeagueDaihyo: true,
              hasRepresentativeMatch: false,
            ),
          ),
        );
        expect(flags.showDaihyoSection, isFalse);
      });

      test('✅ 勝ち抜き戦: isKachinuki=true, 代表戦セクション=false', () {
        final flags = computeDisplayFlags(
          CategoryRuleSet(
            matchType: '勝ち抜き戦',
            normalRule: MatchRule(
              isKachinuki: true,
              hasRepresentativeMatch: true,
            ),
          ),
        );
        expect(flags.isKachinuki, isTrue);
        expect(
          flags.showDaihyoSection,
          isFalse,
          reason: '勝ち抜き戦には代表戦設定セクションを表示しない',
        );
      });

      test('✅ リーグ団体戦: isLeague=true, isTeam=true, 代表戦セクション=false', () {
        final flags = computeDisplayFlags(
          CategoryRuleSet(
            matchType: 'リーグ団体戦',
            normalRule: MatchRule(isLeague: true, hasLeagueDaihyo: true),
          ),
        );
        expect(flags.isTeam, isTrue);
        expect(flags.isLeague, isTrue);
        expect(
          flags.showDaihyoSection,
          isFalse,
          reason: 'リーグ戦は代表戦設定セクションを使わない（リーグ戦設定内で処理）',
        );
      });

      test('✅ リーグ個人戦: isLeague=true, isTeam=false', () {
        final flags = computeDisplayFlags(
          CategoryRuleSet(
            matchType: 'リーグ個人戦',
            normalRule: MatchRule(isLeague: true),
          ),
        );
        expect(flags.isTeam, isFalse);
        expect(flags.isLeague, isTrue);
      });

      test('✅ 錬成会: isRenseikai=true, isTeam=true, 代表戦セクション=false', () {
        final flags = computeDisplayFlags(
          CategoryRuleSet(
            matchType: '錬成会',
            normalRule: MatchRule(isRenseikai: true),
          ),
        );
        expect(flags.isRenseikai, isTrue);
        expect(flags.isTeam, isTrue);
        expect(
          flags.showDaihyoSection,
          isFalse,
          reason: '錬成会には代表戦設定セクションを表示しない',
        );
      });
    });

    // ────────────────────────────────────────────────────────
    // Bug 1 リグレッション: positions.length に依存しないこと
    // ────────────────────────────────────────────────────────
    group('🐛 Bug1 リグレッション: positions.length > 1 に依存しない', () {
      test('✅ 団体戦でも positions がデフォルト["選手"] のままでも団体戦と正しく判定', () {
        final ruleSet = CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(
            hasLeagueDaihyo: true,
            hasRepresentativeMatch: true,
            // positions は意図的に設定しない（デフォルト ['選手'] = length 1）
          ),
        );
        // 実際のデータでは positions は保存されないので常に 1
        expect(ruleSet.normalRule.positions.length, 1);

        final flags = computeDisplayFlags(ruleSet);
        // positions.length > 1 に依存していると以下が失敗する
        expect(flags.formatText, '団体戦', reason: 'matchType ベースで正しく団体戦と表示されること');
        expect(flags.isTeam, isTrue);
        expect(flags.showDaihyoSection, isTrue, reason: '代表戦設定セクションが表示されること');
      });

      test('✅ 錬成会でも positions がデフォルトでも錬成会と正しく判定', () {
        final ruleSet = CategoryRuleSet(
          matchType: '錬成会',
          normalRule: MatchRule(isRenseikai: true),
        );
        expect(ruleSet.normalRule.positions.length, 1);
        final flags = computeDisplayFlags(ruleSet);
        expect(flags.formatText, '錬成会');
        expect(flags.isRenseikai, isTrue);
      });
    });

    // ────────────────────────────────────────────────────────
    // Bug 2 リグレッション: 錬成会の matchType 導出
    // ────────────────────────────────────────────────────────
    group('🐛 Bug2 リグレッション: 錬成会の matchType 導出', () {
      test('✅ isRenseikai=true のとき matchType は "錬成会" に確定', () {
        expect(
          deriveMatchTypeFromRule(MatchRule(isRenseikai: true), ''),
          '錬成会',
        );
      });

      test('✅ isRenseikai=true のとき savedMatchType の値に関わらず "錬成会"', () {
        // 古いデータで savedMatchType が '個人戦' になっていても上書き
        expect(
          deriveMatchTypeFromRule(MatchRule(isRenseikai: true), '個人戦'),
          '錬成会',
        );
      });

      test('✅ isRenseikai=false かつ savedMatchType あり → savedMatchType を使う', () {
        expect(deriveMatchTypeFromRule(MatchRule(), '個人戦'), '個人戦');
      });

      test('✅ isKachinuki=true のとき "勝ち抜き戦"', () {
        expect(
          deriveMatchTypeFromRule(MatchRule(isKachinuki: true), ''),
          '勝ち抜き戦',
        );
      });

      test('✅ isLeague=true, hasLeagueDaihyo=true のとき "リーグ団体戦"', () {
        expect(
          deriveMatchTypeFromRule(
            MatchRule(isLeague: true, hasLeagueDaihyo: true),
            '',
          ),
          'リーグ団体戦',
        );
      });

      test('✅ isLeague=true, hasLeagueDaihyo=false のとき "リーグ個人戦"', () {
        expect(
          deriveMatchTypeFromRule(
            MatchRule(isLeague: true, hasLeagueDaihyo: false),
            '',
          ),
          'リーグ個人戦',
        );
      });

      test('✅ hasLeagueDaihyo=true のとき "団体戦"', () {
        expect(
          deriveMatchTypeFromRule(MatchRule(hasLeagueDaihyo: true), ''),
          '団体戦',
        );
      });

      test('✅ 全フラグ false かつ savedMatchType 空 → "個人戦"', () {
        expect(deriveMatchTypeFromRule(MatchRule(), ''), '個人戦');
      });
    });

    // ────────────────────────────────────────────────────────
    // JSON シリアライズ
    // ────────────────────────────────────────────────────────
    group('💾 JSON シリアライズ round-trip', () {
      test('✅ 錬成会: matchType が保持される', () {
        const original = CategoryRuleSet(
          matchType: '錬成会',
          normalRule: MatchRule(isRenseikai: true),
        );
        final restored = CategoryRuleSet.fromJson(original.toJson());
        expect(restored.matchType, '錬成会');
        expect(restored.normalRule.isRenseikai, isTrue);
      });

      test('✅ 団体戦: matchType と代表戦フラグが保持される', () {
        const original = CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(
            hasLeagueDaihyo: true,
            hasRepresentativeMatch: true,
            isDaihyoIpponShobu: true,
            daihyoMatchTimeMinutes: 3.0,
            daihyoHasExtension: false,
            daihyoHasHantei: true,
          ),
        );
        final restored = CategoryRuleSet.fromJson(original.toJson());

        expect(restored.matchType, '団体戦');
        expect(restored.normalRule.hasRepresentativeMatch, isTrue);
        expect(restored.normalRule.isDaihyoIpponShobu, isTrue);
        expect(restored.normalRule.daihyoMatchTimeMinutes, 3.0);
        expect(restored.normalRule.daihyoHasHantei, isTrue);
        // 復元後の表示フラグも正しいこと
        expect(computeDisplayFlags(restored).showDaihyoSection, isTrue);
      });

      test('✅ 勝ち抜き戦: matchType と kachinukiUnlimitedType が保持される', () {
        const original = CategoryRuleSet(
          matchType: '勝ち抜き戦',
          normalRule: MatchRule(
            isKachinuki: true,
            kachinukiUnlimitedType: '無制限',
          ),
        );
        final restored = CategoryRuleSet.fromJson(original.toJson());
        expect(restored.matchType, '勝ち抜き戦');
        expect(restored.normalRule.kachinukiUnlimitedType, '無制限');
        expect(computeDisplayFlags(restored).isKachinuki, isTrue);
      });
    });

    // ────────────────────────────────────────────────────────
    // 延長戦テキスト
    // ────────────────────────────────────────────────────────
    group('🕐 延長戦テキスト', () {
      String enchoText(MatchRule rule) {
        if (rule.isEnchoUnlimited) return 'あり (時間・回数 無制限)';
        if (rule.enchoCount > 0 || rule.enchoTimeMinutes > 0) {
          final t = rule.enchoTimeMinutes;
          final mins = t == t.toInt()
              ? '${t.toInt()}分'
              : '${t.toInt()}分${((t % 1) * 60).toInt()}秒';
          return 'あり ($mins・${rule.enchoCount}回)';
        }
        return 'なし';
      }

      test('✅ 延長戦なし', () {
        expect(enchoText(MatchRule(enchoCount: 0, enchoTimeMinutes: 0)), 'なし');
      });

      test('✅ 延長戦あり (3分・1回)', () {
        expect(
          enchoText(MatchRule(enchoCount: 1, enchoTimeMinutes: 3.0)),
          'あり (3分・1回)',
        );
      });

      test('✅ 延長戦あり (1分30秒・2回)', () {
        expect(
          enchoText(MatchRule(enchoCount: 2, enchoTimeMinutes: 1.5)),
          'あり (1分30秒・2回)',
        );
      });

      test('✅ 延長戦無制限', () {
        expect(enchoText(MatchRule(isEnchoUnlimited: true)), 'あり (時間・回数 無制限)');
      });
    });
  });
}
