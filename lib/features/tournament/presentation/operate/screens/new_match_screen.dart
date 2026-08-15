import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/organization.dart';
import '../providers/match_generator_provider.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart'; // ★ 追加
import 'package:kendo_os/shared/infrastructure/repository/organization_repository.dart';

// ★ Phase 3 追加: サジェスト用のデータソース
import '../providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import '../components/new_match/new_match_smart_autocomplete.dart';
import '../components/new_match/new_match_team_selector_card.dart';
import '../components/new_match/new_match_heading_notes_card.dart';

// 選手マスタ取得用プロバイダ
final newMatchPlayerMasterProvider =
    StreamProvider.autoDispose<List<PlayerModel>>((ref) {
      return ref.watch(playerRepositoryProvider).getPlayers();
    });

// 過去の対戦履歴取得用プロバイダ
final newMatchHistoryProvider = Provider.autoDispose<List<String>>((ref) {
  final allMatches = ref.watch(matchListProvider);
  final Set<String> history = {};
  for (final m in allMatches) {
    if (m.redName.isNotEmpty) {
      history.add(m.redName.split(':').first.trim());
      history.add(m.redName.trim());
    }
    if (m.whiteName.isNotEmpty) {
      history.add(m.whiteName.split(':').first.trim());
      history.add(m.whiteName.trim());
    }
  }
  final result = history.toList();
  result.sort();
  return result;
});

class NewMatchScreen extends ConsumerStatefulWidget {
  final String? tournamentId;
  const NewMatchScreen({super.key, this.tournamentId});

