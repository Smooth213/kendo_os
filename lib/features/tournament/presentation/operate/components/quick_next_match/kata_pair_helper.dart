import 'package:flutter/widgets.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:uuid/uuid.dart';

/// 🥋 剣道形・木刀基本技稽古法などのペア選手（「・」区切り）解析・個別更新ヘルパー
class KataPairMember {
  final int index;
  final String role;
  final String name;

  const KataPairMember({
    required this.index,
    required this.role,
    required this.name,
  });
}

class KataPairHelper {
  static final RegExp _rolePrefixRegex = RegExp(
    r'^(打太刀|仕太刀|元立ち|掛かり手|掛り手|選手\d*)[:\s]*',
  );

  /// 剣道形または木刀基本技稽古法であるかを判定
  static bool isKataMatch(MatchModel match, MatchRule? rule) {
    if (rule?.isKataMatch == true || match.rule?.isKataMatch == true) {
      return true;
    }
    final mType = match.matchType;
    if (mType.contains('形') || mType.contains('稽古法')) {
      return true;
    }
    final cat = match.category ?? rule?.category ?? '';
    if (cat.contains('形') || cat.contains('稽古法')) {
      return true;
    }
    return false;
  }

  /// チーム名付き文字列（例: "〇〇剣友会 : 選手A・選手B"）からペア2名の名前を抽出
  static List<String> extractPairNames(String rawWithTeam) {
    final rawName = rawWithTeam.contains(':')
        ? rawWithTeam.split(':').last.trim()
        : rawWithTeam.trim();
    if (rawName.isEmpty || rawName == '選手') {
      return ['選手', '選手'];
    }
    final parts = rawName
        .split('・')
        .map((p) => _cleanName(p))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return ['選手', '選手'];
    }
    if (parts.length == 1) {
      return [parts[0], '選手'];
    }
    return [parts[0], parts[1]];
  }

  /// 相手チーム文字列から相手ペア2名の名前を抽出（引き継ぎフラグ考慮）
  static List<String> extractOpponentPairNames(
    String rawWithTeam, {
    required bool shouldPreserve,
  }) {
    if (!shouldPreserve) {
      return ['', ''];
    }
    final rawName = rawWithTeam.contains(':')
        ? rawWithTeam.split(':').last.trim()
        : rawWithTeam.trim();
    if (rawName.isEmpty || rawName == '選手' || rawName == '選手・選手') {
      return ['', ''];
    }
    final parts = rawName.split('・').map((p) => _cleanName(p)).toList();
    final p1 = parts.isNotEmpty && parts[0] != '選手' ? parts[0] : '';
    final p2 = parts.length > 1 && parts[1] != '選手' ? parts[1] : '';
    return [p1, p2];
  }

  /// ペアリストを「・」で結合した文字列を生成（空欄は「選手」補完）
  static String buildCombinedPairName(List<String> names) {
    final cleanNames = names.map((n) {
      final t = n.trim();
      return t.isNotEmpty ? t : '選手';
    }).toList();
    if (cleanNames.isEmpty) return '選手・選手';
    if (cleanNames.length == 1) return '${cleanNames[0]}・選手';
    return cleanNames.take(2).join('・');
  }

  /// 選手名が「・」で結合されたペア（または複数名）であるかを判定
  static bool isPair(String? playerName) {
    if (playerName == null) return false;
    return playerName.contains('・');
  }

  /// ポジション名・役職プレフィックスに基づき、各ペアメンバーの役職名と選手名を解析
  static List<KataPairMember> parsePair(String raw, {String? posName}) {
    if (!raw.contains('・')) {
      final role = _detectRole(raw, 0, posName);
      final cleanName = _cleanName(raw);
      return [KataPairMember(index: 0, role: role, name: cleanName)];
    }

    final parts = raw.split('・');
    final members = <KataPairMember>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      final role = _detectRole(part, i, posName);
      final cleanName = _cleanName(part);
      members.add(KataPairMember(index: i, role: role, name: cleanName));
    }

    return members;
  }

  /// ペアのうち指定したインデックスの選手のみを更新し、再度「・」で結合した文字列を返す
  static String updateMember(
    String currentRaw,
    int memberIndex,
    String newPlayerName,
  ) {
    final parts = currentRaw.split('・');
    if (memberIndex < 0 || memberIndex >= parts.length) {
      return currentRaw;
    }

    final oldPart = parts[memberIndex].trim();
    final prefixMatch = _rolePrefixRegex.firstMatch(oldPart);

    String replacement;
    if (prefixMatch != null) {
      // プレフィックス（例: "打太刀: "）を維持
      final prefix = prefixMatch.group(0)!;
      replacement = '$prefix$newPlayerName';
    } else {
      replacement = newPlayerName;
    }

    parts[memberIndex] = replacement;
    return parts.join('・');
  }

  static String _detectRole(String part, int index, String? posName) {
    final match = _rolePrefixRegex.firstMatch(part.trim());
    if (match != null) {
      final rawRole = match.group(1)!;
      if (rawRole == '掛り手') return '掛かり手';
      return rawRole;
    }

    final pos = posName ?? '';
    if (pos.contains('木刀') || pos.contains('基本技')) {
      if (index == 0) return '元立ち';
      if (index == 1) return '掛かり手';
    } else if (pos.contains('形')) {
      if (index == 0) return '打太刀';
      if (index == 1) return '仕太刀';
    }

    return '選手${index + 1}';
  }

  static String _cleanName(String part) {
    return part.trim().replaceFirst(_rolePrefixRegex, '').trim();
  }

  /// 🥋 次戦クイック作成用: 剣道形または通常試合群のモデル生成
  static List<MatchModel> generateNextMatches({
    required MatchModel base,
    required MatchRule? rule,
    required bool isKata,
    required bool isIndividual,
    required bool isRenseikai,
    required bool isOwnTeamRed,
    required String ownTeamName,
    required String oppTeam,
    required String groupName,
    required String fullNote,
    required List<String> positions,
    required List<String> playerNames,
    required List<TextEditingController> opponentPlayerControllers,
  }) {
    final matchesToCreate = <MatchModel>[];
    final double baseOrder = base.order + 1.0;

    if (isKata) {
      final myPairStr = buildCombinedPairName(playerNames);
      final opPairStr = buildCombinedPairName(
        opponentPlayerControllers.map((c) => c.text).toList(),
      );
      final String redStr = isOwnTeamRed
          ? '$ownTeamName : $myPairStr'
          : '$oppTeam : $opPairStr';
      final String whiteStr = isOwnTeamRed
          ? '$oppTeam : $opPairStr'
          : '$ownTeamName : $myPairStr';

      matchesToCreate.add(
        MatchModel(
          id: const Uuid().v4(),
          tournamentId: base.tournamentId,
          category: base.category,
          groupName: groupName,
          matchType: base.matchType.isNotEmpty ? base.matchType : '形・基本判定',
          rule:
              rule?.copyWith(
                isKataMatch: true,
                matchTimeMinutes: 0.0,
                isRunningTime: false,
                hasHantei: true,
              ) ??
              rule,
          redName: redStr,
          whiteName: whiteStr,
          status: 'pending',
          matchTimeMinutes: 0.0,
          isRunningTime: false,
          hasHantei: true,
          order: baseOrder,
          note: fullNote.isNotEmpty ? fullNote : base.note,
        ),
      );
    } else {
      for (int i = 0; i < positions.length; i++) {
        final pos = positions[i];
        final myPlayer = i < playerNames.length ? playerNames[i] : '選手';
        final oppCtrl = i < opponentPlayerControllers.length
            ? opponentPlayerControllers[i]
            : null;
        final oppPlayer = (oppCtrl != null && oppCtrl.text.trim().isNotEmpty)
            ? oppCtrl.text.trim()
            : '選手';

        final String redStr = isOwnTeamRed
            ? '$ownTeamName : $myPlayer'
            : '$oppTeam : $oppPlayer';
        final String whiteStr = isOwnTeamRed
            ? '$oppTeam : $oppPlayer'
            : '$ownTeamName : $myPlayer';

        matchesToCreate.add(
          MatchModel(
            id: const Uuid().v4(),
            tournamentId: base.tournamentId,
            category: base.category,
            groupName: groupName,
            matchType: isIndividual ? 'individual' : pos,
            rule: rule,
            redName: redStr,
            whiteName: whiteStr,
            status: 'pending',
            matchTimeMinutes: base.matchTimeMinutes,
            isRunningTime: base.isRunningTime,
            order: baseOrder + (i * 0.1),
            note: fullNote.isNotEmpty ? fullNote : base.note,
          ),
        );
      }
    }

    return matchesToCreate;
  }
}
