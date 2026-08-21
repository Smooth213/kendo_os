import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_player_slot_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_rule_and_memo_tab.dart';

/// 🏆 試合・団体戦対戦枠の詳細編集を行うボトムシート
class MatchEditSheet extends ConsumerStatefulWidget {
  final List<MatchModel> matches;
  final String? tournamentId;
  final AppThemeColors themeColors;

  const MatchEditSheet({
    super.key,
    required this.matches,
    this.tournamentId,
    required this.themeColors,
  }) : assert(matches.length > 0, 'Matches list cannot be empty');

  @override
  ConsumerState<MatchEditSheet> createState() => _MatchEditSheetState();
}

class _MatchEditSheetState extends ConsumerState<MatchEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late bool _isDantai;
  bool _isSwapped = false;
  late bool _initialOwnIsRed;

  // 1. チーム・選手情報
  late TextEditingController _redTeamController;
  late TextEditingController _whiteTeamController;
  late List<TextEditingController> _redPlayerControllers;
  late List<TextEditingController> _whitePlayerControllers;

  // 2. コート・グループ情報
  late TextEditingController _courtController;
  late TextEditingController _groupNameController;

  // 3. ルール・メモ
  MatchRule? _selectedPresetRule;
  String? _selectedPresetKey; // 'honsen', 'renseikai', 'moushiawase'
  late double _matchTime;
  late bool _isIpponShobu;
  late bool _hasHantei;
  late TextEditingController _noteController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final first = widget.matches.first;
    _isDantai = widget.matches.length > 1 || first.matchType == '団体戦';

    final r = first.rule ?? const MatchRule();

    String detectedKey;
    if (r.isRenseikai ||
        r.matchScene == 'renseikai' ||
        first.matchScene == 'renseikai') {
      detectedKey = 'renseikai';
    } else if (r.matchScene == 'moushiawase' ||
        first.matchScene == 'moushiawase') {
      detectedKey = 'moushiawase';
    } else if (r.matchScene == 'honsen' || first.matchScene == 'honsen') {
      detectedKey = 'honsen';
    } else {
      detectedKey = 'honsen';
    }

    _selectedPresetKey = detectedKey;
    _selectedPresetRule = r.copyWith(
      matchScene: detectedKey,
      isRenseikai: detectedKey == 'renseikai',
    );

    // チーム名と選手名の分離抽出
    final extractedRedTeam = _extractTeamName(
      first.redName,
      r.teamName.isNotEmpty ? r.teamName : '赤チーム',
    );
    final extractedWhiteTeam = _extractTeamName(first.whiteName, '白チーム');

    // 初期状態での自チーム位置判定
    final originalRuleTeam = r.teamName.trim();
    if (originalRuleTeam.isNotEmpty) {
      if (originalRuleTeam == extractedWhiteTeam) {
        _initialOwnIsRed = false;
      } else {
        _initialOwnIsRed = true;
      }
    } else {
      _initialOwnIsRed = true;
    }

    _redTeamController = TextEditingController(text: extractedRedTeam);
    _whiteTeamController = TextEditingController(text: extractedWhiteTeam);

    _redPlayerControllers = widget.matches
        .map((m) => TextEditingController(text: _extractPlayerName(m.redName)))
        .toList();
    _whitePlayerControllers = widget.matches
        .map(
          (m) => TextEditingController(text: _extractPlayerName(m.whiteName)),
        )
        .toList();

    _courtController = TextEditingController(text: _extractHeadingText(first));

    _groupNameController = TextEditingController(text: '');

    _matchTime = r.matchTimeMinutes > 0
        ? r.matchTimeMinutes
        : first.matchTimeMinutes;
    _isIpponShobu = r.isIpponShobu;
    _hasHantei = (detectedKey == 'renseikai' || detectedKey == 'moushiawase')
        ? false
        : r.hasHantei;

    _noteController = TextEditingController(text: _cleanNoteText(first.note));
    _status = first.status;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _redTeamController.dispose();
    _whiteTeamController.dispose();
    for (var c in _redPlayerControllers) {
      c.dispose();
    }
    for (var c in _whitePlayerControllers) {
      c.dispose();
    }
    _courtController.dispose();
    _groupNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _extractTeamName(String rawName, String fallback) {
    if (rawName.contains(':')) {
      final teamPart = rawName.split(':').first.trim();
      if (teamPart.isNotEmpty) return teamPart;
    }
    if (rawName.isNotEmpty && !rawName.contains(':') && _isDantai) {
      return rawName.trim();
    }
    return fallback;
  }

  String _extractPlayerName(String rawName) {
    if (rawName.contains(':')) {
      return rawName.split(':').last.trim();
    }
    return rawName.trim();
  }

  String _extractHeadingText(MatchModel match) {
    final rawNote = match.note.trim();
    if (rawNote.isEmpty) return '';

    final firstLine = rawNote.split('\n').first.trim();
    final isUuidNote = RegExp(
      r'^[a-f0-9\-]{20,}$',
      caseSensitive: false,
    ).hasMatch(firstLine);

    if (isUuidNote) return '';

    // note の 1行目が vs 行でなく、かつ見出し項目（カンマ区切り含む）であれば見出しとみなす
    if (!firstLine.contains(' vs ') &&
        (firstLine.contains('試合場') ||
            firstLine.contains('コート') ||
            firstLine.contains('回戦') ||
            firstLine.contains('リーグ') ||
            firstLine.contains('試合目') ||
            firstLine.contains(','))) {
      return firstLine;
    }

    return '';
  }

  String _cleanNoteText(String rawNote) {
    if (rawNote.isEmpty) return '';
    final lines = rawNote.split('\n');
    if (lines.isEmpty) return '';

    final firstLine = lines.first.trim();
    final isHeadingLine =
        !firstLine.contains(' vs ') &&
        (firstLine.contains('試合場') ||
            firstLine.contains('コート') ||
            firstLine.contains('回戦') ||
            firstLine.contains('リーグ') ||
            firstLine.contains('試合目') ||
            firstLine.contains(','));

    // 1行目が進行見出しまたは vs 行の場合はそれを取り除いた残りを純粋メモコメントとする
    final noteLines = (isHeadingLine || firstLine.contains(' vs '))
        ? lines.skip(1).where((line) => line.trim().isNotEmpty).toList()
        : lines.where((line) => line.trim().isNotEmpty).toList();

    return noteLines.join('\n').trim();
  }

  void _swapTeamsAndPlayers() {
    setState(() {
      _isSwapped = !_isSwapped;
      final tempTeam = _redTeamController.text;
      _redTeamController.text = _whiteTeamController.text;
      _whiteTeamController.text = tempTeam;

      for (int i = 0; i < _redPlayerControllers.length; i++) {
        final tempPlayer = _redPlayerControllers[i].text;
        _redPlayerControllers[i].text = _whitePlayerControllers[i].text;
        _whitePlayerControllers[i].text = tempPlayer;
      }
    });
  }

  void _applyTargetPresetRule(MatchRule rule, String key) {
    // 錬成会・申し合わせルールの判定
    final isRenseikaiOrMoushiawase =
        key == 'renseikai' ||
        key == 'moushiawase' ||
        rule.isRenseikai ||
        rule.matchScene == 'renseikai' ||
        rule.matchScene == 'moushiawase';

    // 無関係なルール（判定・延長戦・代表戦）は必ず強制的にOFFにする
    final sanitizedRule = rule.copyWith(
      matchScene: key,
      isRenseikai: key == 'renseikai',
      hasHantei: isRenseikaiOrMoushiawase ? false : rule.hasHantei,
      enchoTimeMinutes: isRenseikaiOrMoushiawase ? 0.0 : rule.enchoTimeMinutes,
      isEnchoUnlimited: isRenseikaiOrMoushiawase
          ? false
          : rule.isEnchoUnlimited,
      hasRepresentativeMatch: isRenseikaiOrMoushiawase
          ? false
          : rule.hasRepresentativeMatch,
    );

    setState(() {
      _selectedPresetKey = key;
      _selectedPresetRule = sanitizedRule;
      _matchTime = sanitizedRule.matchTimeMinutes > 0
          ? sanitizedRule.matchTimeMinutes
          : 2.0;
      _isIpponShobu = sanitizedRule.isIpponShobu;
      _hasHantei = sanitizedRule.hasHantei;
    });
  }

  String _getPositionLabel(int index, int total) {
    if (total == 5) {
      const pos = ['先鋒', '次鋒', '中堅', '副将', '大将'];
      if (index < pos.length) return pos[index];
    } else if (total == 3) {
      const pos = ['先鋒', '中堅', '大将'];
      if (index < pos.length) return pos[index];
    }
    return '第${index + 1}試合';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final backgroundColor = themeColors.cardBackground;
    final textColor = context.appColors.textColor;

    final sheetTitle = _isDantai ? '団体戦対戦の編集' : '試合情報の編集';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x33000000),
              borderRadius: AppRadius.micro,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.roundValue,
            ),
            child: Row(
              children: [
                Icon(
                  _isDantai ? Icons.groups : Icons.edit_note,
                  color: widget.themeColors.primaryAccent,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  sheetTitle,
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: widget.themeColors.primaryAccent,
            labelColor: widget.themeColors.primaryAccent,
            unselectedLabelColor: isDark
                ? context.appColors.subTextColor
                : context.appColors.subTextColor,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
            ),
            labelStyle: const TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: AppFontSize.small),
            tabs: [
              Tab(
                icon: Icon(
                  _isDantai ? Icons.groups : Icons.people_alt,
                  size: 18,
                ),
                text: _isDantai ? '対戦・選手' : '選手・チーム',
              ),
              const Tab(icon: Icon(Icons.place, size: 18), text: 'コート・メモ'),
              const Tab(icon: Icon(Icons.tune, size: 18), text: '一括ルール'),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: チーム・選手
                _buildTeamAndPlayersTab(isDark, textColor),

                // Tab 2: コート・グループ
                MatchEditCourtAndGroupTab(
                  themeColors: widget.themeColors,
                  courtController: _courtController,
                  noteController: _noteController,
                  isDark: isDark,
                  textColor: textColor,
                  onToggleHeadingPreset: _toggleHeadingPreset,
                  onClearCourt: () => setState(() => _courtController.clear()),
                ),

                // Tab 3: ルール・メモ
                MatchEditRuleAndMemoTab(
                  primaryAccent: widget.themeColors.primaryAccent,
                  isDark: isDark,
                  textColor: textColor,
                  tournamentId: widget.tournamentId,
                  match: widget.matches.first,
                  selectedPresetKey: _selectedPresetKey,
                  selectedPresetRule: _selectedPresetRule,
                  matchTime: _matchTime,
                  isIpponShobu: _isIpponShobu,
                  hasHantei: _hasHantei,
                  onPresetSelected: _applyTargetPresetRule,
                  onMatchTimeChanged: (v) {
                    setState(() {
                      _matchTime = v;
                      if (_selectedPresetRule != null) {
                        _selectedPresetRule = _selectedPresetRule!.copyWith(
                          matchTimeMinutes: v,
                        );
                      }
                    });
                  },
                  onIpponShobuChanged: (v) {
                    setState(() {
                      _isIpponShobu = v;
                      if (_selectedPresetRule != null) {
                        _selectedPresetRule = _selectedPresetRule!.copyWith(
                          isIpponShobu: v,
                        );
                      }
                    });
                  },
                  onHanteiChanged: (v) {
                    setState(() {
                      _hasHantei = v;
                      if (_selectedPresetRule != null) {
                        _selectedPresetRule = _selectedPresetRule!.copyWith(
                          hasHantei: v,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Footer Save Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withAlpha(isDark ? 50 : 20),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check,
                    color: AppKendoColors.pureWhite,
                  ),
                  label: Text(
                    _isDantai ? '団体戦全体を一括保存' : '変更内容を保存',
                    style: const TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.pureWhite,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.large,
                    ),
                  ),
                  onPressed: _saveChanges,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: チーム・選手情報 ---
  Widget _buildTeamAndPlayersTab(bool isDark, Color textColor) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.roundValue),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x33000000),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isDantai ? '🏫 団体戦 対戦チーム' : '👤 対戦者情報',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _redTeamController,
                      label: '赤（RED）チーム名',
                      hint: '赤チーム名を入力',
                      isDark: isDark,
                      textColor: AppKendoColors.red,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: _whiteTeamController,
                      label: '白（WHITE）チーム名',
                      hint: '白チーム名を入力',
                      isDark: isDark,
                      textColor: context.appColors.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.swap_horiz,
                    color: AppKendoColors.pureWhite,
                  ),
                  label: Text(
                    _isDantai ? 'チーム丸ごと赤と白を入れ替える ⇄' : '赤と白を入れ替える ⇄',
                    style: const TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKendoColors.blueAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.round,
                    ),
                  ),
                  onPressed: _swapTeamsAndPlayers,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          _isDantai ? '👥 選手オーダー一覧（先鋒〜大将）' : '👤 選手名',
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.body,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),

        ...List.generate(widget.matches.length, (index) {
          final posLabel = _getPositionLabel(index, widget.matches.length);
          return MatchEditPlayerSlotTile(
            posLabel: posLabel,
            redController: _redPlayerControllers[index],
            whiteController: _whitePlayerControllers[index],
            primaryAccent: widget.themeColors.primaryAccent,
            isDark: isDark,
            textColor: textColor,
          );
        }),
      ],
    );
  }

  void _toggleHeadingPreset(String preset) {
    final currentText = _courtController.text.trim();
    if (currentText.isEmpty) {
      _courtController.text = preset;
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
    _courtController.text = items.join(', ');
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required Color textColor,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.small,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: AppFontSize.body),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x33000000),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x33000000),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveChanges() async {
    final groupInput = _groupNameController.text.trim();
    final redTeamInput = _redTeamController.text.trim();
    final whiteTeamInput = _whiteTeamController.text.trim();
    final courtInput = _courtController.text.trim();

    // 団体戦アコーディオンを崩さずに1つのカードとして維持するグループキー導出
    final firstMatch = widget.matches.first;
    final rawGroup = firstMatch.groupName ?? '';
    final isUuidGroup = RegExp(
      r'^[a-f0-9\-]{20,}$',
      caseSensitive: false,
    ).hasMatch(rawGroup);

    final String fallbackGroupKey =
        (rawGroup.isNotEmpty &&
            !isUuidGroup &&
            rawGroup != '1回戦' &&
            rawGroup != '2回戦')
        ? rawGroup
        : 'group_${firstMatch.id}';

    final String finalGroupName = _isDantai
        ? (courtInput.isNotEmpty
              ? courtInput
              : (groupInput.isNotEmpty ? groupInput : fallbackGroupKey))
        : (courtInput.isNotEmpty ? courtInput : groupInput);

    // 自チームが赤から白（または白から赤）に入れ替わったか判定
    final bool currentOwnIsRed = _isSwapped
        ? !_initialOwnIsRed
        : _initialOwnIsRed;
    final String targetOwnTeamName = currentOwnIsRed
        ? redTeamInput
        : whiteTeamInput;

    final String sceneKey = _selectedPresetKey ?? 'honsen';
    final bool isRenseikaiBool = sceneKey == 'renseikai';
    final bool isRenseikaiOrMoushiawase =
        sceneKey == 'renseikai' || sceneKey == 'moushiawase';

    final updatedMatches = <MatchModel>[];

    for (int i = 0; i < widget.matches.length; i++) {
      final m = widget.matches[i];
      final baseRule = _selectedPresetRule ?? m.rule ?? const MatchRule();

      final updatedRule = baseRule.copyWith(
        matchScene: sceneKey,
        isRenseikai: isRenseikaiBool,
        matchTimeMinutes: _matchTime,
        isIpponShobu: _isIpponShobu,
        hasHantei: isRenseikaiOrMoushiawase ? false : _hasHantei,
        enchoTimeMinutes: isRenseikaiOrMoushiawase
            ? 0.0
            : baseRule.enchoTimeMinutes,
        isEnchoUnlimited: isRenseikaiOrMoushiawase
            ? false
            : baseRule.isEnchoUnlimited,
        hasRepresentativeMatch: isRenseikaiOrMoushiawase
            ? false
            : baseRule.hasRepresentativeMatch,
        teamName: targetOwnTeamName.isNotEmpty
            ? targetOwnTeamName
            : baseRule.teamName,
      );

      final redPlayer = _redPlayerControllers[i].text.trim();
      final whitePlayer = _whitePlayerControllers[i].text.trim();

      // 団体戦の場合は 'チーム名: 選手名' の形式で実際のチーム名を確実に適用・保存
      final finalRedName = _isDantai
          ? (redTeamInput.isNotEmpty
                ? (redPlayer.isNotEmpty
                      ? '$redTeamInput: $redPlayer'
                      : redTeamInput)
                : redPlayer)
          : redPlayer;

      final finalWhiteName = _isDantai
          ? (whiteTeamInput.isNotEmpty
                ? (whitePlayer.isNotEmpty
                      ? '$whiteTeamInput: $whitePlayer'
                      : whiteTeamInput)
                : whitePlayer)
          : whitePlayer;

      // メモは余計な対戦名合成を行わず、コート名・グループ見出し名・ユーザーメッセージを綺麗に保存
      final userNote = _noteController.text.trim();
      final prefixParts = <String>[];
      if (courtInput.isNotEmpty) prefixParts.add(courtInput);
      if (groupInput.isNotEmpty) prefixParts.add(groupInput);

      final headerPrefix = prefixParts.join(' ');
      final noteCombined = headerPrefix.isNotEmpty
          ? (userNote.isNotEmpty ? '$headerPrefix\n$userNote' : headerPrefix)
          : userNote;

      final updatedMatch = m.copyWith(
        redName: finalRedName,
        whiteName: finalWhiteName,
        groupName: finalGroupName,
        note: noteCombined,
        rule: updatedRule,
        matchScene: sceneKey,
        status: _status,
      );

      updatedMatches.add(updatedMatch);
    }

    await ref
        .read(matchApplicationServiceProvider)
        .saveMatchesBulk(updatedMatches);

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        _isDantai ? '団体戦の全試合情報を一括保存しました' : '試合情報を保存・更新しました',
      );
      Navigator.pop(context);
    }
  }
}
