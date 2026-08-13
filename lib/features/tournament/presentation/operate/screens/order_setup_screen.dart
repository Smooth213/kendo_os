import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart'; // ★ 追加
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import '../providers/last_used_settings_provider.dart'; // ★ 追加：正確な小数の時間を取得するため
import 'package:kendo_os/shared/utils/text_sanitizer.dart'; // ★ 追加：お掃除フィルター
import '../providers/match_list_provider.dart'; // ★ 追加：試合履歴の取得に必要
import 'package:kendo_os/shared/widgets/manual_help_button.dart'; // ファイル上部
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

// ★ 追加：登録した「よく使うチーム名」を取得するプロバイダー
final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

// ★ 修正：相手チーム用に過去の全試合から履歴を抽出するプロバイダー
final opponentTeamHistoryProvider = Provider.autoDispose<List<String>>((ref) {
  final allMatches = ref.watch(matchListProvider);
  final Set<String> history = {};
  for (final m in allMatches) {
    if (m.redName.contains(':')) {
      history.add(m.redName.split(':').first.trim());
    }
    if (m.whiteName.contains(':')) {
      history.add(m.whiteName.split(':').first.trim());
    }
  }
  return history.toList()..sort();
});

class OrderSetupScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const OrderSetupScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<OrderSetupScreen> createState() => _OrderSetupScreenState();
}

class _OrderSetupScreenState extends ConsumerState<OrderSetupScreen> {
  late List<String> _positions;
  final Map<int, String> _selectedPlayers = {};

  final TextEditingController _opponentTeamController = TextEditingController();
  final FocusNode _opponentTeamFocusNode = FocusNode(); // ★ 追加：フォーカス状態を永続化
  final Map<int, String> _opponentPlayers = {};
  bool _isOwnTeamRed = true;
  late AppThemeColors _themeColors;

