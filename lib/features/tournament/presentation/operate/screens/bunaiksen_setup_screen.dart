import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_individual_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_infinite_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_league_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_rule_settings_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_team_tab.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

import 'package:kendo_os/shared/widgets/smart_player_input.dart'
    show bunaiksenPlayerMasterProvider;

class BunaiksenSetupScreen extends ConsumerStatefulWidget {
  const BunaiksenSetupScreen({super.key});

  @override
  ConsumerState<BunaiksenSetupScreen> createState() =>
      _BunaiksenSetupScreenState();
}

class _BunaiksenSetupScreenState extends ConsumerState<BunaiksenSetupScreen>
    with SingleTickerProviderStateMixin {
  late AppThemeColors _themeColors;
  late TabController _tabController;
  final _redPlayerController = TextEditingController();
  final _whitePlayerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(bunaiksenRuleProvider.notifier)
          .update(
            (state) => state.copyWith(
              matchTimeMinutes: 2.0,
              isIpponShobu: false,
              ipponLimit: 2,
              isEnchoUnlimited: false,
              enchoTimeMinutes: 0.0,
              enchoCount: 0,
            ),
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _redPlayerController.dispose();
    _whitePlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final rule = ref.watch(bunaiksenRuleProvider);
    final masterPlayersAsync = ref.watch(bunaiksenPlayerMasterProvider);
    final masterPlayers = masterPlayersAsync.valueOrNull ?? <PlayerModel>[];

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          backgroundColor: isDark
              ? const Color(0xFF1C1C1E)
              : context.appColors.cardBackground,
          foregroundColor: context.appColors.textColor,
          title: '部内戦セットアップ',
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _themeColors.primaryAccent,
            unselectedLabelColor: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
            indicatorColor: _themeColors.primaryAccent,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.person, size: 20), text: '個人戦 (即スタート)'),
              Tab(icon: Icon(Icons.groups, size: 20), text: '団体戦 (紅白戦)'),
              Tab(icon: Icon(Icons.grid_on, size: 20), text: 'リーグ戦 (総当たり)'),
              Tab(icon: Icon(Icons.loop, size: 20), text: '無限戦 (勝ち残り)'),
            ],
          ),
        ),
        body: Column(
          children: [
            BunaiksenRuleSettingsCard(
              rule: rule,
              isDark: isDark,
              themeColors: _themeColors,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  BunaiksenIndividualTab(
                    redPlayerController: _redPlayerController,
                    whitePlayerController: _whitePlayerController,
                    themeColors: _themeColors,
                  ),
                  BunaiksenTeamTab(
                    masterPlayers: masterPlayers,
                    isDark: isDark,
                    themeColors: _themeColors,
                  ),
                  BunaiksenLeagueTab(themeColors: _themeColors),
                  BunaiksenInfiniteTab(themeColors: _themeColors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
