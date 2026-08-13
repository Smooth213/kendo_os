import 'package:flutter/material.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'smart_player_input.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

class MultiPlayerSelectInput extends ConsumerStatefulWidget {
  final List<String> initialSelected;
  final Function(List<String>) onConfirm;
  final String label;
  final Color accentColor;

  const MultiPlayerSelectInput({
    super.key,
    required this.initialSelected,
    required this.onConfirm,
    this.label = '選手を検索して追加（複数選択可）',
    this.accentColor = const Color(0xFF8B0000),
  });

  @override
  ConsumerState<MultiPlayerSelectInput> createState() =>
      _MultiPlayerSelectInputState();
}

class _MultiPlayerSelectInputState
    extends ConsumerState<MultiPlayerSelectInput> {
  Color get _accentColor {
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    if (widget.accentColor == const Color(0xFF8B0000) && themeColors != null) {
      return themeColors.primaryAccent;
    }
    return widget.accentColor;
  }

  Future<void> _showMultiSelectSheet() async {
    final masterPlayers = ref.read(bunaiksenPlayerMasterProvider).value ?? [];
    final guestPlayers = ref.watch(bunaiksenGuestProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String searchText = '';
    String selectedFilter = 'すべて';
    // モーダル内でのみ操作する一時的な選択リスト
    List<String> tempSelected = List.from(widget.initialSelected);

    await showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            List<PlayerModel> filteredMaster = masterPlayers
                .where((p) => p.name.contains(searchText))
                .toList();

            if (selectedFilter != 'すべて') {
              if (selectedFilter == 'ゲスト') {
                filteredMaster = [];
              } else if (selectedFilter == '初心者') {
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
                    .where(
                      (p) => p.grade >= 10 && p.grade <= 12 && !p.isBeginner,
                    )
                    .toList();
              } else if (selectedFilter == '一般') {
                filteredMaster = filteredMaster
                    .where((p) => p.grade >= 13 && !p.isBeginner)
                    .toList();
              } else {
                filteredMaster = [];
              }
            }

            // よみがな順でソート
            filteredMaster.sort((a, b) => a.nameKana.compareTo(b.nameKana));

            final filteredGuest =
                (selectedFilter == 'すべて' || selectedFilter == 'ゲスト')
                ? guestPlayers
                      .where((name) => name.contains(searchText))
                      .toList()
                : <String>[];

            final isNewName =
                searchText.trim().isNotEmpty &&
                !masterPlayers.any((p) => p.name == searchText.trim()) &&
                !guestPlayers.any((name) => name == searchText.trim());

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ヘッダー（確定ボタン付き）
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'キャンセル',
                            style: TextStyle(
                              color: isDark
                                  ? context.appColors.subTextColor
                                  : context.appColors.subTextColor,
                            ),
                          ),
                        ),
                        Text(
                          '${tempSelected.length}名 選択中',
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.subhead,
                            color: _accentColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // ★ ここで確定し、親の画面にリストを一気に渡す
                            widget.onConfirm(tempSelected);
                            Navigator.pop(context);
                          },
                          child: Text(
                            '確定',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.subhead,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // 検索窓
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: AppTextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '名前で検索、または出稽古を追加',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: context.appColors.inputBackground,
                        border: const OutlineInputBorder(
                          borderRadius: AppRadius.small,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) => setStateSheet(() => searchText = val),
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
                  // ★ カテゴリフィルターチップ（横スクロール）
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
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
                            'ゲスト',
                          ].map((filterName) {
                            final isSelected = selectedFilter == filterName;
                            final activeColor = _accentColor;
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: AppChoiceChip(
                                label: Text(filterName),
                                selected: isSelected,
                                customSelectedColor: activeColor,
                                onSelected: (bool selected) {
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
                  const SizedBox(height: AppSpacing.sm),
                  // 選手リスト（チェックボックス式）
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: ListView(
                      children: [
                        if (isNewName)
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _accentColor.withAlpha(26),
                              child: Icon(
                                Icons.person_add,
                                color: _accentColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              '"${searchText.trim()}" をゲスト追加して選択',
                              style: TextStyle(
                                color: _accentColor,
                                fontWeight: AppFontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              ref
                                  .read(bunaiksenGuestProvider.notifier)
                                  .update(
                                    (state) => [...state, searchText.trim()],
                                  );
                              setStateSheet(() {
                                tempSelected.add(searchText.trim());
                                searchText = '';
                              });
                            },
                          ),
                        ...filteredGuest.map((name) {
                          final isSelected = tempSelected.contains(name);
                          return CheckboxListTile(
                            activeColor: _accentColor,
                            value: isSelected,
                            title: Text(name),
                            subtitle: const Text(
                              '出稽古・ゲスト',
                              style: TextStyle(
                                fontSize: AppFontSize.small,
                                color: AppKendoColors.grey,
                              ),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: AppKendoColors.grey.withAlpha(
                                26,
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppKendoColors.grey,
                                size: 20,
                              ),
                            ),
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
                        }),
                        ...filteredMaster.map((p) {
                          final isSelected = tempSelected.contains(p.name);
                          return CheckboxListTile(
                            activeColor: _accentColor,
                            value: isSelected,
                            title: Text(p.name),
                            subtitle: Text(
                              p.gradeName,
                              style: const TextStyle(
                                fontSize: AppFontSize.small,
                                color: AppKendoColors.grey,
                              ),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: _accentColor.withAlpha(26),
                              child: Icon(
                                Icons.person,
                                color: _accentColor,
                                size: 20,
                              ),
                            ),
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
                        }),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 入力欄に「何人選択されているか」と「選択した名前」をサマリー表示する
    final displayText = widget.initialSelected.isEmpty
        ? ''
        : '${widget.initialSelected.length}名選択中: ${widget.initialSelected.join(", ")}';

    return AppTextField(
      readOnly: true, // キーボードは出さずボトムシートを開く
      onTap: _showMultiSelectSheet,
      controller: TextEditingController(text: displayText),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'タップしてメンバーを選択...',
        filled: true,
        fillColor: context.appColors.inputBackground,
        floatingLabelStyle: TextStyle(color: _accentColor),
        prefixIcon: Icon(Icons.group_add, color: _accentColor),
        suffixIcon: const Icon(Icons.touch_app),
        border: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(
            color: isDark
                ? context.appColors.textColor
                : context.appColors.subTextColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(
            color: isDark ? const Color(0xDE000000) : const Color(0x8A000000),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
      ),
    );
  }
}
