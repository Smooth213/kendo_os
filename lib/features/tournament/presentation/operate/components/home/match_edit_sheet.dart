import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';

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

  // 1. チーム・選手情報
  late TextEditingController _redTeamController;
  late TextEditingController _whiteTeamController;
  late List<TextEditingController> _redPlayerControllers;
  late List<TextEditingController> _whitePlayerControllers;

  // 2. コート・グループ情報
  late TextEditingController _courtController;
  late TextEditingController _groupNameController;

  // 3. ルール・メモ
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

    // チーム名
    final initialRedTeam = first.rule?.teamName ?? first.note;
    _redTeamController = TextEditingController(
      text: initialRedTeam.isNotEmpty ? initialRedTeam : '赤チーム',
    );
    _whiteTeamController = TextEditingController(
      text: first.whiteName.isNotEmpty ? first.whiteName : '白チーム',
    );

    // ポジション別の選手入力コントローラー
    _redPlayerControllers = widget.matches
        .map((m) => TextEditingController(text: m.redName))
        .toList();
    _whitePlayerControllers = widget.matches
        .map((m) => TextEditingController(text: m.whiteName))
        .toList();

    _courtController = TextEditingController(
      text: _extractCourtName(first.note),
    );

    _groupNameController = TextEditingController(
      text: first.groupName ?? _extractGroupName(first.note),
    );

    _matchTime = r.matchTimeMinutes > 0
        ? r.matchTimeMinutes
        : first.matchTimeMinutes;
    _isIpponShobu = r.isIpponShobu;
    _hasHantei = r.hasHantei || first.hasHantei;

    _noteController = TextEditingController(text: first.note);
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

  String _extractCourtName(String rawNote) {
    if (rawNote.contains('試合場')) {
      final match = RegExp(r'第\d+試合場|[A-Z]コート').firstMatch(rawNote);
      if (match != null) return match.group(0)!;
    }
    return '第1試合場';
  }

  String _extractGroupName(String rawNote) {
    if (rawNote.isEmpty) return 'Aリーグ';
    return rawNote.split('\n').first;
  }

  void _swapTeamsAndPlayers() {
    setState(() {
      // チーム名の入れ替え
      final tempTeam = _redTeamController.text;
      _redTeamController.text = _whiteTeamController.text;
      _whiteTeamController.text = tempTeam;

      // 全ポジの選手名を一括入れ替え
      for (int i = 0; i < _redPlayerControllers.length; i++) {
        final tempPlayer = _redPlayerControllers[i].text;
        _redPlayerControllers[i].text = _whitePlayerControllers[i].text;
        _whitePlayerControllers[i].text = tempPlayer;
      }
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
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final sheetTitle = _isDantai ? '団体戦対戦の編集' : '試合情報の編集';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  _isDantai ? Icons.groups : Icons.edit_note,
                  color: widget.themeColors.primaryAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  sheetTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
          const SizedBox(height: 8),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: widget.themeColors.primaryAccent,
            labelColor: widget.themeColors.primaryAccent,
            unselectedLabelColor: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            tabs: [
              Tab(
                icon: Icon(
                  _isDantai ? Icons.groups : Icons.people_alt,
                  size: 18,
                ),
                text: _isDantai ? 'チーム・選手' : '選手・チーム',
              ),
              const Tab(icon: Icon(Icons.place, size: 18), text: 'コート・グループ'),
              const Tab(icon: Icon(Icons.tune, size: 18), text: '一括ルール・メモ'),
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
              padding: const EdgeInsets.all(16),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(20),
      children: [
        // チーム名設定カード
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // 赤チーム名
                  Expanded(
                    child: _buildTextField(
                      controller: _redTeamController,
                      label: '赤（RED）チーム名',
                      hint: '赤チーム名を入力',
                      isDark: isDark,
                      textColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 白チーム名
                  Expanded(
                    child: _buildTextField(
                      controller: _whiteTeamController,
                      label: '白（WHITE）チーム名',
                      hint: '白チーム名を入力',
                      isDark: isDark,
                      textColor: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // チーム丸ごと赤白入れ替えボタン
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  label: Text(
                    _isDantai ? 'チーム丸ごと赤と白を入れ替える ⇄' : '赤と白を入れ替える ⇄',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _swapTeamsAndPlayers,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 各ポジションの選手リスト
        Text(
          _isDantai ? '👥 選手オーダー一覧（先鋒〜大将）' : '👤 選手名',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),

        ...List.generate(widget.matches.length, (index) {
          final posLabel = _getPositionLabel(index, widget.matches.length);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252527) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  posLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColors.primaryAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _redPlayerControllers[index],
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '赤 選手名',
                          filled: true,
                          fillColor: Colors.red.withAlpha(isDark ? 25 : 12),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('vs', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _whitePlayerControllers[index],
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '白 選手名',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withAlpha(15)
                              : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
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

  // --- Tab 2: コート・グループ ---
  Widget _buildCourtAndGroupTab(bool isDark, Color textColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 会場（コート）情報
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.themeColors.primaryAccent.withAlpha(isDark ? 25 : 12),
            borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(width: 8),
                  Text(
                    '試合場（コート）の一括設定',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _courtController,
                label: '試合場名 (例: 第1試合場, Aコート)',
                hint: '試合場を入力',
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['第1試合場', '第2試合場', '第3試合場', '部内戦コート'].map((preset) {
                  return ActionChip(
                    label: Text(preset, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _courtController.text = preset;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // グループ・ラウンド情報
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category, size: 18, color: textColor),
                  const SizedBox(width: 8),
                  Text(
                    'グループ・ラウンド見出し（一括グループ名）',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _groupNameController,
                label: 'グループ・ラウンド名 (例: Aリーグ, 1回戦, 準決勝)',
                hint: '見出しグループ名を入力',
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Aリーグ', 'Bリーグ', '1回戦', '2回戦', '準決勝', '決勝戦'].map((
                  preset,
                ) {
                  return ActionChip(
                    label: Text(preset, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _groupNameController.text = preset;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Tab 3: 一括ルール・メモ ---
  Widget _buildRuleAndMemoTab(bool isDark, Color textColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 一括ルール
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⏱️ 試合ルールの一括設定',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
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
                      if (v != null) setState(() => _matchTime = v);
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
                  onChanged: (v) => setState(() => _isIpponShobu = v),
                ),
              ),
              const Divider(),
              Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('個人戦の判定（ハンテイ）を適用'),
                  value: _hasHantei,
                  activeTrackColor: widget.themeColors.primaryAccent,
                  onChanged: (v) => setState(() => _hasHantei = v),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // メモ・備考
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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

    final updatedMatches = <MatchModel>[];

    for (int i = 0; i < widget.matches.length; i++) {
      final m = widget.matches[i];
      final existingRule = m.rule ?? const MatchRule();

      final updatedRule = existingRule.copyWith(
        matchTimeMinutes: _matchTime,
        isIpponShobu: _isIpponShobu,
        hasHantei: _hasHantei,
        teamName: redTeamInput.isNotEmpty
            ? redTeamInput
            : existingRule.teamName,
      );

      final noteCombined =
          _isDantai && redTeamInput.isNotEmpty && whiteTeamInput.isNotEmpty
          ? '$courtInput\n$redTeamInput vs $whiteTeamInput\n${_noteController.text.trim()}'
          : _noteController.text.trim();

      final updatedMatch = m.copyWith(
        redName: _redPlayerControllers[i].text.trim(),
        whiteName: _whitePlayerControllers[i].text.trim(),
        groupName: groupInput.isNotEmpty ? groupInput : m.groupName,
        note: noteCombined,
        rule: updatedRule,
        status: _status,
      );

      updatedMatches.add(updatedMatch);
    }

    await ref
        .read(matchApplicationServiceProvider)
        .saveMatchesBulk(updatedMatches);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isDantai ? '団体戦の全試合情報を一括保存しました' : '試合情報を保存・更新しました'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }
}
