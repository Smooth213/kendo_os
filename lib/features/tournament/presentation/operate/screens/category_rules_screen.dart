import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
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
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
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
            return _buildCategoryList(tournament, themeColors);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('エラーが発生しました: $e')),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    TournamentModel tournament,
    AppThemeColors themeColors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = tournament.categoryRules.keys.toList();
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _newCategoryController,
                  decoration: InputDecoration(
                    hintText: '部門名を入力（例：小学生低学年の部）',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppKendoColors.grey
                          : const Color(0x8A000000),
                      fontSize: AppFontSize.bodySmall,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFFFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0x33000000),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0x33000000),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(
                        color: const Color(0xFF3F51B5),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                ),
                onPressed: () =>
                    _addNewCategory(tournament, _newCategoryController.text),
              ),
            ],
          ),
        ),

        // プリセット追加のショートカット
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 定番の部門をワンタップで追加',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.grey,
                    fontSize: AppFontSize.small,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _presetCategories
                        .map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: AppActionChip(
                              label: Text(name),
                              onPressed: () =>
                                  _addNewCategory(tournament, name),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gavel,
                        size: 48,
                        color: const Color(0x8A000000),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '部門別ルールが未登録です。\n上の入力欄から部門を追加してください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0x8A000000),
                          fontSize: AppFontSize.bodySmall,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  // ★ 最適化: 2画面分先読みキャッシュでスクロール時の描画コストを削減
                  // ignore: deprecated_member_use
                  cacheExtent: 1000.0,
                  itemBuilder: (context, index) {
                    final cat = list[index];
                    final ruleSet = tournament.categoryRules[cat]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Slidable(
                        key: ValueKey('slidable_rule_$cat'),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) =>
                                  _startEditing(cat, ruleSet),
                              backgroundColor: AppKendoColors.blueAccent,
                              foregroundColor: AppKendoColors.pureWhite,
                              icon: Icons.edit,
                              label: '編集',
                            ),
                            SlidableAction(
                              onPressed: (context) =>
                                  _deleteCategory(tournament, cat),
                              backgroundColor: AppKendoColors.redAccent,
                              foregroundColor: AppKendoColors.pureWhite,
                              icon: Icons.delete,
                              label: '削除',
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(AppRadius.largeValue),
                              ),
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.large,
                            side: enableLiquidGlass
                                ? BorderSide(
                                    color: isDark
                                        ? const Color(
                                            0xFFFFFFFF,
                                          ).withValues(alpha: 0.15)
                                        : const Color(
                                            0xFF000000,
                                          ).withValues(alpha: 0.08),
                                    width: 0.5,
                                  )
                                : BorderSide(
                                    color: isDark
                                        ? const Color(0xFF38383A)
                                        : const Color(0x33000000),
                                  ),
                          ),
                          color: enableLiquidGlass
                              ? (isDark
                                    ? const Color(
                                        0xFF1C1C1E,
                                      ).withValues(alpha: 0.35)
                                    : const Color(
                                        0xFFFFFFFF,
                                      ).withValues(alpha: 0.65))
                              : (isDark
                                    ? const Color(0xFF1C1C1E)
                                    : context.appColors.textColor),
                          child: ListTile(
                            onTap: () => _showRuleDetailBottomSheet(
                              context,
                              cat,
                              ruleSet,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: AppSpacing.md,
                            ),
                            title: Text(
                              cat,
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.subhead,
                              ),
                            ),
                            subtitle: _buildRuleChips(ruleSet),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (widget.isFromSetup && list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: () => context.go('/home/${widget.tournamentId}'),
                color: AppKendoColors.indigo,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                icon: Icons.check_circle,
                label: '設定を完了して大会ホームへ進む',
                expandContent: false,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeStepperTile({
    required String title,
    required double value,
    required double minValue,
    required double maxValue,
    required double step,
    required ValueChanged<double> onChanged,
    String? subtitle,
    AppThemeColors? themeColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        themeColors?.primaryAccent ?? context.appColors.primaryAccent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.modernValue,
        vertical: AppSpacing.compact,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? context.appColors.textColor.withValues(alpha: 0.05)
            : context.appColors.cardBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark
              ? context.appColors.textColor.withValues(alpha: 0.12)
              : const Color(0x33000000),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: AppFontWeight.semiBold,
                    fontSize: AppFontSize.body,
                    color: context.appColors.textColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: isDark
                          ? context.appColors.subTextColor
                          : context.appColors.subTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : context.appColors.textColor,
              borderRadius: AppRadius.xlarge,
              border: Border.all(
                color: isDark
                    ? context.appColors.textColor.withValues(alpha: 0.24)
                    : const Color(0x33000000),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppKendoColors.pureBlack.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  padding: const EdgeInsets.all(AppSpacing.subValue),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  color: value > minValue
                      ? primaryColor
                      : const Color(0x8A000000),
                  onPressed: value > minValue
                      ? () {
                          final newVal = (value - step).clamp(
                            minValue,
                            maxValue,
                          );
                          onChanged(newVal);
                        }
                      : null,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 68),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    _formatMinutes(value),
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.body,
                      color: primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: const EdgeInsets.all(AppSpacing.subValue),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  color: value < maxValue
                      ? primaryColor
                      : const Color(0x8A000000),
                  onPressed: value < maxValue
                      ? () {
                          final newVal = (value + step).clamp(
                            minValue,
                            maxValue,
                          );
                          onChanged(newVal);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
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
                    color: AppKendoColors.ipponGold.withValues(alpha: 0.1),
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: AppKendoColors.ipponGold.withValues(alpha: 0.3),
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
                          color: AppKendoColors.ipponGold,
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
                                _buildSimpleSceneRuleForm(
                                  '⚔️ 錬成会ルール',
                                  _renseikaiTime,
                                  _renseikaiIsRunningTime,
                                  _renseikaiHasHantei,
                                  _renseikaiType,
                                  _renseikaiOverallTime,
                                  (val) => setState(() => _renseikaiTime = val),
                                  (val) => setState(
                                    () => _renseikaiIsRunningTime = val,
                                  ),
                                  (val) =>
                                      setState(() => _renseikaiHasHantei = val),
                                  (val) => setState(() => _renseikaiType = val),
                                  (val) => setState(
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
                                _buildSimpleSceneRuleForm(
                                  '🤝 申し合わせルール',
                                  _moushiawaseTime,
                                  _moushiawaseIsRunningTime,
                                  _moushiawaseHasHantei,
                                  _moushiawaseType,
                                  _moushiawaseOverallTime,
                                  (val) =>
                                      setState(() => _moushiawaseTime = val),
                                  (val) => setState(
                                    () => _moushiawaseIsRunningTime = val,
                                  ),
                                  (val) => setState(
                                    () => _moushiawaseHasHantei = val,
                                  ),
                                  (val) =>
                                      setState(() => _moushiawaseType = val),
                                  (val) => setState(
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
        _buildTimeStepperTile(
          title: '試合時間',
          subtitle: '30秒単位で自由に増減できます',
          value: matchTime,
          minValue: 0.5,
          maxValue: 15.0,
          step: 0.5,
          themeColors: themeColors,
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
              color: isDark ? const Color(0x8A000000) : const Color(0x8A000000),
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
            _buildTimeStepperTile(
              title: '延長戦の時間',
              value: enchoTime,
              minValue: 0.5,
              maxValue: 10.0,
              step: 0.5,
              themeColors: themeColors,
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
            _buildLeaguePointsSection(isNormal, winPoint, lossPoint, drawPoint),
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
              _buildTimeStepperTile(
                title: '代表戦延長の時間',
                value: daihyoEnchoTime,
                minValue: 0.5,
                maxValue: 10.0,
                step: 0.5,
                themeColors: themeColors,
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
            _buildLeaguePointsSection(isNormal, winPoint, lossPoint, drawPoint),
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

  Widget _buildLeaguePointsSection(
    bool isNormal,
    double winPoint,
    double lossPoint,
    double drawPoint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '勝ち点（リーグ戦の順位決定用）',
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.body,
            color: AppKendoColors.indigo,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('win_pt_${isNormal}_$_editingCategory'),
                initialValue: winPoint.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '勝ち（点）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                ),
                onChanged: (val) {
                  final d = double.tryParse(val) ?? 0.0;
                  setState(() {
                    if (isNormal) {
                      _normalWinPoint = d;
                    } else {
                      _advancedWinPoint = d;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                key: ValueKey('loss_pt_${isNormal}_$_editingCategory'),
                initialValue: lossPoint.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '負け（点）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                ),
                onChanged: (val) {
                  final d = double.tryParse(val) ?? 0.0;
                  setState(() {
                    if (isNormal) {
                      _normalLossPoint = d;
                    } else {
                      _advancedLossPoint = d;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                key: ValueKey('draw_pt_${isNormal}_$_editingCategory'),
                initialValue: drawPoint.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '引き分け（点）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                ),
                onChanged: (val) {
                  final d = double.tryParse(val) ?? 0.0;
                  setState(() {
                    if (isNormal) {
                      _normalDrawPoint = d;
                    } else {
                      _advancedDrawPoint = d;
                    }
                  });
                },
              ),
            ),
          ],
        ),
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
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    // Helper: formatMinutes
    String fmtMins(double mins) {
      if (mins <= 0) return '無制限';
      if (mins == mins.toInt()) return '${mins.toInt()}分';
      return '${mins.toInt()}分${((mins % 1) * 60).toInt()}秒';
    }

    // Helper: build a detailed rule section from a MatchRule
    // matchType is the CategoryRuleSet.matchType value:
    //   '個人戦' | '団体戦' | '勝ち抜き戦' | 'リーグ団体戦' | 'リーグ個人戦' | '錬成会'
    Widget buildRuleSection(
      String title,
      MatchRule rule,
      Color accentColor,
      String matchType,
    ) {
      // ─── Derived flags from matchType ───
      final bool isTeam =
          matchType == '団体戦' ||
          matchType == '勝ち抜き戦' ||
          matchType == 'リーグ団体戦' ||
          matchType == '錬成会';
      final bool isLeague = matchType == 'リーグ団体戦' || matchType == 'リーグ個人戦';
      final bool isKachinuki = matchType == '勝ち抜き戦';
      final bool isRenseikai = matchType == '錬成会';

      // 団体戦のみ代表戦を持つ（リーグ・勝ち抜きは専用処理）
      final bool hasDaihyo =
          !isKachinuki && !isRenseikai && rule.hasRepresentativeMatch;

      // --- Format text ---
      String formatText;
      if (isRenseikai) {
        formatText = '錬成会';
      } else if (isKachinuki) {
        formatText = '勝ち抜き戦';
      } else if (matchType == 'リーグ団体戦') {
        formatText = 'リーグ戦（団体）';
      } else if (matchType == 'リーグ個人戦') {
        formatText = 'リーグ戦（個人）';
      } else if (matchType == '団体戦') {
        formatText = '団体戦';
      } else {
        formatText = '個人戦';
      }

      // --- Time text ---
      String timeDesc =
          '${fmtMins(rule.matchTimeMinutes)} (${rule.isRunningTime ? "通し/空回し" : "都度ストップ"})';

      // --- Ippon shobu ---
      String ipponDesc = rule.isIpponShobu
          ? '一本勝負'
          : '三本勝負 (${rule.ipponLimit}本先取)';

      // --- Hansoku ---
      String hansokuDesc = '${rule.hansokuLimit}反則で負け';

      // --- Encho text ---
      String enchoDesc;
      if (rule.isEnchoUnlimited) {
        enchoDesc = 'あり (時間・回数 無制限)';
      } else if (rule.enchoCount > 0 || rule.enchoTimeMinutes > 0) {
        enchoDesc =
            'あり (${fmtMins(rule.enchoTimeMinutes)}・${rule.enchoCount}回)';
      } else {
        enchoDesc = 'なし';
      }

      // --- Hantei ---
      String hanteiDesc = rule.hasHantei ? 'あり' : 'なし';

      // --- Daihyo encho ---
      String daihyoEnchoDesc;
      if (!rule.daihyoHasExtension) {
        daihyoEnchoDesc = 'なし';
      } else if (rule.daihyoEnchoCount == -2) {
        daihyoEnchoDesc = 'あり (無制限)';
      } else {
        daihyoEnchoDesc =
            'あり (${fmtMins(rule.daihyoEnchoTimeMinutes)}・${rule.daihyoEnchoCount}回)';
      }

      // --- Build widgets ---
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Section header bar ───
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: AppRadius.micro,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppFontSize.bodyMedium,
                    fontWeight: AppFontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),

          // ─── 試合基本情報 ───
          _buildDetailRow('試合形式', formatText, isDark),
          _buildDetailRow(isRenseikai ? '1対戦の時間' : '試合時間', timeDesc, isDark),

          // ─── 錬成会設定 ───
          if (isRenseikai) ...[
            _buildSectionLabel('錬成会設定', accentColor),
            _buildDetailRow('進行方式', rule.renseikaiType, isDark),
            if (rule.renseikaiType == '時間制')
              _buildDetailRow('全体の制限時間', '${rule.overallTimeMinutes}分', isDark),
          ],

          // ─── 試合ルール（錬成会以外） ───
          if (!isRenseikai) ...[
            _buildSectionLabel('試合ルール', accentColor),
            _buildDetailRow('勝負方式', ipponDesc, isDark),
            _buildDetailRow('反則', hansokuDesc, isDark),
            _buildDetailRow('延長戦', enchoDesc, isDark),
            _buildDetailRow('判定', hanteiDesc, isDark),
          ],

          // ─── 勝ち抜き戦設定 ───
          if (isKachinuki) ...[
            _buildSectionLabel('勝ち抜き戦設定', accentColor),
            _buildDetailRow('大将VS大将', () {
              final t = rule.kachinukiUnlimitedType;
              if (t == 'なし' || t.isEmpty) return '引き分け';
              return '延長戦を行う';
            }(), isDark),
            _buildDetailRow(
              '大将VS他ポジション',
              rule.kachinukiUnlimitedType == '無制限' ? '延長戦を行う' : '引き分け',
              isDark,
            ),
          ],

          // ─── 団体戦・チーム設定（通常団体戦のみ） ───
          if (isTeam && !isKachinuki && !isRenseikai && !isLeague) ...[
            _buildSectionLabel('団体戦・チーム設定', accentColor),
            _buildDetailRow(
              '代表戦',
              rule.hasRepresentativeMatch
                  ? 'あり (${rule.isDaihyoIpponShobu ? "一本勝負" : "三本勝負"})'
                  : 'なし',
              isDark,
            ),
          ],

          // ─── 代表戦設定（通常団体戦の代表戦ありのとき） ───
          if (isTeam &&
              !isKachinuki &&
              !isRenseikai &&
              !isLeague &&
              hasDaihyo) ...[
            _buildSectionLabel('代表戦設定', accentColor),
            _buildDetailRow(
              '代表戦 時間',
              rule.daihyoMatchTimeMinutes <= 0
                  ? '無制限'
                  : fmtMins(rule.daihyoMatchTimeMinutes),
              isDark,
            ),
            _buildDetailRow('代表戦 延長戦', daihyoEnchoDesc, isDark),
            _buildDetailRow(
              '代表戦 判定',
              rule.daihyoHasHantei ? 'あり' : 'なし',
              isDark,
            ),
          ],

          // ─── リーグ戦設定 ───
          if (isLeague) ...[
            _buildSectionLabel('リーグ戦設定', AppKendoColors.orange),
            _buildDetailRow(
              '勝ち点',
              '勝: ${rule.winPoint} / 分: ${rule.drawPoint} / 負: ${rule.lossPoint}',
              isDark,
            ),
            if (matchType == 'リーグ団体戦') ...[
              _buildDetailRow(
                '同点代表戦',
                rule.hasLeagueDaihyo ? 'あり' : 'なし',
                isDark,
              ),
              if (rule.hasLeagueDaihyo) ...[
                _buildDetailRow(
                  '代表戦 時間',
                  rule.daihyoMatchTimeMinutes <= 0
                      ? '無制限'
                      : fmtMins(rule.daihyoMatchTimeMinutes),
                  isDark,
                ),
                _buildDetailRow('代表戦 延長戦', daihyoEnchoDesc, isDark),
                _buildDetailRow(
                  '代表戦 判定',
                  rule.daihyoHasHantei ? 'あり' : 'なし',
                  isDark,
                ),
              ],
            ],
          ],
        ],
      );
    }

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(
                        bottom: AppSpacing.roundValue,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x8A000000),
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.gavel_rounded,
                        color: themeColors.primaryAccent,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '$categoryName のルール設定',
                          style: TextStyle(
                            fontSize: AppFontSize.headline,
                            fontWeight: AppFontWeight.bold,
                            color: context.appColors.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  buildRuleSection(
                    '通常戦ルール',
                    ruleSet.normalRule,
                    themeColors.primaryAccent,
                    ruleSet.matchType,
                  ),

                  if (ruleSet.useAdvancedRule) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    buildRuleSection(
                      '上位戦（準決勝・決勝等）ルール',
                      ruleSet.advancedRule,
                      AppKendoColors.teal,
                      ruleSet.matchType,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      '上位戦 適用ワード',
                      ruleSet.advancedKeywords.join('、'),
                      isDark,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appColors.separatorColor,
                        foregroundColor: context.appColors.textColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: const Text(
                        '閉じる',
                        style: TextStyle(fontWeight: AppFontWeight.semiBold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.subValue),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: AppFontWeight.semiBold,
                fontSize: AppFontSize.bodySmall,
                color: AppKendoColors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: context.appColors.subTextColor,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.small,
          fontWeight: AppFontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRuleChips(CategoryRuleSet ruleSet) {
    Widget buildChip(String label, Color bg, Color text) {
      return Container(
        margin: const EdgeInsets.only(right: 6, top: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.small),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      );
    }

    if (ruleSet.isMultiScene) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              buildChip(
                '⚔️ 錬成会',
                AppKendoColors.ipponGold,
                AppKendoColors.ipponGold,
              ),
              buildChip(
                _formatMinutes(ruleSet.renseikaiRule.matchTimeMinutes),
                const Color(0x33000000),
                AppKendoColors.pureBlack,
              ),
              if (ruleSet.renseikaiRule.isRunningTime)
                buildChip(
                  '流し',
                  const Color(0xFF2196F3),
                  const Color(0xFF2196F3),
                ),
              if (ruleSet.renseikaiRule.hasHantei)
                buildChip(
                  '引分有',
                  AppKendoColors.successGreen,
                  AppKendoColors.successGreen,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              buildChip(
                '🏆 本戦',
                const Color(0xFF3F51B5),
                const Color(0xFF3F51B5),
              ),
              buildChip(
                _formatMinutes(ruleSet.normalRule.matchTimeMinutes),
                const Color(0x33000000),
                AppKendoColors.pureBlack,
              ),
              if (ruleSet.normalRule.isEnchoUnlimited ||
                  ruleSet.normalRule.enchoCount > 0)
                buildChip(
                  '代表戦/延長有',
                  const Color(0xFF9C27B0),
                  const Color(0xFF9C27B0),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              buildChip(
                '🤝 申し合わせ',
                const Color(0xFF009688),
                const Color(0xFF009688),
              ),
              buildChip(
                _formatMinutes(ruleSet.moushiawaseRule.matchTimeMinutes),
                const Color(0x33000000),
                AppKendoColors.pureBlack,
              ),
              if (ruleSet.moushiawaseRule.hasHantei)
                buildChip(
                  '引分有',
                  AppKendoColors.successGreen,
                  AppKendoColors.successGreen,
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            buildChip(
              '標準ルール',
              const Color(0xFF2196F3),
              const Color(0xFF2196F3),
            ),
            buildChip(
              _formatMinutes(ruleSet.normalRule.matchTimeMinutes),
              const Color(0x33000000),
              AppKendoColors.pureBlack,
            ),
            buildChip(
              ruleSet.normalRule.enchoCount > 0
                  ? "延長${ruleSet.normalRule.enchoCount}回"
                  : (ruleSet.normalRule.isEnchoUnlimited ? "延長無制限" : "延長なし"),
              const Color(0xFF9C27B0),
              const Color(0xFF9C27B0),
            ),
            if (ruleSet.normalRule.hasHantei)
              buildChip(
                '判定あり',
                AppKendoColors.successGreen,
                AppKendoColors.successGreen,
              ),
          ],
        ),
        if (ruleSet.useAdvancedRule)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                buildChip(
                  '上位戦',
                  const Color(0xFFFF5722),
                  const Color(0xFFFF5722),
                ),
                buildChip(
                  _formatMinutes(ruleSet.advancedRule.matchTimeMinutes),
                  const Color(0x33000000),
                  AppKendoColors.pureBlack,
                ),
                buildChip(
                  ruleSet.advancedRule.enchoCount > 0
                      ? "延長${ruleSet.advancedRule.enchoCount}回"
                      : (ruleSet.advancedRule.isEnchoUnlimited
                            ? "延長無制限"
                            : "延長なし"),
                  const Color(0xFF9C27B0),
                  const Color(0xFF9C27B0),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleSceneRuleForm(
    String title,
    double time,
    bool isRunning,
    bool hasHantei,
    String renseikaiType,
    int overallTime,
    ValueChanged<double> onTimeChanged,
    ValueChanged<bool> onRunningChanged,
    ValueChanged<bool> onHanteiChanged,
    ValueChanged<String> onTypeChanged,
    ValueChanged<int> onOverallTimeChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.subhead,
              color: AppKendoColors.indigo,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          '錬成形式（試合方式）',
          style: TextStyle(
            fontWeight: AppFontWeight.semiBold,
            fontSize: AppFontSize.bodySmall,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: ['一試合制', '時間制'].map((type) {
            final isSelected = renseikaiType == type;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onTypeChanged(type);
                },
              ),
            );
          }).toList(),
        ),
        if (renseikaiType == '時間制') ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: overallTime.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '全体の制限時間（分）',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(AppSpacing.md),
            ),
            onChanged: (val) {
              final i = int.tryParse(val) ?? 30;
              onOverallTimeChanged(i);
            },
          ),
        ],
        _buildTimeStepperTile(
          title: '1試合の時間',
          value: time,
          minValue: 0.5,
          maxValue: 10.0,
          step: 0.5,
          onChanged: onTimeChanged,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('流し（タイマーを止めない）'),
          value: isRunning,
          onChanged: onRunningChanged,
        ),
      ],
    );
  }
}
