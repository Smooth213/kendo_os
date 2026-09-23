import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_text_parser.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_basic_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_cards.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_raw_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart'
    show playerListProvider;
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

class TournamentShareImportSheet extends ConsumerStatefulWidget {
  final TournamentShareData? initialData;
  final String? rawText;

  const TournamentShareImportSheet({super.key, this.initialData, this.rawText});

  static Future<void> show(
    BuildContext context, {
    TournamentShareData? initialData,
    String? rawText,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TournamentShareImportSheet(
        initialData: initialData,
        rawText: rawText,
      ),
    );
  }

  @override
  ConsumerState<TournamentShareImportSheet> createState() =>
      _TournamentShareImportSheetState();
}

class _TournamentShareImportSheetState
    extends ConsumerState<TournamentShareImportSheet> {
  late TextEditingController _rawTextController;
  late TextEditingController _nameController;
  late TextEditingController _venueController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;
  List<ParsedTeamOrder> _teams = [];
  bool _isEditingRaw = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.rawText ?? widget.initialData?.rawText ?? '';
    _rawTextController = TextEditingController(text: raw);

    final data =
        widget.initialData ??
        (raw.isNotEmpty ? TournamentTextParser.parse(raw) : null);

    _nameController = TextEditingController(text: data?.tournamentName ?? '');
    _venueController = TextEditingController(text: data?.venue ?? '');
    _notesController = TextEditingController(text: data?.notes ?? '');
    _selectedDate = data?.date;
    _teams = TournamentTeamAutoRegisterService.normalizeIndividualTeams(
      List.from(data?.teams ?? []),
    );

    if (data == null || data.tournamentName.isEmpty) {
      _isEditingRaw = true;
    }
  }

  @override
  void dispose() {
    _rawTextController.dispose();
    _nameController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _reparse() {
    final text = _rawTextController.text.trim();
    if (text.isEmpty) {
      AppSnackBar.showError(context, 'テキストを入力してください');
      return;
    }

    final parsed = TournamentTextParser.parse(text);
    setState(() {
      _nameController.text = parsed.tournamentName;
      _venueController.text = parsed.venue;
      _notesController.text = parsed.notes;
      _selectedDate = parsed.date;
      _teams = TournamentTeamAutoRegisterService.normalizeIndividualTeams(
        List.from(parsed.teams),
      );
      _isEditingRaw = false;
    });
    AppSnackBar.showSuccess(context, 'テキストを解析しました');
  }

  TournamentShareData _buildCurrentData([List<PlayerModel>? roster]) {
    List<ParsedTeamOrder> resolvedTeams = _teams;
    if (roster != null && roster.isNotEmpty) {
      resolvedTeams = _teams.map((team) {
        final matchedMembers = PlayerRosterMatcher.matchTeamMembers(
          members: team.members,
          teamCategory: team.teamName,
          roster: roster,
        );
        return ParsedTeamOrder(
          teamName: team.teamName,
          category: team.category,
          matchType: team.matchType,
          members: matchedMembers.map((m) {
            return ParsedTeamMember(position: m.position, name: m.displayName);
          }).toList(),
        );
      }).toList();
    }

    return TournamentShareData(
      tournamentName: _nameController.text.trim(),
      date: _selectedDate,
      venue: _venueController.text.trim(),
      notes: _notesController.text.trim(),
      teams: resolvedTeams,
      rawText: _rawTextController.text,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final roster = playerListAsync.value ?? <PlayerModel>[];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final accentColor = themeColors.primaryAccent;
    final cardColor = themeColors.cardBackground;
    final textColor = themeColors.textColor;
    final subTextColor = themeColors.subTextColor;

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: AppBottomSheetContent(
        title: '大会・オーダー情報の取り込み',
        titleIcon: Icons.auto_awesome,
        titleTrailing: IconButton(
          icon: Icon(
            _isEditingRaw ? Icons.visibility : Icons.edit_note,
            color: accentColor,
          ),
          tooltip: _isEditingRaw ? '解析結果を表示' : '元テキストを編集',
          onPressed: () {
            setState(() {
              _isEditingRaw = !_isEditingRaw;
            });
          },
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditingRaw)
                TournamentShareImportRawView(
                  rawTextController: _rawTextController,
                  onReparse: _reparse,
                  accentColor: accentColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  isDark: isDark,
                )
              else ...[
                // 解析結果プレビュー & 微調整モード
                TournamentShareImportBasicCard(
                  nameController: _nameController,
                  venueController: _venueController,
                  selectedDate: _selectedDate,
                  onPickDate: _pickDate,
                  accentColor: accentColor,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: AppSpacing.md),

                // チーム・オーダー情報
                ShareImportInfoCard(
                  title: 'チーム・オーダー構成 (${_teams.length}チーム)',
                  icon: Icons.groups_outlined,
                  accentColor: accentColor,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  children: [
                    if (_teams.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          'オーダー情報は検出されませんでした',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            color: subTextColor,
                          ),
                        ),
                      )
                    else
                      ...List.generate(_teams.length, (teamIndex) {
                        final team = _teams[teamIndex];
                        return ShareImportTeamSection(
                          team: team,
                          accentColor: accentColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          roster: roster,
                          allTeams: _teams,
                          onTeamNameUpdated: (newName) {
                            setState(() {
                              _teams[teamIndex] = team.copyWith(
                                teamName: newName,
                              );
                            });
                          },
                          onCategoryUpdated: (newCat) {
                            setState(() {
                              _teams[teamIndex] = team.copyWith(
                                category: newCat,
                              );
                            });
                          },
                          onMatchTypeUpdated: (newType) {
                            setState(() {
                              _teams[teamIndex] = team.copyWith(
                                matchType: newType,
                              );
                            });
                          },
                          onMemberUpdated: (memberIndex, updatedMember) {
                            setState(() {
                              final updatedMembers =
                                  List<ParsedTeamMember>.from(team.members);
                              updatedMembers[memberIndex] = updatedMember;
                              _teams[teamIndex] = team.copyWith(
                                members: updatedMembers,
                              );
                            });
                          },
                        );
                      }),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // メモ・連絡事項
                ShareImportInfoCard(
                  title: 'メモ・連絡事項',
                  icon: Icons.notes_outlined,
                  accentColor: accentColor,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  children: [
                    AppTextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '集合場所、責任者、注意事項など',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.smallValue,
                          ),
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final data = _buildCurrentData(roster);
                          Navigator.pop(context);
                          context.push('/create-tournament', extra: data);
                        },
                        icon: const Icon(Icons.add_task),
                        label: const Text(
                          'この情報で大会を作成',
                          style: TextStyle(fontWeight: AppFontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: AppKendoColors.pureWhite,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.mediumValue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final data = _buildCurrentData(roster);
                          Navigator.pop(context);
                          context.push('/bunaiksen-home', extra: data);
                        },
                        icon: const Icon(Icons.sports_kabaddi),
                        label: const Text('部内戦に反映'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: BorderSide(color: accentColor),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.mediumValue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
