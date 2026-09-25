import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/match_rule_setting_form.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 試合編集シート用のルールプリセットチップ構築ビルダー
class MatchEditRulePresetChips {
  static List<Widget> buildChips({
    required Map<String, CategoryRuleSet> categoryRules,
    required MatchModel match,
    required String? selectedPresetKey,
    required double matchTime,
    required bool isDantai,
    required void Function(MatchRule rule, String key) onPresetSelected,
  }) {
    final rawMatchCategory = match.category?.trim();

    // 該当試合の部門（match.category）に適合するルールセットを抽出
    final Map<String, CategoryRuleSet> matchedCategoryRules = {};
    if (rawMatchCategory != null && rawMatchCategory.isNotEmpty) {
      final cleanMatchCat = CategoryRuleMatchHelper.cleanCategoryBaseName(
        rawMatchCategory,
      );
      for (final entry in categoryRules.entries) {
        final catName = entry.key;
        final cleanCatName = CategoryRuleMatchHelper.cleanCategoryBaseName(
          catName,
        );
        if (catName == rawMatchCategory || cleanCatName == cleanMatchCat) {
          matchedCategoryRules[catName] = entry.value;
        }
      }
      // 完全一致や基底名一致で見つからない場合は部分一致で探す
      if (matchedCategoryRules.isEmpty) {
        for (final entry in categoryRules.entries) {
          final catName = entry.key;
          if (catName.contains(rawMatchCategory) ||
              rawMatchCategory.contains(catName)) {
            matchedCategoryRules[catName] = entry.value;
          }
        }
      }
    }

    final targetRules = matchedCategoryRules.isNotEmpty
        ? matchedCategoryRules
        : categoryRules;
    final bool showCategoryPrefix = targetRules.length > 1;

    final List<Widget> presetChips = [];
    targetRules.forEach((catName, ruleSet) {
      final displayName = CategoryRuleMatchHelper.formatDisplayTitle(
        category: catName,
        subtitle: ruleSet.subtitle,
        allCategoryRules: categoryRules,
      );
      final prefix = showCategoryPrefix ? '$displayName: ' : '';

      // 🏆 1. 本戦ルール（通常戦）
      final bool hasValidHonsen =
          ruleSet.useHonsenRule && ruleSet.normalRule.matchTimeMinutes > 0;
      if (hasValidHonsen) {
        final key = '${catName}_honsen';
        final isSelected =
            selectedPresetKey == key ||
            (selectedPresetKey == 'honsen' && targetRules.length == 1);
        presetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.account_balance,
            label: Text(
              '$prefix本戦ルール (${MatchRuleSettingForm.formatMinutes(ruleSet.normalRule.matchTimeMinutes)})',
            ),
            onSelected: (_) {
              onPresetSelected(ruleSet.normalRule, key);
            },
          ),
        );
      }

      // 🔥 2. 上位戦ルール（準決勝・決勝）
      final bool hasValidAdvanced =
          ruleSet.useAdvancedRule && ruleSet.advancedRule.matchTimeMinutes > 0;
      if (hasValidAdvanced) {
        final key = '${catName}_advanced';
        final isSelected = selectedPresetKey == key;
        presetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.military_tech,
            label: Text(
              '$prefix上位戦ルール (${MatchRuleSettingForm.formatMinutes(ruleSet.advancedRule.matchTimeMinutes)})',
            ),
            onSelected: (_) {
              onPresetSelected(ruleSet.advancedRule, key);
            },
          ),
        );
      }

      // ⚔️ 3. 錬成ルール & 🤝 4. 申合せルール（★ isMultiScene が true の場合のみ表示）
      if (ruleSet.isMultiScene) {
        final bool hasValidRenseikai =
            ruleSet.useRenseikaiRule &&
            ruleSet.renseikaiRule.matchTimeMinutes > 0;
        if (hasValidRenseikai) {
          final key = '${catName}_renseikai';
          final isSelected =
              selectedPresetKey == key ||
              (selectedPresetKey == 'renseikai' && targetRules.length == 1);
          presetChips.add(
            AppChoiceChip(
              selected: isSelected,
              icon: Icons.flash_on,
              label: Text(
                '$prefix錬成ルール (${MatchRuleSettingForm.formatMinutes(ruleSet.renseikaiRule.matchTimeMinutes)})',
              ),
              onSelected: (_) {
                onPresetSelected(ruleSet.renseikaiRule, key);
              },
            ),
          );
        }

        final bool hasValidMoushiawase =
            ruleSet.useMoushiawaseRule &&
            ruleSet.moushiawaseRule.matchTimeMinutes > 0;
        if (hasValidMoushiawase) {
          final key = '${catName}_moushiawase';
          final isSelected =
              selectedPresetKey == key ||
              (selectedPresetKey == 'moushiawase' && targetRules.length == 1);
          presetChips.add(
            AppChoiceChip(
              selected: isSelected,
              icon: Icons.handshake,
              label: Text(
                '$prefix申合せルール (${MatchRuleSettingForm.formatMinutes(ruleSet.moushiawaseRule.matchTimeMinutes)})',
              ),
              onSelected: (_) {
                onPresetSelected(ruleSet.moushiawaseRule, key);
              },
            ),
          );
        }
      }
    });

    // 試合ルール設定に登録がない場合のフォールバックチップ
    if (presetChips.isEmpty) {
      final formattedTime = MatchRuleSettingForm.formatMinutes(matchTime);
      MatchRule buildFallbackRule(String scene) {
        final t = matchTime > 0 ? matchTime : 3.0;
        if (scene == 'honsen') {
          return MatchRule(
            matchScene: 'honsen',
            matchTimeMinutes: t,
            isRunningTime: false,
            isIpponShobu: false,
            hasHantei: true,
            enchoTimeMinutes: 2.0,
            enchoCount: isDantai ? 0 : 1,
            isEnchoUnlimited: false,
            hasRepresentativeMatch: isDantai,
            isDaihyoIpponShobu: true,
            daihyoMatchTimeMinutes: 0.0,
            daihyoHasExtension: isDantai,
            daihyoEnchoTimeMinutes: 3.0,
            daihyoEnchoCount: -2,
            daihyoHasHantei: false,
            renseikaiType: '一試合制',
          );
        }
        return MatchRule(
          matchScene: scene,
          isRenseikai: scene == 'renseikai',
          matchTimeMinutes: t,
          isRunningTime: true,
          isIpponShobu: false,
          hasHantei: false,
          enchoTimeMinutes: 0.0,
          enchoCount: 0,
          isEnchoUnlimited: false,
          hasRepresentativeMatch: false,
          isDaihyoIpponShobu: false,
          daihyoMatchTimeMinutes: 0.0,
          daihyoHasExtension: false,
          daihyoEnchoTimeMinutes: 0.0,
          daihyoEnchoCount: 0,
          daihyoHasHantei: false,
          renseikaiType: '一試合制',
        );
      }

      for (final (scene, title, icon) in [
        ('honsen', '本戦ルール', Icons.account_balance),
        ('renseikai', '錬成会ルール', Icons.flash_on),
        ('moushiawase', '申合せルール', Icons.handshake),
      ]) {
        presetChips.add(
          AppChoiceChip(
            selected: selectedPresetKey == scene,
            icon: icon,
            label: Text('$title ($formattedTime)'),
            onSelected: (_) =>
                onPresetSelected(buildFallbackRule(scene), scene),
          ),
        );
      }
    }

    return presetChips;
  }
}
