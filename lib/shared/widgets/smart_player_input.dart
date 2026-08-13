import 'package:flutter/material.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

// 部内戦機能で利用する選手マスタを取得する専用Provider
final bunaiksenPlayerMasterProvider =
    StreamProvider.autoDispose<List<PlayerModel>>((ref) {
      // 既存のplayerRepositoryProviderをwatchして選手リストを取得
      return ref.watch(playerRepositoryProvider).getPlayers();
    });

class SmartPlayerInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final Color accentColor;

  const SmartPlayerInput({
    super.key,
    required this.controller,
    required this.label,
    this.accentColor = const Color(0xFF8B0000), // ★ 修正：洗練されたボルドー（深紅）に変更
  });

  @override
  ConsumerState<SmartPlayerInput> createState() => _SmartPlayerInputState();
}

class _SmartPlayerInputState extends ConsumerState<SmartPlayerInput> {
  Color get _accentColor {
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    if (widget.accentColor == const Color(0xFF8B0000) && themeColors != null) {
      return themeColors.primaryAccent;
    }
    return widget.accentColor;
  }

  // ボトムシートを開いて選手を選択・追加するメソッド
  Future<void> _showPlayerSelectSheet() async {
    final masterPlayers = ref.read(bunaiksenPlayerMasterProvider).value ?? [];
    final guestPlayers = ref.watch(bunaiksenGuestProvider);

    String searchText = '';
    String selectedFilter = 'すべて';

    await showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            // 1. 検索ワードによる絞り込み ＋ カテゴリ別フィルタ
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

            // よみがな順でソート（常に美しく並ぶ）
            filteredMaster.sort((a, b) => a.nameKana.compareTo(b.nameKana));

            // ゲストは「すべて」または「ゲスト」フィルターの時のみ表示
            final filteredGuest =
                (selectedFilter == 'すべて' || selectedFilter == 'ゲスト')
                ? guestPlayers
                      .where((name) => name.contains(searchText))
                      .toList()
                : <String>[];

            // 入力文字が完全に新しい（名簿・ゲストともに重複しない）場合のみ「追加」ボタンを表示
            final isNewName =
                searchText.trim().isNotEmpty &&
                !masterPlayers.any((p) => p.name == searchText.trim()) &&
                !guestPlayers.any((name) => name == searchText.trim());

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // キーボードを避ける
                top: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '選手を選択',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.subhead,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: AppTextField(
                      autofocus: true, // 開いた瞬間にキーボードを出す
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
                      onChanged: (val) {
                        setStateSheet(() => searchText = val);
                      },
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          if (isNewName) {
                            ref
                                .read(bunaiksenGuestProvider.notifier)
                                .update((state) => [...state, val.trim()]);
                          }
                          widget.controller.text = val.trim();
                          Navigator.pop(context);
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
                                customTextColor: isSelected
                                    ? AppKendoColors.pureWhite
                                    : null,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setStateSheet(() {
                                      selectedFilter = filterName;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4, // リストの高さ
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
                              '"${searchText.trim()}" をゲストとして追加',
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
                              widget.controller.text = searchText.trim();
                              Navigator.pop(context);
                            },
                          ),
                        ...filteredGuest.map(
                          (name) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppKendoColors.grey.withAlpha(
                                26,
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppKendoColors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text(name),
                            subtitle: const Text(
                              '出稽古・ゲスト',
                              style: TextStyle(
                                fontSize: AppFontSize.small,
                                color: AppKendoColors.grey,
                              ),
                            ),
                            onTap: () {
                              widget.controller.text = name;
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        ...filteredMaster.map(
                          (p) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _accentColor.withAlpha(26),
                              child: Icon(
                                Icons.person,
                                color: _accentColor,
                                size: 20,
                              ),
                            ),
                            title: Text(p.name),
                            subtitle: Text(
                              p.gradeName,
                              style: const TextStyle(
                                fontSize: AppFontSize.small,
                                color: AppKendoColors.grey,
                              ),
                            ), // ★ 修正：マスタの学年を表示
                            onTap: () {
                              widget.controller.text = p.name;
                              Navigator.pop(context);
                            },
                          ),
                        ),
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
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return AppTextField(
      controller: widget.controller,
      readOnly: true, // 直接入力させず、ボトムシートに誘導する
      onTap: _showPlayerSelectSheet, // タップでボトムシートを開く
      decoration: InputDecoration(
        labelText: widget.label,
        filled: true,
        fillColor: themeColors.inputBackground,
        floatingLabelStyle: TextStyle(color: _accentColor),
        suffixIcon: const Icon(Icons.arrow_drop_down), // ボトムシートが開くことを示唆するアイコン
        border: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(color: themeColors.separatorColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(color: themeColors.separatorColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
      ),
    );
  }
}
