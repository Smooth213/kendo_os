import 'package:flutter/material.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 観戦共有URLへトークンパラメータを安全に付与・差し替えする純粋ヘルパー
class ViewerShareUrlHelper {
  const ViewerShareUrlHelper._();

  static String attachToken(String rawUrl, String? token) {
    if (token == null || token.isEmpty) return rawUrl;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    final params = Map<String, String>.from(uri.queryParameters);
    params['token'] = token;
    return uri.replace(queryParameters: params).toString();
  }

  static String replaceUrlInText(String rawText, String oldUrl, String newUrl) {
    if (oldUrl == newUrl) return rawText;
    return rawText.replaceAll(oldUrl, newUrl);
  }
}

/// 1大会限定 観戦共有リンクの有効期限（24時間 / 7日間 / 無期限 / 停止）を選択するUI
class ViewerShareExpirySelector extends StatelessWidget {
  final ViewerShareExpiryPreset selectedPreset;
  final DateTime? expiresAt;
  final bool isUpdating;
  final ValueChanged<ViewerShareExpiryPreset> onPresetSelected;

  const ViewerShareExpirySelector({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelected,
    this.expiresAt,
    this.isUpdating = false,
  });

  String _statusText() {
    if (selectedPreset == ViewerShareExpiryPreset.revoked) {
      return '現在この共有リンクは停止中です（URLやQRから閲覧できません）';
    }
    if (selectedPreset == ViewerShareExpiryPreset.unlimited ||
        expiresAt == null) {
      return '有効期限なし（停止するまで閲覧可能）';
    }
    final local = expiresAt!.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '公開期限: $month/$day $hour:$minute まで（以降は自動終了）';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final isRevoked = selectedPreset == ViewerShareExpiryPreset.revoked;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: themeColors.inputBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isRevoked
              ? AppKendoColors.redAccent.withValues(alpha: 0.6)
              : themeColors.separatorColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRevoked ? Icons.block_rounded : Icons.schedule_rounded,
                size: 16,
                color: isRevoked
                    ? AppKendoColors.redAccent
                    : themeColors.primaryAccent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '観戦リンクの有効期限（1大会限定）',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: ViewerShareExpiryPreset.values.map((preset) {
              final selected = preset == selectedPreset;
              final isStop = preset == ViewerShareExpiryPreset.revoked;
              return AppChoiceChip(
                label: Text(preset.label),
                selected: selected,
                selectedColor: isStop
                    ? AppKendoColors.redAccent
                    : AppKendoColors.teal,
                customTextColor: selected ? AppKendoColors.pureWhite : null,
                onSelected: isUpdating
                    ? null
                    : (val) {
                        if (val) onPresetSelected(preset);
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _statusText(),
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: isRevoked
                  ? AppKendoColors.redAccent
                  : themeColors.subTextColor,
              fontWeight: isRevoked
                  ? AppFontWeight.bold
                  : AppFontWeight.regular,
            ),
          ),
        ],
      ),
    );
  }
}
