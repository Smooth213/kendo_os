import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import '../providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart'; // ★ MatchRuleモデルを読み込む
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart'; // ファイル上部
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

final noteHistoryProvider = StateProvider<List<String>>((ref) {
  return ['1回戦', '2回戦', '準決勝', '決勝', '第1試合', '第2コート'];
});

// ★ 選手一覧を取得するProviderを追加
final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

class SetupMatchFormatScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const SetupMatchFormatScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<SetupMatchFormatScreen> createState() =>
      _SetupMatchFormatScreenState();
}

class _SetupMatchFormatScreenState
    extends ConsumerState<SetupMatchFormatScreen> {
  late AppThemeColors _themeColors;
  late String _matchType;
  late bool _hasExtension;
  late bool _hasHantei;
  late double _matchTime;
  late bool _isRunningTime;
  late bool _isRenseikai;
  String? _selectedTeamId;

  late String _kachinukiUnlimitedType;
  late bool _hasLeagueDaihyo;
  late String _renseikaiType;
  final _overallTimeController = TextEditingController(text: '30');
  late bool _isDaihyoIpponShobu;

  // 代表戦詳細
  late double _daihyoMatchTime;
  late bool _daihyoHasExtension;
  late double _daihyoEnchoTime;
  late int _daihyoEnchoCount;
  late bool _daihyoHasHantei;

  // 勝負方式・反則
  late bool _isIpponShobu;
  late int _ipponLimit;
  late int _hansokuLimit;

  // ★ リーグ戦拡張：勝ち点入力用のコントローラー
  final _winPointController = TextEditingController(text: '0');
  final _lossPointController = TextEditingController(text: '0');
  final _drawPointController = TextEditingController(text: '0');

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ★ 追加：2段階選択用の状態変数
  late String _selectedMajorCategory;
  late String _selectedMinorCategory;
  String _selectedRuleScene =
      'honsen'; // 'renseikai', 'honsen', 'moushiawase', 'advanced'

  // ★ 追加：チーム登録画面と共通！最終的なカテゴリ名を生成
  String get _category {
    if (_selectedMajorCategory == '初心者') return '初心者の部';
    if (_selectedMajorCategory == '幼年') return '幼年の部';
    if (_selectedMinorCategory == '全体') return '$_selectedMajorCategoryの部';
    if (_selectedMajorCategory == '大学・一般') return '$_selectedMinorCategoryの部';
    return '$_selectedMajorCategory$_selectedMinorCategoryの部';
  }

  // ★ 追加：初期化時に文字列からUI状態を復元するロジック
  void _parseCategoryToState(String categoryName) {
    if (categoryName == '初心者の部') {
      _selectedMajorCategory = '初心者';
      _selectedMinorCategory = '全体';
      return;
    }
    if (categoryName == '幼年の部') {
      _selectedMajorCategory = '幼年';
      _selectedMinorCategory = '全体';
      return;
    }
    final cleanCat = categoryName.replaceAll('の部', '');
    if (['大学生', '一般', 'シニア'].contains(cleanCat)) {
      _selectedMajorCategory = '大学・一般';
      _selectedMinorCategory = cleanCat;
      return;
    }
    for (var major in ['小学生', '中学生', '高校生']) {
      if (cleanCat.startsWith(major)) {
        _selectedMajorCategory = major;
        final minor = cleanCat.substring(major.length);
        _selectedMinorCategory = minor.isEmpty ? '全体' : minor;
        return;
      }
    }
    _selectedMajorCategory = '小学生';
    _selectedMinorCategory = '低学年';
  }

  final List<String> _majorCategories = [
    '初心者',
    '幼年',
    '小学生',
    '中学生',
    '高校生',
    '大学・一般',
  ];

  List<String> _getMinorCategories(String major) {
    if (major == '初心者' || major == '幼年') {
      return ['全体', '男子', '女子'];
    }
    if (major == '小学生') {
      return [
        '全体',
        '低学年',
        '高学年',
        '1年',
        '2年',
        '3年',
        '4年',
        '5年',
        '6年',
        '男子',
        '女子',
      ];
    }
    if (major == '中学生' || major == '高校生') {
      return ['全体', '1年', '2年', '3年', '男子', '女子'];
    }
    if (major == '大学・一般') {
      return ['全体', '大学生', '一般', 'シニア', '男子', '女子'];
    }
    return ['全体'];
  }

  @override
  void initState() {
    super.initState();
    final lastSettings = ref.read(lastUsedSettingsProvider);
    _matchType = lastSettings['matchType'];

    // ★ 修正：前回のカテゴリ設定を2段階UIの状態に美しく復元
    _parseCategoryToState(lastSettings['category'] ?? '小学生低学年の部');

    _matchTime = lastSettings['matchTime'];
    _isRunningTime = lastSettings['isRunningTime'];
    _hasExtension = lastSettings['hasExtension'];
    _hasHantei = lastSettings['hasHantei'];
    _isRenseikai = lastSettings['isRenseikai'] ?? false;

    _kachinukiUnlimitedType = lastSettings['kachinukiUnlimitedType'] ?? '大将対大将';
    _hasLeagueDaihyo = lastSettings['hasLeagueDaihyo'] ?? false;
    _renseikaiType = lastSettings['renseikaiType'] ?? '一試合制';
    _isDaihyoIpponShobu = lastSettings['isDaihyoIpponShobu'] ?? true;

    // 代表戦詳細
    _daihyoMatchTime =
        (lastSettings['daihyoMatchTime'] as num?)?.toDouble() ?? 0.0;
    _daihyoHasExtension = lastSettings['daihyoHasExtension'] ?? true;
    _daihyoEnchoTime =
        (lastSettings['daihyoEnchoTime'] as num?)?.toDouble() ?? 3.0;
    _daihyoEnchoCount = lastSettings['daihyoEnchoCount'] ?? -2;
    _daihyoHasHantei = lastSettings['daihyoHasHantei'] ?? false;

    // 勝負方式・反則
    _isIpponShobu = lastSettings['isIpponShobu'] ?? false;
    _ipponLimit = lastSettings['ipponLimit'] ?? 2;
    _hansokuLimit = lastSettings['hansokuLimit'] ?? 2;

    // ★ 勝ち点の初期値を復元
    _winPointController.text = (lastSettings['winPoint'] ?? 0).toString();
    _lossPointController.text = (lastSettings['lossPoint'] ?? 0).toString();
    _drawPointController.text = (lastSettings['drawPoint'] ?? 0).toString();

    // Note変更監視
    _noteController.addListener(_onNoteChanged);

    // 初期のカテゴリールール読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryRules();
    });
  }

  final _noteController = TextEditingController();
  final _courtController = TextEditingController();

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

  int _extCount = -2;
  double _extTime = -2.0;

  String _formatMinutesText(double time) {
    if (time <= 0) return '0分';
    final mins = time.floor();
    final secs = ((time - mins) * 60).round();
    if (mins == 0) {
      return '$secs秒';
    }
    if (secs == 0) {
      return '$mins分';
    }
    return '$mins分$secs秒';
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    _courtController.dispose();
    _overallTimeController.dispose();
    _winPointController.dispose();
    _lossPointController.dispose();
    _drawPointController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ★ 修正：詳細ダイアログ内でスマート・スワップを実行し、保存まで行う
  void _showTeamDetailDialog(BuildContext context, TeamModel team) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // ダイアログ内の状態更新のため
        builder: (context, setDialogState) {
          final List<String> posNames = _generatePositions(
            team.playerNames.length,
          );

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _themeColors.primaryAccent,
                          _themeColors.primaryAccent.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.shield, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.teamName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${team.category} / ${team.matchType}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16, left: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'オーダー（タップして入れ替え）',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      itemCount: team.playerNames.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final String posName = i < posNames.length
                            ? posNames[i]
                            : '補欠';
                        final String name = team.playerNames[i].isEmpty
                            ? '未設定'
                            : team.playerNames[i];
                        final bool isSub = posName == '補欠';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            // 選手選択とスワップを実行
                            final newTeam = await _selectAndSwapPlayer(
                              context,
                              i,
                              team,
                              posNames,
                            );
                            if (newTeam != null) {
                              setDialogState(() {
                                team = newTeam;
                              }); // ダイアログの表示を更新
                              setState(() {}); // 親画面のリストも更新
                            }
                          },
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isSub
                                ? Colors.orange.shade50
                                : _themeColors.softAccent,
                            child: Text(
                              isSub ? '補' : posName.substring(0, 1),
                              style: TextStyle(
                                color: isSub
                                    ? Colors.orange.shade700
                                    : _themeColors.primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: name == '未設定'
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            posName,
                            style: TextStyle(
                              color: isSub
                                  ? Colors.orange.shade600
                                  : _themeColors.primaryAccent,
                              fontSize: 11,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.swap_vert,
                            color: Colors.grey,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '完了',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _themeColors.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ★ スマート・スワップを実行してDBに保存するヘルパー
  Future<TeamModel?> _selectAndSwapPlayer(
    BuildContext context,
    int index,
    TeamModel team,
    List<String> posNames,
  ) async {
    final playerListAsync = ref.read(playerListProvider);
    final players = playerListAsync.value ?? [];

    // 現在のチームメンバーのうち、名簿にいない「手入力選手」を抽出
    final helperEntries = team.playerNames
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty && e.value != '欠員')
        .where((e) => !players.any((p) => p.name == e.value))
        .toList();

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 16,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${posNames[index]} の選択',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      if (helperEntries.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '手入力選手から選ぶ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        ...helperEntries.map(
                          (entry) => Card(
                            color: Colors.orange.shade50,
                            child: ListTile(
                              title: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                '${entry.key < posNames.length ? posNames[entry.key] : "補欠"}と入替',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx, entry.value),
                            ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '登録名簿から選ぶ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _themeColors.primaryAccent,
                          ),
                        ),
                      ),
                      ...players.map((p) {
                        final usedIdx = team.playerNames.indexOf(p.name);
                        final isUsed = usedIdx != -1 && usedIdx != index;
                        return ListTile(
                          title: Text(p.name),
                          trailing: isUsed
                              ? Text(
                                  '${usedIdx < posNames.length ? posNames[usedIdx] : "補欠"}と入替',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.pop(ctx, p.name),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected != null) {
      List<String> newOrder = List.from(team.playerNames);
      int existingIdx = newOrder.indexOf(selected);

      if (existingIdx != -1) {
        // スワップ
        String currentOccupant = newOrder[index];
        newOrder[existingIdx] = currentOccupant;
      }
      newOrder[index] = selected;

      final updatedTeam = team.copyWith(playerNames: newOrder);
      await ref.read(teamRepositoryProvider).saveTeam(updatedTeam);
      return updatedTeam;
    }
    return null;
  }

  List<String> _generatePositions(int size) {
    if (size <= 0) return [];
    if (size == 1) return ['選手'];
    if (size == 3) return ['先鋒', '中堅', '大将'];
    if (size == 5) return ['先鋒', '次鋒', '中堅', '副将', '大将'];

    List<String> positions = [];
    positions.add('先鋒');
    if (size >= 2) positions.add('次鋒');

    for (int i = 3; i <= size - 2; i++) {
      if (size % 2 != 0 && i == (size + 1) ~/ 2) {
        positions.add('中堅');
      } else {
        int k = size - i + 1;
        positions.add('$k将');
      }
    }

    if (size >= 4) positions.add('副将');
    if (size >= 3) positions.add('大将');

    return positions;
  }

  Widget _buildDynamicSectionBox({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const Divider(),
              child,
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildTextFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: _themeColors.subTextColor),
      hintText: hintText,
      hintStyle: TextStyle(color: _themeColors.hintColor),
      suffixText: suffixText,
      suffixStyle: TextStyle(color: _themeColors.subTextColor),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: _themeColors.inputBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _themeColors.separatorColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _themeColors.primaryAccent, width: 2),
      ),
    );
  }

  // ★ 不要になった _buildImmersiveAppBar を削除し、スッキリさせます

  Widget _buildDynamicHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ★ Phase 8-1: 画面が横向き（かつ高さ500以下）のスマホ・タブレットではヘッダーを隠して作業領域を確保
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        if (isLandscape && MediaQuery.of(context).size.height < 500) {
          return const SizedBox.shrink();
        }

        final t = (_currentPage / 1).clamp(0.0, 1.0);

        final color1 = _themeColors.primaryAccent;
        final color2 = _themeColors.primaryAccent.withValues(alpha: 0.8);
        final endColor = _themeColors.softAccent;

        final gradientColor = Color.lerp(color1, color2, t)!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '試合ルールの設定',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '魔法のウィザードに従って、\n2つのステップで条件を設定しましょう',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: (_currentPage + 1) / 2,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 13,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRuleRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : _themeColors.softAccent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : _themeColors.primaryAccent.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : _themeColors.textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ★ 部門別ルールの自動読み込み & 連動ロジック
  // ==========================================
  String? _manualRoundTypeOverride;
  String _lastCheckedNote = '';

  bool get _isCurrentMatchAdvanced {
    if (_manualRoundTypeOverride != null) {
      return _manualRoundTypeOverride == 'advanced';
    }
    return _isAdvancedMatchName(_noteController.text);
  }

  bool _isAdvancedMatchName(String note) {
    final cleanNote = note.toLowerCase().trim();
    List<String> keywords = [
      '準決勝',
      '準決',
      'じゅんけつ',
      'ベスト4',
      'b4',
      'sf',
      'semifinal',
      '准決',
      '順決',
      '決勝',
      'けっしょう',
      'ファイナル',
      'final',
      '結勝',
      '決勝戦',
      '3位決定',
      '3決',
      '三決',
    ];

    final categoryName = _category;
    final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
    asyncTourney.whenData((tournament) {
      if (tournament != null) {
        final ruleSet = tournament.categoryRules[categoryName];
        if (ruleSet != null && ruleSet.advancedKeywords.isNotEmpty) {
          keywords = ruleSet.advancedKeywords
              .map((kw) => kw.toLowerCase().trim())
              .toList();
        }
      }
    });

    String testNote = cleanNote;
    final hasSemisKeyword = keywords.any(
      (kw) =>
          kw.contains('準決') ||
          kw.contains('準決勝') ||
          kw.contains('ベスト4') ||
          kw.contains('sf'),
    );
    if (!hasSemisKeyword) {
      testNote = testNote
          .replaceAll('準決勝', '')
          .replaceAll('準決', '')
          .replaceAll('准決', '')
          .replaceAll('順決', '')
          .replaceAll('じゅんけつ', '')
          .replaceAll('semifinal', '')
          .replaceAll('sf', '')
          .replaceAll('3位決定', '')
          .replaceAll('3決', '')
          .replaceAll('三決', '');
    }

    return keywords.any((kw) => kw.isNotEmpty && testNote.contains(kw));
  }

  void _onNoteChanged() {
    final currentNote = _noteController.text;
    if (currentNote == _lastCheckedNote) return;
    _lastCheckedNote = currentNote;

    if (_manualRoundTypeOverride != null) return;

    final categoryName = _category;
    final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
    asyncTourney.whenData((tournament) {
      if (tournament != null) {
        final categoryRules = tournament.categoryRules;
        if (categoryRules.containsKey(categoryName)) {
          final ruleSet = categoryRules[categoryName]!;
          if (ruleSet.useAdvancedRule) {
            final isAdvanced = _isAdvancedMatchName(currentNote);
            final targetRule = isAdvanced
                ? ruleSet.advancedRule
                : ruleSet.normalRule;
            _applyMatchRuleToState(targetRule);
          }
        }
      }
    });
  }

  void _loadCategoryRules() {
    final categoryName = _category;
    final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
    asyncTourney.whenData((tournament) {
      if (tournament != null) {
        final categoryRules = tournament.categoryRules;
        if (categoryRules.containsKey(categoryName)) {
          final ruleSet = categoryRules[categoryName]!;
          if (!ruleSet.useHonsenRule && _selectedRuleScene == 'honsen') {
            if (ruleSet.useRenseikaiRule) {
              _selectedRuleScene = 'renseikai';
            } else if (ruleSet.useMoushiawaseRule) {
              _selectedRuleScene = 'moushiawase';
            }
          }
          if (_selectedRuleScene == 'renseikai') {
            _applyMatchRuleToState(ruleSet.renseikaiRule);
            _isRenseikai = true;
          } else if (_selectedRuleScene == 'moushiawase') {
            _applyMatchRuleToState(ruleSet.moushiawaseRule);
            _isRenseikai = true;
          } else if (_selectedRuleScene == 'advanced' &&
              ruleSet.useAdvancedRule) {
            _applyMatchRuleToState(ruleSet.advancedRule);
            _isRenseikai = false;
          } else {
            final isAdvanced =
                _isCurrentMatchAdvanced && ruleSet.useAdvancedRule;
            final targetRule = isAdvanced
                ? ruleSet.advancedRule
                : ruleSet.normalRule;
            _applyMatchRuleToState(targetRule);
            _isRenseikai = false;
          }
        }
      }
    });
  }

  void _applyCategoryRuleScene(String scene, CategoryRuleSet ruleSet) {
    setState(() {
      _selectedRuleScene = scene;
      MatchRule targetRule;
      if (scene == 'renseikai') {
        targetRule = ruleSet.renseikaiRule;
        _isRenseikai = true;
        _renseikaiType = ruleSet.renseikaiRule.renseikaiType;
      } else if (scene == 'moushiawase') {
        targetRule = ruleSet.moushiawaseRule;
        _isRenseikai = true;
        _renseikaiType = ruleSet.moushiawaseRule.renseikaiType;
      } else if (scene == 'advanced') {
        targetRule = ruleSet.advancedRule;
        _isRenseikai = false;
      } else {
        targetRule = ruleSet.normalRule;
        _isRenseikai = false;
      }
      _applyMatchRuleToState(targetRule);
    });
  }

  void _applyMatchRuleToState(MatchRule rule) {
    setState(() {
      _matchTime = rule.matchTimeMinutes;
      _isRunningTime = rule.isRunningTime;

      // 延長
      _hasExtension = rule.enchoCount > 0 || rule.isEnchoUnlimited;
      if (rule.isEnchoUnlimited) {
        _extCount = -2;
      } else {
        _extCount = rule.enchoCount;
      }

      // 延長時間
      _extTime = rule.enchoTimeMinutes;

      _hasHantei = rule.hasHantei;
      _isRenseikai = rule.isRenseikai;
      _renseikaiType = rule.renseikaiType;
      _overallTimeController.text = rule.overallTimeMinutes.toString();

      // 勝ち点
      _winPointController.text = rule.winPoint.toString();
      _lossPointController.text = rule.lossPoint.toString();
      _drawPointController.text = rule.drawPoint.toString();

      // 追加されたフィールドの読み込み
      _kachinukiUnlimitedType = rule.kachinukiUnlimitedType;
      _hasLeagueDaihyo = rule.hasLeagueDaihyo;
      _isDaihyoIpponShobu = rule.isDaihyoIpponShobu;

      // 代表戦詳細
      _daihyoMatchTime = rule.daihyoMatchTimeMinutes;
      _daihyoHasExtension = rule.daihyoHasExtension;
      _daihyoEnchoTime = rule.daihyoEnchoTimeMinutes;
      _daihyoEnchoCount = rule.daihyoEnchoCount;
      _daihyoHasHantei = rule.daihyoHasHantei;

      // 勝負方式・反則
      _isIpponShobu = rule.isIpponShobu;
      _ipponLimit = rule.ipponLimit;
      _hansokuLimit = rule.hansokuLimit;
    });
  }

  void _setManualRoundType(String type) {
    setState(() {
      _manualRoundTypeOverride = type;
      final categoryName = _category;
      final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
      asyncTourney.whenData((tournament) {
        if (tournament != null) {
          final categoryRules = tournament.categoryRules;
          if (categoryRules.containsKey(categoryName)) {
            final ruleSet = categoryRules[categoryName]!;
            final isAdvanced = type == 'advanced';
            final targetRule = isAdvanced
                ? ruleSet.advancedRule
                : ruleSet.normalRule;
            _applyMatchRuleToState(targetRule);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    // ★ Phase 8-3: キーボードが開いているかを検知
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            '対戦フォーマット設定',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _themeColors.textColor,
            ),
          ),
          backgroundColor:
              ref.watch(settingsProvider.select((s) => s.enableLiquidGlass))
              ? Colors.transparent
              : _themeColors.cardBackground,
          iconTheme: IconThemeData(color: _themeColors.textColor),
          actions: const [
            // 大会設定のマニュアルへ
            ManualHelpButton(manualPath: 'docs/manuals/operator/settings.md'),
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // ★ キーボードが開いた時はヘッダーをスッと隠す
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              // ★ 修正: 不要な Column と _buildImmersiveAppBar を削り、直接ヘッダーを描画する
              child: isKeyboardOpen
                  ? const SizedBox.shrink()
                  : _buildDynamicHeader(),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage1Category(),
                  _buildPage2RuleSummaryAndDetails(),
                ],
              ),
            ),
            // ★ キーボードが開いた時は下のボタンも隠す
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isKeyboardOpen
                  ? const SizedBox.shrink()
                  : _buildStickyBottomAction(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1Category() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final selectedChipColor = _themeColors.softAccent;

    return ListView(
      // ★ Phase 8-2: 余白のないページ（2ページ目以降）に合わせるため、パディングを調整
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Text(
          '対象のカテゴリと\n自チームを選んでください',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: 32),

        // ★ 修正：カテゴリ大分類
        _buildSectionTitle('1. 対象カテゴリを選択（大分類）'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _majorCategories
              .map(
                (cat) => ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontWeight: _selectedMajorCategory == cat
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedMajorCategory == cat
                          ? _themeColors.primaryAccent
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  selected: _selectedMajorCategory == cat,
                  selectedColor: selectedChipColor,
                  onSelected: (s) => s
                      ? setState(() {
                          _selectedMajorCategory = cat;
                          _selectedMinorCategory = '全体';
                          _selectedTeamId = null;
                          _manualRoundTypeOverride = null; // リセット
                          _loadCategoryRules();
                        })
                      : null,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),

        // ★ 修正：カテゴリ小分類（大分類に応じて動的に現れる）
        _buildSectionTitle('2. 対象カテゴリを選択（小分類）'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getMinorCategories(_selectedMajorCategory).map((cat) {
            String label = cat;
            if (_selectedMajorCategory == '小学生') {
              if (cat == '低学年') label = '低学年 (1-4年)';
              if (cat == '高学年') label = '高学年 (5-6年)';
            }
            return ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontWeight: _selectedMinorCategory == cat
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedMinorCategory == cat
                      ? _themeColors.primaryAccent
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              selected: _selectedMinorCategory == cat,
              selectedColor: selectedChipColor,
              onSelected: (s) => s
                  ? setState(() {
                      _selectedMinorCategory = cat;
                      _selectedTeamId = null;
                      _manualRoundTypeOverride = null; // リセット
                      _loadCategoryRules();
                    })
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // ★ 修正：最終的に設定されるカテゴリ名のプレビュー表示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _themeColors.softAccent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeColors.primaryAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: _themeColors.primaryAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '設定されるカテゴリ名',
                      style: TextStyle(
                        fontSize: 12,
                        color: _themeColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionTitle('3. 出場する自チームを選択'), // ★ 番号を3に修正
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: () =>
                    context.push('/team-registration/${widget.tournamentId}'),
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text(
                  'チームを追加・編集',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _themeColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),

        ref
            .watch(registeredTeamsProvider(widget.tournamentId))
            .when(
              data: (teams) {
                final filteredTeams = teams
                    .where((t) => t.category == _category)
                    .toList();

                if (filteredTeams.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      // ★ 修正：赤系の警告色を完全に廃止し、iOS風の上品なEmpty State（空状態）デザインへ
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_off_outlined,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '「$_category」のチームが未登録です。\n右上の「チームを追加・編集」から\n登録を行ってください。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: filteredTeams.map((team) {
                    final isSelected = _selectedTeamId == team.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? (isDark ? 0 : 2) : 0,
                      color: isSelected
                          ? _themeColors.softAccent
                          : inputBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? _themeColors.primaryAccent
                              : (isDark
                                    ? const Color(0xFF38383A)
                                    : Colors.grey.shade200),
                          width: isSelected ? 2 : 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () => setState(() {
                              _selectedTeamId = team.id;
                              _matchType = team.matchType;
                            }),
                            contentPadding: EdgeInsets.only(
                              left: 20,
                              right: 16,
                              top: 12,
                              bottom: isSelected ? 4 : 12,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: isSelected
                                  ? _themeColors.softAccent
                                  : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.grey.shade100),
                              child: Icon(
                                Icons.shield,
                                color: isSelected
                                    ? _themeColors.primaryAccent
                                    : (isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              team.teamName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isSelected
                                    ? _themeColors.primaryAccent
                                    : textColor,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${team.matchType} / 選手: ${team.playerNames.where((n) => n.isNotEmpty).join(", ")}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? _themeColors.primaryAccent.withValues(
                                          alpha: 0.8,
                                        )
                                      : (isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? _themeColors.primaryAccent
                                  : (isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade300),
                              size: 28,
                            ),
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 16,
                                bottom: 16,
                                top: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _showTeamDetailDialog(context, team),
                                    icon: Icon(
                                      Icons.swap_horizontal_circle,
                                      color: _themeColors.primaryAccent,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'オーダーを調整',
                                      style: TextStyle(
                                        color: _themeColors.primaryAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF1C1C1E)
                                          : Colors.white,
                                      side: BorderSide(
                                        color: _themeColors.primaryAccent,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) =>
                  Text('エラー: $e', style: TextStyle(color: textColor)),
            ),
      ],
    );
  }

  Widget _buildPage2RuleSummaryAndDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final categoryName = _category;
    final asyncTourney = ref.watch(tournamentProvider(widget.tournamentId));
    final tournament = asyncTourney.valueOrNull;
    final ruleSet = tournament?.categoryRules[categoryName];

    final displayRuleName = _selectedRuleScene == 'renseikai'
        ? '⚔️ 錬成会ルール'
        : (_selectedRuleScene == 'moushiawase'
              ? '🤝 申し合わせルール'
              : (_selectedRuleScene == 'advanced'
                    ? '⭐ 上位戦ルール'
                    : '🏆 本戦（通常戦）ルール'));

    final isAdvanced =
        _selectedRuleScene == 'advanced' || _isCurrentMatchAdvanced;

    // 延長表示用のテキストを生成するヘルパー
    String getExtensionText() {
      if (!_hasExtension) return 'なし';
      final extTimeStr = _extTime == -2.0
          ? '時間無制限'
          : _formatMinutesText(_extTime);
      final extCountStr = _extCount == -2 ? '回数無制限' : '最大$_extCount回';
      return 'あり ($extTimeStr / $extCountStr)';
    }

    final headerColor = isAdvanced ? Colors.teal : _themeColors.primaryAccent;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '適用ルールの確認と\n詳細情報の入力',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),

        // ★ 部門設定ルールのシーン切り替えUI
        if (ruleSet != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              'この部門（$categoryName）に設定されているルールを選択:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (ruleSet.isMultiScene) ...[
                if (ruleSet.useRenseikaiRule)
                  ChoiceChip(
                    label: const Text('⚔️ 錬成会ルール'),
                    selected: _selectedRuleScene == 'renseikai',
                    selectedColor: Colors.amber.shade200,
                    onSelected: (selected) {
                      if (selected) {
                        _applyCategoryRuleScene('renseikai', ruleSet);
                      }
                    },
                  ),
                if (ruleSet.useHonsenRule)
                  ChoiceChip(
                    label: const Text('🏆 本戦ルール'),
                    selected: _selectedRuleScene == 'honsen',
                    selectedColor: Colors.indigo.shade200,
                    onSelected: (selected) {
                      if (selected) {
                        _applyCategoryRuleScene('honsen', ruleSet);
                      }
                    },
                  ),
                if (ruleSet.useMoushiawaseRule)
                  ChoiceChip(
                    label: const Text('🤝 申し合わせルール'),
                    selected: _selectedRuleScene == 'moushiawase',
                    selectedColor: Colors.teal.shade200,
                    onSelected: (selected) {
                      if (selected) {
                        _applyCategoryRuleScene('moushiawase', ruleSet);
                      }
                    },
                  ),
              ] else if (ruleSet.useHonsenRule) ...[
                ChoiceChip(
                  label: const Text('🏆 通常戦ルール'),
                  selected: _selectedRuleScene == 'honsen',
                  selectedColor: Colors.indigo.shade200,
                  onSelected: (selected) {
                    if (selected) {
                      _applyCategoryRuleScene('honsen', ruleSet);
                    }
                  },
                ),
              ],
              if (ruleSet.useAdvancedRule)
                ChoiceChip(
                  label: const Text('⭐ 上位戦ルール'),
                  selected: _selectedRuleScene == 'advanced',
                  selectedColor: Colors.deepOrange.shade200,
                  onSelected: (selected) {
                    if (selected) _applyCategoryRuleScene('advanced', ruleSet);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        _buildDynamicSectionBox(
          title: '現在適用中のルール: $displayRuleName',
          icon: isAdvanced ? Icons.stars : Icons.gavel,
          color: isAdvanced ? Colors.teal : _themeColors.primaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 錢成会設定 ───
              if (_isRenseikai) ...[
                _buildSectionHeader('錬成会設定', headerColor),
                _buildReadOnlyRuleRow('進行方式', _renseikaiType),
                _buildReadOnlyRuleRow('1対戦の時間', _formatMinutesText(_matchTime)),
                if (_renseikaiType == '時間制')
                  _buildReadOnlyRuleRow(
                    '全体の制限時間',
                    '${int.tryParse(_overallTimeController.text) ?? 30}分',
                  ),
              ],

              // ─── 試合ルール（錬成会以外） ───
              if (!_isRenseikai) ...[
                _buildSectionHeader('試合ルール', headerColor),
                _buildReadOnlyRuleRow('試合方式', _matchType),
                _buildReadOnlyRuleRow(
                  '試合時間',
                  '${_formatMinutesText(_matchTime)} (${_isRunningTime ? "ランニング計測" : "通常計測"})',
                ),
                _buildReadOnlyRuleRow(
                  '勝負方式',
                  _isIpponShobu ? '一本勝負' : '三本勝負 ($_ipponLimit本先取)',
                ),
                _buildReadOnlyRuleRow('反則', '$_hansokuLimit反則で負け'),
                _buildReadOnlyRuleRow('延長戦', getExtensionText()),
                _buildReadOnlyRuleRow('判定', _hasHantei ? '引き分け時に判定あり' : 'なし'),
              ],

              // ─── 勝ち抜き戦設定 ───
              if (_matchType == '勝ち抜き戦') ...[
                _buildSectionHeader('勝ち抜き戦設定', headerColor),
                _buildReadOnlyRuleRow(
                  '大将VS大将',
                  (_kachinukiUnlimitedType == 'なし' ||
                          _kachinukiUnlimitedType.isEmpty)
                      ? '引き分け'
                      : '延長戦を行う',
                ),
                _buildReadOnlyRuleRow(
                  '大将VS他ポジション',
                  _kachinukiUnlimitedType == '無制限' ? '延長戦を行う' : '引き分け',
                ),
              ],

              // ─── 団体戦・チーム設定（通常団体戦のみ） ───
              if (_matchType == '団体戦') ...[
                _buildSectionHeader('団体戦・チーム設定', headerColor),
                _buildReadOnlyRuleRow(
                  '代表戦',
                  _hasLeagueDaihyo
                      ? 'あり (${_isDaihyoIpponShobu ? "一本勝負" : "三本勝負"})'
                      : 'なし',
                ),
              ],

              // ─── 代表戦設定（通常団体戦の代表戦ありのみ） ───
              if (_matchType == '団体戦' && _hasLeagueDaihyo) ...[
                _buildSectionHeader('代表戦設定', headerColor),
                _buildReadOnlyRuleRow(
                  '代表戦 時間',
                  _daihyoMatchTime <= 0
                      ? '無制限'
                      : _formatMinutesText(_daihyoMatchTime),
                ),
                _buildReadOnlyRuleRow(
                  '代表戦 延長戦',
                  !_daihyoHasExtension
                      ? 'なし'
                      : (_daihyoEnchoCount == -2
                            ? 'あり (無制限)'
                            : 'あり (${_formatMinutesText(_daihyoEnchoTime)}・$_daihyoEnchoCount回)'),
                ),
                _buildReadOnlyRuleRow('代表戦 判定', _daihyoHasHantei ? 'あり' : 'なし'),
              ],

              // ─── リーグ戦設定 ───
              if (_matchType.contains('リーグ')) ...[
                _buildSectionHeader('リーグ戦設定', Colors.orange),
                _buildReadOnlyRuleRow(
                  '勝ち点',
                  '勝: ${double.tryParse(_winPointController.text) ?? 0}点 / '
                      '負: ${double.tryParse(_lossPointController.text) ?? 0}点 / '
                      '分: ${double.tryParse(_drawPointController.text) ?? 0}点',
                ),
                if (_matchType == 'リーグ団体戦') ...[
                  _buildReadOnlyRuleRow(
                    '同点代表戦',
                    _hasLeagueDaihyo ? 'あり' : 'なし',
                  ),
                  if (_hasLeagueDaihyo) ...[
                    _buildReadOnlyRuleRow(
                      '代表戦 時間',
                      _daihyoMatchTime <= 0
                          ? '無制限'
                          : _formatMinutesText(_daihyoMatchTime),
                    ),
                    _buildReadOnlyRuleRow(
                      '代表戦 延長戦',
                      !_daihyoHasExtension
                          ? 'なし'
                          : (_daihyoEnchoCount == -2
                                ? 'あり (無制限)'
                                : 'あり (${_formatMinutesText(_daihyoEnchoTime)}・$_daihyoEnchoCount回)'),
                    ),
                    _buildReadOnlyRuleRow(
                      '代表戦 判定',
                      _daihyoHasHantei ? 'あり' : 'なし',
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 適用ルールの手動切替トグル (useAdvancedRule が有効な場合のみ)
        Builder(
          builder: (context) {
            final categoryName = _category;
            final asyncTourney = ref.watch(
              tournamentProvider(widget.tournamentId),
            );
            return asyncTourney.maybeWhen(
              data: (tournament) {
                if (tournament == null) return const SizedBox.shrink();
                final ruleSet = tournament.categoryRules[categoryName];
                if (ruleSet == null || !ruleSet.useAdvancedRule) {
                  return const SizedBox.shrink();
                }

                final isAdvanced = _isCurrentMatchAdvanced;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '適用ルール（自動判別・手動切替）',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setManualRoundType('normal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isAdvanced
                                  ? _themeColors.primaryAccent
                                  : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.grey.shade100),
                              foregroundColor: !isAdvanced
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black87),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: !isAdvanced
                                      ? Colors.transparent
                                      : (isDark
                                            ? const Color(0xFF38383A)
                                            : Colors.grey.shade300),
                                ),
                              ),
                            ),
                            child: const Text(
                              '通常戦のルール',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setManualRoundType('advanced'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAdvanced
                                  ? Colors.teal
                                  : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.grey.shade100),
                              foregroundColor: isAdvanced
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black87),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isAdvanced
                                      ? Colors.transparent
                                      : (isDark
                                            ? const Color(0xFF38383A)
                                            : Colors.grey.shade300),
                                ),
                              ),
                            ),
                            child: const Text(
                              '上位戦のルール',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
        // ★ 統合された「試合場・進行見出し」および「試合メモ」入力セクション (ウィザードテーマ完全調和)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2E)
                : _themeColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF38383A)
                  : _themeColors.separatorColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
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
                    color: _themeColors.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '試合場・進行見出しの一括設定',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (_courtController.text.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(
                        Icons.clear,
                        size: 14,
                        color: _themeColors.primaryAccent,
                      ),
                      label: Text(
                        'クリア',
                        style: TextStyle(
                          fontSize: 12,
                          color: _themeColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
              const SizedBox(height: 12),
              TextField(
                controller: _courtController,
                style: TextStyle(color: textColor),
                decoration: _buildTextFieldDecoration(
                  labelText: '試合場・進行見出し (カンマ区切り)',
                  hintText: '例: 第1試合場, 1回戦, 3試合目 (未入力時は空欄になります)',
                  prefixIcon: Icon(
                    Icons.edit_location_alt,
                    color: _themeColors.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: _themeColors.subTextColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '※ここに入力した試合場・進行見出しは、メモ（詳細情報）に保存・表示されます',
                      style: TextStyle(
                        fontSize: 11,
                        color: _themeColors.subTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '🏟️ 試合場（コート）を選択',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _themeColors.subTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['第1試合場', '第2試合場', '第3試合場', '部内戦コート'].map((preset) {
                  final isSelected = _courtController.text
                      .split(',')
                      .map((e) => e.trim())
                      .contains(preset);
                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: isSelected,
                    avatar: isSelected
                        ? null
                        : Icon(
                            Icons.add,
                            size: 14,
                            color: _themeColors.primaryAccent,
                          ),
                    label: Text(
                      preset,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (isDark
                                  ? Colors.white
                                  : _themeColors.primaryAccent)
                            : (isDark
                                  ? _themeColors.textColor
                                  : _themeColors.primaryAccent),
                      ),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF2C2C2E)
                        : _themeColors.softAccent,
                    selectedColor: _themeColors.primaryAccent.withValues(
                      alpha: 0.2,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? _themeColors.primaryAccent
                          : (isDark
                                ? const Color(0xFF38383A)
                                : _themeColors.primaryAccent.withValues(
                                    alpha: 0.2,
                                  )),
                    ),
                    onSelected: (_) {
                      _toggleHeadingPreset(preset);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                '🏆 回戦・ラウンド・試合順を選択',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _themeColors.subTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                      return FilterChip(
                        selected: isSelected,
                        showCheckmark: isSelected,
                        avatar: isSelected
                            ? null
                            : Icon(
                                Icons.add,
                                size: 14,
                                color: _themeColors.primaryAccent,
                              ),
                        label: Text(
                          preset,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? (isDark
                                      ? Colors.white
                                      : _themeColors.primaryAccent)
                                : (isDark
                                      ? _themeColors.textColor
                                      : _themeColors.primaryAccent),
                          ),
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : _themeColors.softAccent,
                        selectedColor: _themeColors.primaryAccent.withValues(
                          alpha: 0.2,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? _themeColors.primaryAccent
                              : (isDark
                                    ? const Color(0xFF38383A)
                                    : _themeColors.primaryAccent.withValues(
                                        alpha: 0.2,
                                      )),
                        ),
                        onSelected: (_) {
                          _toggleHeadingPreset(preset);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              Divider(color: _themeColors.separatorColor),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: TextStyle(color: textColor),
                decoration: _buildTextFieldDecoration(
                  labelText: '試合のメモ・詳細コメント',
                  hintText: 'メモや追記事項があれば入力してください',
                  prefixIcon: Icon(
                    Icons.edit_note,
                    color: _themeColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildStickyBottomAction() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );
    final isLastPage = _currentPage == 1;

    // iOS Native: ボトムバーの色と区切り線
    final bottomColor = enableLiquidGlass
        ? Colors.transparent
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
    final borderColor = enableLiquidGlass
        ? Colors.transparent
        : (isDark ? const Color(0xFF38383A) : Colors.grey.shade300);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bottomColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: const CircleBorder(),
                  side: BorderSide(color: borderColor),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: _themeColors.primaryAccent,
                ), // ダークでも見やすいThemeColor
              ),
            ),
          Expanded(
            child: GlassButton(
              onPressed: () {
                if (!isLastPage) {
                  if (_currentPage == 0 && _selectedTeamId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('出場する自チームを選択してください')),
                    );
                    return;
                  }
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  final courtText = _courtController.text.trim();
                  final userNote = _noteController.text.trim();
                  final noteCombined = courtText.isNotEmpty
                      ? (userNote.isNotEmpty
                            ? '$courtText\n$userNote'
                            : courtText)
                      : userNote;

                  if (userNote.isNotEmpty) {
                    final words = userNote.split(' ');
                    final currentHistory = ref.read(noteHistoryProvider);
                    final updatedHistory = {
                      ...words,
                      ...currentHistory,
                    }.toList().take(10).toList();
                    ref.read(noteHistoryProvider.notifier).state =
                        updatedHistory;
                  }

                  List<String> selectedBaseOrder = [];
                  String teamNamePrefix = '';
                  if (_selectedTeamId != null) {
                    final teams =
                        ref
                            .read(registeredTeamsProvider(widget.tournamentId))
                            .value ??
                        [];
                    for (var t in teams) {
                      if (t.id == _selectedTeamId) {
                        selectedBaseOrder = t.playerNames;
                        teamNamePrefix = t.teamName;
                        break;
                      }
                    }
                  }

                  int teamSize = 5;
                  bool isLeague = _matchType.contains('リーグ');
                  bool isKachinuki = _matchType == '勝ち抜き戦';

                  if (_matchType == '個人戦' || _matchType == 'リーグ個人戦') {
                    teamSize = 1;
                  } else if (selectedBaseOrder.isNotEmpty) {
                    teamSize = selectedBaseOrder.length;
                  }

                  final generatedPositions = _generatePositions(teamSize);

                  final double finalTime = _matchTime;
                  final double finalExtTime = _extTime;
                  final int finalExtCount = _extCount;

                  bool finalIsRunningTime = _isRenseikai
                      ? _isRunningTime
                      : false;

                  final double winPt =
                      double.tryParse(_winPointController.text) ?? 0;
                  final double lossPt =
                      double.tryParse(_lossPointController.text) ?? 0;
                  final double drawPt =
                      double.tryParse(_drawPointController.text) ?? 0;

                  ref.read(lastUsedSettingsProvider.notifier).state = {
                    'matchType': _matchType,
                    'category': _category,
                    'matchTime': finalTime,
                    'isRunningTime': finalIsRunningTime,
                    'hasExtension': _hasExtension,
                    'hasHantei': _hasHantei,
                    'extensionCount': finalExtCount,
                    'extensionTimeMinutes': finalExtTime,
                    'isRenseikai': _isRenseikai,
                    'kachinukiUnlimitedType': _kachinukiUnlimitedType,
                    'hasLeagueDaihyo': _hasLeagueDaihyo,
                    'renseikaiType': _renseikaiType,
                    'isDaihyoIpponShobu': _isDaihyoIpponShobu,
                    'winPoint': winPt,
                    'lossPoint': lossPt,
                    'drawPoint': drawPt,
                  };

                  ref
                      .read(matchRuleProvider.notifier)
                      .updateRule(
                        MatchRule(
                          positions: generatedPositions,
                          matchTimeMinutes: finalTime,
                          isRunningTime: finalIsRunningTime,
                          isLeague: isLeague,
                          category: _category,
                          note: noteCombined,
                          isRenseikai: _isRenseikai,
                          baseOrder: selectedBaseOrder,
                          teamName: teamNamePrefix,
                          isKachinuki: isKachinuki,
                          kachinukiUnlimitedType: _kachinukiUnlimitedType,
                          hasLeagueDaihyo: _hasLeagueDaihyo,
                          renseikaiType: _renseikaiType,
                          overallTimeMinutes:
                              int.tryParse(_overallTimeController.text) ?? 30,
                          isDaihyoIpponShobu: _isDaihyoIpponShobu,
                          isEnchoUnlimited:
                              _hasExtension &&
                              (finalExtTime == -2.0 || finalExtCount == -2),
                          enchoTimeMinutes: _hasExtension
                              ? (finalExtTime == -2.0 ? 0.0 : finalExtTime)
                              : 0.0,
                          enchoCount: _hasExtension
                              ? (finalExtCount == -2 ? 99 : finalExtCount)
                              : 0,
                          hasHantei: _hasHantei,
                          winPoint: winPt,
                          lossPoint: lossPt,
                          drawPoint: drawPt,
                          matchScene: _selectedRuleScene,
                        ),
                      );

                  context.push('/order-setup/${widget.tournamentId}');
                }
              },
              color: _themeColors.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              icon: isLastPage ? Icons.check_circle : Icons.navigate_next,
              label: isLastPage ? 'このルールで枠を作成' : '次へ進む',
              expandContent: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _themeColors.primaryAccent,
        ),
      ),
    );
  }
}
