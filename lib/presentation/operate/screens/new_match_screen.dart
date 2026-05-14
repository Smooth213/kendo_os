import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/organization.dart';
import '../providers/match_generator_provider.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart'; // ★ 追加
import 'package:kendo_os/infrastructure/repository/organization_repository.dart';

// ★ Phase 3 追加: サジェスト用のデータソース
import '../providers/match_list_provider.dart';
import 'package:kendo_os/domain/entities/player_model.dart';
import 'package:kendo_os/infrastructure/repository/player_repository.dart';

// 選手マスタ取得用プロバイダ
final newMatchPlayerMasterProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
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

  final _redNameController = TextEditingController();
  final _whiteNameController = TextEditingController();
  final _leagueParticipantsController = TextEditingController();
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
    _noteController.dispose();
    _categoryController.dispose();
    _redFocusNode.dispose();
    _whiteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgsStream = ref.watch(organizationRepositoryProvider).watchOrganizations();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ★ Phase 3 追加: サジェスト候補の統合（マスタ＋履歴）
    final masterPlayers = ref.watch(newMatchPlayerMasterProvider).value ?? [];
    final history = ref.watch(newMatchHistoryProvider);
    final Set<String> combinedSet = {};
    for (var p in masterPlayers) { combinedSet.add(p.name); }
    combinedSet.addAll(history);
    final combinedSuggestions = combinedSet.toList();
    combinedSuggestions.sort();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('新規試合作成・自動生成', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 生成モード選択
                  InputDecorator(
                    decoration: const InputDecoration(labelText: '生成モード', border: OutlineInputBorder()),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _creationMode,
                        isExpanded: true,
                        items: ['単発試合', '団体戦テンプレ生成', 'リーグ戦自動生成'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() {
                          _creationMode = val!;
                          _redOrg = null; _redTeam = null; _whiteOrg = null; _whiteTeam = null;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
    
                  // 2. メタデータ（練習試合フラグ）トグル
                  SwitchListTile(
                    title: const Text('星取表（ランキング）に集計する', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('練習試合の場合はオフにしてください'),
                    value: _countForStandings,
                    onChanged: (val) => setState(() => _countForStandings = val),
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
                    const SizedBox(height: 16),
                    _buildSmartAutocomplete(
                      controller: _whiteNameController,
                      focusNode: _whiteFocusNode,
                      suggestions: combinedSuggestions,
                      labelText: '白の選手名（またはチーム名）',
                      isDark: isDark,
                    ),
                  ] else if (_creationMode == 'リーグ戦自動生成') ...[
                    const Text('参加チーム（選手）をカンマ( , )区切りで入力してください\n例: Aチーム, Bチーム, C道場, D剣友会', style: TextStyle(color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _leagueParticipantsController,
                      decoration: const InputDecoration(labelText: '参加者リスト', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ] else if (_creationMode == '団体戦テンプレ生成') ...[
                    StreamBuilder<List<Organization>>(
                      stream: orgsStream,
                      builder: (context, snapshot) {
                        final orgs = snapshot.data ?? [];
                        if (orgs.isEmpty) return const Text('マスタ管理で組織とチームを登録してください', style: TextStyle(color: Colors.red));
                        return Column(
                          children: [
                            _buildTeamSelector('赤', orgs, true),
                            const SizedBox(height: 16),
                            _buildTeamSelector('白', orgs, false),
                          ],
                        );
                      }
                    ),
                  ],
                  
                  const SizedBox(height: 32),
    
                  const SizedBox(height: 16),
                  TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'カテゴリ（例：小学生の部）', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _noteController, decoration: const InputDecoration(labelText: '試合詳細（例：1回戦 第3試合）', border: OutlineInputBorder())),
                  const SizedBox(height: 32),
                  
                  // 4. 実行（生成）ボタン
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.flash_on),
                    label: Text('$_creationMode を実行', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50), 
                      backgroundColor: Colors.redAccent, 
                      foregroundColor: Colors.white
                    ),
                  ),
                ],
              ),
            ),
          ),
        ), 
      ),
    );
  }

  Widget _buildTeamSelector(String colorLabel, List<Organization> orgs, bool isRed) {
    final currentOrg = isRed ? _redOrg : _whiteOrg;
    final currentTeam = isRed ? _redTeam : _whiteTeam;

    return Card(
      color: isRed ? Colors.red.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$colorLabelチーム選択', style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black87)),
            DropdownButton<Organization>(
              value: currentOrg,
              isExpanded: true,
              hint: const Text('組織（道場・学校）を選択'),
              items: orgs.map((o) => DropdownMenuItem(value: o, child: Text(o.name))).toList(),
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
              const SizedBox(height: 8),
              StreamBuilder<List<TeamTemplate>>(
                stream: ref.watch(organizationRepositoryProvider).watchTeamTemplates(currentOrg.id),
                builder: (context, snapshot) {
                  final teams = snapshot.data ?? [];
                  return DropdownButton<TeamTemplate>(
                    value: currentTeam,
                    isExpanded: true,
                    hint: const Text('チームテンプレを選択'),
                    items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: (val) => setState(() {
                      if (isRed) {
                        _redTeam = val;
                      } else {
                        _whiteTeam = val;
                      }
                    }),
                  );
                }
              ),
            ]
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
          fieldViewBuilder: (context, fieldController, textFieldFocusNode, onFieldSubmitted) {
            return TextField(
              controller: fieldController,
              focusNode: textFieldFocusNode,
              onTap: () {
                setState(() { isTapped = true; });
                // 魔法のハック：1文字空欄を入れて戻すことで、Flutterのキャッシュを貫通して強制的にリストを描画する
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final currentVal = fieldController.value;
                  fieldController.value = const TextEditingValue(text: ' ');
                  fieldController.value = currentVal;
                });
              },
              onChanged: (text) {
                setState(() { isTapped = true; });
              },
              onSubmitted: (text) {
                setState(() { isTapped = false; });
                onFieldSubmitted();
              },
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: labelText,
                prefixIcon: const Icon(Icons.person, color: Colors.blueGrey),
                suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade400)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.redAccent)),
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
                borderRadius: BorderRadius.circular(12),
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 250, 
                    // 親がmaxWidth:600なので、画面幅に応じて適切に制限
                    maxWidth: MediaQuery.of(context).size.width > 600 ? 568 : MediaQuery.of(context).size.width - 32
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.add_circle_outline, color: Colors.redAccent, size: 18),
                        onTap: () {
                          onSelected(option);
                          setState(() { isTapped = false; }); // 選択完了後にフラグを下げてリストを隠す
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
      }
    );
  }

  Future<void> _submit() async {
    final generator = ref.read(matchGeneratorProvider);
    
    if (_creationMode == '単発試合') {
      if (_redNameController.text.isEmpty || _whiteNameController.text.isEmpty) return;
      if (widget.tournamentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('大会IDが不明なため保存できません')));
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
        note: _noteController.text, 
      );
      await ref.read(matchApplicationServiceProvider).saveMatch(newMatch); // ★ 修正
      
    } else if (_creationMode == 'リーグ戦自動生成') {
      final participants = _leagueParticipantsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (participants.length < 2) return;
      await generator.generateLeagueMatches(_categoryController.text, participants, _countForStandings, _noteController.text, widget.tournamentId); 
      
    } else if (_creationMode == '団体戦テンプレ生成') {
      if (_redOrg == null || _redTeam == null || _whiteOrg == null || _whiteTeam == null) return;
      await generator.generateTeamMatchBouts(
        _redTeam!.name, _redTeam!.orderedMemberNames,
        _whiteTeam!.name, _whiteTeam!.orderedMemberNames,
        _countForStandings,
        category: _categoryController.text, 
        note: _noteController.text,
        tournamentId: widget.tournamentId,
      );
    }
    
    if (!mounted) return;
    Navigator.pop(context);
  }
}