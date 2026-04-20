import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/organization.dart';
import '../providers/match_command_provider.dart';
import '../providers/match_generator_provider.dart';
import '../repositories/organization_repository.dart';

class NewMatchScreen extends ConsumerStatefulWidget {
  const NewMatchScreen({super.key});

  @override
  ConsumerState<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends ConsumerState<NewMatchScreen> {
  String _creationMode = '単発試合';
  bool _countForStandings = true;

  final _redNameController = TextEditingController();
  final _whiteNameController = TextEditingController();
  final _leagueParticipantsController = TextEditingController();
  final _noteController = TextEditingController(); // ★ 追加
  final _categoryController = TextEditingController(); // ★ カテゴリ入力用も追加

  Organization? _redOrg;
  TeamTemplate? _redTeam;
  Organization? _whiteOrg;
  TeamTemplate? _whiteTeam;

  @override
  void dispose() {
    _redNameController.dispose();
    _whiteNameController.dispose();
    _leagueParticipantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgsStream = ref.watch(organizationRepositoryProvider).watchOrganizations();

    return Scaffold(
      appBar: AppBar(title: const Text('新規試合作成・自動生成', style: TextStyle(fontWeight: FontWeight.bold))),
      // ★ Phase 8-2: フォーム全体を中央に配置し、最大幅を600pxに制限（iPadの間延び防止）
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 生成モード選択（★Flutter最新仕様に合わせてDropdownButtonへ変更）
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
    
                  // 2. メタデータ（練習試合フラグ）トグル（★activeThumbColorへ変更）
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
                    TextField(controller: _redNameController, decoration: const InputDecoration(labelText: '赤の選手名（またはチーム名）')),
                    const SizedBox(height: 16),
                    TextField(controller: _whiteNameController, decoration: const InputDecoration(labelText: '白の選手名（またはチーム名）')),
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
    
                  // 110行目付近（実行ボタンの前）
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
        ), // ★ ConstrainedBox の閉じ
      ),
      // ★ Center の閉じ
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
            
            // ★Flutter最新仕様に合わせてDropdownButtonへ変更
            DropdownButton<Organization>(
              value: currentOrg,
              isExpanded: true,
              hint: const Text('組織（道場・学校）を選択'),
              items: orgs.map((o) => DropdownMenuItem(value: o, child: Text(o.name))).toList(),
              onChanged: (val) => setState(() {
                // ★波カッコを追加
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
                      // ★波カッコを追加
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

  

  Future<void> _submit() async {
    // ★ 修正: それぞれの専門家を呼び出す
    final command = ref.read(matchCommandProvider);
    final generator = ref.read(matchGeneratorProvider);
    
    if (_creationMode == '単発試合') {
      if (_redNameController.text.isEmpty || _whiteNameController.text.isEmpty) return;
      final newMatch = MatchModel(
        id: '',
        matchType: '個人戦',
        redName: _redNameController.text,
        whiteName: _whiteNameController.text,
        source: 'manual',
        countForStandings: _countForStandings,
      );
      await command.saveMatch(newMatch);
      
    // 160行目付近
    } else if (_creationMode == 'リーグ戦自動生成') {
      final participants = _leagueParticipantsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (participants.length < 2) return;
      await generator.generateLeagueMatches(_categoryController.text, participants, _countForStandings, _noteController.text); // ★ 第4引数にnoteを追加
      
    } else if (_creationMode == '団体戦テンプレ生成') {
      if (_redOrg == null || _redTeam == null || _whiteOrg == null || _whiteTeam == null) return;
      await generator.generateTeamMatchBouts(
        _redTeam!.name, _redTeam!.orderedMemberNames,
        _whiteTeam!.name, _whiteTeam!.orderedMemberNames,
        _countForStandings,
        category: _categoryController.text, // ★ カテゴリを渡す
        note: _noteController.text, // ★ noteを渡す
      );
    }
    
    // ★context.mounted から mounted に変更
    if (!mounted) return;
    Navigator.pop(context);
  }
}