  @override
  ConsumerState<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends ConsumerState<NewMatchScreen> {
  String _creationMode = '単発試合';
  bool _countForStandings = true;
  String _selectedScene = 'honsen'; // 'renseikai', 'honsen', 'moushiawase'

  final _redNameController = TextEditingController();
  final _whiteNameController = TextEditingController();
  final _leagueParticipantsController = TextEditingController();
  final _courtController = TextEditingController();
  final _noteController = TextEditingController();
  final _categoryController = TextEditingController();

  // ★ Phase 3 追加: フォーカス制御用ノード
  final _redFocusNode = FocusNode();
  final _whiteFocusNode = FocusNode();

  Organization? _redOrg;
  TeamTemplate? _redTeam;
  Organization? _whiteOrg;
  TeamTemplate? _whiteTeam;

  @override
  void dispose() {
    _redNameController.dispose();
    _whiteNameController.dispose();
    _leagueParticipantsController.dispose();
    _courtController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    _redFocusNode.dispose();
    _whiteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgsStream = ref
        .watch(organizationRepositoryProvider)
        .watchOrganizations();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final asyncTournament = widget.tournamentId != null
        ? ref.watch(tournamentProvider(widget.tournamentId!))
        : null;
    final tournament = asyncTournament?.value;
    final categoryRules = tournament?.categoryRules ?? {};
    final existingCategories = tournament?.categories ?? [];

    // ★ Phase 3 追加: サジェスト候補の統合（マスタ＋履歴）
    final masterPlayers = ref.watch(newMatchPlayerMasterProvider).value ?? [];
    final history = ref.watch(newMatchHistoryProvider);
    final Set<String> combinedSet = {};
    for (var p in masterPlayers) {
      combinedSet.add(p.name);
    }
    combinedSet.addAll(history);
    final combinedSuggestions = combinedSet.toList();
    combinedSuggestions.sort();

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: const AppHeader(
          title: '新規試合作成・自動生成',
          backgroundColor: AppKendoColors.transparent,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 生成モード選択
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '生成モード',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _creationMode,
                          isExpanded: true,
                          items: ['単発試合', '団体戦テンプレ生成', 'リーグ戦自動生成']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) => setState(() {
                            _creationMode = val!;
                            _redOrg = null;
                            _redTeam = null;
                            _whiteOrg = null;
                            _whiteTeam = null;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. メタデータ（練習試合フラグ）トグル
                    SwitchListTile.adaptive(
                      title: const Text(
                        '星取表（ランキング）に集計する',
                        style: TextStyle(fontWeight: AppFontWeight.bold),
                      ),
                      subtitle: const Text('練習試合の場合はオフにしてください'),
                      value: _countForStandings,
                      onChanged: (val) =>
                          setState(() => _countForStandings = val),
                      activeThumbColor: AppKendoColors.indigo,
                    ),
                    const Divider(height: 32),

                    // 3. モード別の入力UI
                    if (_creationMode == '単発試合') ...[
                      // ★ Phase 3 追加: 最強のオートコンプリートに差し替え
                      NewMatchSmartAutocomplete(
                        controller: _redNameController,
                        focusNode: _redFocusNode,
                        suggestions: combinedSuggestions,
                        labelText: '赤の選手名（またはチーム名）',
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      NewMatchSmartAutocomplete(
                        controller: _whiteNameController,
                        focusNode: _whiteFocusNode,
                        suggestions: combinedSuggestions,
                        labelText: '白の選手名（またはチーム名）',
                        isDark: isDark,
                      ),
                    ] else if (_creationMode == 'リーグ戦自動生成') ...[
                      const Text(
                        '参加チーム（選手）をカンマ( , )区切りで入力してください\n例: Aチーム, Bチーム, C道場, D剣友会',
                        style: TextStyle(color: AppKendoColors.blueGrey),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _leagueParticipantsController,
                        decoration: const InputDecoration(
                          labelText: '参加者リスト',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ] else if (_creationMode == '団体戦テンプレ生成') ...[
                      StreamBuilder<List<Organization>>(
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
                                stream: _redOrg != null
                                    ? ref
                                          .watch(organizationRepositoryProvider)
                                          .watchTeamTemplates(_redOrg!.id)
                                    : const Stream.empty(),
                                builder: (context, teamSnap) {
                                  return NewMatchTeamSelectorCard(
                                    colorLabel: '赤',
                                    orgs: orgs,
                                    isRed: true,
                                    selectedOrg: _redOrg,
                                    selectedTeam: _redTeam,
                                    teamTemplates: teamSnap.data ?? [],
                                    onOrgChanged: (val) => setState(() {
                                      _redOrg = val;
                                      _redTeam = null;
                                    }),
                                    onTeamChanged: (val) => setState(() {
                                      _redTeam = val;
                                    }),
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              StreamBuilder<List<TeamTemplate>>(
                                stream: _whiteOrg != null
                                    ? ref
                                          .watch(organizationRepositoryProvider)
                                          .watchTeamTemplates(_whiteOrg!.id)
                                    : const Stream.empty(),
                                builder: (context, teamSnap) {
                                  return NewMatchTeamSelectorCard(
                                    colorLabel: '白',
                                    orgs: orgs,
                                    isRed: false,
                                    selectedOrg: _whiteOrg,
                                    selectedTeam: _whiteTeam,
                                    teamTemplates: teamSnap.data ?? [],
                                    onOrgChanged: (val) => setState(() {
                                      _whiteOrg = val;
                                      _whiteTeam = null;
                                    }),
                                    onTeamChanged: (val) => setState(() {
                                      _whiteTeam = val;
                                    }),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xxl),

                    const SizedBox(height: AppSpacing.lg),
                    if (existingCategories.isNotEmpty) ...[
                      const Text(
                        '登録済み部門',
                        style: TextStyle(
                          fontSize: AppFontSize.small,
                          color: AppKendoColors.grey,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: existingCategories.map((cat) {
                          final isSelected =
                              _categoryController.text.trim() == cat;
                          return AppChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _categoryController.text = cat;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    AppTextField(
                      controller: _categoryController,
                      onChanged: (text) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'カテゴリ（例：小学生の部）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ★ 適用ルールのインタラクティブカード選択
                    _buildRuleSelectionSection(categoryRules, isDark),
                    const SizedBox(height: AppSpacing.lg),
                    // ★ 統合された「試合場・進行見出し」および「試合メモ」入力セクション
                    NewMatchHeadingNotesCard(
                      courtController: _courtController,
                      noteController: _noteController,
                      isDark: isDark,
                      onClearCourt: () =>
                          setState(() => _courtController.clear()),
                      onHeadingPresetToggled: _toggleHeadingPreset,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 4. 実行（生成）ボタン
                    GlassButton(
                      onPressed: _submit,
                      color: AppKendoColors.redAccent,
                      icon: Icons.flash_on,
                      label: '$_creationMode を実行',
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleHeadingPreset(String preset) {
    final current = _courtController.text.trim();
    if (current.isEmpty) {
      setState(() {
        _courtController.text = preset;
      });
      return;
    }
    final items = current
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.contains(preset)) {
      items.remove(preset);
    } else {
      items.add(preset);
    }
    setState(() {
      _courtController.text = items.join(', ');
    });
  }

  Future<void> _submit() async {
    final generator = ref.read(matchGeneratorProvider);
    final courtText = _courtController.text.trim();
    final userNote = _noteController.text.trim();
    final noteCombined = courtText.isNotEmpty
        ? (userNote.isNotEmpty ? '$courtText\n$userNote' : courtText)
        : userNote;

    if (_creationMode == '単発試合') {
      if (_redNameController.text.isEmpty ||
          _whiteNameController.text.isEmpty) {
        return;
      }
      if (widget.tournamentId == null) {
        AppSnackBar.showError(context, '大会IDが不明なため保存できません');
        return;
      }

      final newMatch = MatchModel(
        id: const Uuid().v4(),
        matchType: '個人戦',
        redName: _redNameController.text,
        whiteName: _whiteNameController.text,
        source: 'manual',
        countForStandings: _countForStandings,
        tournamentId: widget.tournamentId,
        category: _categoryController.text,
        note: noteCombined,
        matchScene: _selectedScene,
      );
      await ref
          .read(matchApplicationServiceProvider)
          .saveMatch(newMatch); // ★ 修正
    } else if (_creationMode == 'リーグ戦自動生成') {
      final participants = _leagueParticipantsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (participants.length < 2) {
        return;
      }
      await generator.generateLeagueMatches(
        _categoryController.text,
        participants,
        _countForStandings,
        noteCombined,
        widget.tournamentId,
      );
    } else if (_creationMode == '団体戦テンプレ生成') {
      if (_redOrg == null ||
          _redTeam == null ||
          _whiteOrg == null ||
          _whiteTeam == null) {
        return;
      }
      await generator.generateTeamMatchBouts(
        _redTeam!.name,
        _redTeam!.orderedMemberNames,
        _whiteTeam!.name,
        _whiteTeam!.orderedMemberNames,
        _countForStandings,
        category: _categoryController.text,
        note: noteCombined,
        tournamentId: widget.tournamentId,
      );
    }

    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Widget _buildRuleSelectionSection(
    Map<String, CategoryRuleSet> categoryRules,
    bool isDark,
  ) {
    final cleanCategory = _categoryController.text.trim();
    final ruleSet = categoryRules[cleanCategory];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '現在適用するルール（タップして選択）',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: AppKendoColors.grey,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            if (ruleSet != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5),
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: const Color(0xFF3F51B5)),
                ),
                child: Text(
                  '部門ルール適用中: $cleanCategory',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: const Color(0xFF3F51B5),
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        if (ruleSet != null && ruleSet.isMultiScene) ...[
          _buildRuleCard(
            sceneId: 'renseikai',
            title: '⚔️ 錬成会ルール（午前・練習試合）',
            subText:
                '時間: ${ruleSet.renseikaiRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.renseikaiRule.isRunningTime ? '流し' : '正式'}) / 引き分け: ${ruleSet.renseikaiRule.hasHantei ? 'あり' : 'なし'} / ${ruleSet.renseikaiRule.renseikaiType}',
            accentColor: AppKendoColors.amber,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            sceneId: 'honsen',
            title: '🏆 本戦ルール（午後・トーナメント）',
            subText:
                '時間: ${ruleSet.normalRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.normalRule.isRunningTime ? '流し' : '正式'}) / 延長: ${ruleSet.normalRule.isEnchoUnlimited ? '無制限' : (ruleSet.normalRule.enchoCount > 0 ? 'あり' : 'なし')}',
            accentColor: AppKendoColors.indigo,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            sceneId: 'moushiawase',
            title: '🤝 申し合わせルール（終了後・自由戦）',
            subText:
                '時間: ${ruleSet.moushiawaseRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.moushiawaseRule.isRunningTime ? '流し' : '正式'}) / 引き分け: ${ruleSet.moushiawaseRule.hasHantei ? 'あり' : 'なし'}',
            accentColor: AppKendoColors.teal,
            isDark: isDark,
          ),
        ] else if (ruleSet != null) ...[
          _buildRuleCard(
            sceneId: 'honsen',
            title: '🏆 本戦（通常戦）ルール',
            subText:
                '時間: ${ruleSet.normalRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.normalRule.isRunningTime ? '流し' : '正式'}) / 延長: ${ruleSet.normalRule.isEnchoUnlimited ? '無制限' : (ruleSet.normalRule.enchoCount > 0 ? 'あり' : 'なし')}',
            accentColor: AppKendoColors.indigo,
            isDark: isDark,
          ),
        ] else ...[
          _buildRuleCard(
            sceneId: 'renseikai',
            title: '⚔️ 錬成会（練習試合）',
            subText: '2分流し / 引き分けあり',
            accentColor: AppKendoColors.amber,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            sceneId: 'honsen',
            title: '🏆 本戦（通常戦）',
            subText: '3分正式 / 代表戦・勝敗重視',
            accentColor: AppKendoColors.indigo,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            sceneId: 'moushiawase',
            title: '🤝 申し合わせ（自由対戦）',
            subText: '2分流し / 引き分けあり',
            accentColor: AppKendoColors.teal,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildRuleCard({
    required String sceneId,
    required String title,
    required String subText,
    required MaterialColor accentColor,
    required bool isDark,
  }) {
    final isSelected = _selectedScene == sceneId;

    return Material(
      color: AppKendoColors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedScene = sceneId;
          });
        },
        borderRadius: AppRadius.medium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? accentColor.shade900.withValues(alpha: 0.4)
                      : accentColor.shade50)
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF)),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: isSelected
                  ? (isDark ? accentColor.shade300 : accentColor.shade700)
                  : (isDark
                        ? const Color(0xFF38383A)
                        : const Color(0x33000000)),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? (isDark ? accentColor.shade300 : accentColor.shade700)
                    : AppKendoColors.grey,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: AppFontWeight.bold,
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFFFFFFFF)
                                  : accentColor.shade900)
                            : (context.appColors.subTextColor),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: isSelected
                            ? (isDark
                                  ? context.appColors.textColor.withValues(
                                      alpha: 0.7,
                                    )
                                  : accentColor.shade800)
                            : context.appColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
