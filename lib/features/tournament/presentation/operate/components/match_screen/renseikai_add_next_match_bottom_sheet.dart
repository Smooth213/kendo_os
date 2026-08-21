import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:uuid/uuid.dart';
import '../../match_screen.dart' show playerListProvider;

/// 錬成会用 次の試合追加ボトムシート
class RenseikaiAddNextMatchBottomSheet extends ConsumerStatefulWidget {
  final MatchModel currentMatch;

  const RenseikaiAddNextMatchBottomSheet({
    super.key,
    required this.currentMatch,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel currentMatch,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) =>
          RenseikaiAddNextMatchBottomSheet(currentMatch: currentMatch),
    );
  }

  @override
  ConsumerState<RenseikaiAddNextMatchBottomSheet> createState() =>
      _RenseikaiAddNextMatchBottomSheetState();
}

class _RenseikaiAddNextMatchBottomSheetState
    extends ConsumerState<RenseikaiAddNextMatchBottomSheet> {
  late final TextEditingController _redCtrl;
  late final TextEditingController _whiteCtrl;

  @override
  void initState() {
    super.initState();
    _redCtrl = TextEditingController();
    _whiteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _redCtrl.dispose();
    _whiteCtrl.dispose();
    super.dispose();
  }

  bool _isCategoryMatch(String teamCat, String matchCat) {
    final tCat = teamCat.trim();
    final mCat = matchCat.trim();
    if (mCat.isEmpty || tCat.isEmpty) return true;
    if (tCat == mCat || mCat.contains(tCat) || tCat.contains(mCat)) {
      return true;
    }
    final keywords = ['低学年', '高学年', '小学生', '中学生', '高校生', '一般'];
    for (final kw in keywords) {
      if (mCat.contains(kw) && tCat.contains(kw)) return true;
      if (mCat.contains(kw) && !tCat.contains(kw)) return false;
    }
    return true;
  }

  bool _isDojoPlayerGradeMatch(int grade, String matchCat) {
    if (matchCat.isEmpty) return true;
    if ((matchCat.contains('低学年') ||
            matchCat.contains('1・2年') ||
            matchCat.contains('3・4年')) &&
        (grade >= 1 && grade <= 4)) {
      return true;
    }
    if ((matchCat.contains('高学年') || matchCat.contains('5・6年')) &&
        (grade >= 5 && grade <= 6)) {
      return true;
    }
    if ((matchCat.contains('小学生') ||
            matchCat.contains('学童') ||
            matchCat.contains('児童')) &&
        (grade >= 1 && grade <= 6)) {
      return true;
    }
    if ((matchCat.contains('中学生') || matchCat.contains('中学')) &&
        (grade >= 7 && grade <= 9)) {
      return true;
    }
    if ((matchCat.contains('高校生') || matchCat.contains('高校')) &&
        (grade >= 10 && grade <= 12)) {
      return true;
    }
    if ((matchCat.contains('一般') ||
            matchCat.contains('成人') ||
            matchCat.contains('社会人') ||
            matchCat.contains('大学')) &&
        (grade >= 13 || grade == 0)) {
      return true;
    }

    final hasKnownSchoolLevel =
        matchCat.contains('低学年') ||
        matchCat.contains('高学年') ||
        matchCat.contains('小学生') ||
        matchCat.contains('中学生') ||
        matchCat.contains('高校生') ||
        matchCat.contains('一般');
    return !hasKnownSchoolLevel;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = context.appColors.cardBackground;
    final textColor = context.appColors.textColor;
    final inputBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : context.appColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    final String rTeam = widget.currentMatch.redName.contains(':')
        ? widget.currentMatch.redName.split(':').first.trim()
        : '赤';
    final String wTeam = widget.currentMatch.whiteName.contains(':')
        ? widget.currentMatch.whiteName.split(':').first.trim()
        : '白';

    final allMatches = ref.watch(matchListProvider);
    final teamMatches = allMatches
        .where((m) => m.groupName == widget.currentMatch.groupName)
        .toList();

    final List<String> baseRedPlayers = [];
    for (final m in teamMatches) {
      if (m.redName.contains(':')) {
        final parts = m.redName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == rTeam &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          baseRedPlayers.add(pName);
        }
      }
      if (m.whiteName.contains(':')) {
        final parts = m.whiteName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == rTeam &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          baseRedPlayers.add(pName);
        }
      }
    }

    final List<String> baseWhitePlayers = [];
    for (final m in teamMatches) {
      if (m.redName.contains(':')) {
        final parts = m.redName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == wTeam &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          baseWhitePlayers.add(pName);
        }
      }
      if (m.whiteName.contains(':')) {
        final parts = m.whiteName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == wTeam &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          baseWhitePlayers.add(pName);
        }
      }
    }

    List<PlayerModel> localPlayers = [];
    try {
      localPlayers = ref.watch(playerListProvider).value ?? [];
    } catch (_) {}

    List<TeamModel> registeredTeams = [];
    try {
      registeredTeams =
          ref
              .watch(
                registeredTeamsProvider(widget.currentMatch.tournamentId ?? ''),
              )
              .value ??
          [];
    } catch (_) {}

    final matchCat = widget.currentMatch.category?.trim() ?? '';

    final matchingRedTeams = registeredTeams.where((t) {
      final nameMatch =
          t.teamName.trim() == rTeam.trim() ||
          rTeam.trim().contains(t.teamName.trim()) ||
          t.teamName.trim().contains(rTeam.trim());
      return nameMatch;
    }).toList();

    final redTeamData =
        matchingRedTeams.firstWhereOrNull(
          (t) => _isCategoryMatch(t.category, matchCat),
        ) ??
        matchingRedTeams.firstOrNull;

    final List<String> redMasterPlayers =
        redTeamData?.playerNames
            .map((n) => n.trim())
            .where(
              (n) => n.isNotEmpty && !n.contains('未定') && !n.contains('欠員'),
            )
            .toList() ??
        [];

    final List<String> redDojoPlayers = localPlayers
        .where((p) {
          final org = p.organization.trim();
          if (org.isEmpty) return false;
          final orgMatch =
              org == rTeam.trim() ||
              rTeam.trim().contains(org) ||
              org.contains(rTeam.trim());
          if (!orgMatch) return false;
          return _isDojoPlayerGradeMatch(p.grade, matchCat);
        })
        .map((p) => p.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final List<String> redPlayers = redMasterPlayers.isNotEmpty
        ? {...redMasterPlayers, ...baseRedPlayers}.toList()
        : {...redDojoPlayers, ...baseRedPlayers}.toList();

    final matchingWhiteTeams = registeredTeams.where((t) {
      final nameMatch =
          t.teamName.trim() == wTeam.trim() ||
          wTeam.trim().contains(t.teamName.trim()) ||
          t.teamName.trim().contains(wTeam.trim());
      return nameMatch;
    }).toList();

    final whiteTeamData =
        matchingWhiteTeams.firstWhereOrNull(
          (t) => _isCategoryMatch(t.category, matchCat),
        ) ??
        matchingWhiteTeams.firstOrNull;

    final List<String> whiteMasterPlayers =
        whiteTeamData?.playerNames
            .map((n) => n.trim())
            .where(
              (n) => n.isNotEmpty && !n.contains('未定') && !n.contains('欠員'),
            )
            .toList() ??
        [];

    final List<String> whiteDojoPlayers = localPlayers
        .where((p) {
          final org = p.organization.trim();
          if (org.isEmpty) return false;
          final orgMatch =
              org == wTeam.trim() ||
              wTeam.trim().contains(org) ||
              org.contains(wTeam.trim());
          if (!orgMatch) return false;
          return _isDojoPlayerGradeMatch(p.grade, matchCat);
        })
        .map((p) => p.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final List<String> whitePlayers = whiteMasterPlayers.isNotEmpty
        ? {...whiteMasterPlayers, ...baseWhitePlayers}.toList()
        : {...whiteDojoPlayers, ...baseWhitePlayers}.toList();

    final Set<String> redMasterSet = redPlayers.toSet();
    final Set<String> whiteMasterSet = whitePlayers.toSet();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlargeValue),
          ),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: context.appColors.subTextColor.withValues(alpha: 0.3),
                borderRadius: AppRadius.compact,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '次の試合を追加 (錬成会)',
              style: TextStyle(
                fontSize: AppFontSize.header,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '次の試合に出場する選手を入力または選択してください。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: context.appColors.subTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  if (redPlayers.isNotEmpty) ...[
                    Text(
                      '$rTeam の選手を選択:',
                      style: const TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        color: Color(0xFF009688),
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: redPlayers.map((p) {
                        final isMaster = redMasterSet.contains(p);
                        return AppChoiceChip(
                          label: Text(p),
                          selected: _redCtrl.text == p,
                          selectedColor: const Color(0xFF009688),
                          backgroundColor: _redCtrl.text == p
                              ? const Color(0xFF009688)
                              : (isMaster
                                    ? (isDark
                                          ? const Color(0xFF2C2C2E)
                                          : context.appColors.inputBackground)
                                    : (isDark
                                          ? const Color(0xFF1E1E20)
                                          : context.appColors.cardBackground)),
                          side: BorderSide(
                            color: _redCtrl.text == p
                                ? AppKendoColors.transparent
                                : (isMaster
                                      ? AppKendoColors.transparent
                                      : (context.appColors.separatorColor)),
                            width: 1.0,
                          ),
                          labelStyle: TextStyle(
                            color: _redCtrl.text == p
                                ? AppKendoColors.pureWhite
                                : (isMaster
                                      ? textColor
                                      : context.appColors.subTextColor),
                            fontWeight: AppFontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _redCtrl.text = p;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppTextField(
                    controller: _redCtrl,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: AppFontWeight.bold,
                    ),
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: '$rTeam の選手名を入力',
                      labelStyle: const TextStyle(color: AppKendoColors.grey),
                      filled: true,
                      fillColor: inputBgColor,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                        horizontal: AppSpacing.lg,
                      ),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                        borderSide: const BorderSide(
                          color: Color(0xFF009688),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (whitePlayers.isNotEmpty) ...[
                    Text(
                      '$wTeam の選手を選択:',
                      style: const TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        color: Color(0xFF009688),
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: whitePlayers.map((p) {
                        final isMaster = whiteMasterSet.contains(p);
                        return AppChoiceChip(
                          label: Text(p),
                          selected: _whiteCtrl.text == p,
                          selectedColor: const Color(0xFF009688),
                          backgroundColor: _whiteCtrl.text == p
                              ? const Color(0xFF009688)
                              : (isMaster
                                    ? (isDark
                                          ? const Color(0xFF2C2C2E)
                                          : context.appColors.inputBackground)
                                    : (isDark
                                          ? const Color(0xFF1E1E20)
                                          : context.appColors.cardBackground)),
                          side: BorderSide(
                            color: _whiteCtrl.text == p
                                ? AppKendoColors.transparent
                                : (isMaster
                                      ? AppKendoColors.transparent
                                      : (context.appColors.separatorColor)),
                            width: 1.0,
                          ),
                          labelStyle: TextStyle(
                            color: _whiteCtrl.text == p
                                ? AppKendoColors.pureWhite
                                : (isMaster
                                      ? textColor
                                      : context.appColors.subTextColor),
                            fontWeight: AppFontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _whiteCtrl.text = p;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppTextField(
                    controller: _whiteCtrl,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: AppFontWeight.bold,
                    ),
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: '$wTeam の選手名を入力',
                      labelStyle: const TextStyle(color: AppKendoColors.grey),
                      filled: true,
                      fillColor: inputBgColor,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                        horizontal: AppSpacing.lg,
                      ),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                        borderSide: const BorderSide(
                          color: Color(0xFF009688),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppKendoColors.grey,
                          side: const BorderSide(color: AppKendoColors.grey),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'キャンセル',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: AppFontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          foregroundColor: const Color(0xFFFFFFFF),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          showAppDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final nextMatchId = const Uuid().v4();
                          final newRed =
                              '$rTeam : ${_redCtrl.text.trim().isEmpty ? '選手' : _redCtrl.text.trim()}';
                          final newWhite =
                              '$wTeam : ${_whiteCtrl.text.trim().isEmpty ? '選手' : _whiteCtrl.text.trim()}';

                          final rule = ref.read(matchRuleProvider);
                          final lastSettings = ref.read(
                            lastUsedSettingsProvider,
                          );
                          final double exactMatchTime =
                              (lastSettings['matchTime'] as num?)?.toDouble() ??
                              rule.matchTimeMinutes.toDouble();

                          final nextMatch = MatchModel(
                            id: nextMatchId,
                            tournamentId: widget.currentMatch.tournamentId,
                            category: widget.currentMatch.category,
                            groupName: widget.currentMatch.groupName,
                            matchType: '錬成会',
                            rule: widget.currentMatch.rule ?? rule,
                            redName: newRed,
                            whiteName: newWhite,
                            status: 'waiting',
                            matchTimeMinutes: exactMatchTime,
                            isRunningTime: rule.isRunningTime,
                            order: widget.currentMatch.order + 0.1,
                            note: widget.currentMatch.note,
                          );

                          await ref
                              .read(matchApplicationServiceProvider)
                              .saveMatch(nextMatch);

                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true).pop();
                          if (!context.mounted) return;
                          Navigator.pop(context);

                          if (!context.mounted) return;
                          context.pushReplacement('/match/$nextMatchId');
                        },
                        child: const Text(
                          '決定して開始',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppFontSize.bodyMedium,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? get firstOrNull => isEmpty ? null : first;
}
