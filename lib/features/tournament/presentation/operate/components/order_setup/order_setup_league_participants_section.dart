import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_team_autocomplete_field.dart';

class OrderSetupLeagueParticipantsSection extends StatefulWidget {
  final AppThemeColors themeColors;
  final List<String> leagueParticipants;
  final Map<String, List<String>> leagueTeamOrders;
  final List<String> positions;
  final String ruleTeamName;
  final String matchType;
  final List<String> opponentTeamSuggestions;
  final VoidCallback onParticipantsChanged;
  final bool isDark;

  const OrderSetupLeagueParticipantsSection({
    super.key,
    required this.themeColors,
    required this.leagueParticipants,
    required this.leagueTeamOrders,
    required this.positions,
    required this.ruleTeamName,
    required this.matchType,
    required this.opponentTeamSuggestions,
    required this.onParticipantsChanged,
    required this.isDark,
  });

  @override
  State<OrderSetupLeagueParticipantsSection> createState() =>
      _OrderSetupLeagueParticipantsSectionState();
}

class _OrderSetupLeagueParticipantsSectionState
    extends State<OrderSetupLeagueParticipantsSection> {
  final TextEditingController _addParticipantController =
      TextEditingController();
  final FocusNode _addParticipantFocusNode = FocusNode();

  @override
  void dispose() {
    _addParticipantController.dispose();
    _addParticipantFocusNode.dispose();
    super.dispose();
  }

  Future<List<String>?> _showLeagueOrderSheet(
    BuildContext context,
    String teamName,
    List<String> positions,
  ) async {
    final List<TextEditingController> controllers = List.generate(
      positions.length,
      (i) => TextEditingController(),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showAppBottomSheet<List<String>>(
      context: context,
      builder: (ctx) => AppBottomSheetContent(
        title: '$teamName のオーダー',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: positions.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppTextField(
                      controller: controllers[i],
                      autofocus: i == 0,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : context.appColors.cardBackground,
                      ),
                      decoration: InputDecoration(
                        labelText: positions[i],
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : context.appColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.small,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    controllers
                        .map((c) => TextSanitizer.clean(c.text))
                        .toList(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColors.primaryAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                  ),
                  child: const Text(
                    '決定して追加',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showIndividualNameInputSheet(
    BuildContext context,
    String teamName,
  ) async {
    final nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showAppBottomSheet<String>(
      context: context,
      builder: (ctx) => AppBottomSheetContent(
        title: teamName.isNotEmpty ? '$teamName の選手名' : '選手名の登録',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : context.appColors.cardBackground,
                ),
                decoration: InputDecoration(
                  labelText: '選手名（例：田中太郎）',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: AppRadius.small),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    TextSanitizer.clean(nameController.text),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColors.primaryAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                  ),
                  child: const Text(
                    '決定して追加',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.appColors.textColor;
    final borderColor = widget.isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final subTextColor = widget.isDark
        ? const Color(0xFF8E8E93)
        : context.appColors.subTextColor;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. リーグ参加者リストの作成',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: widget.themeColors.primaryAccent,
              fontSize: AppFontSize.subhead,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '大会パンフレットの番号順に並べ替えてください（長押しで移動）',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OrderSetupTeamAutocompleteField(
            controller: _addParticipantController,
            focusNode: _addParticipantFocusNode,
            suggestions: widget.opponentTeamSuggestions,
            labelText: '参加チーム名を追加',
            hintText: '入力または履歴から選択',
            fillColor: widget.isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
            primaryAccent: widget.themeColors.primaryAccent,
            isDark: widget.isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                _addParticipantFocusNode.unfocus();
                FocusScope.of(context).unfocus();

                final inputTeamName = TextSanitizer.clean(
                  _addParticipantController.text,
                );

                if (widget.leagueParticipants.contains(inputTeamName)) {
                  AppSnackBar.showError(context, 'その名称は既に登録されています');
                  return;
                }

                if (widget.matchType.contains('個人戦')) {
                  final playerName = await _showIndividualNameInputSheet(
                    context,
                    inputTeamName,
                  );
                  if (playerName != null && playerName.isNotEmpty) {
                    final fullName = inputTeamName.isNotEmpty
                        ? '$inputTeamName : $playerName'
                        : playerName;
                    widget.leagueParticipants.add(fullName);
                    widget.leagueTeamOrders[fullName] = [playerName];
                    widget.onParticipantsChanged();
                    _addParticipantController.clear();
                  }
                } else {
                  if (inputTeamName.isEmpty) {
                    AppSnackBar.showError(context, 'チーム名を入力してください');
                    return;
                  }
                  final order = await _showLeagueOrderSheet(
                    context,
                    inputTeamName,
                    widget.positions,
                  );
                  if (order != null) {
                    widget.leagueParticipants.add(inputTeamName);
                    widget.leagueTeamOrders[inputTeamName] = order;
                    widget.onParticipantsChanged();
                    _addParticipantController.clear();
                  }
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text(
                'リストに追加',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColors.primaryAccent,
                foregroundColor: AppKendoColors.pureWhite,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFFFFFFFF),
              borderRadius: AppRadius.large,
              border: Border.all(color: borderColor),
            ),
            child: Material(
              color: AppKendoColors.transparent,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.leagueParticipants.length,
                onReorderItem: (oldIndex, newIndex) {
                  final item = widget.leagueParticipants.removeAt(oldIndex);
                  widget.leagueParticipants.insert(newIndex, item);
                  widget.onParticipantsChanged();
                },
                itemBuilder: (context, index) {
                  final name = widget.leagueParticipants[index];
                  final isOwn =
                      name.contains('自チーム') || name == widget.ruleTeamName;
                  return ListTile(
                    key: ValueKey(name),
                    leading: CircleAvatar(
                      backgroundColor: isOwn
                          ? widget.themeColors.softAccent
                          : context.appColors.separatorColor,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: widget.themeColors.primaryAccent,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.drag_handle,
                      color: AppKendoColors.grey,
                    ),
                    onLongPress: () {},
                    subtitle: isOwn
                        ? Text(
                            '（自チーム）',
                            style: TextStyle(
                              fontSize: AppFontSize.badge,
                              color: widget.themeColors.primaryAccent,
                            ),
                          )
                        : null,
                    onTap: isOwn
                        ? null
                        : () {
                            widget.leagueParticipants.removeAt(index);
                            widget.onParticipantsChanged();
                          },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            '2. 自チームのオーダーを確認',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: widget.themeColors.primaryAccent,
              fontSize: AppFontSize.subhead,
            ),
          ),
        ],
      ),
    );
  }
}
