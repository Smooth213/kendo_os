import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_smart_autocomplete.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_team_selector_card.dart';
import 'package:kendo_os/shared/domain/entities/organization.dart';
import 'package:kendo_os/shared/infrastructure/repository/organization_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// ⚔️ 新規試合作成 モード別入力UIセクション（単発 / リーグ / 団体戦）
class NewMatchModeInputSection extends ConsumerWidget {
  final String creationMode;
  final TextEditingController redNameController;
  final FocusNode redFocusNode;
  final TextEditingController whiteNameController;
  final FocusNode whiteFocusNode;
  final TextEditingController leagueParticipantsController;
  final List<String> suggestions;
  final Organization? redOrg;
  final TeamTemplate? redTeam;
  final Organization? whiteOrg;
  final TeamTemplate? whiteTeam;
  final ValueChanged<Organization?> onRedOrgChanged;
  final ValueChanged<TeamTemplate?> onRedTeamChanged;
  final ValueChanged<Organization?> onWhiteOrgChanged;
  final ValueChanged<TeamTemplate?> onWhiteTeamChanged;
  final bool isDark;

  const NewMatchModeInputSection({
    super.key,
    required this.creationMode,
    required this.redNameController,
    required this.redFocusNode,
    required this.whiteNameController,
    required this.whiteFocusNode,
    required this.leagueParticipantsController,
    required this.suggestions,
    required this.redOrg,
    required this.redTeam,
    required this.whiteOrg,
    required this.whiteTeam,
    required this.onRedOrgChanged,
    required this.onRedTeamChanged,
    required this.onWhiteOrgChanged,
    required this.onWhiteTeamChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (creationMode == '単発試合') {
      return Column(
        children: [
          NewMatchSmartAutocomplete(
            controller: redNameController,
            focusNode: redFocusNode,
            suggestions: suggestions,
            labelText: '赤の選手名（またはチーム名）',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),
          NewMatchSmartAutocomplete(
            controller: whiteNameController,
            focusNode: whiteFocusNode,
            suggestions: suggestions,
            labelText: '白の選手名（またはチーム名）',
            isDark: isDark,
          ),
        ],
      );
    }

    if (creationMode == 'リーグ戦自動生成') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '参加チーム（選手）をカンマ( , )区切りで入力してください\n例: Aチーム, Bチーム, C道場, D剣友会',
            style: TextStyle(color: AppKendoColors.blueGrey),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: leagueParticipantsController,
            decoration: const InputDecoration(
              labelText: '参加者リスト',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      );
    }

    if (creationMode == '団体戦テンプレ生成') {
      final orgsStream = ref
          .watch(organizationRepositoryProvider)
          .watchOrganizations();

      return StreamBuilder<List<Organization>>(
        stream: orgsStream,
        builder: (context, snapshot) {
          final orgs = snapshot.data ?? [];
          if (orgs.isEmpty) {
            return const Text(
              'マスタ管理で組織とチームを登録してください',
              style: TextStyle(color: AppKendoColors.red),
            );
          }
          return Column(
            children: [
              StreamBuilder<List<TeamTemplate>>(
                stream: redOrg != null
                    ? ref
                          .watch(organizationRepositoryProvider)
                          .watchTeamTemplates(redOrg!.id)
                    : const Stream.empty(),
                builder: (context, teamSnap) {
                  return NewMatchTeamSelectorCard(
                    colorLabel: '赤',
                    orgs: orgs,
                    isRed: true,
                    selectedOrg: redOrg,
                    selectedTeam: redTeam,
                    teamTemplates: teamSnap.data ?? [],
                    onOrgChanged: onRedOrgChanged,
                    onTeamChanged: onRedTeamChanged,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              StreamBuilder<List<TeamTemplate>>(
                stream: whiteOrg != null
                    ? ref
                          .watch(organizationRepositoryProvider)
                          .watchTeamTemplates(whiteOrg!.id)
                    : const Stream.empty(),
                builder: (context, teamSnap) {
                  return NewMatchTeamSelectorCard(
                    colorLabel: '白',
                    orgs: orgs,
                    isRed: false,
                    selectedOrg: whiteOrg,
                    selectedTeam: whiteTeam,
                    teamTemplates: teamSnap.data ?? [],
                    onOrgChanged: onWhiteOrgChanged,
                    onTeamChanged: onWhiteTeamChanged,
                  );
                },
              ),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
