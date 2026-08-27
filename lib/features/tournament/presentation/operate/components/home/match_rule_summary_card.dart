import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 適用中ルールの全内訳カード
///
/// category_rule_detail_bottom_sheet.dart と同じ表示ロジックを採用し、
/// 試合形式ごとに適切な項目のみを表示する。
class MatchRuleSummaryCard extends StatelessWidget {
  const MatchRuleSummaryCard({
    super.key,
    required this.matchType,
    this.isTeamOverride,
    required this.currentRule,
    required this.matchTime,
    required this.isIpponShobu,
    required this.hasHantei,
    required this.primaryAccent,
    required this.isDark,
    required this.textColor,
  });

  final String matchType;
  final bool? isTeamOverride;
  final MatchRule currentRule;
  final double matchTime;
  final bool isIpponShobu;
  final bool hasHantei;
  final Color primaryAccent;
  final bool isDark;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    // category_rule_detail_bottom_sheet と同じ判定ロジック
    final bool isTeam =
        isTeamOverride ??
        (matchType == '団体戦' || matchType == '勝ち抜き戦' || matchType == 'リーグ団体戦');
    final bool isLeague = matchType == 'リーグ団体戦' || matchType == 'リーグ個人戦';
    final bool isKachinuki = matchType == '勝ち抜き戦';
    final bool isRenseikaiMode =
        currentRule.isRenseikai ||
        currentRule.matchScene == 'renseikai' ||
        currentRule.matchScene == 'moushiawase';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2333) : const Color(0xFFEEF2FF),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF3B4A6B) : const Color(0xFFBFCAFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル
          Row(
            children: [
              Icon(Icons.verified, size: 16, color: primaryAccent),
              const SizedBox(width: 6),
              Text(
                '適用中のルール',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _divider(),
          const SizedBox(height: AppSpacing.xs),

          // ── 試合時間（全形式共通）────────────────────
          _row(
            icon: Icons.timer_outlined,
            label: '試合時間',
            value:
                '${matchTime == matchTime.toInt() ? matchTime.toInt() : matchTime}分'
                '${currentRule.isRunningTime ? "（ランニング）" : "（都度ストップ）"}',
          ),

          // ── 試合ルール（錬成会以外）──────────────────
          if (!isRenseikaiMode) ...[
            _divider(),
            _row(
              icon: Icons.sports_mma_outlined,
              label: '勝負方式',
              value: isIpponShobu ? '一本勝負' : '三本勝負（二本先取）',
            ),
            // 延長戦・判定は個人戦・リーグ個人戦のみ
            if (!isTeam) ...[
              _divider(),
              _row(
                icon: Icons.more_time,
                label: '延長戦',
                value: currentRule.isEnchoUnlimited
                    ? 'あり（無制限）'
                    : (currentRule.enchoTimeMinutes > 0
                          ? 'あり（${_fmt(currentRule.enchoTimeMinutes)}分）'
                          : 'なし'),
              ),
              _divider(),
              _row(
                icon: Icons.gavel_outlined,
                label: '判定',
                value: hasHantei ? 'あり' : 'なし',
              ),
            ],
          ],

          // ── 勝ち抜き戦設定 ──────────────────────────
          if (isKachinuki) ...[
            _divider(),
            _section('勝ち抜き戦設定'),
            _row(
              icon: Icons.emoji_events_outlined,
              label: '無制限条件',
              value: currentRule.kachinukiUnlimitedType.isEmpty
                  ? '大将対大将'
                  : currentRule.kachinukiUnlimitedType,
            ),
          ],

          // ── 団体戦・代表戦設定（団体戦のみ）────────────
          if (matchType == '団体戦' && !isRenseikaiMode) ...[
            _divider(),
            _section('団体戦・代表戦設定'),
            _row(
              icon: Icons.groups_outlined,
              label: '代表戦',
              value: currentRule.hasRepresentativeMatch ? 'あり' : 'なし',
            ),
            if (currentRule.hasRepresentativeMatch) ...[
              _divider(),
              _row(
                icon: Icons.sports_mma_outlined,
                label: '代表戦勝負形式',
                value: currentRule.isDaihyoIpponShobu ? '一本勝負' : '三本勝負',
              ),
              _divider(),
              _row(
                icon: Icons.timer_outlined,
                label: '代表戦時間',
                value: currentRule.daihyoMatchTimeMinutes <= 0
                    ? '時間制限なし'
                    : '${_fmt(currentRule.daihyoMatchTimeMinutes)}分',
              ),
              _divider(),
              _row(
                icon: Icons.more_time,
                label: '代表戦延長',
                value: _daihyoEnchoText(currentRule),
              ),
            ],
          ],

          // ── リーグ戦設定（リーグ個人・リーグ団体）────────
          if (isLeague) ...[
            _divider(),
            _section('リーグ戦設定'),
            _row(
              icon: Icons.leaderboard_outlined,
              label: '勝点配分',
              value:
                  '勝: ${_fmt(currentRule.winPoint)}点 /'
                  ' 分: ${_fmt(currentRule.drawPoint)}点 /'
                  ' 負: ${_fmt(currentRule.lossPoint)}点',
            ),
            if (matchType == 'リーグ団体戦') ...[
              _divider(),
              _row(
                icon: Icons.groups_outlined,
                label: '同点時代表戦',
                value: currentRule.hasLeagueDaihyo ? 'あり' : 'なし',
              ),
              if (currentRule.hasLeagueDaihyo) ...[
                _divider(),
                _row(
                  icon: Icons.timer_outlined,
                  label: '代表戦時間',
                  value: currentRule.daihyoMatchTimeMinutes <= 0
                      ? '時間制限なし'
                      : '${_fmt(currentRule.daihyoMatchTimeMinutes)}分',
                ),
                _divider(),
                _row(
                  icon: Icons.more_time,
                  label: '代表戦延長',
                  value: _daihyoEnchoText(currentRule),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  // ヘルパー: 代表戦延長テキスト
  String _daihyoEnchoText(MatchRule rule) {
    if (!rule.daihyoHasExtension) return 'なし';
    if (rule.daihyoEnchoCount == -2 || rule.daihyoEnchoCount == 0) {
      return 'あり（無制限）';
    }
    return 'あり（${_fmt(rule.daihyoEnchoTimeMinutes)}分）';
  }

  // ヘルパー: double を整数/小数で表示
  String _fmt(double v) => v == v.toInt() ? v.toInt().toString() : v.toString();

  // ヘルパー: ラベル・値の行
  Widget _row({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 15, color: textColor.withValues(alpha: 0.6)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.semiBold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ヘルパー: セクション見出し
  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.badge,
          fontWeight: AppFontWeight.bold,
          color: primaryAccent,
        ),
      ),
    );
  }

  // ヘルパー: 区切り線
  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: isDark ? const Color(0xFF3B4A6B) : const Color(0xFFBFCAFF),
    );
  }
}
