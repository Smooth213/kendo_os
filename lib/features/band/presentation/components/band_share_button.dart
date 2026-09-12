import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_select_sheet.dart';
import 'package:kendo_os/features/band/presentation/services/band_match_text_formatter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 大会ホーム・チーム試合状況カードの右上に統一配置されるBAND連携ボタン
class BandShareButton extends ConsumerWidget {
  final List<MatchModel>? matches;
  final TeamProgressStatus? teamStatus;
  final String? tournamentName;
  final String? tournamentId;

  const BandShareButton({
    super.key,
    this.matches,
    this.teamStatus,
    this.tournamentName,
    this.tournamentId,
  }) : assert(
         matches != null || teamStatus != null,
         'matches または teamStatus のどちらかは必須です',
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const brandColor = Color(0xFF00C73C);

    return SizedBox(
      height: 22,
      child: OutlinedButton.icon(
        onPressed: () async {
          AppHaptics.selection();
          final dojoId = ref.read(currentDojoIdProvider);
          final String? resolvedTournamentId =
              (tournamentId != null && tournamentId!.isNotEmpty)
              ? tournamentId
              : (matches?.firstOrNull?.tournamentId?.isNotEmpty == true
                    ? matches!.first.tournamentId
                    : (teamStatus?.tournamentId?.isNotEmpty == true
                          ? teamStatus!.tournamentId
                          : (ref.read(currentTournamentIdProvider).isNotEmpty
                                ? ref.read(currentTournamentIdProvider)
                                : null)));

          // 1. テキスト生成
          final String text;
          if (teamStatus != null) {
            text = BandMatchTextFormatter.formatFromTeamStatus(
              status: teamStatus!,
              tournamentName: tournamentName,
              tournamentId: resolvedTournamentId,
              dojoId: dojoId,
            );
          } else {
            text = BandMatchTextFormatter.formatFromMatchGroup(
              matches: matches!,
              tournamentName: tournamentName,
              tournamentId: resolvedTournamentId,
              dojoId: dojoId,
            );
          }

          // 2. クリップボードへ格納
          await Clipboard.setData(ClipboardData(text: text));

          // 3. グループ選択シートを表示
          if (context.mounted) {
            BandGroupSelectSheet.show(context, formattedText: text);
          }
        },
        icon: ClipRRect(
          borderRadius: AppRadius.micro,
          child: Image.asset(
            'assets/images/band_icon.png',
            width: 12,
            height: 12,
            fit: BoxFit.cover,
          ),
        ),
        label: const Text(
          'BAND',
          style: TextStyle(
            fontSize: AppFontSize.nano,
            fontWeight: AppFontWeight.bold,
            color: brandColor,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.subValue),
          side: BorderSide(
            color: brandColor.withValues(alpha: 0.4),
            width: 1.0,
          ),
          backgroundColor: brandColor.withValues(alpha: 0.06),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.capsule),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
