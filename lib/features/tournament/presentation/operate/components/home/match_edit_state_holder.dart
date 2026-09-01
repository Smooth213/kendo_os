import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_data_helper.dart';

/// 🏆 試合編集シート用のステート＆コントローラー管理クラス
class MatchEditStateHolder {
  final List<MatchModel> matches;
  late bool isDantai;
  bool isSwapped = false;
  late bool initialOwnIsRed;

  // 1. チーム・選手情報
  late TextEditingController redTeamController;
  late TextEditingController whiteTeamController;
  late List<TextEditingController> redPlayerControllers;
  late List<TextEditingController> whitePlayerControllers;

  // 2. コート・グループ情報
  late TextEditingController courtController;
  late TextEditingController groupNameController;

  // 3. ルール・メモ
  MatchRule? selectedPresetRule;
  String? selectedPresetKey;
  late double matchTime;
  late bool isRunningTime;
  late bool isIpponShobu;
  late int ipponLimit;
  late int hansokuLimit;
  late bool hasExtension;
  late double enchoTime;
  late int enchoCount;
  late bool isEnchoUnlimited;
  late bool hasHantei;

  late bool hasRepresentativeMatch;
  late bool isDaihyoIpponShobu;
  late double daihyoMatchTime;
  late bool daihyoHasExtension;
  late double daihyoEnchoTime;
  late int daihyoEnchoCount;
  late bool isDaihyoEnchoUnlimited;
  late bool daihyoHasHantei;

  late String renseikaiType;
  late TextEditingController overallTimeController;

  late bool isKachinuki;
  late String kachinukiUnlimitedType;
  late bool isLeague;
  late double winPoint;
  late double lossPoint;
  late double drawPoint;

  late TextEditingController noteController;
  late String status;

  MatchEditStateHolder(this.matches) {
    final first = matches.first;
    isDantai = matches.length > 1 || first.matchType == '団体戦';

    final r = first.rule ?? const MatchRule();

    String detectedKey;
    if (r.isRenseikai ||
        r.matchScene == 'renseikai' ||
        first.matchScene == 'renseikai') {
      detectedKey = 'renseikai';
    } else if (r.matchScene == 'moushiawase' ||
        first.matchScene == 'moushiawase') {
      detectedKey = 'moushiawase';
    } else {
      detectedKey = 'honsen';
    }

    selectedPresetKey = detectedKey;
    selectedPresetRule = r.copyWith(
      matchScene: detectedKey,
      isRenseikai: detectedKey == 'renseikai',
    );

    final extractedRedTeam = MatchEditDataHelper.extractTeamName(
      first.redName,
      r.teamName.isNotEmpty ? r.teamName : '赤チーム',
      isDantai,
    );
    final extractedWhiteTeam = MatchEditDataHelper.extractTeamName(
      first.whiteName,
      '白チーム',
      isDantai,
    );

    final originalRuleTeam = r.teamName.trim();
    if (originalRuleTeam.isNotEmpty) {
      initialOwnIsRed = originalRuleTeam != extractedWhiteTeam;
    } else {
      initialOwnIsRed = true;
    }

    redTeamController = TextEditingController(text: extractedRedTeam);
    whiteTeamController = TextEditingController(text: extractedWhiteTeam);

    redPlayerControllers = matches
        .map(
          (m) => TextEditingController(
            text: MatchEditDataHelper.extractPlayerName(m.redName),
          ),
        )
        .toList();
    whitePlayerControllers = matches
        .map(
          (m) => TextEditingController(
            text: MatchEditDataHelper.extractPlayerName(m.whiteName),
          ),
        )
        .toList();

    courtController = TextEditingController(
      text: MatchEditDataHelper.extractHeadingText(first),
    );
    groupNameController = TextEditingController(text: '');

    matchTime = r.matchTimeMinutes > 0
        ? r.matchTimeMinutes
        : first.matchTimeMinutes;
    isRunningTime = r.isRunningTime;
    isIpponShobu = r.isIpponShobu;
    ipponLimit = r.ipponLimit;
    hansokuLimit = r.hansokuLimit;
    hasExtension =
        (r.isEnchoUnlimited || r.enchoCount > 0) || first.hasExtension;
    enchoTime = r.enchoTimeMinutes > 0
        ? r.enchoTimeMinutes
        : (first.extensionTimeMinutes?.toDouble() ?? 2.0);
    enchoCount = r.enchoCount > 0 ? r.enchoCount : 1;
    isEnchoUnlimited = r.isEnchoUnlimited || (first.extensionCount == -2);
    hasHantei = r.hasHantei || first.hasHantei;

    hasRepresentativeMatch = r.hasRepresentativeMatch || r.hasLeagueDaihyo;
    isDaihyoIpponShobu = r.isDaihyoIpponShobu;
    daihyoMatchTime = r.daihyoMatchTimeMinutes;
    daihyoHasExtension = r.daihyoHasExtension;
    daihyoEnchoTime = r.daihyoEnchoTimeMinutes > 0
        ? r.daihyoEnchoTimeMinutes
        : 3.0;
    daihyoEnchoCount = r.daihyoEnchoCount;
    isDaihyoEnchoUnlimited = r.daihyoEnchoCount == -2 || r.isEnchoUnlimited;
    daihyoHasHantei = r.daihyoHasHantei;

    renseikaiType = r.renseikaiType.isNotEmpty ? r.renseikaiType : '一試合制';
    overallTimeController = TextEditingController(
      text: r.overallTimeMinutes > 0 ? r.overallTimeMinutes.toString() : '30',
    );

    isKachinuki = r.isKachinuki;
    kachinukiUnlimitedType = r.kachinukiUnlimitedType.isNotEmpty
        ? r.kachinukiUnlimitedType
        : '大将対大将';
    isLeague = r.isLeague;
    winPoint = r.winPoint > 0 ? r.winPoint : 3.0;
    lossPoint = r.lossPoint;
    drawPoint = r.drawPoint > 0 ? r.drawPoint : 1.0;

    noteController = TextEditingController(
      text: MatchEditDataHelper.cleanNoteText(first.note),
    );
    status = first.status;
  }

