import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_league_points_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_simple_scene_rule_form.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_list_section.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

class CategoryRulesScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isFromSetup;
  const CategoryRulesScreen({
    super.key,
    required this.tournamentId,
    this.isFromSetup = false,
  });

  @override
  ConsumerState<CategoryRulesScreen> createState() =>
      _CategoryRulesScreenState();
}

class _CategoryRulesScreenState extends ConsumerState<CategoryRulesScreen> {
  String? _editingCategory;

  // 編集中のルールセット状態保持用
  bool _useAdvancedRule = false;
  List<String> _editingAdvancedKeywords = const [
    '準決勝',
    '準決',
    '決勝',
    'final',
    '3位決定',
    '3決',
    'ベスト4',
  ];
  String _editingMatchType = '個人戦';
  bool _editingIsRenseikai = false;

  // 道場遠征用マルチシーン設定
  bool _isMultiScene = false;
  bool _useHonsenRule = true;
  bool _useRenseikaiRule = true;
  bool _useMoushiawaseRule = true;
  double _renseikaiTime = 2.0;
  bool _renseikaiIsRunningTime = true;
  bool _renseikaiHasHantei = true;
  String _renseikaiType = '一試合制';
  int _renseikaiOverallTime = 30;

  double _moushiawaseTime = 2.0;
  bool _moushiawaseIsRunningTime = true;
  bool _moushiawaseHasHantei = true;
  String _moushiawaseType = '一試合制';
  int _moushiawaseOverallTime = 30;

  // 通常戦の設定
  double _normalTime = 3.0;
  bool _normalIsRunningTime = false;
  bool _normalIsIpponShobu = false;
  int _normalIpponLimit = 2;
  int _normalHansokuLimit = 2;
  bool _normalHasHantei = false;
  bool _normalHasExtension = false;
  bool _normalIsEnchoUnlimited = false;
  double _normalEnchoTime = 2.0;
  int _normalEnchoCount = 1;
  String _normalKachinukiUnlimitedType = '大将対大将';
  bool _normalHasLeagueDaihyo = false;
  bool _normalIsDaihyoIpponShobu = true;
  double _normalWinPoint = 0.0;
  double _normalLossPoint = 0.0;
  double _normalDrawPoint = 0.0;
  String _normalRenseikaiType = '一試合制';
  int _normalOverallTime = 30;

  // 上位戦の設定
  double _advancedTime = 3.0;
  bool _advancedIsRunningTime = false;
  bool _advancedIsIpponShobu = false;
  int _advancedIpponLimit = 2;
  int _advancedHansokuLimit = 2;
  bool _advancedHasHantei = false;
  bool _advancedHasExtension = true;
  bool _advancedIsEnchoUnlimited = true;
  double _advancedEnchoTime = 3.0;
  int _advancedEnchoCount = 0;
  String _advancedKachinukiUnlimitedType = '大将対大将';
  bool _advancedHasLeagueDaihyo = false;
  bool _advancedIsDaihyoIpponShobu = true;
  double _advancedWinPoint = 0.0;
  double _advancedLossPoint = 0.0;
  double _advancedDrawPoint = 0.0;
  String _advancedRenseikaiType = '一試合制';
  int _advancedOverallTime = 30;

  // 代表戦の詳細設定 (通常戦用)
  double _normalDaihyoMatchTime = 0.0; // 0.0: 無制限
  bool _normalDaihyoHasExtension = true;
  double _normalDaihyoEnchoTime = 3.0;
  int _normalDaihyoEnchoCount = -2; // -2: 無制限
  bool _normalDaihyoHasHantei = false;

  // 代表戦の詳細設定 (上位戦用)
  double _advancedDaihyoMatchTime = 0.0; // 0.0: 無制限
  bool _advancedDaihyoHasExtension = true;
  double _advancedDaihyoEnchoTime = 3.0;
  int _advancedDaihyoEnchoCount = -2; // -2: 無制限
  bool _advancedDaihyoHasHantei = false;

  final _newCategoryController = TextEditingController();
  final _keywordsController = TextEditingController();

  final List<String> _presetCategories = [
    '小学生の部',
    '小学生低学年の部',
    '小学生高学年の部',
    '中学生の部',
    '中学生男子の部',
    '中学生女子の部',
    '高校生男子の部',
    '高校生女子の部',
    '一般男子の部',
    '一般女子の部',
  ];

