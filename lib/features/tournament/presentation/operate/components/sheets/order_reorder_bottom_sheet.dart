import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/dialogs/add_reserve_player_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/sheets/order_reorder_player_tile.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 団体戦のオーダー並び替え＆補欠交代を行うボトムシート
class OrderReorderBottomSheet extends ConsumerStatefulWidget {
  final List<MatchModel> sortedMatches;

  const OrderReorderBottomSheet({super.key, required this.sortedMatches});

  @override
  ConsumerState<OrderReorderBottomSheet> createState() =>
      _OrderReorderBottomSheetState();
}

class _OrderReorderBottomSheetState
    extends ConsumerState<OrderReorderBottomSheet> {
  late List<String> _positions;
  late List<String> _currentPlayers;
  List<String> _reservePlayers = [];
  List<Map<String, String>> _unifiedList = [];

  String _ownTeamName = '';
  bool _isOwnTeamRed = true;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSyncData();
  }

  void _initializeSyncData() {
    final firstMatch = widget.sortedMatches.first;
    final ownTeams = ref.read(customTeamNamesProvider).value ?? [];
    final ruleTeamName = firstMatch.rule?.teamName;

    final rTeam = firstMatch.redName.contains(':')
        ? firstMatch.redName.split(':').first.trim()
        : firstMatch.redName;
    final wTeam = firstMatch.whiteName.contains(':')
        ? firstMatch.whiteName.split(':').first.trim()
        : firstMatch.whiteName;

    final isRedOwn =
        ownTeams.contains(rTeam) ||
        (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
    final isWhiteOwn =
        ownTeams.contains(wTeam) ||
        (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);

    if (isRedOwn) {
      _ownTeamName = rTeam;
      _isOwnTeamRed = true;
    } else if (isWhiteOwn) {
      _ownTeamName = wTeam;
      _isOwnTeamRed = false;
    } else {
      _ownTeamName = rTeam;
      _isOwnTeamRed = true;
    }

    _positions = [];
    _currentPlayers = [];
    for (var m in widget.sortedMatches) {
      final pos = m.matchType;
      final rawName = _isOwnTeamRed ? m.redName : m.whiteName;
      final name = rawName.contains(':')
          ? rawName.split(':').last.trim()
          : rawName;

      _positions.add(pos);
      _currentPlayers.add(name);
    }
  }

  void _buildUnifiedList() {
    _unifiedList = [];
    for (int i = 0; i < _positions.length; i++) {
      _unifiedList.add({
        'id': 'pos_$i',
        'type': 'position',
        'label': _positions[i],
        'name': _currentPlayers[i],
      });
    }
    for (int i = 0; i < _reservePlayers.length; i++) {
      final rp = _reservePlayers[i];
      _unifiedList.add({
        'id': 'reserve_${rp}_$i',
        'type': 'reserve',
        'label': '控え',
        'name': rp,
      });
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _unifiedList.removeAt(oldIndex);
      _unifiedList.insert(newIndex, item);

      final posCount = _positions.length;
      _currentPlayers = [];
      _reservePlayers = [];

      for (int i = 0; i < _unifiedList.length; i++) {
        final name = _unifiedList[i]['name']!;
        if (i < posCount) {
          _currentPlayers.add(name);
          _unifiedList[i]['type'] = 'position';
          _unifiedList[i]['label'] = _positions[i];
        } else {
          _reservePlayers.add(name);
          _unifiedList[i]['type'] = 'reserve';
          _unifiedList[i]['label'] = '控え';
        }
      }
    });
  }

  Future<void> _addNewPlayerToReserve(
    List<PlayerModel> allPlayers,
    List<TeamModel> allTeams,
  ) async {
    final teamPlayers = allPlayers
        .where((p) {
          final org = p.organization.trim();
          if (org.isEmpty) return false;
          return _ownTeamName.contains(org) || org.contains(_ownTeamName);
        })
        .map((p) => p.name)
        .toList();

    final matchedTeam = allTeams.firstWhere(
      (t) => t.teamName == _ownTeamName || _ownTeamName == t.teamName,
      orElse: () {
        return allTeams.firstWhere(
          (t) =>
              _ownTeamName.contains(t.teamName) ||
              t.teamName.contains(_ownTeamName),
          orElse: () => TeamModel(
            id: '',
            tournamentId: '',
            category: '',
            teamName: '',
            matchType: '',
            playerNames: [],
          ),
        );
      },
    );
    final teamRegisteredPlayerNames = matchedTeam.playerNames
        .where((name) => name.isNotEmpty)
        .toList();

    final Set<String> candidates = {
      ...teamRegisteredPlayerNames,
      ...teamPlayers,
    };

    final existingNames = _unifiedList.map((item) => item['name']!).toSet();
    final availablePlayers = candidates
        .where(
          (name) =>
              !existingNames.contains(name) && name != '未定' && name != '欠員',
        )
        .toList();

    if (!mounted) return;

    final String? selectedName = await showAppDialog<String>(
      context: context,
      builder: (context) =>
          AddReservePlayerDialog(availablePlayers: availablePlayers),
    );

    if (selectedName != null) {
      setState(() {
        _reservePlayers.add(selectedName);
        _buildUnifiedList();
      });
    }
  }

  Future<void> _saveOrder() async {
    setState(() {
      _isSaving = true;
    });

    final List<MatchModel> updatedMatches = [];
    for (int i = 0; i < widget.sortedMatches.length; i++) {
      final originalMatch = widget.sortedMatches[i];
      final newPlayerName = _currentPlayers[i];

      final String updatedRedName;
      final String updatedWhiteName;

      if (_isOwnTeamRed) {
        updatedRedName = '$_ownTeamName : $newPlayerName';
        updatedWhiteName = originalMatch.whiteName;
      } else {
        updatedRedName = originalMatch.redName;
        updatedWhiteName = '$_ownTeamName : $newPlayerName';
      }

      final updatedMatch = originalMatch.copyWith(
        redName: updatedRedName,
        whiteName: updatedWhiteName,
      );
      updatedMatches.add(updatedMatch);
    }

    try {
      await ref
          .read(matchApplicationServiceProvider)
          .saveMatchesBulk(updatedMatches);

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(context, 'オーダーを更新しました。');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'オーダーの更新に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return const SizedBox(
        height: 300,
        child: Center(child: AppLoadingIndicator()),
      );
    }

    final playersAsync = ref.watch(timelinePlayerListProvider);
    final tournamentId = widget.sortedMatches.first.tournamentId ?? '';
    final teamsAsync = ref.watch(registeredTeamsProvider(tournamentId));

    return playersAsync.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: AppLoadingIndicator()),
      ),
      error: (err, stack) => SizedBox(
        height: 300,
        child: Center(child: Text('選手リストの読み込みに失敗しました: $err')),
      ),
      data: (allPlayers) {
        return teamsAsync.when(
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: AppLoadingIndicator()),
          ),
          error: (err, stack) => SizedBox(
            height: 300,
            child: Center(child: Text('チームリストの読み込みに失敗しました: $err')),
          ),
          data: (allTeams) {
            if (!_isInitialized) {
              final matchedTeam = allTeams.firstWhere(
                (t) => t.teamName == _ownTeamName || _ownTeamName == t.teamName,
                orElse: () {
                  return allTeams.firstWhere(
                    (t) =>
                        _ownTeamName.contains(t.teamName) ||
                        t.teamName.contains(_ownTeamName),
                    orElse: () => TeamModel(
                      id: '',
                      tournamentId: '',
                      category: '',
                      teamName: '',
                      matchType: '',
                      playerNames: [],
                    ),
                  );
                },
              );

              final List<String> teamRegisteredPlayerNames = matchedTeam
                  .playerNames
                  .where((name) => name.isNotEmpty)
                  .toList();

              final Set<String> candidates = {...teamRegisteredPlayerNames};

              _reservePlayers = candidates
                  .where(
                    (name) =>
                        !_currentPlayers.contains(name) &&
                        name != '未定' &&
                        name != '欠員',
                  )
                  .toList();

              _buildUnifiedList();
              _isInitialized = true;
            }

            return AppBottomSheetContent(
              showDragHandle: true,
              title: 'オーダー編集 : $_ownTeamName',
              titleTrailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      '右側の三本線を長押し・ドラッグして並び替えます。上の5枠が出場選手になります。',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: AppKendoColors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: _unifiedList.length,
                      itemBuilder: (context, index) {
                        final item = _unifiedList[index];
                        final id = item['id']!;
                        final name = item['name']!;
                        final label = item['label']!;
                        final isPosition = item['type'] == 'position';

                        return OrderReorderPlayerTile(
                          key: ValueKey('unified_item_$id'),
                          label: label,
                          playerName: name,
                          isPosition: isPosition,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                        );
                      },
                      onReorderItem: _onReorder,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _addNewPlayerToReserve(allPlayers, allTeams),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          '控えを追加',
                          style: TextStyle(fontSize: AppFontSize.small),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _saveOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.primaryAccent,
                          foregroundColor: AppKendoColors.pureWhite,
                        ),
                        child: const Text('オーダーを確定'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
