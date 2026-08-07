import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

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
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
                ? Colors.grey.shade400
                : Colors.grey.shade600,
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
                _buildCourtAndGroupTab(isDark, textColor),

                // Tab 3: ルール・メモ
                _buildRuleAndMemoTab(isDark, textColor),
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
                    color: Colors.black.withAlpha(isDark ? 50 : 20),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _isDantai ? '団体戦全体を一括保存' : '変更内容を保存',
                    style: const TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                      color: Colors.white,
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
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
                      textColor: Colors.red,
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
                  icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  label: Text(
                    _isDantai ? 'チーム丸ごと赤と白を入れ替える ⇄' : '赤と白を入れ替える ⇄',
                    style: const TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
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
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252527) : Colors.white,
              borderRadius: AppRadius.medium,
              border: Border.all(color: context.appColors.separatorColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  posLabel,
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: widget.themeColors.primaryAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _redPlayerControllers[index],
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: AppFontSize.bodySmall,
                        ),
                        decoration: InputDecoration(
                          hintText: '赤 選手名',
                          filled: true,
                          fillColor: Colors.red.withAlpha(isDark ? 25 : 12),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.small,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('vs', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _whitePlayerControllers[index],
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppFontSize.bodySmall,
                        ),
                        decoration: InputDecoration(
                          hintText: '白 選手名',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withAlpha(15)
                              : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.small,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  // --- Tab 2: コート・グループ ---
  Widget _buildCourtAndGroupTab(bool isDark, Color textColor) {
    final currentText = _courtController.text;
    final selectedItems = currentText.split(',').map((e) => e.trim()).toSet();

    final courtPresets = ['第1試合場', '第2試合場', '第3試合場', '部内戦コート'];
    final roundPresets = [
      '1回戦',
      '2回戦',
      '3回戦',
      '準決勝',
      '決勝戦',
      '1試合目',
      '2試合目',
      '3試合目',
      'Aリーグ',
      'Bリーグ',
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.roundValue),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: widget.themeColors.primaryAccent.withAlpha(isDark ? 25 : 12),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: widget.themeColors.primaryAccent.withAlpha(
                isDark ? 80 : 40,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.stadium,
                    size: 18,
                    color: widget.themeColors.primaryAccent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '試合場・進行見出しの一括設定',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (_courtController.text.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text(
                        'クリア',
                        style: TextStyle(fontSize: AppFontSize.caption),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          _courtController.clear();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _courtController,
                label: '試合場・進行見出し (カンマ区切り)',
                hint: '例: 第1試合場, 1回戦, 3試合目 (未入力時は空欄になります)',
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '※ここに入力した試合場・進行見出しは、メモ（詳細情報）に保存・表示されます',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '🏟️ 試合場（コート）を選択',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: courtPresets.map((preset) {
                  final isSelected = selectedItems.contains(preset);
                  return AppFilterChip(
                    selected: isSelected,
                    label: Text(preset),
                    onSelected: (_) {
                      setState(() {
                        _toggleHeadingPreset(preset);
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),
              Text(
                '🏆 回戦・ラウンド・試合順を選択',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: roundPresets.map((preset) {
                  final isSelected = selectedItems.contains(preset);
                  return AppFilterChip(
                    selected: isSelected,
                    label: Text(preset),
                    onSelected: (_) {
                      setState(() {
                        _toggleHeadingPreset(preset);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _noteController,
          label: '📝 試合のメモ・詳細コメント',
          hint: '注意事項や備考を入力',
          isDark: isDark,
          textColor: textColor,
          maxLines: 3,
        ),
      ],
    );
  }

  // --- Tab 3: 一括ルール・メモ ---
  Widget _buildRuleAndMemoTab(bool isDark, Color textColor) {
    final tourneyId =
        widget.tournamentId ?? widget.matches.first.tournamentId ?? '';
    final asyncTourney = ref.watch(tournamentProvider(tourneyId));
    final categoryRules = asyncTourney.valueOrNull?.categoryRules ?? {};

    final matchCategory = widget.matches.first.category;

    final List<Widget> categoryPresetChips = [];
    categoryRules.forEach((catName, ruleSet) {
      if (matchCategory != null &&
          matchCategory.isNotEmpty &&
          catName != matchCategory &&
          !catName.contains(matchCategory) &&
          !matchCategory.contains(catName)) {
        return;
      }

      // 設定が存在・有効化されているルールのみチップとして表示
      final bool hasValidHonsen =
          ruleSet.useHonsenRule && ruleSet.normalRule.matchTimeMinutes > 0;
      if (hasValidHonsen) {
        final isSelected = _selectedPresetKey == 'honsen';
        categoryPresetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.bookmark,
            label: Text(
              '本線ルール (${ruleSet.normalRule.matchTimeMinutes == ruleSet.normalRule.matchTimeMinutes.toInt() ? ruleSet.normalRule.matchTimeMinutes.toInt() : ruleSet.normalRule.matchTimeMinutes}分)',
            ),
            onSelected: (selected) {
              if (selected) {
                _applyTargetPresetRule(ruleSet.normalRule, 'honsen');
              }
            },
          ),
        );
      }

      final bool hasValidRenseikai =
          ruleSet.useRenseikaiRule &&
          ruleSet.renseikaiRule.matchTimeMinutes > 0;
      if (hasValidRenseikai) {
        final isSelected = _selectedPresetKey == 'renseikai';
        categoryPresetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.flash_on,
            label: Text(
              '錬成会ルール (${ruleSet.renseikaiRule.matchTimeMinutes == ruleSet.renseikaiRule.matchTimeMinutes.toInt() ? ruleSet.renseikaiRule.matchTimeMinutes.toInt() : ruleSet.renseikaiRule.matchTimeMinutes}分)',
            ),
            onSelected: (selected) {
              if (selected) {
                _applyTargetPresetRule(ruleSet.renseikaiRule, 'renseikai');
              }
            },
          ),
        );
      }

      final bool hasValidMoushiawase =
          ruleSet.useMoushiawaseRule &&
          ruleSet.moushiawaseRule.matchTimeMinutes > 0;
      if (hasValidMoushiawase) {
        final isSelected = _selectedPresetKey == 'moushiawase';
        categoryPresetChips.add(
          AppChoiceChip(
            selected: isSelected,
            icon: Icons.handshake,
            label: Text(
              '申し合わせルール (${ruleSet.moushiawaseRule.matchTimeMinutes == ruleSet.moushiawaseRule.matchTimeMinutes.toInt() ? ruleSet.moushiawaseRule.matchTimeMinutes.toInt() : ruleSet.moushiawaseRule.matchTimeMinutes}分)',
            ),
            onSelected: (selected) {
              if (selected) {
                _applyTargetPresetRule(ruleSet.moushiawaseRule, 'moushiawase');
              }
            },
          ),
        );
      }
    });

    final currentRule = _selectedPresetRule ?? const MatchRule();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.roundValue),
      children: [
        // 部門別ルールからのワンタップ選択エリア
        if (categoryPresetChips.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.modernValue),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: widget.themeColors.primaryAccent.withAlpha(
                isDark ? 25 : 12,
              ),
              borderRadius: AppRadius.large,
              border: Border.all(
                color: widget.themeColors.primaryAccent.withAlpha(
                  isDark ? 80 : 40,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: widget.themeColors.primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '🏷️ 部門別ルール設定からワンタップ選択',
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: 6, runSpacing: 6, children: categoryPresetChips),
              ],
            ),
          ),
        ],

        // 🛡️ 適用中ルールの全内訳表示カード
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232326) : Colors.blue.shade50,
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isDark ? Colors.blue.shade800 : Colors.blue.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, size: 18, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    '🛡️ 適用されるルールの全内訳 (リアルタイム同期)',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                      color: isDark
                          ? Colors.blue.shade200
                          : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildRuleSummaryChip(
                    icon: Icons.timer,
                    label:
                        '試合時間: ${_matchTime == _matchTime.toInt() ? _matchTime.toInt() : _matchTime}分${currentRule.isRunningTime ? " (ランニング)" : ""}',
                    isActive: true,
                    isDark: isDark,
                  ),
                  _buildRuleSummaryChip(
                    icon: Icons.sports_mma,
                    label: _isIpponShobu ? '勝負: 一本勝負 ⚡' : '勝負: 三本勝負 ⚔️',
                    isActive: true,
                    isDark: isDark,
                  ),
                  _buildRuleSummaryChip(
                    icon: Icons.gavel,
                    label: _hasHantei ? '判定: ON ⭕' : '判定: 強制OFF ❌',
                    isActive: _hasHantei,
                    isDark: isDark,
                  ),
                  _buildRuleSummaryChip(
                    icon: Icons.more_time,
                    label:
                        (currentRule.enchoTimeMinutes > 0 ||
                            currentRule.isEnchoUnlimited)
                        ? '延長: ${currentRule.isEnchoUnlimited ? "無制限" : "${currentRule.enchoTimeMinutes}分"}'
                        : '延長: 強制OFF ❌',
                    isActive:
                        (currentRule.enchoTimeMinutes > 0 ||
                        currentRule.isEnchoUnlimited),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),

        // 一括ルールスイッチコントロール
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⏱️ ルールの詳細コントロール & 微調整',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('試合時間'),
                  DropdownButton<double>(
                    value: _matchTime,
                    items: [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0].map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text('${v == v.toInt() ? v.toInt() : v}分'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _matchTime = v;
                          if (_selectedPresetRule != null) {
                            _selectedPresetRule = _selectedPresetRule!.copyWith(
                              matchTimeMinutes: v,
                            );
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const Divider(),
              Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('一本勝負にする'),
                  value: _isIpponShobu,
                  activeTrackColor: widget.themeColors.primaryAccent,
                  onChanged: (v) => setState(() {
                    _isIpponShobu = v;
                    if (_selectedPresetRule != null) {
                      _selectedPresetRule = _selectedPresetRule!.copyWith(
                        isIpponShobu: v,
                      );
                    }
                  }),
                ),
              ),
              const Divider(),
              Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '個人戦の判定（ハンテイ）を適用',
                    style: TextStyle(
                      color:
                          currentRule.isRenseikai ||
                              currentRule.matchScene == 'renseikai' ||
                              currentRule.matchScene == 'moushiawase'
                          ? Colors.grey
                          : textColor,
                    ),
                  ),
                  subtitle:
                      currentRule.isRenseikai ||
                          currentRule.matchScene == 'renseikai' ||
                          currentRule.matchScene == 'moushiawase'
                      ? const Text(
                          '※錬成会・申し合わせルールのため強制OFFに固定されています',
                          style: TextStyle(
                            fontSize: AppFontSize.badge,
                            color: Colors.orange,
                          ),
                        )
                      : null,
                  value: _hasHantei,
                  activeTrackColor: widget.themeColors.primaryAccent,
                  onChanged: (v) {
                    final isRenseikaiOrMoushiawase =
                        currentRule.isRenseikai ||
                        currentRule.matchScene == 'renseikai' ||
                        currentRule.matchScene == 'moushiawase';
                    if (isRenseikaiOrMoushiawase) return;
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleSummaryChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
  }) {
    return AppChoiceChip(
      icon: icon,
      label: Text(label),
      selected: isActive,
      onSelected: null,
    );
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
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: AppFontSize.body),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
