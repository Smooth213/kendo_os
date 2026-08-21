import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_data_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_player_slot_tile.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 試合編集シートの「チーム・選手情報」タブ
class MatchEditTeamAndPlayersTab extends StatelessWidget {
  final bool isDantai;
  final TextEditingController redTeamController;
  final TextEditingController whiteTeamController;
  final List<TextEditingController> redPlayerControllers;
  final List<TextEditingController> whitePlayerControllers;
  final Color primaryAccent;
  final bool isDark;
  final Color textColor;
  final VoidCallback onSwapTeamsAndPlayers;

  const MatchEditTeamAndPlayersTab({
    super.key,
    required this.isDantai,
    required this.redTeamController,
    required this.whiteTeamController,
    required this.redPlayerControllers,
    required this.whitePlayerControllers,
    required this.primaryAccent,
    required this.isDark,
    required this.textColor,
    required this.onSwapTeamsAndPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.roundValue),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x33000000),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDantai ? '🏫 団体戦 対戦チーム' : '👤 対戦者情報',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: redTeamController,
                      label: '赤（RED）チーム名',
                      hint: '赤チーム名を入力',
                      isDark: isDark,
                      textColor: AppKendoColors.red,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: whiteTeamController,
                      label: '白（WHITE）チーム名',
                      hint: '白チーム名を入力',
                      isDark: isDark,
                      textColor: context.appColors.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.swap_horiz,
                    color: AppKendoColors.pureWhite,
                  ),
                  label: Text(
                    isDantai ? 'チーム丸ごと赤と白を入れ替える ⇄' : '赤と白を入れ替える ⇄',
                    style: const TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKendoColors.blueAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.round,
                    ),
                  ),
                  onPressed: onSwapTeamsAndPlayers,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isDantai ? '👥 選手オーダー一覧（先鋒〜大将）' : '👤 選手名',
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.body,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(redPlayerControllers.length, (index) {
          final posLabel = MatchEditDataHelper.getPositionLabel(
            index,
            redPlayerControllers.length,
          );
          return MatchEditPlayerSlotTile(
            posLabel: posLabel,
            redController: redPlayerControllers[index],
            whiteController: whitePlayerControllers[index],
            primaryAccent: primaryAccent,
            isDark: isDark,
            textColor: textColor,
          );
        }),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required Color textColor,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.small,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: AppFontSize.body),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x33000000),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x33000000),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
