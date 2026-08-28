import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 試合操作画面用 代表戦選手選択モーダルボトムシート
class MatchRepresentativeModalBottomSheet extends ConsumerStatefulWidget {
  final MatchModel match;
  final String rTeam;
  final String wTeam;
  final List<String> redPlayers;
  final List<String> whitePlayers;

  const MatchRepresentativeModalBottomSheet({
    super.key,
    required this.match,
    required this.rTeam,
    required this.wTeam,
    required this.redPlayers,
    required this.whitePlayers,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel match,
    required String rTeam,
    required String wTeam,
    required List<String> redPlayers,
    required List<String> whitePlayers,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => MatchRepresentativeModalBottomSheet(
        match: match,
        rTeam: rTeam,
        wTeam: wTeam,
        redPlayers: redPlayers,
        whitePlayers: whitePlayers,
      ),
    );
  }

  @override
  ConsumerState<MatchRepresentativeModalBottomSheet> createState() =>
      _MatchRepresentativeModalBottomSheetState();
}

class _MatchRepresentativeModalBottomSheetState
    extends ConsumerState<MatchRepresentativeModalBottomSheet> {
  late final TextEditingController _redCtrl;
  late final TextEditingController _whiteCtrl;

  @override
  void initState() {
    super.initState();
    _redCtrl = TextEditingController(
      text: widget.redPlayers.isNotEmpty ? widget.redPlayers.first : '',
    );
    _whiteCtrl = TextEditingController(
      text: widget.whitePlayers.isNotEmpty ? widget.whitePlayers.first : '',
    );
  }

  @override
  void dispose() {
    _redCtrl.dispose();
    _whiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = context.appColors;
    final textColor = themeColors.textColor;
    final inputBg = themeColors.inputBackground;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: themeColors.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.roundValue),
          ),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: themeColors.separatorColor,
                borderRadius: AppRadius.capsule,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '代表戦の準備',
              style: TextStyle(
                fontSize: AppFontSize.header,
                fontWeight: AppFontWeight.bold,
                color: themeColors.textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '代表戦を戦う選手を選んでください。\n決定するとタイマーが0:00にリセットされます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: themeColors.subTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppKendoColors.red.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: AppRadius.large,
                      border: Border.all(color: AppKendoColors.red),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shield,
                              color: AppKendoColors.red,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${widget.rTeam} の代表者',
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                color: AppKendoColors.red,
                                fontSize: AppFontSize.subhead,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (widget.redPlayers.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.redPlayers
                                .map(
                                  (p) => AppChoiceChip(
                                    label: Text(p),
                                    selected: _redCtrl.text == p,
                                    selectedColor: AppKendoColors.red,
                                    backgroundColor: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : context.appColors.inputBackground,
                                    labelStyle: TextStyle(
                                      color: _redCtrl.text == p
                                          ? AppKendoColors.pureWhite
                                          : textColor,
                                      fontWeight: _redCtrl.text == p
                                          ? AppFontWeight.bold
                                          : AppFontWeight.regular,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _redCtrl.text = p;
                                        });
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AppTextField(
                          controller: _redCtrl,
                          decoration: InputDecoration(
                            labelText: '選手名（直接入力も可）',
                            hintText: '例: 山田',
                            prefixIcon: const Icon(
                              Icons.person,
                              color: AppKendoColors.red,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.medium,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: themeColors.separatorColor.withValues(
                        alpha: isDark ? 0.3 : 0.15,
                      ),
                      borderRadius: AppRadius.large,
                      border: Border.all(color: themeColors.separatorColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield,
                              color: themeColors.subTextColor,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${widget.wTeam} の代表者',
                              style: TextStyle(
                                fontWeight: AppFontWeight.bold,
                                color: themeColors.textColor,
                                fontSize: AppFontSize.subhead,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (widget.whitePlayers.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.whitePlayers
                                .map(
                                  (p) => AppChoiceChip(
                                    label: Text(p),
                                    selected: _whiteCtrl.text == p,
                                    selectedColor: themeColors.primaryAccent,
                                    backgroundColor: inputBg,
                                    labelStyle: TextStyle(
                                      color: _whiteCtrl.text == p
                                          ? AppKendoColors.pureWhite
                                          : textColor,
                                      fontWeight: _whiteCtrl.text == p
                                          ? AppFontWeight.bold
                                          : AppFontWeight.regular,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _whiteCtrl.text = p;
                                        });
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AppTextField(
                          controller: _whiteCtrl,
                          decoration: InputDecoration(
                            labelText: '選手名（直接入力も可）',
                            hintText: '例: 鈴木',
                            prefixIcon: Icon(
                              Icons.person,
                              color: themeColors.subTextColor,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.medium,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    foregroundColor: AppKendoColors.pureWhite,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.large,
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    final rName = _redCtrl.text.trim().isEmpty
                        ? '代表'
                        : _redCtrl.text.trim();
                    final wName = _whiteCtrl.text.trim().isEmpty
                        ? '代表'
                        : _whiteCtrl.text.trim();

                    final newRed = '${widget.rTeam} : $rName';
                    final newWhite = '${widget.wTeam} : $wName';

                    final updatedMatch = widget.match
                        .copyWith(redName: newRed, whiteName: newWhite)
                        .updateRemainingSeconds(
                          0,
                          ref.read(timeSourceProvider).now(),
                        )
                        .copyWith(timerStartedAt: null);

                    await ref
                        .read(matchApplicationServiceProvider)
                        .saveMatch(updatedMatch);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    '決定して準備完了',
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
