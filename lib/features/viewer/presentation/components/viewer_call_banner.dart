import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 観客席画面用 進行中・次試合コールバナー
class ViewerCallBanner extends StatelessWidget {
  final List<MatchModel> inProgressMatches;
  final List<MatchModel> waitingMatches;

  const ViewerCallBanner({
    super.key,
    required this.inProgressMatches,
    required this.waitingMatches,
  });

  static String _reverseWhiteName(String whiteName) {
    if (!whiteName.contains(':')) return whiteName;
    final parts = whiteName.split(':');
    if (parts.length != 2) return whiteName;
    final teamName = parts[0].trim();
    final playerName = parts[1].trim();
    return '$playerName : $teamName';
  }

  static String _getMatchTitle(dynamic match) {
    final isGrouped = match.groupName != null && match.groupName!.isNotEmpty;
    final isIndividual =
        match.matchType == 'individual' ||
        match.matchType == '選手' ||
        match.matchType.contains('個人戦');

    if (isGrouped && !isIndividual) {
      final rTeam = match.redName.contains(':')
          ? match.redName.split(':').first.trim()
          : match.redName;
      final wTeam = match.whiteName.contains(':')
          ? match.whiteName.split(':').first.trim()
          : match.whiteName;
      return '$rTeam vs $wTeam';
    }

    return '${match.redName} vs ${_reverseWhiteName(match.whiteName)}';
  }

  Widget _buildCallRow(String label, dynamic match, Color textColor) {
    return Column(
      children: [
        if (match.note.isNotEmpty)
          Text(
            match.note,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                _getMatchTitle(match),
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontSize.headline,
                  fontWeight: AppFontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (inProgressMatches.isEmpty && waitingMatches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF607D8B), // 観客席らしい落ち着いた色に変更
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (inProgressMatches.isNotEmpty)
            _buildCallRow(
              '進行中',
              inProgressMatches.first,
              const Color(0xFFFFD180), // orangeAccent
            ),
          if (inProgressMatches.isNotEmpty && waitingMatches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.24),
                height: 1,
              ),
            ),
          if (waitingMatches.isNotEmpty)
            _buildCallRow('次試合', waitingMatches.first, const Color(0xFFFFFFFF)),
        ],
      ),
    );
  }
}