  void dispose() {
    redTeamController.dispose();
    whiteTeamController.dispose();
    for (var c in redPlayerControllers) {
      c.dispose();
    }
    for (var c in whitePlayerControllers) {
      c.dispose();
    }
    courtController.dispose();
    groupNameController.dispose();
    noteController.dispose();
    overallTimeController.dispose();
  }

  void swapTeamsAndPlayers() {
    isSwapped = !isSwapped;
    final tempTeam = redTeamController.text;
    redTeamController.text = whiteTeamController.text;
    whiteTeamController.text = tempTeam;

    for (int i = 0; i < redPlayerControllers.length; i++) {
      final tempPlayer = redPlayerControllers[i].text;
      redPlayerControllers[i].text = whitePlayerControllers[i].text;
      whitePlayerControllers[i].text = tempPlayer;
    }
  }

  void applyTargetPresetRule(MatchRule rule, String key) {
    selectedPresetKey = key;
    selectedPresetRule = rule.copyWith(
      matchScene: key,
      isRenseikai: key == 'renseikai',
    );
    matchTime = rule.matchTimeMinutes;
    isRunningTime = rule.isRunningTime;
    isIpponShobu = rule.isIpponShobu;
    ipponLimit = rule.ipponLimit;
    hansokuLimit = rule.hansokuLimit;
    hasExtension =
        rule.isEnchoUnlimited || rule.enchoCount > 0 || rule.enchoCount == -2;
    enchoTime = rule.enchoTimeMinutes > 0 ? rule.enchoTimeMinutes : 2.0;
    enchoCount = rule.enchoCount > 0 ? rule.enchoCount : 1;
    isEnchoUnlimited = rule.isEnchoUnlimited || rule.enchoCount == -2;
    hasHantei = rule.hasHantei;
    hasRepresentativeMatch = isDantai
        ? (rule.hasRepresentativeMatch || rule.hasLeagueDaihyo)
        : false;
    isDaihyoIpponShobu = rule.isDaihyoIpponShobu;
    daihyoMatchTime = rule.daihyoMatchTimeMinutes;
    daihyoHasExtension = rule.daihyoHasExtension;
    daihyoEnchoTime = rule.daihyoEnchoTimeMinutes > 0
        ? rule.daihyoEnchoTimeMinutes
        : 3.0;
    daihyoEnchoCount = rule.daihyoEnchoCount > 0 ? rule.daihyoEnchoCount : 1;
    isDaihyoEnchoUnlimited =
        rule.daihyoEnchoCount == -2 || rule.isEnchoUnlimited;
    daihyoHasHantei = rule.daihyoHasHantei;
    renseikaiType = rule.renseikaiType.isNotEmpty
        ? rule.renseikaiType
        : (key == 'renseikai' ? '時間制' : '一試合制');
    overallTimeController.text =
        (rule.overallTimeMinutes > 0 ? rule.overallTimeMinutes : 30).toString();
    isKachinuki = rule.isKachinuki;
    kachinukiUnlimitedType = rule.kachinukiUnlimitedType.isNotEmpty
        ? rule.kachinukiUnlimitedType
        : '大将対大将';
    isLeague = rule.isLeague;
    winPoint = rule.winPoint > 0 ? rule.winPoint : 3.0;
    lossPoint = rule.lossPoint;
    drawPoint = rule.drawPoint > 0 ? rule.drawPoint : 1.0;
  }

  void toggleHeadingPreset(String preset) {
    final currentText = courtController.text.trim();
    if (currentText.isEmpty) {
      courtController.text = preset;
      return;
    }

    final items = currentText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.contains(preset)) {
      items.remove(preset);
    } else {
      items.add(preset);
    }
    courtController.text = items.join(', ');
  }
}
