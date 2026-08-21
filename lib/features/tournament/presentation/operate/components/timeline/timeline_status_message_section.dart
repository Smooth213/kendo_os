import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// タイムライン画面の状態メッセージ（エラー・検索0件・試合未登録・ローディング）
class TimelineStatusMessageSection extends StatelessWidget {
  final SafeTimelineResult timelineResult;
  final String sanitizedQuery;
  final bool isDark;

  const TimelineStatusMessageSection({
    super.key,
    required this.timelineResult,
    required this.sanitizedQuery,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (timelineResult.hasError) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppKendoColors.red,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'データの取得に失敗しました',
                style: TextStyle(
                  color: isDark ? const Color(0xFFE53935) : AppKendoColors.red,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                timelineResult.errorMessage ?? '通信状況を確認してください',
                style: const TextStyle(
                  color: AppKendoColors.grey,
                  fontSize: AppFontSize.small,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (timelineResult.entries.isEmpty && sanitizedQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: const Center(
          child: Text(
            '該当する試合が見つかりません',
            style: TextStyle(color: AppKendoColors.grey),
          ),
        ),
      );
    }

    if (timelineResult.entries.isEmpty &&
        !timelineResult.isLoading &&
        sanitizedQuery.isEmpty &&
        !timelineResult.hasError) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.giant),
        child: Center(
          child: Text(
            'まだ試合がありません\n（またはクラウド同期待ちです）',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
              fontWeight: AppFontWeight.bold,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    if (timelineResult.entries.isEmpty && timelineResult.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return const SizedBox.shrink();
  }
}