  // ★ リーグ戦拡張：参加者リストと追加用コントローラー
  final List<String> _leagueParticipants = [];
  final Map<String, List<String>> _leagueTeamOrders =
      {}; // ★ 追加：参加チームごとのオーダーを保持
  final TextEditingController _addParticipantController =
      TextEditingController();
  final FocusNode _addParticipantFocusNode = FocusNode(); // ★ 追加：フォーカス状態を永続化

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChange);

    final rule = ref.read(matchRuleProvider);
    _positions = List.from(rule.positions);

    if (rule.baseOrder.isNotEmpty) {
      for (int i = 0; i < rule.baseOrder.length && i < _positions.length; i++) {
        if (rule.baseOrder[i].isNotEmpty) {
          _selectedPlayers[i] = rule.baseOrder[i];
        }
      }
    }
    // ★ リーグ戦の場合、自チームを最初の参加者として登録
    if (rule.isLeague) {
      _leagueParticipants.add('自チーム'); // ★ 修正：名前ではなくキーワードで固定し、ペアリング生成時に中身を呼ぶ
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    _opponentTeamController.dispose();
    _opponentTeamFocusNode.dispose(); // ★ 追加：メモリリーク防止
    _addParticipantController.dispose();
    _addParticipantFocusNode.dispose(); // ★ 追加：メモリリーク防止
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _showManualInputDialog() async {
    String manualName = '';
    return showAppDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        title: '選手名を直接入力',
        content: AppTextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '助っ人選手名などを入力',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => manualName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, manualName),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColors.primaryAccent,
              foregroundColor: AppKendoColors.pureWhite,
            ),
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPlayer(int index, List<PlayerModel> masterPlayers) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : context.appColors.cardBackground;

    String searchText = '';
    String selectedFilter = 'すべて';

    final result = await showAppBottomSheet<String>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          List<PlayerModel> filteredMaster = masterPlayers
              .where((p) => p.name.contains(searchText))
              .toList();

          if (selectedFilter != 'すべて') {
            if (selectedFilter == '初心者') {
              filteredMaster = filteredMaster
                  .where((p) => p.isBeginner)
                  .toList();
            } else if (selectedFilter == '幼年') {
              filteredMaster = filteredMaster
                  .where((p) => p.grade == 0 && !p.isBeginner)
                  .toList();
            } else if (selectedFilter == '低学年') {
              filteredMaster = filteredMaster
                  .where((p) => p.grade >= 1 && p.grade <= 4 && !p.isBeginner)
                  .toList();
            } else if (selectedFilter == '高学年') {
              filteredMaster = filteredMaster
                  .where((p) => p.grade >= 5 && p.grade <= 6 && !p.isBeginner)
                  .toList();
            } else if (selectedFilter == '中学生') {
              filteredMaster = filteredMaster
                  .where((p) => p.grade >= 7 && p.grade <= 9 && !p.isBeginner)
                  .toList();
            } else if (selectedFilter == '高校生') {
              filteredMaster = filteredMaster
                  .where((p) => p.grade >= 10 && p.grade <= 12 && !p.isBeginner)
                  .toList();
            } else if (selectedFilter == '一般') {
              filteredMaster = filteredMaster
                  .where((p) => p.grade >= 13 && !p.isBeginner)
                  .toList();
            }
          }

          filteredMaster.sort((a, b) => a.nameKana.compareTo(b.nameKana));

          return AppBottomSheetContent(
            title: '選手の選択',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context, 'CLEAR_FLAG'),
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text(
                            '未定（空枠）',
                            style: TextStyle(fontWeight: AppFontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.appColors.textColor,
                            side: BorderSide(
                              color: context.appColors.separatorColor,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.compact,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.compact,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context, '欠員'),
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text(
                            '欠員（不戦敗）',
                            style: TextStyle(fontWeight: AppFontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppKendoColors.hansokuRed,
                            side: BorderSide(color: AppKendoColors.hansokuRed),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.compact,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.compact,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final inputName = await _showManualInputDialog();
                      if (context.mounted && inputName != null) {
                        Navigator.pop(context, inputName);
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(
                      '直接入力（助っ人など）',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _themeColors.primaryAccent,
                      side: BorderSide(color: _themeColors.softAccent),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.compact,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 検索窓
                  AppTextField(
                    decoration: InputDecoration(
                      hintText: '名前で絞り込み...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.small,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) => setStateSheet(() => searchText = val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // カテゴリフィルター
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                            'すべて',
                            '初心者',
                            '幼年',
                            '低学年',
                            '高学年',
                            '中学生',
                            '高校生',
                            '一般',
                          ].map((filterName) {
                            final isSelected = selectedFilter == filterName;
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: AppChoiceChip(
                                label: Text(filterName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setStateSheet(
                                      () => selectedFilter = filterName,
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView(
                      children: [
                        ...filteredMaster.map(
                          (p) => Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            elevation: 0,
                            color: _themeColors.softAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.transparent
                                    : _themeColors.softAccent,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFFFFFFF),
                                child: Text(
                                  p.name.substring(0, 1),
                                  style: TextStyle(
                                    color: _themeColors.primaryAccent,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              subtitle: Text(
                                p.gradeName,
                                style: TextStyle(
                                  color: _themeColors.primaryAccent,
                                  fontSize: AppFontSize.small,
                                ),
                              ),
                              trailing: Icon(
                                Icons.check_circle_outline,
                                color: _themeColors.primaryAccent,
                              ),
                              onTap: () => Navigator.pop(context, p.name),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == 'CLEAR_FLAG') {
      setState(() => _selectedPlayers.remove(index));
    } else if (result != null && result.trim().isNotEmpty) {
      setState(() => _selectedPlayers[index] = result);
    }
  }

  void _addExtraPosition() {
    setState(() {
      int newNum = _positions.length + 1;
      _positions.insert(_positions.length - 1, '追加枠$newNum');
    });
  }

  // ★ 団体リーグ戦：最下部に適度な余白（24px）を追加
  Future<List<String>?> _showLeagueOrderSheet(
    String teamName,
    List<String> positions,
  ) async {
    final List<TextEditingController> controllers = List.generate(
      positions.length,
      (i) => TextEditingController(),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showAppBottomSheet<List<String>>(
      context: context,
      builder: (ctx) => AppBottomSheetContent(
        title: '$teamName のオーダー',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: positions.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppTextField(
                      controller: controllers[i],
                      autofocus: i == 0,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : context.appColors.cardBackground,
                      ),
                      decoration: InputDecoration(
                        labelText: positions[i],
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : context.appColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.small,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    controllers
                        .map((c) => TextSanitizer.clean(c.text))
                        .toList(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColors.primaryAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                  ),
                  child: const Text(
                    '決定して追加',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ),
              // ★ 修正：団体戦用の下部余白
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ★ 個人リーグ戦：最下部に広めの余白（48px）を追加してゆったり配置
  Future<String?> _showIndividualNameInputSheet(String teamName) async {
    final nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showAppBottomSheet<String>(
      context: context,
      builder: (ctx) => AppBottomSheetContent(
        title: teamName.isNotEmpty ? '$teamName の選手名' : '選手名の登録',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : context.appColors.cardBackground,
                ),
                decoration: InputDecoration(
                  labelText: '選手名（例：田中太郎）',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: AppRadius.small),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    TextSanitizer.clean(nameController.text),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColors.primaryAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                  ),
                  child: const Text(
                    '決定して追加',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ),
              // ★ 修正：個人戦用は「少し広め」の48pxに設定
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticHeader() {
    // ★ Phase 8-1: 横画面ではヘッダーを隠す
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape && MediaQuery.of(context).size.height < 500) {
      return const SizedBox.shrink();
    }

    final color1 = _themeColors.primaryAccent;
    final endColor = _themeColors.softAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.giantValue),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最終ステップ: オーダー編成',
            style: TextStyle(
              fontSize: AppFontSize.display,
              fontWeight: AppFontWeight.bold,
              color: AppKendoColors.pureWhite,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '対戦相手と出場選手を決定し、\n試合枠を生成します',
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              color: AppKendoColors.pureWhite.withValues(alpha: 0.9),
              fontWeight: AppFontWeight.medium,
            ),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: AppKendoColors.pureWhite.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppKendoColors.pureWhite,
            ),
            minHeight: 6,
            borderRadius: AppRadius.tiny,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final rule = ref.watch(matchRuleProvider);
    // ★ 追加：lastSettings から試合形式の文字列(matchType)を取得する
    final String matchType =
        ref.watch(lastUsedSettingsProvider)['matchType'] as String? ?? '';
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final textColor = context.appColors.textColor;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : context.appColors.subTextColor;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: const AppHeader(
          title: 'オーダー編成',
          backgroundColor: AppKendoColors.transparent,
          actions: [
            ManualHelpButton(
              manualPath: 'docs/manuals/operator/team_registration.md',
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: playerListAsync.when(
                // ★ Phase 8-1: ColumnをListViewに変更し、画面全体をスクロール可能にして縦幅エラー(63px)を解消
                // ヘッダーをスクロール可能なListViewの中に移動し、入力枠が圧迫されるのを防ぐ
                data: (masterPlayers) => ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildStaticHeader(),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      color: _themeColors.softAccent,
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _themeColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '自チームの選手を選択し、必要に応じて相手のチーム・選手名を入力してください。',
                              style: TextStyle(
                                color: context.appColors.subTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rule.isLeague)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1. リーグ参加者リストの作成',
                              style: TextStyle(
                                fontWeight: AppFontWeight.bold,
                                color: _themeColors.primaryAccent,
                                fontSize: AppFontSize.subhead,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '大会パンフレットの番号順に並べ替えてください（長押しで移動）',
                              style: TextStyle(
                                fontSize: AppFontSize.caption,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // 参加者追加フォーム
                            _buildTeamAutocomplete(
                              controller: _addParticipantController,
                              focusNode: _addParticipantFocusNode,
                              suggestions: ref.watch(
                                opponentTeamHistoryProvider,
                              ),
                              labelText: '参加チーム名を追加', // ★ 修正：個人戦・団体戦で統一
                              hintText: '入力または履歴から選択',
                              fillColor: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : const Color(0xFFFFFFFF),
                              borderColor: borderColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // ★ 統一改修：ダイアログからボトムシート呼び出しへ変更
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  _addParticipantFocusNode.unfocus();
                                  FocusScope.of(context).unfocus();

                                  final inputTeamName = TextSanitizer.clean(
                                    _addParticipantController.text,
                                  );

                                  if (_leagueParticipants.contains(
                                    inputTeamName,
                                  )) {
                                    AppSnackBar.showError(
                                      context,
                                      'その名称は既に登録されています',
                                    );
                                    return;
                                  }

                                  if (matchType.contains('個人戦')) {
                                    // ★ ボトムシートを呼び出す
                                    final playerName =
                                        await _showIndividualNameInputSheet(
                                          inputTeamName,
                                        );
                                    if (playerName != null &&
                                        playerName.isNotEmpty) {
                                      final fullName = inputTeamName.isNotEmpty
                                          ? '$inputTeamName : $playerName'
                                          : playerName;
                                      setState(() {
                                        _leagueParticipants.add(fullName);
                                        _leagueTeamOrders[fullName] = [
                                          playerName,
                                        ];
                                      });
                                      _addParticipantController.clear();
                                    }
                                  } else {
                                    if (inputTeamName.isEmpty) {
                                      AppSnackBar.showError(
                                        context,
                                        'チーム名を入力してください',
                                      );
                                      return;
                                    }
                                    // ★ ボトムシートを呼び出す
                                    final order = await _showLeagueOrderSheet(
                                      inputTeamName,
                                      _positions,
                                    );
                                    if (order != null) {
                                      setState(() {
                                        _leagueParticipants.add(inputTeamName);
                                        _leagueTeamOrders[inputTeamName] =
                                            order;
                                      });
                                      _addParticipantController.clear();
                                    }
                                  }
                                },
                                icon: const Icon(Icons.person_add),
                                label: const Text(
                                  'リストに追加',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _themeColors.primaryAccent,
                                  foregroundColor: AppKendoColors.pureWhite,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // 並び替え可能なリスト
                            Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1C1C1E)
                                    : const Color(0xFFFFFFFF),
                                borderRadius: AppRadius.large,
                                border: Border.all(color: borderColor),
                              ),
                              child: Material(
                                color: AppKendoColors.transparent,
                                child: ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _leagueParticipants.length,
                                  onReorderItem: (oldIndex, newIndex) {
                                    setState(() {
                                      final item = _leagueParticipants.removeAt(
                                        oldIndex,
                                      );
                                      _leagueParticipants.insert(
                                        newIndex,
                                        item,
                                      );
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final name = _leagueParticipants[index];
                                    return ListTile(
                                      key: ValueKey(name),
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            name.contains('自チーム') ||
                                                name == rule.teamName
                                            ? _themeColors.softAccent
                                            : context.appColors.separatorColor,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: _themeColors.primaryAccent,
                                            fontWeight: AppFontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: AppFontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.drag_handle,
                                        color: AppKendoColors.grey,
                                      ),
                                      onLongPress:
                                          () {}, // ReorderableListViewのトリガー用
                                      subtitle:
                                          (name.contains('自チーム') ||
                                              name == rule.teamName)
                                          ? Text(
                                              '（自チーム）',
                                              style: TextStyle(
                                                fontSize: AppFontSize.badge,
                                                color:
                                                    _themeColors.primaryAccent,
                                              ),
                                            )
                                          : null,
                                      onTap:
                                          (name.contains('自チーム') ||
                                              name == rule.teamName)
                                          ? null
                                          : () {
                                              setState(
                                                () => _leagueParticipants
                                                    .removeAt(index),
                                              );
                                            },
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Text(
                              '2. 自チームのオーダーを確認',
                              style: TextStyle(
                                fontWeight: AppFontWeight.bold,
                                color: _themeColors.primaryAccent,
                                fontSize: AppFontSize.subhead,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '自チームの紅白（タスキ）',
                              style: TextStyle(
                                fontWeight: AppFontWeight.bold,
                                color: _themeColors.primaryAccent,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              '※数字の小さい方または上・左のチーム（選手）が赤になります',
                              style: TextStyle(
                                fontSize: AppFontSize.small,
                                color: AppKendoColors.red,
                                fontWeight: AppFontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              // ★ 修正：外枠を沈み込むダークグレーへ
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1C1C1E)
                                    : const Color(0x33000000),
                                borderRadius: AppRadius.medium,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isOwnTeamRed = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          // ★ 修正：選択時のツマミ部分を少し浮かせる明るめのグレーへ
                                          color: _isOwnTeamRed
                                              ? (isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : const Color(0xFFFFFFFF))
                                              : Colors.transparent,
                                          borderRadius: AppRadius.small,
                                          boxShadow: (_isOwnTeamRed && !isDark)
                                              ? [
                                                  BoxShadow(
                                                    color: AppKendoColors
                                                        .pureBlack
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.looks_one,
                                              size: 18,
                                              color: _isOwnTeamRed
                                                  ? AppKendoColors.hansokuRed
                                                  : (isDark
                                                        ? AppKendoColors
                                                              .grey
                                                              .shade600
                                                        : AppKendoColors.grey),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Text(
                                              '赤 (左側)',
                                              style: TextStyle(
                                                color: _isOwnTeamRed
                                                    ? AppKendoColors.hansokuRed
                                                    : subTextColor,
                                                fontWeight: AppFontWeight.bold,
                                                fontSize: AppFontSize.body,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isOwnTeamRed = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_isOwnTeamRed
                                              ? (isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : const Color(0xFFFFFFFF))
                                              : Colors.transparent,
                                          borderRadius: AppRadius.small,
                                          boxShadow: (!_isOwnTeamRed && !isDark)
                                              ? [
                                                  BoxShadow(
                                                    color: AppKendoColors
                                                        .pureBlack
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.looks_two,
                                              size: 18,
                                              color: !_isOwnTeamRed
                                                  ? (isDark
                                                        ? Colors
                                                              .blueGrey
                                                              .shade300
                                                        : Colors
                                                              .blueGrey
                                                              .shade700)
                                                  : (isDark
                                                        ? AppKendoColors
                                                              .grey
                                                              .shade600
                                                        : AppKendoColors.grey),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            // ★ 修正：白チーム選択時の文字色を純白へ
                                            Text(
                                              '白 (右側)',
                                              style: TextStyle(
                                                color: !_isOwnTeamRed
                                                    ? (isDark
                                                          ? AppKendoColors
                                                                .pureWhite
                                                          : Colors
                                                                .blueGrey
                                                                .shade700)
                                                    : subTextColor,
                                                fontWeight: AppFontWeight.bold,
                                                fontSize: AppFontSize.body,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl), // 余白を広げる
                            // ★ 直感UX改修：相手チームの入力を明確なブロック（カード風）で囲み、迷いをなくす
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1C1C1E)
                                    : const Color(0xFFF2F2F7), // 背景を少し落とす
                                borderRadius: AppRadius.large,
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shield,
                                        color: isDark
                                            ? const Color(0xFF607D8B)
                                            : const Color(0xFF607D8B),
                                        size: 18,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        '相手チームの情報を入力',
                                        style: TextStyle(
                                          fontWeight: AppFontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFF607D8B)
                                              : AppKendoColors
                                                    .blueGrey
                                                    .shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // ★ 修正：先ほど作ったヘルパー関数を使ってサジェスト（予測変換）対応にする
                                  _buildTeamAutocomplete(
                                    controller: _opponentTeamController,
                                    focusNode: _opponentTeamFocusNode,
                                    suggestions: ref.watch(
                                      opponentTeamHistoryProvider,
                                    ),
                                    labelText: '相手チーム名・所属名（任意）',
                                    hintText: 'タップして登録済みリストから選択',
                                    fillColor: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFFFFFFF),
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final currentOrder = List.generate(
                                  _positions.length,
                                  (i) => _selectedPlayers[i] ?? '',
                                );
                                ref
                                    .read(matchRuleProvider.notifier)
                                    .updateBaseOrder(currentOrder);
                                AppSnackBar.showSuccess(
                                  context,
                                  '現在のオーダーを「基本オーダー」として記憶しました',
                                );
                              },
                              icon: const Icon(Icons.save_alt, size: 16),
                              label: const Text(
                                '基本オーダーに登録',
                                style: TextStyle(fontSize: AppFontSize.small),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? AppKendoColors.pureWhite
                                    : _themeColors.primaryAccent,
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF64B5F6)
                                      : _themeColors.primaryAccent,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: rule.baseOrder.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        for (
                                          int i = 0;
                                          i < rule.baseOrder.length &&
                                              i < _positions.length;
                                          i++
                                        ) {
                                          if (rule.baseOrder[i].isNotEmpty) {
                                            _selectedPlayers[i] =
                                                rule.baseOrder[i];
                                          } else {
                                            _selectedPlayers.remove(i);
                                          }
                                        }
                                      });
                                      AppSnackBar.showSuccess(
                                        context,
                                        '基本オーダーを呼び出しました',
                                      );
                                    },
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text(
                                '基本オーダーを呼出',
                                style: TextStyle(fontSize: AppFontSize.small),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFE2E8F0),
                                foregroundColor: isDark
                                    ? AppKendoColors.pureWhite
                                    : const Color(0xFF0F172A),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ★ 直感UX向上：ドラッグ＆ドロップ（長押し並び替え）対応のオーダー登録スロット一覧
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_vert,
                            size: 16,
                            color: _themeColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '長押しドラッグで選手の配置・順番を自由に入れ替えできます',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: _positions.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final oldPlayer = _selectedPlayers[oldIndex];
                          final newPlayer = _selectedPlayers[newIndex];

                          if (oldPlayer != null) {
                            _selectedPlayers[newIndex] = oldPlayer;
                          } else {
                            _selectedPlayers.remove(newIndex);
                          }

                          if (newPlayer != null) {
                            _selectedPlayers[oldIndex] = newPlayer;
                          } else {
                            _selectedPlayers.remove(oldIndex);
                          }
                        });
                      },
                      itemBuilder: (context, index) {
                        final posName = _positions[index];
                        final playerName = _selectedPlayers[index] ?? '未定';
                        final isSelected = _selectedPlayers.containsKey(index);

                        return Card(
                          key: ValueKey(
                            'order_slot_${_positions[index]}_$index',
                          ),
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          elevation: 0,
                          color: inputBgColor,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? _themeColors.primaryAccent
                                  : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: AppRadius.medium,
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  await _selectPlayer(index, masterPlayers);
                                  if (!mounted) return;
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.mediumValue),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isSelected
                                            ? _themeColors.softAccent
                                            : (isDark
                                                  ? const Color(0xFF2C2C2E)
                                                  : AppKendoColors
                                                        .grey
                                                        .shade200),
                                        child: Text(
                                          posName.substring(0, 1),
                                          style: TextStyle(
                                            color: isSelected
                                                ? _themeColors.primaryAccent
                                                : subTextColor,
                                            fontWeight: AppFontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.lg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rule.teamName.isNotEmpty
                                                  ? '${rule.teamName} : $posName'
                                                  : posName,
                                              style: TextStyle(
                                                fontSize: AppFontSize.small,
                                                color:
                                                    _themeColors.primaryAccent,
                                                fontWeight: AppFontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              playerName,
                                              style: TextStyle(
                                                fontSize: AppFontSize.headline,
                                                fontWeight: AppFontWeight.bold,
                                                color: isSelected
                                                    ? textColor
                                                    : subTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.modernValue,
                                          vertical: AppSpacing.subValue,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? _themeColors.softAccent
                                              : (isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : AppKendoColors
                                                          .grey
                                                          .shade100),
                                          borderRadius: AppRadius.round,
                                        ),
                                        child: Text(
                                          isSelected ? '変更' : '選択',
                                          style: TextStyle(
                                            color: isSelected
                                                ? _themeColors.primaryAccent
                                                : subTextColor,
                                            fontSize: AppFontSize.bodySmall,
                                            fontWeight: AppFontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.xs,
                                          ),
                                          child: Icon(
                                            Icons.drag_handle,
                                            color: subTextColor.withValues(
                                              alpha: 0.6,
                                            ),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // ★ 修正：画像でご指摘いただいた通り、リーグ戦では相手の個別入力を非表示にしてスッキリさせる！
                              if (!rule.isLeague) ...[
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: isDark
                                      ? const Color(0xFF38383A)
                                      : const Color(0x33000000),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : const Color(0xFFF2F2F7),
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(
                                        AppRadius.mediumValue,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.md,
                                  ),
                                  child: TextFormField(
                                    key: ValueKey(_opponentPlayers[index]),
                                    initialValue: _opponentPlayers[index],
                                    onChanged: (val) =>
                                        _opponentPlayers[index] = val,
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      labelText: '対戦相手 ($posName)',
                                      labelStyle: TextStyle(
                                        color: subTextColor,
                                      ),
                                      hintText: '相手選手名（任意）',
                                      hintStyle: TextStyle(color: subTextColor),
                                      isDense: true,
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                        size: 20,
                                        color: AppKendoColors.blueGrey,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.small,
                                        borderSide: BorderSide(
                                          color: borderColor,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: AppRadius.small,
                                        borderSide: BorderSide(
                                          color: borderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.small,
                                        borderSide: BorderSide(
                                          color: _themeColors.primaryAccent,
                                        ),
                                      ),
                                      fillColor: isDark
                                          ? const Color(0xFF2C2C2E)
                                          : const Color(0xFFFFFFFF),
                                      filled: true,
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.only(
                                          right: AppSpacing.xs,
                                        ),
                                        child: TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                            ),
                                            minimumSize: Size.zero,
                                            backgroundColor:
                                                AppKendoColors.hansokuRed,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: AppRadius.sub,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.block,
                                            color: AppKendoColors.pureWhite,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            '欠員',
                                            style: TextStyle(
                                              color: AppKendoColors.pureWhite,
                                              fontWeight: AppFontWeight.bold,
                                              fontSize: AppFontSize.small,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _opponentPlayers[index] =
                                                  '欠員',
                                            );
                                            FocusScope.of(context).unfocus();
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ], // ★ if (!rule.isLeague) を閉じる
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('エラー: $err')),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: enableLiquidGlass
                    ? AppKendoColors.transparent
                    : inputBgColor,
                border: Border(
                  top: BorderSide(
                    color: enableLiquidGlass
                        ? AppKendoColors.transparent
                        : borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _addExtraPosition,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: isDark
                          ? const Color(0xFF64B5F6)
                          : _themeColors.primaryAccent,
                    ),
                    label: Text(
                      'イレギュラー枠を追加する（錬成会用）',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF64B5F6)
                            : _themeColors.primaryAccent,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // ★ 修正：ここではチェックせず、後の pairings 生成直前のバリデーションに集約します
                        final bool? isStartNow = await showAppDialog<bool>(
                          context: context,
                          builder: (context) => AppDialog(
                            title: '試合の登録',
                            content: const Text(
                              'このオーダーで試合を登録します。今すぐ試合画面に進みますか？',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  '後で（リストに保存）',
                                  style: TextStyle(color: AppKendoColors.grey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _themeColors.primaryAccent,
                                  foregroundColor: AppKendoColors.pureWhite,
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '今すぐ試合開始',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isStartNow == null) {
                          return;
                        }

                        if (!context.mounted) {
                          return;
                        }
                        // ★ Phase 8-1: ダイアログの「戻る」が画面を消さないように、rootNavigatorを使う
                        showAppDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          // ★ 修正：不要になった古い変数を綺麗にお掃除
                          String senpoMatchId = '';
                          double baseOrder = ref
                              .read(timeSourceProvider)
                              .now()
                              .millisecondsSinceEpoch
                              .toDouble();
                          List<MatchModel> matchesToSave = [];

                          // ★ 追加：リーグ戦であることを明示するタグを生成し、後で全試合のnoteに付与する
                          final String saveNote = rule.isLeague
                              ? '[リーグ戦] ${rule.note}'.trim()
                              : rule.note;
                          // ★ 追加：リーグ全体を1つのアコーディオンにまとめるための共通ID
                          final String leagueGroupId = rule.isLeague
                              ? const Uuid().v4()
                              : '';

                          List<List<String>> pairings = [];
                          // ★ 修正：入力された相手チーム名をお掃除フィルターに通す！
                          String myTeamName = rule.teamName.isNotEmpty
                              ? rule.teamName
                              : '自チーム';
                          String opTeamName = TextSanitizer.clean(
                            _opponentTeamController.text,
                          );
                          if (opTeamName.isEmpty) opTeamName = '対戦相手';

                          if (rule.isLeague) {
                            if (_leagueParticipants.length < 2) {
                              AppSnackBar.showError(
                                context,
                                'リーグ戦には少なくとも2つのチーム・選手が必要です',
                              );
                              Navigator.of(context, rootNavigator: true).pop();
                              return;
                            }

                            // ★ 修正：並び替えた順序をルールに記憶させる
                            ref
                                .read(matchRuleProvider.notifier)
                                .updateRule(
                                  rule.copyWith(
                                    leagueOrder: _leagueParticipants,
                                  ),
                                );

                            // ★ 修正：並び替えたリストに基づいて総当たりのペアを生成
                            for (
                              int i = 0;
                              i < _leagueParticipants.length;
                              i++
                            ) {
                              for (
                                int j = i + 1;
                                j < _leagueParticipants.length;
                                j++
                              ) {
                                pairings.add([
                                  _leagueParticipants[i],
                                  _leagueParticipants[j],
                                ]);
                              }
                            }
                          } else {
                            if (_isOwnTeamRed) {
                              pairings.add([myTeamName, opTeamName]);
                            } else {
                              pairings.add([opTeamName, myTeamName]);
                            }
                          }

                          await Future.microtask(() {
                            for (
                              int pIndex = 0;
                              pIndex < pairings.length;
                              pIndex++
                            ) {
                              final pair = pairings[pIndex];
                              // ★ 修正：リーグ戦なら共通IDを使い、通常なら個別のIDを発行
                              final String teamGroupId = rule.isLeague
                                  ? leagueGroupId
                                  : const Uuid().v4();

                              if (rule.isKachinuki) {
                                List<String> redFull = [];
                                List<String> whiteFull = [];

                                for (int i = 0; i < _positions.length; i++) {
                                  String myP = _selectedPlayers[i] ?? '未定';
                                  if (myP.isEmpty) myP = '未定';
                                  String opP =
                                      _opponentPlayers[i]?.trim() ?? '';
                                  if (opP.isEmpty) opP = '選手';
                                  String myFull = '$myTeamName : $myP';
                                  String opFull = '$opTeamName : $opP';
                                  String rN, wN;
                                  if (rule.isLeague) {
                                    // ★ 修正：入力されたオーダーを呼び出して完璧にセットする！
                                    String rTeam = pair[0];
                                    String wTeam = pair[1];
                                    String rPlayer = (rTeam == '自チーム')
                                        ? myP
                                        : (_leagueTeamOrders[rTeam]?[i] ??
                                              '選手');
                                    if (rPlayer.isEmpty) rPlayer = '選手';
                                    String wPlayer = (wTeam == '自チーム')
                                        ? myP
                                        : (_leagueTeamOrders[wTeam]?[i] ??
                                              '選手');
                                    if (wPlayer.isEmpty) wPlayer = '選手';

                                    rN = (rTeam == '自チーム')
                                        ? myFull
                                        : '$rTeam : $rPlayer';
                                    wN = (wTeam == '自チーム')
                                        ? myFull
                                        : '$wTeam : $wPlayer';
                                  } else {
                                    rN = _isOwnTeamRed ? myFull : opFull;
                                    wN = _isOwnTeamRed ? opFull : myFull;
                                  }
                                  redFull.add(rN);
                                  whiteFull.add(wN);
                                }

                                final matchId = const Uuid().v4();
                                if (senpoMatchId.isEmpty) {
                                  senpoMatchId = matchId;
                                }

                                final newMatch = MatchModel(
                                  id: matchId,
                                  tournamentId: widget.tournamentId,
                                  category: rule.category.isNotEmpty
                                      ? rule.category
                                      : null,
                                  groupName: teamGroupId,
                                  matchType: _positions[0],
                                  whiteName: whiteFull[0],
                                  redName: redFull[0],
                                  status: (isStartNow && pIndex == 0)
                                      ? 'in_progress'
                                      : 'waiting',
                                  refereeNames: [],

                                  // ★ 全て rule からもらう
                                  matchTimeMinutes: rule.matchTimeMinutes,
                                  isRunningTime: rule.isRunningTime,
                                  hasExtension:
                                      rule.enchoTimeMinutes > 0 ||
                                      rule.isEnchoUnlimited,
                                  extensionTimeMinutes: rule.enchoTimeMinutes,
                                  extensionCount: rule.enchoCount,
                                  hasHantei: rule.hasHantei,

                                  order: baseOrder + (pIndex * 10),
                                  note: saveNote,
                                  isKachinuki: true,
                                  matchScene: rule.matchScene != 'honsen'
                                      ? rule.matchScene
                                      : (rule.isRenseikai
                                            ? 'renseikai'
                                            : 'honsen'),
                                  rule: rule,
                                  redRemaining: redFull.length > 1
                                      ? redFull.sublist(1)
                                      : [],
                                  whiteRemaining: whiteFull.length > 1
                                      ? whiteFull.sublist(1)
                                      : [],
                                );
                                matchesToSave.add(newMatch);
                              } else {
                                for (int i = 0; i < _positions.length; i++) {
                                  final String matchId = const Uuid().v4();
                                  if (senpoMatchId.isEmpty) {
                                    senpoMatchId = matchId;
                                  }
                                  final posName = _positions[i];
                                  String myP = _selectedPlayers[i] ?? '未定';
                                  if (myP.isEmpty) myP = '未定';
                                  String opP =
                                      _opponentPlayers[i]?.trim() ?? '';
                                  if (opP.isEmpty) opP = '選手';
                                  String myFull = '$myTeamName : $myP';
                                  String opFull = '$opTeamName : $opP';
                                  String rName, wName;
                                  if (rule.isLeague) {
                                    // ★ 修正：入力されたオーダーと「個人戦/団体戦」の違いを反映！
                                    String rTeam = pair[0];
                                    String wTeam = pair[1];
                                    String rPlayer = (rTeam == '自チーム')
                                        ? myP
                                        : (_leagueTeamOrders[rTeam]?[i] ??
                                              '選手');
                                    if (rPlayer.isEmpty) rPlayer = '選手';
                                    String wPlayer = (wTeam == '自チーム')
                                        ? myP
                                        : (_leagueTeamOrders[wTeam]?[i] ??
                                              '選手');
                                    if (wPlayer.isEmpty) wPlayer = '選手';

                                    // ★ 修正：画面上部で既に取得している matchType をそのまま利用する
                                    if (matchType.contains('個人戦')) {
                                      // ★ 修正：ダイアログの時点で既に「所属 : 名前」になっているので、そのまま使う！
                                      rName = (rTeam == '自チーム')
                                          ? myFull
                                          : rTeam;
                                      wName = (wTeam == '自チーム')
                                          ? myFull
                                          : wTeam;
                                    } else {
                                      rName = (rTeam == '自チーム')
                                          ? myFull
                                          : '$rTeam : $rPlayer';
                                      wName = (wTeam == '自チーム')
                                          ? myFull
                                          : '$wTeam : $wPlayer';
                                    }
                                  } else {
                                    rName = _isOwnTeamRed ? myFull : opFull;
                                    wName = _isOwnTeamRed ? opFull : myFull;
                                  }
                                  bool isFirstMatchOfAll =
                                      (pIndex == 0 && i == 0);
                                  final newMatch = MatchModel(
                                    id: matchId,
                                    tournamentId: widget.tournamentId,
                                    category: rule.category.isNotEmpty
                                        ? rule.category
                                        : null,
                                    groupName: teamGroupId,
                                    matchType: posName,
                                    redName: rName,
                                    whiteName: wName,
                                    status: (isStartNow && isFirstMatchOfAll)
                                        ? 'in_progress'
                                        : 'waiting',
                                    refereeNames: [],

                                    // ★ 修正：すべて完璧な状態の「rule」から直接もらう！
                                    matchTimeMinutes: rule.matchTimeMinutes,
                                    isRunningTime: rule.isRunningTime,
                                    hasExtension:
                                        rule.enchoTimeMinutes > 0 ||
                                        rule.isEnchoUnlimited ||
                                        posName.contains('代表'),
                                    extensionTimeMinutes: rule.enchoTimeMinutes,
                                    extensionCount: rule.enchoCount,
                                    hasHantei: rule.hasHantei,

                                    order: baseOrder + (pIndex * 10) + i,
                                    note: saveNote,
                                    matchScene: rule.matchScene != 'honsen'
                                        ? rule.matchScene
                                        : (rule.isRenseikai
                                              ? 'renseikai'
                                              : 'honsen'),
                                    rule: rule, // ★ これだけで全てが封印されます
                                  );
                                  debugPrint(
                                    '📦 [1. 生成センサー] MatchId: $matchId, Ruleがnullか?: ${newMatch.rule == null}',
                                  ); // ★ デバッグ用センサー
                                  matchesToSave.add(newMatch);
                                }
                              }
                            }
                          });

                          if (matchesToSave.isNotEmpty) {
                            await ref
                                .read(matchApplicationServiceProvider)
                                .saveMatchesBulk(matchesToSave); // ★ 修正
                          }

                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(); // ★ Phase 8-1: ローディングダイアログだけを確実に閉じる！

                          if (isStartNow) {
                            if (senpoMatchId.isNotEmpty) {
                              context.push('/match/$senpoMatchId');
                            } else {
                              context.go('/home/${widget.tournamentId}');
                            }
                          } else {
                            AppSnackBar.showSuccess(
                              context,
                              '試合をプールしました（待機リストに追加）',
                            );
                            context.go('/home/${widget.tournamentId}');
                          }
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context, rootNavigator: true).pop();
                          AppSnackBar.showError(context, '保存に失敗しました: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeColors.primaryAccent,
                        foregroundColor: AppKendoColors.pureWhite,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'このオーダーで確定して進む',
                            style: TextStyle(
                              fontSize: AppFontSize.subhead,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ 追加：予測変換（サジェスト）と手入力を両立する、最強の入力フィールドビルダー
  Widget _buildTeamAutocomplete({
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> suggestions,
    required String labelText,
    required String hintText,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (!focusNode.hasFocus) {
          return const Iterable<String>.empty();
        }
        if (textEditingValue.text.isEmpty) {
          return suggestions;
        }
        return const Iterable<String>.empty();
      },
      fieldViewBuilder:
          (context, fieldController, textFieldFocusNode, onFieldSubmitted) {
            return AppTextField(
              controller: fieldController,
              focusNode: textFieldFocusNode,
              onTap: () {
                if (fieldController.text.isEmpty) {
                  // ★ 修正: 1回目のタップ時にフォーカスが確実に当たるのを待つため、フレーム描画後に実行する
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final currentVal = fieldController.value;
                    fieldController.value = const TextEditingValue(text: ' ');
                    fieldController.value = currentVal;
                  });
                }
              },
              onChanged: (text) {},
              style: TextStyle(
                color: textColor,
                fontWeight: AppFontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(color: subTextColor),
                hintText: hintText,
                hintStyle: TextStyle(color: subTextColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: borderColor),
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: _themeColors.primaryAccent),
                ),
                prefixIcon: Icon(
                  Icons.shield_outlined,
                  color: isDark
                      ? const Color(0xFF607D8B)
                      : const Color(0xFF607D8B),
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppKendoColors.grey,
                ), // ▼アイコン
                fillColor: fillColor,
                filled: true,
                isDense: true,
              ),
            );
          },
      // 浮かび上がる候補リストのデザイン
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: AppRadius.medium,
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
            child: ConstrainedBox(
              // 幅を画面に合わせる
              constraints: BoxConstraints(
                maxHeight: 250,
                maxWidth: MediaQuery.of(context).size.width - 48,
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
                        color: textColor,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.add_circle_outline,
                      color: _themeColors.primaryAccent,
                      size: 18,
                    ),
                    onTap: () {
                      onSelected(option); // 選んだら入力完了
                      FocusScope.of(
                        context,
                      ).unfocus(); // ★ 追加：フォーカスを外してサジェストとキーボードをスッと消す
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
}
