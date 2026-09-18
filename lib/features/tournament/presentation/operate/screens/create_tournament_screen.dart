import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page1.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page2.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_sticky_bottom_action.dart';

import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart'
    show playerListProvider;
import 'package:kendo_os/features/tournament/presentation/components/share_import/clipboard_import_button.dart';

import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  final TournamentShareData? initialData;
  const CreateTournamentScreen({super.key, this.initialData});

  @override
  ConsumerState<CreateTournamentScreen> createState() =>
      _CreateTournamentScreenState();
}

class _CreateTournamentScreenState
    extends ConsumerState<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _shouldAutoRegisterTeams = true;
  List<ParsedTeamOrder> _teams = [];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    final init = widget.initialData;
    _nameController = TextEditingController(text: init?.tournamentName ?? '');
    _venueController = TextEditingController(text: init?.venue ?? '');
    _notesController = TextEditingController(text: init?.notes ?? '');
    _selectedDate = init?.date ?? DateTime.now();
    _teams = List.from(init?.teams ?? []);

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentProgress = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('ja'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _openMap() async {
    if (_venueController.text.isEmpty) {
      AppSnackBar.show(context, '会場名または住所を入力してください');
      return;
    }

    final Uri url = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': _venueController.text,
    });

    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // 成功
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'マップアプリを起動できませんでした');
      }
    }
  }

  Future<void> _handleSaveOrNext() async {
    if (_currentPage == 0) {
      if (_nameController.text.isEmpty) {
        AppSnackBar.showError(context, '大会名を入力してください');
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (_formKey.currentState!.validate()) {
        try {
          final dojoId = ref.read(currentDojoIdProvider);
          debugPrint('🔥 [DEBUG] 現在の道場ID: "$dojoId"');
          final uid = FirebaseAuth.instance.currentUser?.uid;
          debugPrint('🔥 [DEBUG] 現在のUID: "$uid"');

          final hasTeams = _teams.isNotEmpty;
          final roster = ref.read(playerListProvider).value ?? <PlayerModel>[];
          final categories = (_shouldAutoRegisterTeams && hasTeams)
              ? TournamentTeamAutoRegisterService.extractCategories(
                  _teams,
                  roster: roster,
                )
              : const <String>[];

          final newTournament = TournamentModel(
            id: '',
            organizationId: ref.read(settingsProvider).organizationId,
            name: _nameController.text,
            date: _selectedDate,
            venue: _venueController.text,
            categories: categories,
            notes: _notesController.text.trim(),
          );

          final newId = await ref
              .read(tournamentRepositoryProvider)
              .saveTournament(newTournament);

          int autoRegisteredCount = 0;
          if (_shouldAutoRegisterTeams && hasTeams) {
            final roster =
                ref.read(playerListProvider).value ?? <PlayerModel>[];
            autoRegisteredCount =
                await TournamentTeamAutoRegisterService.registerTeams(
                  teams: _teams,
                  tournamentId: newId,
                  roster: roster,
                  teamRepository: ref.read(teamRepositoryProvider),
                  teamNameHistoryNotifier: ref.read(
                    teamNameHistoryProvider.notifier,
                  ),
                );
          }

          if (!mounted) return;

          if (autoRegisteredCount > 0) {
            AppSnackBar.showSuccess(
              context,
              '基本情報と$autoRegisteredCountチームのオーダーを自動登録しました！',
            );
          } else {
            AppSnackBar.showSuccess(context, '基本情報を保存しました！');
          }

          final targetRoute = autoRegisteredCount > 0
              ? '/team-registration/$newId?initialPage=2'
              : '/team-registration/$newId';
          context.push(targetRoute);
        } catch (e) {
          debugPrint('🔥 [ERROR] 大会保存エラー: $e');
          if (mounted) {
            AppSnackBar.showError(context, '保存エラー: $e');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final roster = playerListAsync.value ?? <PlayerModel>[];
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          title: '大会の新規作成',
          backgroundColor: AppKendoColors.transparent,
          actions: [
            const ClipboardImportButton(),
            const ManualHelpButton(
              manualPath: 'docs/manuals/operator/settings.md',
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: isKeyboardOpen
                      ? const SizedBox.shrink()
                      : CreateTournamentDynamicHeader(
                          currentProgress: _currentProgress,
                        ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      children: [
                        CreateTournamentPage1(
                          nameController: _nameController,
                          selectedDate: _selectedDate,
                          onPickDate: _pickDate,
                        ),
                        CreateTournamentPage2(
                          venueController: _venueController,
                          notesController: _notesController,
                          onOpenMap: _openMap,
                          extraContent: _teams.isNotEmpty
                              ? CreateTournamentImportTeamsCard(
                                  teams: _teams,
                                  isEnabled: _shouldAutoRegisterTeams,
                                  onToggle: (val) => setState(
                                    () => _shouldAutoRegisterTeams = val,
                                  ),
                                  roster: roster,
                                  onTeamsUpdated: (updated) =>
                                      setState(() => _teams = updated),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: isKeyboardOpen
                      ? const SizedBox.shrink()
                      : CreateTournamentStickyBottomAction(
                          currentPage: _currentPage,
                          onPrevious: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          onNextOrSave: _handleSaveOrNext,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
