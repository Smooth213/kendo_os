import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
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
        backgroundColor: Colors.transparent,
        appBar: const AppHeader(
          title: '新規試合作成・自動生成',
          backgroundColor: Colors.transparent,
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
                      activeThumbColor: Colors.indigo,
                    ),
                    const Divider(height: 32),

                    // 3. モード別の入力UI
                    if (_creationMode == '単発試合') ...[
                      // ★ Phase 3 追加: 最強のオートコンプリートに差し替え
                      _buildSmartAutocomplete(
                        controller: _redNameController,
                        focusNode: _redFocusNode,
                        suggestions: combinedSuggestions,
                        labelText: '赤の選手名（またはチーム名）',
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSmartAutocomplete(
                        controller: _whiteNameController,
                        focusNode: _whiteFocusNode,
                        suggestions: combinedSuggestions,
                        labelText: '白の選手名（またはチーム名）',
                        isDark: isDark,
                      ),
                    ] else if (_creationMode == 'リーグ戦自動生成') ...[
                      const Text(
                        '参加チーム（選手）をカンマ( , )区切りで入力してください\n例: Aチーム, Bチーム, C道場, D剣友会',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
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
                              style: TextStyle(color: Colors.red),
                            );
                          }
                          return Column(
                            children: [
                              _buildTeamSelector('赤', orgs, true),
                              const SizedBox(height: AppSpacing.lg),
                              _buildTeamSelector('白', orgs, false),
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
                          color: Colors.grey,
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

                    TextField(
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
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : Colors.grey.shade300,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stadium,
                                size: 18,
                                color: isDark
                                    ? Colors.cyanAccent
                                    : Colors.indigo,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '試合場・進行見出しの設定',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              if (_courtController.text.isNotEmpty)
                                TextButton.icon(
                                  icon: const Icon(Icons.clear, size: 14),
                                  label: const Text(
                                    'クリア',
                                    style: TextStyle(
                                      fontSize: AppFontSize.caption,
                                    ),
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
                          TextField(
                            controller: _courtController,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: AppFontSize.bodySmall,
                              fontWeight: AppFontWeight.semiBold,
                            ),
                            decoration: InputDecoration(
                              labelText: '試合場・進行の見出し',
                              hintText: '例: 準決勝, 第1試合場, 23試合目',
                              hintStyle: const TextStyle(
                                fontSize: AppFontSize.bodyMedium,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF38383A)
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 13,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
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
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['第1試合場', '第2試合場', '第3試合場', '部内戦コート'].map(
                              (preset) {
                                final isSelected = _courtController.text
                                    .split(',')
                                    .map((e) => e.trim())
                                    .contains(preset);
                                return AppFilterChip(
                                  selected: isSelected,
                                  label: Text(
                                    preset,
                                    style: const TextStyle(
                                      fontSize: AppFontSize.caption,
                                    ),
                                  ),
                                  onSelected: (_) {
                                    _toggleHeadingPreset(preset);
                                  },
                                );
                              },
                            ).toList(),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '🏆 回戦・ラウンド・試合順を選択',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children:
                                [
                                  '1回戦',
                                  '2回戦',
                                  '準決勝',
                                  '決勝戦',
                                  'Aリーグ',
                                  'Bリーグ',
                                  '3試合目',
                                  '5試合目',
                                ].map((preset) {
                                  final isSelected = _courtController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .contains(preset);
                                  return AppFilterChip(
                                    selected: isSelected,
                                    label: Text(
                                      preset,
                                      style: const TextStyle(
                                        fontSize: AppFontSize.caption,
                                      ),
                                    ),
                                    onSelected: (_) {
                                      _toggleHeadingPreset(preset);
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _noteController,
                            maxLines: 2,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: '試合のメモ・詳細コメント',
                              hintText: 'メモや追記事項があれば入力してください',
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF38383A)
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 4. 実行（生成）ボタン
                    GlassButton(
                      onPressed: _submit,
                      color: Colors.redAccent,
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

  Widget _buildTeamSelector(
    String colorLabel,
    List<Organization> orgs,
    bool isRed,
  ) {
    final currentOrg = isRed ? _redOrg : _whiteOrg;
    final currentTeam = isRed ? _redTeam : _whiteTeam;

    return Card(
      color: isRed ? Colors.red.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$colorLabelチーム選択',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                color: isRed ? Colors.red : Colors.black87,
              ),
            ),
            DropdownButton<Organization>(
              value: currentOrg,
              isExpanded: true,
              hint: const Text('組織（道場・学校）を選択'),
              items: orgs
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.name)))
                  .toList(),
              onChanged: (val) => setState(() {
                if (isRed) {
                  _redOrg = val;
                  _redTeam = null;
                } else {
                  _whiteOrg = val;
                  _whiteTeam = null;
                }
              }),
            ),
            if (currentOrg != null) ...[
              const SizedBox(height: AppSpacing.sm),
              StreamBuilder<List<TeamTemplate>>(
                stream: ref
                    .watch(organizationRepositoryProvider)
                    .watchTeamTemplates(currentOrg.id),
                builder: (context, snapshot) {
                  final teams = snapshot.data ?? [];
                  return DropdownButton<TeamTemplate>(
                    value: currentTeam,
                    isExpanded: true,
                    hint: const Text('チームテンプレを選択'),
                    items: teams
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.name)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      if (isRed) {
                        _redTeam = val;
                      } else {
                        _whiteTeam = val;
                      }
                    }),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ★ Phase 3 追加: 絶対に空欄タップ時のみ出現する最強のオートコンプリート
  Widget _buildSmartAutocomplete({
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> suggestions,
    required String labelText,
    required bool isDark,
  }) {
    bool isTapped = false; // ボトムシート的な動きをさせるためのローカルフラグ

    return StatefulBuilder(
      builder: (context, setState) {
        return RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            // 確実な制御：フォーカスが無い、またはタップされていない時は絶対に出さない
            if (!focusNode.hasFocus || !isTapped) {
              return const Iterable<String>.empty();
            }
            final query = textEditingValue.text.trim();
            // 空欄の場合は全件表示、入力があれば絞り込み
            if (query.isEmpty) {
              return suggestions;
            }
            return suggestions.where((s) => s.contains(query));
          },
          fieldViewBuilder:
              (context, fieldController, textFieldFocusNode, onFieldSubmitted) {
                return TextField(
                  controller: fieldController,
                  focusNode: textFieldFocusNode,
                  onTap: () {
                    setState(() {
                      isTapped = true;
                    });
                    // 魔法のハック：1文字空欄を入れて戻すことで、Flutterのキャッシュを貫通して強制的にリストを描画する
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final currentVal = fieldController.value;
                      fieldController.value = const TextEditingValue(text: ' ');
                      fieldController.value = currentVal;
                    });
                  },
                  onChanged: (text) {
                    setState(() {
                      isTapped = true;
                    });
                  },
                  onSubmitted: (text) {
                    setState(() {
                      isTapped = false;
                    });
                    onFieldSubmitted();
                  },
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: labelText,
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Colors.blueGrey,
                    ),
                    suffixIcon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(borderRadius: AppRadius.small),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.small,
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.small,
                      borderSide: BorderSide(color: Colors.redAccent),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8.0,
                borderRadius: AppRadius.medium,
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 250,
                    // 親がmaxWidth:600なので、画面幅に応じて適切に制限
                    maxWidth: MediaQuery.of(context).size.width > 600
                        ? 568
                        : MediaQuery.of(context).size.width - 32,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        onTap: () {
                          onSelected(option);
                          setState(() {
                            isTapped = false;
                          }); // 選択完了後にフラグを下げてリストを隠す
                          FocusScope.of(context).unfocus(); // キーボードも隠す
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
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
                color: Colors.grey,
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
                  color: Colors.indigo.shade50,
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Text(
                  '部門ルール適用中: $cleanCategory',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: Colors.indigo.shade800,
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
            accentColor: Colors.amber,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            sceneId: 'honsen',
            title: '🏆 本戦ルール（午後・トーナメント）',
            subText:
                '時間: ${ruleSet.normalRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.normalRule.isRunningTime ? '流し' : '正式'}) / 延長: ${ruleSet.normalRule.isEnchoUnlimited ? '無制限' : (ruleSet.normalRule.enchoCount > 0 ? 'あり' : 'なし')}',
            accentColor: Colors.indigo,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            sceneId: 'moushiawase',
            title: '🤝 申し合わせルール（終了後・自由戦）',
            subText:
                '時間: ${ruleSet.moushiawaseRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.moushiawaseRule.isRunningTime ? '流し' : '正式'}) / 引き分け: ${ruleSet.moushiawaseRule.hasHantei ? 'あり' : 'なし'}',
            accentColor: Colors.teal,
            isDark: isDark,
          ),
        ] else if (ruleSet != null) ...[
          _buildRuleCard(
            sceneId: 'honsen',
            title: '🏆 本戦（通常戦）ルール',
            subText:
                '時間: ${ruleSet.normalRule.matchTimeMinutes.toStringAsFixed(0)}分 (${ruleSet.normalRule.isRunningTime ? '流し' : '正式'}) / 延長: ${ruleSet.normalRule.isEnchoUnlimited ? '無制限' : (ruleSet.normalRule.enchoCount > 0 ? 'あり' : 'なし')}',
            accentColor: Colors.indigo,
            isDark: isDark,
          ),
        ] else ...[
          _buildRuleCard(
            sceneId: 'renseikai',
            title: '⚔️ 錬成会（練習試合）',
            subText: '2分流し / 引き分けあり',
            accentColor: Colors.amber,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            sceneId: 'honsen',
            title: '🏆 本戦（通常戦）',
            subText: '3分正式 / 代表戦・勝敗重視',
            accentColor: Colors.indigo,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRuleCard(
            sceneId: 'moushiawase',
            title: '🤝 申し合わせ（自由対戦）',
            subText: '2分流し / 引き分けあり',
            accentColor: Colors.teal,
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
      color: Colors.transparent,
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
                : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: isSelected
                  ? (isDark ? accentColor.shade300 : accentColor.shade700)
                  : (isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
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
                    : Colors.grey,
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
                            ? (isDark ? Colors.white : accentColor.shade900)
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: isSelected
                            ? (isDark ? Colors.white70 : accentColor.shade800)
                            : Colors.grey.shade600,
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
