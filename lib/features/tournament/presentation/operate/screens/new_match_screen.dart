import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/organization.dart';

// ★ Phase 3 追加: サジェスト用のデータソース
import '../providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import '../components/new_match/new_match_heading_notes_card.dart';
import '../components/new_match/new_match_mode_input_section.dart';
import '../components/new_match/new_match_scene_rule_selector_section.dart';
import '../services/new_match_submission_service.dart';

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
                    NewMatchModeInputSection(
                      creationMode: _creationMode,
                      redNameController: _redNameController,
                      redFocusNode: _redFocusNode,
                      whiteNameController: _whiteNameController,
                      whiteFocusNode: _whiteFocusNode,
                      leagueParticipantsController:
                          _leagueParticipantsController,
                      suggestions: combinedSuggestions,
                      redOrg: _redOrg,
                      redTeam: _redTeam,
                      whiteOrg: _whiteOrg,
                      whiteTeam: _whiteTeam,
                      onRedOrgChanged: (val) => setState(() {
                        _redOrg = val;
                        _redTeam = null;
                      }),
                      onRedTeamChanged: (val) => setState(() {
                        _redTeam = val;
                      }),
                      onWhiteOrgChanged: (val) => setState(() {
                        _whiteOrg = val;
                        _whiteTeam = null;
                      }),
                      onWhiteTeamChanged: (val) => setState(() {
                        _whiteTeam = val;
                      }),
                      isDark: isDark,
                    ),

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
                    NewMatchSceneRuleSelectorSection(
                      categoryRules: categoryRules,
                      category: _categoryController.text,
                      selectedScene: _selectedScene,
                      onSceneSelected: (scene) =>
                          setState(() => _selectedScene = scene),
                      isDark: isDark,
                    ),
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

  final NewMatchSubmissionService _submissionService =
      const NewMatchSubmissionService();

  Future<void> _submit() async {
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
    }

    final success = await _submissionService.submitMatch(
      ref: ref,
      creationMode: _creationMode,
      tournamentId: widget.tournamentId,
      redName: _redNameController.text,
      whiteName: _whiteNameController.text,
      leagueParticipantsRaw: _leagueParticipantsController.text,
      redOrg: _redOrg,
      redTeam: _redTeam,
      whiteOrg: _whiteOrg,
      whiteTeam: _whiteTeam,
      category: _categoryController.text,
      noteCombined: noteCombined,
      countForStandings: _countForStandings,
      selectedScene: _selectedScene,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
