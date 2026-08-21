import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_target_select_section.dart';

/// 一括ルール編集用のデータ解析・グループ化ヘルパー
class BulkRuleDataHelper {
  static String getResolvedType(MatchModel m) {
    if (m.isKachinuki || m.matchType == '無限勝ち抜き' || m.matchType == '勝ち抜き戦') {
      return '勝ち抜き戦';
    }
    final isLeague =
        m.note.contains('リーグ戦') ||
        m.note.contains('[リーグ戦]') ||
        m.matchType.contains('リーグ');
    final isTeam =
        m.matchType.contains('団体') ||
        const {
          '先鋒',
          '次鋒',
          '中堅',
          '副将',
          '大将',
          '代表戦',
          '代',
          '大将延長戦',
        }.contains(m.matchType);
    if (isLeague) {
      return isTeam ? 'リーグ団体戦' : 'リーグ個人戦';
    } else {
      return isTeam ? '団体戦' : '個人戦';
    }
  }

  static List<MatchGroupUnit> buildGroupUnits(List<MatchModel> matches) {
    final List<MatchGroupUnit> units = [];
    final Map<String, List<MatchModel>> teamGroups = {};

    for (final m in matches) {
      final type = getResolvedType(m);
      final category = m.category ?? '';

      if (type == '団体戦' || type == 'リーグ団体戦') {
        final groupName = m.groupName != null && m.groupName!.isNotEmpty
            ? m.groupName!
            : '団体戦';
        final key = '$category::$type::$groupName';
        teamGroups.putIfAbsent(key, () => []).add(m);
      } else {
        final displayName = m.category != null && m.category!.isNotEmpty
            ? '[${m.category}] ${m.redName} vs ${m.whiteName}'
            : '${m.redName} vs ${m.whiteName}';

        units.add(
          MatchGroupUnit(
            id: 'single:${m.id}',
            displayName: displayName,
            matchIds: [m.id],
            category: category,
            resolvedType: type,
          ),
        );
      }
    }

    teamGroups.forEach((key, list) {
      final parts = key.split('::');
      final category = parts[0];
      final type = parts[1];
      final groupNameVal = parts[2];

      String displayGroupName = groupNameVal;
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (uuidRegex.hasMatch(groupNameVal) || groupNameVal.length > 20) {
        String rTeam = '';
        String wTeam = '';
        for (final m in list) {
          if (m.redName.contains(':') && m.whiteName.contains(':')) {
            rTeam = m.redName.split(':').first.trim();
            wTeam = m.whiteName.split(':').first.trim();
            break;
          }
        }
        if (rTeam.isNotEmpty && wTeam.isNotEmpty) {
          displayGroupName = '$rTeam vs $wTeam';
        } else {
          if (list.isNotEmpty) {
            final first = list.first;
            displayGroupName = '${first.redName} vs ${first.whiteName}';
          } else {
            displayGroupName = '団体戦対戦';
          }
        }
      }

      final displayName = category.isNotEmpty
          ? '[$category] $displayGroupName'
          : displayGroupName;

      units.add(
        MatchGroupUnit(
          id: 'team:$key',
          displayName: displayName,
          matchIds: list.map((m) => m.id).toList(),
          category: category,
          resolvedType: type,
        ),
      );
    });

    return units;
  }
}