  String _formatMinutes(double minutes) {
    if (minutes <= 0) return '0分';
    final mins = minutes.floor();
    final secs = ((minutes - mins) * 60).round();
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
    _newCategoryController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _startEditing(String category, CategoryRuleSet rules) {
    setState(() {
      _editingCategory = category;
      _useAdvancedRule = rules.useAdvancedRule;

      _isMultiScene = rules.isMultiScene;
      _useHonsenRule = rules.useHonsenRule;
      _useRenseikaiRule = rules.useRenseikaiRule;
      _useMoushiawaseRule = rules.useMoushiawaseRule;
      _renseikaiTime = rules.renseikaiRule.matchTimeMinutes;
      _renseikaiIsRunningTime = rules.renseikaiRule.isRunningTime;
      _renseikaiHasHantei = rules.renseikaiRule.hasHantei;
      _renseikaiType = rules.renseikaiRule.renseikaiType;
      _renseikaiOverallTime = rules.renseikaiRule.overallTimeMinutes;

      _moushiawaseTime = rules.moushiawaseRule.matchTimeMinutes;
      _moushiawaseIsRunningTime = rules.moushiawaseRule.isRunningTime;
      _moushiawaseHasHantei = rules.moushiawaseRule.hasHantei;
      _moushiawaseType = rules.moushiawaseRule.renseikaiType;
      _moushiawaseOverallTime = rules.moushiawaseRule.overallTimeMinutes;

      // 通常戦設定
      _normalTime = rules.normalRule.matchTimeMinutes;
      _normalIsRunningTime = rules.normalRule.isRunningTime;
      _normalIsIpponShobu = rules.normalRule.isIpponShobu;
      _normalIpponLimit = rules.normalRule.ipponLimit;
      _normalHansokuLimit = rules.normalRule.hansokuLimit;
      _normalHasHantei = rules.normalRule.hasHantei;
      _normalHasExtension =
          rules.normalRule.enchoCount > 0 || rules.normalRule.isEnchoUnlimited;
      _normalIsEnchoUnlimited = rules.normalRule.isEnchoUnlimited;
      _normalEnchoTime = rules.normalRule.enchoTimeMinutes;
      _normalEnchoCount = rules.normalRule.enchoCount;
      _normalKachinukiUnlimitedType = rules.normalRule.kachinukiUnlimitedType;
      _normalHasLeagueDaihyo = rules.normalRule.hasLeagueDaihyo;
      _normalIsDaihyoIpponShobu = rules.normalRule.isDaihyoIpponShobu;
      _normalWinPoint = rules.normalRule.winPoint;
      _normalLossPoint = rules.normalRule.lossPoint;
      _normalDrawPoint = rules.normalRule.drawPoint;
      _normalRenseikaiType = rules.normalRule.renseikaiType;
      _normalOverallTime = rules.normalRule.overallTimeMinutes;

      // 上位戦設定
      _advancedTime = rules.advancedRule.matchTimeMinutes;
      _advancedIsRunningTime = rules.advancedRule.isRunningTime;
      _advancedIsIpponShobu = rules.advancedRule.isIpponShobu;
      _advancedIpponLimit = rules.advancedRule.ipponLimit;
      _advancedHansokuLimit = rules.advancedRule.hansokuLimit;
      _advancedHasHantei = rules.advancedRule.hasHantei;
      _advancedHasExtension =
          rules.advancedRule.enchoCount > 0 ||
          rules.advancedRule.isEnchoUnlimited;
      _advancedIsEnchoUnlimited = rules.advancedRule.isEnchoUnlimited;
      _advancedEnchoTime = rules.advancedRule.enchoTimeMinutes;
      _advancedEnchoCount = rules.advancedRule.enchoCount;
      _advancedKachinukiUnlimitedType =
          rules.advancedRule.kachinukiUnlimitedType;
      _advancedHasLeagueDaihyo = rules.advancedRule.hasLeagueDaihyo;
      _advancedIsDaihyoIpponShobu = rules.advancedRule.isDaihyoIpponShobu;
      _advancedWinPoint = rules.advancedRule.winPoint;
      _advancedLossPoint = rules.advancedRule.lossPoint;
      _advancedDrawPoint = rules.advancedRule.drawPoint;
      _advancedRenseikaiType = rules.advancedRule.renseikaiType;
      _advancedOverallTime = rules.advancedRule.overallTimeMinutes;
      _editingAdvancedKeywords = List.from(rules.advancedKeywords);
      _keywordsController.text = _editingAdvancedKeywords.join(', ');

      _normalDaihyoMatchTime = rules.normalRule.daihyoMatchTimeMinutes;
      _normalDaihyoHasExtension = rules.normalRule.daihyoHasExtension;
      _normalDaihyoEnchoTime = rules.normalRule.daihyoEnchoTimeMinutes;
      _normalDaihyoEnchoCount = rules.normalRule.daihyoEnchoCount;
      _normalDaihyoHasHantei = rules.normalRule.daihyoHasHantei;

      _advancedDaihyoMatchTime = rules.advancedRule.daihyoMatchTimeMinutes;
      _advancedDaihyoHasExtension = rules.advancedRule.daihyoHasExtension;
      _advancedDaihyoEnchoTime = rules.advancedRule.daihyoEnchoTimeMinutes;
      _advancedDaihyoEnchoCount = rules.advancedRule.daihyoEnchoCount;
      _advancedDaihyoHasHantei = rules.advancedRule.daihyoHasHantei;

      _editingIsRenseikai = rules.normalRule.isRenseikai;
      if (rules.normalRule.isRenseikai) {
        _editingMatchType = '錬成会';
      } else if (rules.normalRule.isKachinuki) {
        _editingMatchType = '勝ち抜き戦';
      } else if (rules.normalRule.isLeague) {
        _editingMatchType = rules.normalRule.hasLeagueDaihyo
            ? 'リーグ団体戦'
            : 'リーグ個人戦';
      } else if (rules.normalRule.hasLeagueDaihyo) {
        _editingMatchType = '団体戦';
      } else if (rules.matchType.isNotEmpty) {
        _editingMatchType = rules.matchType;
      } else {
        _editingMatchType = category.contains('団体') ? '団体戦' : '個人戦';
      }
    });
  }

  MatchRule _buildNormalMatchRule(String category) {
    final isLeague =
        _editingMatchType == 'リーグ団体戦' || _editingMatchType == 'リーグ個人戦';
    final isKachinuki = _editingMatchType == '勝ち抜き戦';
    final hasLeagueDaihyo =
        _editingMatchType == '団体戦' || _editingMatchType == 'リーグ団体戦';

    return MatchRule(
      category: category,
      matchTimeMinutes: _normalTime,
      isRunningTime: _normalIsRunningTime,
      isIpponShobu: _normalIsIpponShobu,
      ipponLimit: _normalIsIpponShobu ? 1 : _normalIpponLimit,
      hansokuLimit: _normalHansokuLimit,
      hasHantei: _normalHasHantei,
      isEnchoUnlimited: _normalHasExtension && _normalIsEnchoUnlimited,
      enchoTimeMinutes: _normalEnchoTime,
      enchoCount: _normalHasExtension
          ? (_normalIsEnchoUnlimited ? 0 : _normalEnchoCount)
          : 0,
      isKachinuki: isKachinuki,
      kachinukiUnlimitedType: _normalKachinukiUnlimitedType,
      hasLeagueDaihyo: hasLeagueDaihyo,
      isDaihyoIpponShobu: _normalIsDaihyoIpponShobu,
      winPoint: _normalWinPoint,
      lossPoint: _normalLossPoint,
      drawPoint: _normalDrawPoint,
      isRenseikai: _editingIsRenseikai,
      renseikaiType: _normalRenseikaiType,
      overallTimeMinutes: _normalOverallTime,
      isLeague: isLeague,
      daihyoMatchTimeMinutes: _normalDaihyoMatchTime,
      daihyoHasExtension: _normalDaihyoHasExtension,
      daihyoEnchoTimeMinutes: _normalDaihyoEnchoTime,
      daihyoEnchoCount: _normalDaihyoEnchoCount,
      daihyoHasHantei: _normalDaihyoHasHantei,
    );
  }

  MatchRule _buildAdvancedMatchRule(String category) {
    final isLeague =
        _editingMatchType == 'リーグ団体戦' || _editingMatchType == 'リーグ個人戦';
    final isKachinuki = _editingMatchType == '勝ち抜き戦';
    final hasLeagueDaihyo =
        _editingMatchType == '団体戦' || _editingMatchType == 'リーグ団体戦';

    return MatchRule(
      category: category,
      matchTimeMinutes: _advancedTime,
      isRunningTime: _advancedIsRunningTime,
      isIpponShobu: _advancedIsIpponShobu,
      ipponLimit: _advancedIsIpponShobu ? 1 : _advancedIpponLimit,
      hansokuLimit: _advancedHansokuLimit,
      hasHantei: _advancedHasHantei,
      isEnchoUnlimited: _advancedHasExtension && _advancedIsEnchoUnlimited,
      enchoTimeMinutes: _advancedEnchoTime,
      enchoCount: _advancedHasExtension
          ? (_advancedIsEnchoUnlimited ? 0 : _advancedEnchoCount)
          : 0,
      isKachinuki: isKachinuki,
      kachinukiUnlimitedType: _advancedKachinukiUnlimitedType,
      hasLeagueDaihyo: hasLeagueDaihyo,
      isDaihyoIpponShobu: _advancedIsDaihyoIpponShobu,
      winPoint: _advancedWinPoint,
      lossPoint: _advancedLossPoint,
      drawPoint: _advancedDrawPoint,
      isRenseikai: _editingIsRenseikai,
      renseikaiType: _advancedRenseikaiType,
      overallTimeMinutes: _advancedOverallTime,
      isLeague: isLeague,
      daihyoMatchTimeMinutes: _advancedDaihyoMatchTime,
      daihyoHasExtension: _advancedDaihyoHasExtension,
      daihyoEnchoTimeMinutes: _advancedDaihyoEnchoTime,
      daihyoEnchoCount: _advancedDaihyoEnchoCount,
      daihyoHasHantei: _advancedDaihyoHasHantei,
    );
  }

  // 上位戦かどうかの判定用ヘルパー
  bool _isAdvancedMatchName(String note, {List<String>? customKeywords}) {
    final cleanNote = note.toLowerCase().trim();
    final List<String> keywords;
    if (customKeywords != null && customKeywords.isNotEmpty) {
      keywords = customKeywords.map((kw) => kw.toLowerCase().trim()).toList();
    } else {
      keywords = [
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
    }

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

  Future<void> _saveCategoryRules(TournamentModel tournament) async {
    if (_editingCategory == null) return;

    final category = _editingCategory!;
    final normalRule = _buildNormalMatchRule(category);
    final advancedRule = _buildAdvancedMatchRule(category);

    final renseikaiRule = MatchRule(
      matchTimeMinutes: _renseikaiTime,
      isRunningTime: _renseikaiIsRunningTime,
      hasHantei: _renseikaiHasHantei,
      enchoCount: 0,
      isEnchoUnlimited: false,
      isRenseikai: true,
      renseikaiType: _renseikaiType,
      overallTimeMinutes: _renseikaiOverallTime,
    );

    final moushiawaseRule = MatchRule(
      matchTimeMinutes: _moushiawaseTime,
      isRunningTime: _moushiawaseIsRunningTime,
      hasHantei: _moushiawaseHasHantei,
      enchoCount: 0,
      isEnchoUnlimited: false,
      isRenseikai: true,
      renseikaiType: _moushiawaseType,
      overallTimeMinutes: _moushiawaseOverallTime,
    );

    final newRuleSet = CategoryRuleSet(
      normalRule: normalRule,
      advancedRule: advancedRule,
      useAdvancedRule: _useAdvancedRule,
      advancedKeywords: _editingAdvancedKeywords,
      matchType: _editingIsRenseikai ? '錬成会' : _editingMatchType,
      isMultiScene: _isMultiScene,
      useHonsenRule: _useHonsenRule,
      useRenseikaiRule: _useRenseikaiRule,
      useMoushiawaseRule: _useMoushiawaseRule,
      renseikaiRule: renseikaiRule,
      moushiawaseRule: moushiawaseRule,
    );

    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    );
    updatedCategoryRules[category] = newRuleSet;

    // 大会モデルのリスト更新
    List<String> updatedCategories = List.from(tournament.categories);
    if (!updatedCategories.contains(category)) {
      updatedCategories.add(category);
    }

    final updatedTournament = tournament.copyWith(
      categories: updatedCategories,
      categoryRules: updatedCategoryRules,
    );

    // 既存の試合を探して一括適用の判定
    final allMatches =
        ref.read(matchListByTournamentProvider(widget.tournamentId)).value ??
        [];
    final targetMatches = allMatches
        .where(
          (m) =>
              m.category == category &&
              m.status != 'finished' &&
              m.status != 'approved',
        )
        .toList();

    if (targetMatches.isNotEmpty) {
      // 確認ダイアログを表示
      final result = await showAppDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AppDialog(
          title: '作成済みの試合に一括適用しますか？',
          content: Text(
            '「$category」の未開始・進行前の試合が ${targetMatches.length} 件見つかりました。\n'
            '設定したルールをこれらの既存の試合にも今すぐ適用しますか？\n'
            '（※すでに終了した試合のデータは保護されます）',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: AppKendoColors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'no'),
              child: const Text('適用しない（新規試合のみ）'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'yes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                foregroundColor: AppKendoColors.pureWhite,
              ),
              child: const Text(
                '一括適用する',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (result == 'cancel') return;

      if (result == 'yes') {
        // 既存の試合に適用する
        List<MatchModel> matchesToSave = [];
        for (var match in targetMatches) {
          final isAdvanced =
              _useAdvancedRule &&
              _isAdvancedMatchName(
                match.note,
                customKeywords: _editingAdvancedKeywords,
              );
          final activeRule = isAdvanced ? advancedRule : normalRule;

          final updatedMatch = match.copyWith(
            matchTimeMinutes: activeRule.matchTimeMinutes,
            isRunningTime: activeRule.isRunningTime,
            hasExtension:
                activeRule.enchoCount > 0 || activeRule.isEnchoUnlimited,
            extensionTimeMinutes: activeRule.enchoTimeMinutes,
            extensionCount: activeRule.enchoCount,
            hasHantei: activeRule.hasHantei,
            isKachinuki: activeRule.isKachinuki,
            rule: activeRule,
          );
          matchesToSave.add(updatedMatch);
        }

        await ref
            .read(matchApplicationServiceProvider)
            .saveMatchesBulk(matchesToSave);
      }
    }

    // 大会データの保存
    await ref
        .read(tournamentRepositoryProvider)
        .updateTournament(updatedTournament);

    if (mounted) {
      AppSnackBar.showSuccess(context, '「$category」のルール設定を保存しました');
      setState(() {
        _editingCategory = null;
      });
    }
  }

  Future<void> _deleteCategory(
    TournamentModel tournament,
    String category,
  ) async {
    final result = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: '部門を削除しますか？',
        titleIcon: Icons.warning_amber_rounded,
        iconColor: AppKendoColors.red,
        content: Text('「$category」の部門および設定されているデフォルトルールをリストから削除します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppKendoColors.hansokuRed,
              foregroundColor: AppKendoColors.pureWhite,
            ),
            child: const Text(
              '削除',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
        tournament.categoryRules,
      );
      updatedCategoryRules.remove(category);

      List<String> updatedCategories = List.from(tournament.categories);
      updatedCategories.remove(category);

      final updatedTournament = tournament.copyWith(
        categories: updatedCategories,
        categoryRules: updatedCategoryRules,
      );

      await ref
          .read(tournamentRepositoryProvider)
          .updateTournament(updatedTournament);

      if (mounted) {
        AppSnackBar.show(context, '「$category」を削除しました');
      }
    }
  }

  void _addNewCategory(TournamentModel tournament, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    if (tournament.categoryRules.containsKey(cleanName)) {
      final existingRuleSet = tournament.categoryRules[cleanName]!;
      _startEditing(cleanName, existingRuleSet);
      return;
    }

    // デフォルトルールで登録
    final newRuleSet = CategoryRuleSet(
      normalRule: const MatchRule(matchTimeMinutes: 3.0),
      advancedRule: const MatchRule(matchTimeMinutes: 3.0),
      useAdvancedRule: false,
    );

    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    );
    updatedCategoryRules[cleanName] = newRuleSet;

    List<String> updatedCategories = List.from(tournament.categories);
    if (!updatedCategories.contains(cleanName)) {
      updatedCategories.add(cleanName);
    }

    final updatedTournament = tournament.copyWith(
      categories: updatedCategories,
      categoryRules: updatedCategoryRules,
    );

    await ref
        .read(tournamentRepositoryProvider)
        .updateTournament(updatedTournament);
    _newCategoryController.clear();

    if (mounted) {
      AppSnackBar.showSuccess(context, '「$cleanName」を追加しました');
      _startEditing(cleanName, newRuleSet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final asyncTournament = ref.watch(tournamentProvider(widget.tournamentId));

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          title: _editingCategory == null ? '部門別ルール設定' : 'ルールの編集',
          backgroundColor: AppKendoColors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_editingCategory != null) {
                setState(() {
                  _editingCategory = null;
                });
              } else {
                context.pop();
              }
            },
          ),
          actions: [
            if (widget.isFromSetup && _editingCategory == null)
              TextButton(
                onPressed: () => context.go('/home/${widget.tournamentId}'),
                child: Text(
                  'スキップ',
                  style: TextStyle(
                    color: themeColors.primaryAccent,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: asyncTournament.when(
          data: (tournament) {
            if (tournament == null) {
              return const Center(child: Text('大会データが見つかりません'));
            }
            if (_editingCategory != null) {
              return _buildRuleEditor(
                tournament,
                _editingCategory!,
                themeColors,
              );
            }
            final enableLiquidGlass = ref.watch(
              settingsProvider.select((s) => s.enableLiquidGlass),
            );
            return CategoryRulesListSection(
              tournament: tournament,
              isDark: isDark,
              enableLiquidGlass: enableLiquidGlass,
              newCategoryController: _newCategoryController,
              presetCategories: _presetCategories,
              isFromSetup: widget.isFromSetup,
              tournamentId: widget.tournamentId,
              onAddCategory: (name) => _addNewCategory(tournament, name),
              onStartEditing: (cat, ruleSet) => _startEditing(cat, ruleSet),
              onDeleteCategory: (cat) => _deleteCategory(tournament, cat),
              onShowRuleDetail: (cat, ruleSet) =>
                  _showRuleDetailBottomSheet(context, cat, ruleSet),
              onCompleteSetup: () => context.go('/home/${widget.tournamentId}'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('エラーが発生しました: $e')),
        ),
      ),
    );
  }

  Widget _buildRuleEditor(
    TournamentModel tournament,
    String category,
    AppThemeColors themeColors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = themeColors.textColor;
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.roundValue),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppKendoColors.indigo.withValues(alpha: 0.05),
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: AppKendoColors.indigo.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppKendoColors.indigo,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '対象部門',
                            style: TextStyle(
                              fontSize: AppFontSize.small,
                              color: AppKendoColors.indigo,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: AppFontSize.headline,
                              fontWeight: AppFontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              const Text(
                '試合方式',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                  color: AppKendoColors.indigo,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _editingMatchType,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  fillColor: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFFFFFFF),
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(value: '個人戦', child: Text('個人戦')),
                  DropdownMenuItem(value: '団体戦', child: Text('団体戦 (トーナメント)')),
                  DropdownMenuItem(value: 'リーグ個人戦', child: Text('リーグ個人戦')),
                  DropdownMenuItem(value: 'リーグ団体戦', child: Text('リーグ団体戦')),
                  DropdownMenuItem(value: '勝ち抜き戦', child: Text('勝ち抜き戦 (団体戦)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _editingMatchType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '⚔️ 遠征マルチシーンルール（錬成会・本戦・申し合わせ）',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.subhead,
                  ),
                ),
                subtitle: const Text(
                  'ONにすると、1つの部門に「錬成会」「本戦」「申し合わせ」の各ルールを個別に定義できます。',
                ),
                value: _isMultiScene,
                activeThumbColor: AppKendoColors.ipponGold,
                onChanged: (val) {
                  setState(() {
                    _isMultiScene = val;
                  });
                },
              ),

              const Divider(height: 16),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '準決勝・決勝は別ルールにする',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.subhead,
                  ),
                ),
                subtitle: const Text('ONにすると、上位戦用の特別ルールを別途定義できます。'),
                value: _useAdvancedRule,
                activeThumbColor: AppKendoColors.indigo,
                onChanged: (val) {
                  setState(() {
                    _useAdvancedRule = val;
                  });
                },
              ),

              const Divider(height: 32),

              if (_isMultiScene) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppKendoColors.ipponGold
                                : const Color(0xFFD97706))
                            .withValues(alpha: 0.1),
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color:
                          (isDark
                                  ? AppKendoColors.ipponGold
                                  : const Color(0xFFD97706))
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '実施するルールシーンの選択',
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.bodySmall,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '⚔️ 錬成会ルール',
                          style: TextStyle(fontSize: AppFontSize.body),
                        ),
                        value: _useRenseikaiRule,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _useRenseikaiRule = val);
                          }
                        },
                      ),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '🏆 本戦ルール',
                          style: TextStyle(fontSize: AppFontSize.body),
                        ),
                        value: _useHonsenRule,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _useHonsenRule = val);
                          }
                        },
                      ),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '🤝 申し合わせルール',
                          style: TextStyle(fontSize: AppFontSize.body),
                        ),
                        value: _useMoushiawaseRule,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _useMoushiawaseRule = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DefaultTabController(
                  length: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TabBar(
                        labelColor: AppKendoColors.indigo,
                        unselectedLabelColor: AppKendoColors.grey,
                        indicatorColor: AppKendoColors.indigo,
                        isScrollable: true,
                        labelStyle: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.body,
                        ),
                        tabs: [
                          Tab(text: '⚔️ 錬成会ルール'),
                          Tab(text: '🏆 本戦ルール'),
                          Tab(text: '🤝 申し合わせルール'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 450,
                        child: TabBarView(
                          children: [
                            ListView(
                              children: [
                                CategorySimpleSceneRuleForm(
                                  title: '⚔️ 錬成会ルール',
                                  time: _renseikaiTime,
                                  isRunning: _renseikaiIsRunningTime,
                                  hasHantei: _renseikaiHasHantei,
                                  renseikaiType: _renseikaiType,
                                  overallTime: _renseikaiOverallTime,
                                  onTimeChanged: (val) =>
                                      setState(() => _renseikaiTime = val),
                                  onRunningChanged: (val) => setState(
                                    () => _renseikaiIsRunningTime = val,
                                  ),
                                  onHanteiChanged: (val) =>
                                      setState(() => _renseikaiHasHantei = val),
                                  onTypeChanged: (val) =>
                                      setState(() => _renseikaiType = val),
                                  onOverallTimeChanged: (val) => setState(
                                    () => _renseikaiOverallTime = val,
                                  ),
                                ),
                              ],
                            ),
                            ListView(
                              children: [
                                _buildRuleFormSection(
                                  '🏆 本戦ルール',
                                  true,
                                  themeColors,
                                ),
                              ],
                            ),
                            ListView(
                              children: [
                                CategorySimpleSceneRuleForm(
                                  title: '🤝 申し合わせルール',
                                  time: _moushiawaseTime,
                                  isRunning: _moushiawaseIsRunningTime,
                                  hasHantei: _moushiawaseHasHantei,
                                  renseikaiType: _moushiawaseType,
                                  overallTime: _moushiawaseOverallTime,
                                  onTimeChanged: (val) =>
                                      setState(() => _moushiawaseTime = val),
                                  onRunningChanged: (val) => setState(
                                    () => _moushiawaseIsRunningTime = val,
                                  ),
                                  onHanteiChanged: (val) => setState(
                                    () => _moushiawaseHasHantei = val,
                                  ),
                                  onTypeChanged: (val) =>
                                      setState(() => _moushiawaseType = val),
                                  onOverallTimeChanged: (val) => setState(
                                    () => _moushiawaseOverallTime = val,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!_useAdvancedRule) ...[
                _buildRuleFormSection('通常戦（本戦）ルール', true, themeColors),
              ] else ...[
                DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TabBar(
                        labelColor: AppKendoColors.indigo,
                        unselectedLabelColor: AppKendoColors.grey,
                        indicatorColor: AppKendoColors.indigo,
                        labelStyle: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.bodyMedium,
                        ),
                        tabs: [
                          Tab(text: '通常戦のルール'),
                          Tab(text: '上位戦（準決勝・決勝）'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 800,
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ListView(
                              children: [
                                _buildRuleFormSection(
                                  '通常戦ルール',
                                  true,
                                  themeColors,
                                ),
                              ],
                            ),
                            ListView(
                              children: [
                                _buildRuleFormSection(
                                  '上位戦ルール',
                                  false,
                                  themeColors,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // 下部アクションボタン
        Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: enableLiquidGlass
                ? AppKendoColors.transparent
                : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF)),
            border: Border(
              top: BorderSide(
                color: enableLiquidGlass
                    ? Colors.transparent
                    : (isDark
                          ? const Color(0xFF38383A)
                          : context.appColors.separatorColor),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editingCategory = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.modernValue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassButton(
                  onPressed: () => _saveCategoryRules(tournament),
                  color: AppKendoColors.indigo,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.modernValue,
                  ),
                  label: '設定を保存',
                  icon: Icons.save,
                  expandContent: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleFormSection(
    String title,
    bool isNormal,
    AppThemeColors themeColors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // isNormal に応じて状態変数への参照を分ける
    double matchTime = isNormal ? _normalTime : _advancedTime;
    bool isRunningTime = isNormal
        ? _normalIsRunningTime
        : _advancedIsRunningTime;
    int ipponLimit = isNormal ? _normalIpponLimit : _advancedIpponLimit;
    bool hasHantei = isNormal ? _normalHasHantei : _advancedHasHantei;
    bool hasExtension = isNormal ? _normalHasExtension : _advancedHasExtension;
    bool isEnchoUnlimited = isNormal
        ? _normalIsEnchoUnlimited
        : _advancedIsEnchoUnlimited;
    double enchoTime = isNormal ? _normalEnchoTime : _advancedEnchoTime;
    int enchoCount = isNormal ? _normalEnchoCount : _advancedEnchoCount;
    int hansokuLimit = isNormal ? _normalHansokuLimit : _advancedHansokuLimit;
    String kachinukiUnlimitedType = isNormal
        ? _normalKachinukiUnlimitedType
        : _advancedKachinukiUnlimitedType;
    bool hasLeagueDaihyo = isNormal
        ? _normalHasLeagueDaihyo
        : _advancedHasLeagueDaihyo;
    bool isDaihyoIpponShobu = isNormal
        ? _normalIsDaihyoIpponShobu
        : _advancedIsDaihyoIpponShobu;
    double winPoint = isNormal ? _normalWinPoint : _advancedWinPoint;
    double lossPoint = isNormal ? _normalLossPoint : _advancedLossPoint;
    double drawPoint = isNormal ? _normalDrawPoint : _advancedDrawPoint;
    String renseikaiType = isNormal
        ? _normalRenseikaiType
        : _advancedRenseikaiType;
    int overallTime = isNormal ? _normalOverallTime : _advancedOverallTime;

    // 追加分のマッピング
    double daihyoMatchTime = isNormal
        ? _normalDaihyoMatchTime
        : _advancedDaihyoMatchTime;
    bool daihyoHasExtension = isNormal
        ? _normalDaihyoHasExtension
        : _advancedDaihyoHasExtension;
    double daihyoEnchoTime = isNormal
        ? _normalDaihyoEnchoTime
        : _advancedDaihyoEnchoTime;
    int daihyoEnchoCount = isNormal
        ? _normalDaihyoEnchoCount
        : _advancedDaihyoEnchoCount;
    bool daihyoHasHantei = isNormal
        ? _normalDaihyoHasHantei
        : _advancedDaihyoHasHantei;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        const SizedBox(height: AppSpacing.lg),

        // 1. 共通: 試合時間設定
        CategoryTimeStepperTile(
          title: '試合時間',
          subtitle: '30秒単位で自由に増減できます',
          value: matchTime,
          minValue: 0.5,
          maxValue: 15.0,
          step: 0.5,
          primaryColor: themeColors.primaryAccent,
          onChanged: (newVal) {
            setState(() {
              if (isNormal) {
                _normalTime = newVal;
              } else {
                _advancedTime = newVal;
              }
            });
          },
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            'クイック選択',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0].map((t) {
            final isSelected = matchTime == t;
            return AppChoiceChip(
              label: Text(_formatMinutes(t)),
              selected: isSelected,
              onSelected: (s) {
                if (s) {
                  setState(() {
                    if (isNormal) {
                      _normalTime = t;
                    } else {
                      _advancedTime = t;
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // === 形式別表示 ===
        if (_editingIsRenseikai) ...[
          // ----------------------------------------------------
          // 錬成会モード (Renseikai Mode)
          // ----------------------------------------------------
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('ランニングタイム計測'),
            subtitle: const Text('ON: 試合中断時も時計を止めない / OFF: 都度停止'),
            value: isRunningTime,
            activeThumbColor: AppKendoColors.indigo,
            onChanged: (val) {
              setState(() {
                if (isNormal) {
                  _normalIsRunningTime = val;
                } else {
                  _advancedIsRunningTime = val;
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '進行形式',
            style: TextStyle(
              fontWeight: AppFontWeight.semiBold,
              fontSize: AppFontSize.body,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['一試合制', '時間制'].map((type) {
              final isSelected = renseikaiType == type;
              return AppChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      if (isNormal) {
                        _normalRenseikaiType = type;
                      } else {
                        _advancedRenseikaiType = type;
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
          if (renseikaiType == '時間制') ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: ValueKey('renseikai_time_${isNormal}_$_editingCategory'),
              initialValue: overallTime.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '全体の制限時間（分）',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(AppSpacing.md),
              ),
              onChanged: (val) {
                final i = int.tryParse(val) ?? 30;
                if (isNormal) {
                  _normalOverallTime = i;
                } else {
                  _advancedOverallTime = i;
                }
              },
            ),
          ],
          const Divider(height: 32),
        ] else if (_editingMatchType == '勝ち抜き戦') ...[
          // ----------------------------------------------------
          // 勝ち抜き戦 (Kachinuki Mode)
          // ----------------------------------------------------
          const SizedBox(height: AppSpacing.md),
          const Text(
            '大将 VS 大将 のときの挙動',
            style: TextStyle(
              fontWeight: AppFontWeight.semiBold,
              fontSize: AppFontSize.body,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChoiceChip(
                label: const Text('延長戦を行う (デフォルト)'),
                selected:
                    kachinukiUnlimitedType == '大将対大将' ||
                    kachinukiUnlimitedType == '無制限' ||
                    kachinukiUnlimitedType == '大将のみ',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      if (isNormal) {
                        _normalKachinukiUnlimitedType = '大将対大将';
                      } else {
                        _advancedKachinukiUnlimitedType = '大将対大将';
                      }
                    });
                  }
                },
              ),
              AppChoiceChip(
                label: const Text('引き分けとする'),
                selected:
                    kachinukiUnlimitedType == 'なし' ||
                    kachinukiUnlimitedType.isEmpty,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      if (isNormal) {
                        _normalKachinukiUnlimitedType = 'なし';
                      } else {
                        _advancedKachinukiUnlimitedType = 'なし';
                      }
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            '大将対他のポジション（大将以外）の挙動',
            style: TextStyle(
              fontWeight: AppFontWeight.semiBold,
              fontSize: AppFontSize.body,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChoiceChip(
                label: const Text('引き分けとする (デフォルト)'),
                selected:
                    kachinukiUnlimitedType == '大将対大将' ||
                    kachinukiUnlimitedType == 'なし' ||
                    kachinukiUnlimitedType.isEmpty ||
                    kachinukiUnlimitedType == '大将のみ',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      if (isNormal) {
                        if (kachinukiUnlimitedType == 'なし' ||
                            kachinukiUnlimitedType.isEmpty) {
                          _normalKachinukiUnlimitedType = 'なし';
                        } else {
                          _normalKachinukiUnlimitedType = '大将対大将';
                        }
                      } else {
                        if (kachinukiUnlimitedType == 'なし' ||
                            kachinukiUnlimitedType.isEmpty) {
                          _advancedKachinukiUnlimitedType = 'なし';
                        } else {
                          _advancedKachinukiUnlimitedType = '大将対大将';
                        }
                      }
                    });
                  }
                },
              ),
              AppChoiceChip(
                label: const Text('延長戦を行う'),
                selected: kachinukiUnlimitedType == '無制限',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      if (isNormal) {
                        _normalKachinukiUnlimitedType = '無制限';
                      } else {
                        _advancedKachinukiUnlimitedType = '無制限';
                      }
                    });
                  }
                },
              ),
            ],
          ),
          const Divider(height: 32),
        ] else if (_editingMatchType == '個人戦' ||
            _editingMatchType == 'リーグ個人戦') ...[
          // ----------------------------------------------------
          // 個人戦 / リーグ個人戦 (Individual Mode)
          // ----------------------------------------------------
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('延長戦を有効にする'),
            value: hasExtension,
            activeThumbColor: AppKendoColors.indigo,
            onChanged: (val) {
              setState(() {
                if (isNormal) {
                  _normalHasExtension = val;
                } else {
                  _advancedHasExtension = val;
                }
              });
            },
          ),
          if (hasExtension) ...[
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.only(left: AppSpacing.lg),
              title: const Text('時間・回数無制限'),
              value: isEnchoUnlimited,
              activeThumbColor: AppKendoColors.indigo,
              onChanged: (val) {
                setState(() {
                  if (isNormal) {
                    _normalIsEnchoUnlimited = val;
                  } else {
                    _advancedIsEnchoUnlimited = val;
                  }
                });
              },
            ),
            if (!isEnchoUnlimited) ...[
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.sm,
                  top: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('最大延長回数'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: enchoCount > 1
                              ? () => setState(() {
                                  if (isNormal) {
                                    _normalEnchoCount--;
                                  } else {
                                    _advancedEnchoCount--;
                                  }
                                })
                              : null,
                        ),
                        Text(
                          '$enchoCount回',
                          style: const TextStyle(
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: enchoCount < 10
                              ? () => setState(() {
                                  if (isNormal) {
                                    _normalEnchoCount++;
                                  } else {
                                    _advancedEnchoCount++;
                                  }
                                })
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            CategoryTimeStepperTile(
              title: '延長戦の時間',
              value: enchoTime,
              minValue: 0.5,
              maxValue: 10.0,
              step: 0.5,
              primaryColor: themeColors.primaryAccent,
              onChanged: (newVal) {
                setState(() {
                  if (isNormal) {
                    _normalEnchoTime = newVal;
                  } else {
                    _advancedEnchoTime = newVal;
                  }
                });
              },
            ),
          ],
          if (!hasExtension || !isEnchoUnlimited) ...[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('引き分け時の判定を有効にする'),
              value: hasHantei,
              activeThumbColor: AppKendoColors.indigo,
              onChanged: (val) {
                setState(() {
                  if (isNormal) {
                    _normalHasHantei = val;
                  } else {
                    _advancedHasHantei = val;
                  }
                });
              },
            ),
          ],
          if (_editingMatchType == 'リーグ個人戦') ...[
            const Divider(height: 32),
            CategoryLeaguePointsSection(
              keyPrefix: '${isNormal}_$_editingCategory',
              winPoint: winPoint,
              lossPoint: lossPoint,
              drawPoint: drawPoint,
              onWinChanged: (d) {
                setState(() {
                  if (isNormal) {
                    _normalWinPoint = d;
                  } else {
                    _advancedWinPoint = d;
                  }
                });
              },
              onLossChanged: (d) {
                setState(() {
                  if (isNormal) {
                    _normalLossPoint = d;
                  } else {
                    _advancedLossPoint = d;
                  }
                });
              },
              onDrawChanged: (d) {
                setState(() {
                  if (isNormal) {
                    _normalDrawPoint = d;
                  } else {
                    _advancedDrawPoint = d;
                  }
                });
              },
            ),
          ],
          const Divider(height: 32),
        ] else if (_editingMatchType == '団体戦' ||
            _editingMatchType == 'リーグ団体戦') ...[
          // ----------------------------------------------------
          // 団体戦 / リーグ団体戦 (Team Mode)
          // ----------------------------------------------------
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('代表戦あり（団体戦用）'),
            subtitle: const Text('チーム合計が引き分けの時、代表者同士で決定戦を行います。'),
            value: hasLeagueDaihyo,
            activeThumbColor: AppKendoColors.indigo,
            onChanged: (val) {
              setState(() {
                if (isNormal) {
                  _normalHasLeagueDaihyo = val;
                } else {
                  _advancedHasLeagueDaihyo = val;
                }
              });
            },
          ),
          if (hasLeagueDaihyo) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              '代表戦の本数',
              style: TextStyle(
                fontWeight: AppFontWeight.semiBold,
                fontSize: AppFontSize.body,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChoiceChip(
                  label: const Text('１本勝負 (デフォルト)'),
                  selected: isDaihyoIpponShobu,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        if (isNormal) {
                          _normalIsDaihyoIpponShobu = true;
                        } else {
                          _advancedIsDaihyoIpponShobu = true;
                        }
                      });
                    }
                  },
                ),
                AppChoiceChip(
                  label: const Text('３本勝負'),
                  selected: !isDaihyoIpponShobu,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        if (isNormal) {
                          _normalIsDaihyoIpponShobu = false;
                        } else {
                          _advancedIsDaihyoIpponShobu = false;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '代表戦の試合時間',
              style: TextStyle(
                fontWeight: AppFontWeight.semiBold,
                fontSize: AppFontSize.body,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChoiceChip(
                  label: const Text('時間制限なし (デフォルト)'),
                  selected: daihyoMatchTime == 0.0,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        if (isNormal) {
                          _normalDaihyoMatchTime = 0.0;
                        } else {
                          _advancedDaihyoMatchTime = 0.0;
                        }
                      });
                    }
                  },
                ),
                ...[1.5, 2.0, 2.5, 3.0, 4.0, 5.0].map((t) {
                  final isSelected = daihyoMatchTime == t;
                  return AppChoiceChip(
                    label: Text(_formatMinutes(t)),
                    selected: isSelected,
                    onSelected: (s) {
                      if (s) {
                        setState(() {
                          if (isNormal) {
                            _normalDaihyoMatchTime = t;
                          } else {
                            _advancedDaihyoMatchTime = t;
                          }
                        });
                      }
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('代表戦の延長を有効にする'),
              value: daihyoHasExtension,
              activeThumbColor: AppKendoColors.indigo,
              onChanged: (val) {
                setState(() {
                  if (isNormal) {
                    _normalDaihyoHasExtension = val;
                  } else {
                    _advancedDaihyoHasExtension = val;
                  }
                });
              },
            ),
            if (daihyoHasExtension) ...[
              CategoryTimeStepperTile(
                title: '代表戦延長の時間',
                value: daihyoEnchoTime,
                minValue: 0.5,
                maxValue: 10.0,
                step: 0.5,
                primaryColor: themeColors.primaryAccent,
                onChanged: (newVal) {
                  setState(() {
                    if (isNormal) {
                      _normalDaihyoEnchoTime = newVal;
                    } else {
                      _advancedDaihyoEnchoTime = newVal;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.lg),
                child: Text(
                  '代表戦延長の回数',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodySmall,
                    color: AppKendoColors.grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  top: AppSpacing.xs,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppChoiceChip(
                      label: const Text('無制限 (デフォルト)'),
                      selected: daihyoEnchoCount == -2,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            if (isNormal) {
                              _normalDaihyoEnchoCount = -2;
                            } else {
                              _advancedDaihyoEnchoCount = -2;
                            }
                          });
                        }
                      },
                    ),
                    ...[1, 2, 3, 5].map((c) {
                      final isSelected = daihyoEnchoCount == c;
                      return AppChoiceChip(
                        label: Text('$c回'),
                        selected: isSelected,
                        onSelected: (s) {
                          if (s) {
                            setState(() {
                              if (isNormal) {
                                _normalDaihyoEnchoCount = c;
                              } else {
                                _advancedDaihyoEnchoCount = c;
                              }
                            });
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('代表戦の判定を有効にする'),
              subtitle: const Text('時間切れで決着がつかない場合に判定を行います。'),
              value: daihyoHasHantei,
              activeThumbColor: AppKendoColors.indigo,
              onChanged: (val) {
                setState(() {
                  if (isNormal) {
                    _normalDaihyoHasHantei = val;
                  } else {
                    _advancedDaihyoHasHantei = val;
                  }
                });
              },
            ),
          ],
          if (_editingMatchType == 'リーグ団体戦') ...[
            const Divider(height: 32),
            CategoryLeaguePointsSection(
              keyPrefix: '${isNormal}_$_editingCategory',
              winPoint: winPoint,
              lossPoint: lossPoint,
              drawPoint: drawPoint,
              onWinChanged: (d) {
                setState(() {
                  if (isNormal) {
                    _normalWinPoint = d;
                  } else {
                    _advancedWinPoint = d;
                  }
                });
              },
              onLossChanged: (d) {
                setState(() {
                  if (isNormal) {
                    _normalLossPoint = d;
                  } else {
                    _advancedLossPoint = d;
                  }
                });
              },
              onDrawChanged: (d) {
                setState(() {
                  if (isNormal) {
                    _normalDrawPoint = d;
                  } else {
                    _advancedDrawPoint = d;
                  }
                });
              },
            ),
          ],
          const Divider(height: 32),
        ],

        // ----------------------------------------------------
        // 2. 詳細設定（得点制限、反則数など）- ExpansionTileで隠す
        // ----------------------------------------------------
        Theme(
          data: Theme.of(
            context,
          ).copyWith(dividerColor: AppKendoColors.transparent),
          child: ExpansionTile(
            title: const Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: AppKendoColors.grey,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '詳細設定（得点制限・反則ルール）',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.body,
                    color: AppKendoColors.grey,
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0x33000000),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 勝敗本数制限
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '勝敗本数制限（得点制限）',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.bodySmall,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '勝敗に必要な本数（通常は三本勝負＝2本先取）',
                                style: TextStyle(
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                              ),
                              onPressed: ipponLimit > 1
                                  ? () => setState(() {
                                      if (isNormal) {
                                        _normalIpponLimit--;
                                      } else {
                                        _advancedIpponLimit--;
                                      }
                                    })
                                  : null,
                            ),
                            Text(
                              '$ipponLimit本',
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.body,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              onPressed: ipponLimit < 5
                                  ? () => setState(() {
                                      if (isNormal) {
                                        _normalIpponLimit++;
                                      } else {
                                        _advancedIpponLimit++;
                                      }
                                    })
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // 反則制限
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '反則制限本数（ペナルティ）',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.bodySmall,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '相手に一本を与える反則の数（公式は反則2回）',
                                style: TextStyle(
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                              ),
                              onPressed: hansokuLimit > 1
                                  ? () => setState(() {
                                      if (isNormal) {
                                        _normalHansokuLimit--;
                                      } else {
                                        _advancedHansokuLimit--;
                                      }
                                    })
                                  : null,
                            ),
                            Text(
                              '$hansokuLimit回',
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.body,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              onPressed: hansokuLimit < 5
                                  ? () => setState(() {
                                      if (isNormal) {
                                        _normalHansokuLimit++;
                                      } else {
                                        _advancedHansokuLimit++;
                                      }
                                    })
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (!isNormal) ...[
          const Divider(height: 32),
          const Text(
            '自動判別用キーワード設定',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.body,
              color: AppKendoColors.indigo,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '試合詳細メモに入力された文字と部分一致した場合に、この上位戦ルールを自動適用します。',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: AppKendoColors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: ValueKey('advanced_keywords_field_$_editingCategory'),
            controller: _keywordsController,
            decoration: const InputDecoration(
              labelText: '自動判定キーワード（カンマ「,」区切り）',
              hintText: '例: 準決勝, 決勝, 3位決定',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(AppSpacing.md),
            ),
            onChanged: (val) {
              _editingAdvancedKeywords = val
                  .split(',')
                  .map((kw) => kw.trim())
                  .where((kw) => kw.isNotEmpty)
                  .toList();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppActionChip(
                label: const Text('準決勝以上'),
                onPressed: () {
                  setState(() {
                    _editingAdvancedKeywords = [
                      '準決勝',
                      '準決',
                      'ベスト4',
                      '決勝',
                      'final',
                      '3位決定',
                      '3決',
                    ];
                    _keywordsController.text = _editingAdvancedKeywords.join(
                      ', ',
                    );
                  });
                },
              ),
              AppActionChip(
                label: const Text('決勝のみ'),
                onPressed: () {
                  setState(() {
                    _editingAdvancedKeywords = ['決勝', 'final'];
                    _keywordsController.text = _editingAdvancedKeywords.join(
                      ', ',
                    );
                  });
                },
              ),
              AppActionChip(
                label: const Text('3回戦以上'),
                onPressed: () {
                  setState(() {
                    _editingAdvancedKeywords = [
                      '3回戦',
                      '３回戦',
                      '三回戦',
                      '4回戦',
                      '４回戦',
                      '四回戦',
                      '準決勝',
                      '準決',
                      '決勝',
                      'final',
                    ];
                    _keywordsController.text = _editingAdvancedKeywords.join(
                      ', ',
                    );
                  });
                },
              ),
              AppActionChip(
                label: const Text('クリア'),
                onPressed: () {
                  setState(() {
                    _editingAdvancedKeywords = [];
                    _keywordsController.text = '';
                  });
                },
              ),
            ],
          ),
        ],

        const Divider(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppKendoColors.indigo, width: 4),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: AppFontSize.bodyMedium,
          color: AppKendoColors.indigo,
        ),
      ),
    );
  }

  void _showRuleDetailBottomSheet(
    BuildContext context,
    String categoryName,
    CategoryRuleSet ruleSet,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    CategoryRuleDetailBottomSheet.show(
      context,
      categoryName: categoryName,
      ruleSet: ruleSet,
      isDark: isDark,
    );
  }
}
