import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_rule_summary_card.dart';

// ── テスト共通ヘルパー ─────────────────────────────────────────

/// MatchRuleSummaryCard をレンダリングするラッパー
Widget _buildCard({
  required String matchType,
  MatchRule rule = const MatchRule(),
  double matchTime = 2.0,
  bool isIpponShobu = false,
  bool hasHantei = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: MatchRuleSummaryCard(
          matchType: matchType,
          currentRule: rule,
          matchTime: matchTime,
          isIpponShobu: isIpponShobu,
          hasHantei: hasHantei,
          primaryAccent: const Color(0xFF6366F1),
          isDark: false,
          textColor: const Color(0xFF1E293B),
        ),
      ),
    ),
  );
}

/// テキストが画面に存在することを確認
void _expectText(String text) =>
    expect(find.textContaining(text), findsWidgets);

/// テキストが画面に存在しないことを確認
void _expectNoText(String text) =>
    expect(find.textContaining(text), findsNothing);

// ─────────────────────────────────────────────────────────────

void main() {
  group('[Widget] MatchRuleSummaryCard 全形式表示テスト', () {
    // ================================================================
    // 個人戦
    // ================================================================
    group('個人戦', () {
      testWidgets('試合時間・勝負方式が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(matchType: '個人戦', matchTime: 2.0, isIpponShobu: false),
        );
        _expectText('試合時間');
        _expectText('2分');
        _expectText('勝負方式');
        _expectText('三本勝負');
      });

      testWidgets('延長戦・判定が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '個人戦',
            rule: const MatchRule(isEnchoUnlimited: true, hasHantei: true),
            hasHantei: true,
          ),
        );
        _expectText('延長戦');
        _expectText('判定');
        _expectText('あり');
      });

      testWidgets('延長なし・判定なしが正しく表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '個人戦',
            rule: const MatchRule(enchoTimeMinutes: 0),
            hasHantei: false,
          ),
        );
        _expectText('延長戦');
        _expectText('判定');
        _expectText('なし');
      });

      testWidgets('団体戦・代表戦設定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: '個人戦'));
        _expectNoText('団体戦・代表戦設定');
        _expectNoText('代表戦');
      });

      testWidgets('リーグ設定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: '個人戦'));
        _expectNoText('リーグ戦設定');
        _expectNoText('勝点配分');
      });

      testWidgets('勝ち抜き設定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: '個人戦'));
        _expectNoText('勝ち抜き戦設定');
        _expectNoText('無制限条件');
      });
    });

    // ================================================================
    // 団体戦
    // ================================================================
    group('団体戦', () {
      testWidgets('試合時間・勝負方式が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(matchType: '団体戦', matchTime: 3.0, isIpponShobu: true),
        );
        _expectText('試合時間');
        _expectText('3分');
        _expectText('勝負方式');
        _expectText('一本勝負');
      });

      testWidgets('延長戦・判定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: '団体戦'));
        _expectNoText('延長戦');
        _expectNoText('判定');
      });

      testWidgets('【代表戦あり】団体戦・代表戦設定が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '団体戦',
            rule: const MatchRule(
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
            ),
          ),
        );
        _expectText('団体戦・代表戦設定');
        _expectText('代表戦');
        _expectText('あり');
        _expectText('代表戦勝負形式');
        _expectText('代表戦時間');
        _expectText('時間制限なし');
        _expectText('代表戦延長');
        _expectText('あり（無制限）');
      });

      testWidgets('代表戦なしの場合、代表戦詳細は表示されないこと', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '団体戦',
            rule: const MatchRule(hasRepresentativeMatch: false),
          ),
        );
        _expectText('代表戦');
        _expectText('なし');
        _expectNoText('代表戦勝負形式');
        _expectNoText('代表戦時間');
        _expectNoText('代表戦延長');
      });

      testWidgets('リーグ設定・勝ち抜き設定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: '団体戦'));
        _expectNoText('リーグ戦設定');
        _expectNoText('勝ち抜き戦設定');
      });
    });

    // ================================================================
    // リーグ個人戦
    // ================================================================
    group('リーグ個人戦', () {
      testWidgets('試合時間・勝負方式が表示されること', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: 'リーグ個人戦'));
        _expectText('試合時間');
        _expectText('勝負方式');
      });

      testWidgets('延長戦・判定が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: 'リーグ個人戦',
            rule: const MatchRule(isEnchoUnlimited: false, enchoTimeMinutes: 0),
            hasHantei: false,
          ),
        );
        _expectText('延長戦');
        _expectText('判定');
      });

      testWidgets('リーグ戦設定（勝点配分）が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: 'リーグ個人戦',
            rule: const MatchRule(winPoint: 3, drawPoint: 1, lossPoint: 0),
          ),
        );
        _expectText('リーグ戦設定');
        _expectText('勝点配分');
        _expectText('勝: 3点');
        _expectText('分: 1点');
        _expectText('負: 0点');
      });

      testWidgets('団体戦・代表戦設定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: 'リーグ個人戦'));
        _expectNoText('団体戦・代表戦設定');
        _expectNoText('同点時代表戦');
      });

      testWidgets('勝ち抜き設定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: 'リーグ個人戦'));
        _expectNoText('勝ち抜き戦設定');
      });
    });

    // ================================================================
    // リーグ団体戦
    // ================================================================
    group('リーグ団体戦', () {
      testWidgets('試合時間・勝負方式が表示されること', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: 'リーグ団体戦'));
        _expectText('試合時間');
        _expectText('勝負方式');
      });

      testWidgets('延長戦・判定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: 'リーグ団体戦'));
        _expectNoText('延長戦');
        _expectNoText('判定');
      });

      testWidgets('リーグ戦設定（勝点配分・同点時代表戦）が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: 'リーグ団体戦',
            rule: const MatchRule(
              winPoint: 2,
              drawPoint: 1,
              lossPoint: 0,
              hasLeagueDaihyo: true,
              daihyoMatchTimeMinutes: 2,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
            ),
          ),
        );
        _expectText('リーグ戦設定');
        _expectText('勝点配分');
        _expectText('同点時代表戦');
        _expectText('あり');
        _expectText('代表戦時間');
        _expectText('代表戦延長');
        _expectText('あり（無制限）');
      });

      testWidgets('同点時代表戦なしの場合、代表戦詳細は表示されないこと', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: 'リーグ団体戦',
            rule: const MatchRule(hasLeagueDaihyo: false),
          ),
        );
        _expectText('同点時代表戦');
        _expectText('なし');
        _expectNoText('代表戦時間');
        _expectNoText('代表戦延長');
      });

      testWidgets('団体戦・代表戦設定セクション（通常）は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: 'リーグ団体戦'));
        _expectNoText('団体戦・代表戦設定');
        _expectNoText('勝ち抜き戦設定');
      });
    });

    // ================================================================
    // 勝ち抜き戦
    // ================================================================
    group('勝ち抜き戦', () {
      testWidgets('試合時間・勝負方式が表示されること', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: '勝ち抜き戦'));
        _expectText('試合時間');
        _expectText('勝負方式');
      });

      testWidgets('延長戦・判定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: '勝ち抜き戦'));
        _expectNoText('延長戦');
        _expectNoText('判定');
      });

      testWidgets('勝ち抜き戦設定（無制限条件）が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '勝ち抜き戦',
            rule: const MatchRule(kachinukiUnlimitedType: '大将対大将'),
          ),
        );
        _expectText('勝ち抜き戦設定');
        _expectText('無制限条件');
        _expectText('大将対大将');
      });

      testWidgets('無制限条件が空の場合はデフォルト値「大将対大将」が表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '勝ち抜き戦',
            rule: const MatchRule(kachinukiUnlimitedType: ''),
          ),
        );
        _expectText('大将対大将');
      });

      testWidgets('団体戦・代表戦設定・リーグ設定は表示されないこと', (tester) async {
        await tester.pumpWidget(_buildCard(matchType: '勝ち抜き戦'));
        _expectNoText('団体戦・代表戦設定');
        _expectNoText('リーグ戦設定');
      });
    });

    // ================================================================
    // 共通仕様：値のフォーマット
    // ================================================================
    group('値のフォーマット', () {
      testWidgets('ランニングタイムが正しく表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '個人戦',
            rule: const MatchRule(isRunningTime: true),
            matchTime: 2.0,
          ),
        );
        _expectText('ランニング');
      });

      testWidgets('都度ストップが正しく表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '個人戦',
            rule: const MatchRule(isRunningTime: false),
            matchTime: 2.0,
          ),
        );
        _expectText('都度ストップ');
      });

      testWidgets('延長戦「あり（◯分）」が正しく表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '個人戦',
            rule: const MatchRule(
              isEnchoUnlimited: false,
              enchoTimeMinutes: 1.5,
            ),
          ),
        );
        _expectText('あり（1.5分）');
      });

      testWidgets('代表戦時間「◯分」が正しく表示されること', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            matchType: '団体戦',
            rule: const MatchRule(
              hasRepresentativeMatch: true,
              daihyoMatchTimeMinutes: 2.0,
              daihyoHasExtension: false,
            ),
          ),
        );
        _expectText('2分');
      });
    });
  });
}
