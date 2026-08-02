import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';

/// 🏆 試合データの詳細編集を行うプレミアムボトムシート
class MatchEditSheet extends ConsumerStatefulWidget {
  final MatchModel match;
  final String? tournamentId;
  final AppThemeColors themeColors;

  const MatchEditSheet({
    super.key,
    required this.match,
    this.tournamentId,
    required this.themeColors,
  });

  @override
  ConsumerState<MatchEditSheet> createState() => _MatchEditSheetState();
}

class _MatchEditSheetState extends ConsumerState<MatchEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. 選手・チーム情報
  late TextEditingController _redNameController;
  late TextEditingController _redTeamController;
  late TextEditingController _whiteNameController;
  late TextEditingController _whiteTeamController;

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

    final m = widget.match;
    final r = m.rule ?? const MatchRule();

    _redNameController = TextEditingController(text: m.redName);
    _redTeamController = TextEditingController(text: r.teamName);
    _whiteNameController = TextEditingController(text: m.whiteName);
    _whiteTeamController = TextEditingController(text: r.teamName);

    _courtController = TextEditingController(text: _extractCourtName(m.note));

    _groupNameController = TextEditingController(
      text: m.groupName ?? _extractGroupName(m.note),
    );

    _matchTime = r.matchTimeMinutes > 0
        ? r.matchTimeMinutes
        : m.matchTimeMinutes;
    _isIpponShobu = r.isIpponShobu;
    _hasHantei = r.hasHantei || m.hasHantei;

    _noteController = TextEditingController(text: m.note);
    _status = m.status;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _redNameController.dispose();
    _redTeamController.dispose();
    _whiteNameController.dispose();
    _whiteTeamController.dispose();
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

  void _swapRedAndWhite() {
    setState(() {
      final tempName = _redNameController.text;
      _redNameController.text = _whiteNameController.text;
      _whiteNameController.text = tempName;

      final tempTeam = _redTeamController.text;
      _redTeamController.text = _whiteTeamController.text;
      _whiteTeamController.text = tempTeam;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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

          // Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: widget.themeColors.primaryAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '試合情報の編集',
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
            tabs: const [
              Tab(icon: Icon(Icons.people_alt, size: 18), text: '選手・チーム'),
              Tab(icon: Icon(Icons.place, size: 18), text: 'コート・グループ'),
              Tab(icon: Icon(Icons.tune, size: 18), text: 'ルール・メモ'),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: 選手・チーム
                _buildPlayersTab(isDark, textColor),

                // Tab 2: コート・グループ
                _buildCourtAndGroupTab(isDark, textColor),

                // Tab 3: ルール・メモ
                _buildRuleAndMemoTab(isDark, textColor),
              ],
            ),
          ),

          // Footer Action Button
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
                  label: const Text(
                    '変更内容を保存',
                    style: TextStyle(
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

  // --- Tab 1: 選手・チーム ---
  Widget _buildPlayersTab(bool isDark, Color textColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 赤選手カード
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(isDark ? 25 : 12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withAlpha(isDark ? 80 : 40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    '赤（RED）選手情報',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _redNameController,
                label: '赤 選手名',
                hint: '名前を入力',
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _redTeamController,
                label: '赤 所属チーム名',
                hint: '所属道場・学校名',
                isDark: isDark,
                textColor: textColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 赤白入れ替えボタン
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.swap_vert, color: Colors.blueAccent),
            label: const Text('赤と白を入れ替える ⇄'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(color: Colors.blueAccent.withAlpha(100)),
            ),
            onPressed: _swapRedAndWhite,
          ),
        ),

        const SizedBox(height: 12),

        // 白選手カード
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100,
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
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: isDark ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '白（WHITE）選手情報',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _whiteNameController,
                label: '白 選手名',
                hint: '名前を入力',
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _whiteTeamController,
                label: '白 所属チーム名',
                hint: '所属道場・学校名',
                isDark: isDark,
                textColor: textColor,
              ),
            ],
          ),
        ),
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
                    '試合場（コート）の設定',
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
                    'グループ・ラウンド見出し（アコーディオン）',
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

  // --- Tab 3: ルール・メモ ---
  Widget _buildRuleAndMemoTab(bool isDark, Color textColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 個別ルール
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
                '⏱️ この試合だけの個別ルール',
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
    final m = widget.match;
    final groupInput = _groupNameController.text.trim();

    final existingRule = m.rule ?? const MatchRule();
    final updatedRule = existingRule.copyWith(
      matchTimeMinutes: _matchTime,
      isIpponShobu: _isIpponShobu,
      hasHantei: _hasHantei,
      teamName: _redTeamController.text.trim().isNotEmpty
          ? _redTeamController.text.trim()
          : existingRule.teamName,
    );

    final updatedMatch = m.copyWith(
      redName: _redNameController.text.trim(),
      whiteName: _whiteNameController.text.trim(),
      groupName: groupInput.isNotEmpty ? groupInput : m.groupName,
      note: _noteController.text.trim(),
      rule: updatedRule,
      status: _status,
    );

    await ref.read(matchApplicationServiceProvider).saveMatchesBulk([
      updatedMatch,
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('試合情報を保存・更新しました'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }
}
