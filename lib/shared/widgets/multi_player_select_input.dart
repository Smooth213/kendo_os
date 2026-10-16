import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/multi_player_candidate_chip.dart';
import 'package:kendo_os/shared/widgets/multi_player_filter_helper.dart';
import 'smart_player_input.dart';

class MultiPlayerSelectInput extends ConsumerStatefulWidget {
  final List<String> initialSelected;
  final Function(List<String>) onConfirm;
  final String label;
  final Color accentColor;
  final bool useRootNavigator;

  const MultiPlayerSelectInput({
    super.key,
    required this.initialSelected,
    required this.onConfirm,
    this.label = '選手を検索して追加（複数選択可）',
    this.accentColor = const Color(0xFF8B0000),
    this.useRootNavigator = true,
  });

  @override
  ConsumerState<MultiPlayerSelectInput> createState() =>
      _MultiPlayerSelectInputState();
}

class _MultiPlayerSelectInputState
    extends ConsumerState<MultiPlayerSelectInput> {
  late final TextEditingController _displayController;

  String _getDisplayText(List<String> selected) =>
      selected.isEmpty ? '' : '${selected.length}名選択中: ${selected.join(", ")}';

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController(
      text: _getDisplayText(widget.initialSelected),
    );
  }

  @override
  void didUpdateWidget(covariant MultiPlayerSelectInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = _getDisplayText(widget.initialSelected);
    if (_displayController.text != newText) {
      _displayController.text = newText;
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  Color get _accentColor => widget.accentColor == const Color(0xFF8B0000)
      ? (Theme.of(context).extension<AppThemeColors>()?.primaryAccent ??
            widget.accentColor)
      : widget.accentColor;

  Future<void> _showMultiSelectSheet() async {
    // 🥋 部員マスタの最新データを確実に先行取得（画像2の取得フローと同一化）
    List<PlayerModel> initialMaster = [];
    try {
      final repo = ref.read(playerRepositoryProvider);
      initialMaster = await repo.getPlayers().first.timeout(
        const Duration(milliseconds: 1000),
        onTimeout: () => ref.read(bunaiksenPlayerMasterProvider).value ?? [],
      );
    } catch (_) {
      initialMaster = ref.read(bunaiksenPlayerMasterProvider).value ?? [];
    }

    String searchText = '';
    String selectedFilter = 'すべて';
    bool isAscending = true;
    List<String> tempSelected = List.from(widget.initialSelected);

    if (!mounted) return;

    await showAppBottomSheet(
      context: context,
      useRootNavigator: widget.useRootNavigator,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final masterAsync = ref.watch(bunaiksenPlayerMasterProvider);
            final masterPlayers = masterAsync.value ?? initialMaster;
            final guestPlayers = ref.watch(bunaiksenGuestProvider);
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return StatefulBuilder(
              builder: (context, setStateSheet) {
                final filteredMaster =
                    MultiPlayerFilterHelper.filterAndSortMaster(
                      masterPlayers: masterPlayers,
                      searchText: searchText,
                      selectedFilter: selectedFilter,
                      isAscending: isAscending,
                    );
                final filteredGuest = MultiPlayerFilterHelper.filterGuests(
                  guestPlayers: guestPlayers,
                  searchText: searchText,
                  selectedFilter: selectedFilter,
                );
                final isNewName = MultiPlayerFilterHelper.isNewName(
                  searchText: searchText,
                  masterPlayers: masterPlayers,
                  guestPlayers: guestPlayers,
                );
                final totalCount =
                    (isNewName ? 1 : 0) +
                    filteredGuest.length +
                    filteredMaster.length;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    top: AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. ヘッダー（添付ファイル2準拠）
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people_alt_rounded,
                                  color: _accentColor,
                                  size: 22,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  widget.label,
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: AppFontSize.subhead,
                                    color: context.appColors.textColor,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => setStateSheet(
                                () => isAscending = !isAscending,
                              ),
                              borderRadius: AppRadius.full,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : context.appColors.inputBackground,
                                  borderRadius: AppRadius.full,
                                  border: Border.all(
                                    color: context.appColors.separatorColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: _accentColor,
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Text(
                                      isAscending ? '学年 昇順' : '学年 降順',
                                      style: TextStyle(
                                        fontSize: AppFontSize.badge,
                                        fontWeight: AppFontWeight.bold,
                                        color: context.appColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 2. 検索窓（添付ファイル2準拠）
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: AppTextField(
                          autofocus: false,
                          decoration: InputDecoration(
                            hintText: '名前を入力または名簿から1タップ選択',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: context.appColors.inputBackground,
                            border: const OutlineInputBorder(
                              borderRadius: AppRadius.small,
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                          onChanged: (val) =>
                              setStateSheet(() => searchText = val),
                          onSubmitted: (val) {
                            if (isNewName) {
                              ref
                                  .read(bunaiksenGuestProvider.notifier)
                                  .update((state) => [...state, val.trim()]);
                              setStateSheet(() {
                                tempSelected.add(val.trim());
                                searchText = '';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 3. カテゴリフィルター（横スクロール）
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Row(
                          children: MultiPlayerFilterHelper.filterCategories
                              .map((filterName) {
                                final isSelected = selectedFilter == filterName;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.sm,
                                  ),
                                  child: AppChoiceChip(
                                    label: Text(filterName),
                                    selected: isSelected,
                                    customSelectedColor: _accentColor,
                                    customTextColor: isSelected
                                        ? AppKendoColors.pureWhite
                                        : null,
                                    onSelected: (bool selected) {
                                      if (selected) {
                                        setStateSheet(
                                          () => selectedFilter = filterName,
                                        );
                                      }
                                    },
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 4. 選手カードリスト（添付ファイル2準拠）
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.42,
                        child: totalCount == 0
                            ? Center(
                                child: Text(
                                  searchText.isNotEmpty
                                      ? '「$searchText」をゲスト追加して選択できます'
                                      : '該当する選手がいません',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(
                                            0xFFFFFFFF,
                                          ).withValues(alpha: 0.54)
                                        : const Color(0x8A000000),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                itemCount: totalCount,
                                itemBuilder: (context, index) {
                                  if (isNewName && index == 0) {
                                    final newName = searchText.trim();
                                    return MultiPlayerCandidateTile(
                                      name: newName,
                                      subtitle: 'ゲスト追加して選択',
                                      isSelected: false,
                                      accentColor: _accentColor,
                                      onChanged: (_) {
                                        ref
                                            .read(
                                              bunaiksenGuestProvider.notifier,
                                            )
                                            .addGuest(newName);
                                        setStateSheet(() {
                                          tempSelected.add(newName);
                                          searchText = '';
                                        });
                                      },
                                    );
                                  }

                                  final adjustedIndex = isNewName
                                      ? index - 1
                                      : index;
                                  if (adjustedIndex < filteredGuest.length) {
                                    final name = filteredGuest[adjustedIndex];
                                    final isSelected = tempSelected.contains(
                                      name,
                                    );
                                    return MultiPlayerCandidateTile(
                                      name: name,
                                      subtitle: '出稽古・ゲスト',
                                      isSelected: isSelected,
                                      accentColor: _accentColor,
                                      onChanged: (bool? val) {
                                        setStateSheet(() {
                                          if (val == true) {
                                            tempSelected.add(name);
                                          } else {
                                            tempSelected.remove(name);
                                          }
                                        });
                                      },
                                    );
                                  }

                                  final masterIndex =
                                      adjustedIndex - filteredGuest.length;
                                  final p = filteredMaster[masterIndex];
                                  final isSelected = tempSelected.contains(
                                    p.name,
                                  );
                                  return MultiPlayerCandidateTile(
                                    name: p.name,
                                    subtitle: p.gradeName,
                                    isSelected: isSelected,
                                    accentColor: _accentColor,
                                    onChanged: (bool? val) {
                                      setStateSheet(() {
                                        if (val == true) {
                                          tempSelected.add(p.name);
                                        } else {
                                          tempSelected.remove(p.name);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 5. 確定ボタン（何名選択中か一目でわかる）
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: AppKendoColors.pureWhite,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.medium,
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(
                              tempSelected.isEmpty
                                  ? '選択を完了（0名）'
                                  : 'この${tempSelected.length}名で決定',
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.body,
                              ),
                            ),
                            onPressed: () {
                              widget.onConfirm(tempSelected);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _showMultiSelectSheet,
      borderRadius: AppRadius.small,
      child: IgnorePointer(
        child: AppTextField(
          readOnly: true,
          controller: _displayController,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'タップしてメンバーを選択...',
            filled: true,
            fillColor: context.appColors.inputBackground,
            floatingLabelStyle: TextStyle(color: _accentColor),
            prefixIcon: Icon(Icons.group_add, color: _accentColor),
            suffixIcon: const Icon(Icons.touch_app),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x8A000000),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide(color: _accentColor, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
