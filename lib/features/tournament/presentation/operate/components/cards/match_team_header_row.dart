import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合カード上部に左右チーム名を独立表示する純粋UIコンポーネント
class MatchTeamHeaderRow extends StatelessWidget {
  final String redTeam;
  final String whiteTeam;
  final Color textColor;
  final bool isRedOwn;
  final bool isWhiteOwn;

  const MatchTeamHeaderRow({
    super.key,
    required this.redTeam,
    required this.whiteTeam,
    required this.textColor,
    this.isRedOwn = false,
    this.isWhiteOwn = false,
  });

  @override
  Widget build(BuildContext context) {
    final String rDisplay = redTeam.isNotEmpty ? redTeam : '（個人エントリー）';
    final String wDisplay = whiteTeam.isNotEmpty ? whiteTeam : '（個人エントリー）';

    return Row(
      children: [
        // 赤側チーム名
        Expanded(
          child: Text(
            rDisplay,
            style: TextStyle(
              fontSize: AppFontSize.badge,
              color: isRedOwn ? const Color(0xFFD97706) : textColor,
              fontWeight: isRedOwn ? AppFontWeight.bold : AppFontWeight.medium,
            ),
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
        // 白側チーム名
        Expanded(
          child: Text(
            wDisplay,
            style: TextStyle(
              fontSize: AppFontSize.badge,
              color: isWhiteOwn ? const Color(0xFFD97706) : textColor,
              fontWeight: isWhiteOwn
                  ? AppFontWeight.bold
                  : AppFontWeight.medium,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
