import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/organization.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 新規試合作成画面における団体戦チーム（組織・テンプレート）選択カード（純粋UIコンポーネント）
class NewMatchTeamSelectorCard extends StatelessWidget {
  final String colorLabel;
  final List<Organization> orgs;
  final bool isRed;
  final Organization? selectedOrg;
  final TeamTemplate? selectedTeam;
  final List<TeamTemplate> teamTemplates;
  final ValueChanged<Organization?> onOrgChanged;
  final ValueChanged<TeamTemplate?> onTeamChanged;

  const NewMatchTeamSelectorCard({
    super.key,
    required this.colorLabel,
    required this.orgs,
    required this.isRed,
    this.selectedOrg,
    this.selectedTeam,
    this.teamTemplates = const [],
    required this.onOrgChanged,
    required this.onTeamChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isRed ? AppKendoColors.hansokuRed : const Color(0xFFF2F2F7),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$colorLabelチーム選択',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                color: isRed ? AppKendoColors.red : AppKendoColors.pureBlack,
              ),
            ),
            DropdownButton<Organization>(
              value: selectedOrg,
              isExpanded: true,
              hint: const Text('組織（道場・学校）を選択'),
              items: orgs
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.name)))
                  .toList(),
              onChanged: onOrgChanged,
            ),
            if (selectedOrg != null) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButton<TeamTemplate>(
                value: selectedTeam,
                isExpanded: true,
                hint: const Text('チームテンプレを選択'),
                items: teamTemplates
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: onTeamChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
