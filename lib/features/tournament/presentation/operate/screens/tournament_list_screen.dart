import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import '../providers/sync_provider.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart'; // ファイル上部
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'dart:ui';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

// ★ 直感UXホットフィックス：アーカイブ画面の即時反映用トリガー
final archiveRefreshProvider = StateProvider.autoDispose<int>((ref) => 0);

class TournamentListScreen extends ConsumerWidget {
  final bool isArchive;
  const TournamentListScreen({super.key, this.isArchive = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isArchive) {
      ref.watch(archiveRefreshProvider);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );
    final permissions = ref.watch(permissionProvider);
    final isReadOnly = permissions.isReadOnly;

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final Color accentColor = themeColors.primaryAccent;
    final Color softAccentColor = themeColors.softAccent;
    final Color cardColor = themeColors.cardBackground;
    final Color textColor = themeColors.textColor;
    final Color subTextColor = themeColors.subTextColor;
    final Color separatorColor = themeColors.separatorColor;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppHeader(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: accentColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: isArchive ? '過去の大会 (アーカイブ)' : '最近の大会',
          backgroundColor: enableLiquidGlass ? Colors.transparent : cardColor,
          actions: const [
            ManualHelpButton(manualPath: 'docs/manuals/manual_index.md'),
            SizedBox(width: 8),
          ],
        ),
        body: StreamBuilder<List<TournamentModel>>(
          stream: isArchive
              ? Stream.fromFuture(
                  ref
                      .read(tournamentRepositoryProvider)
                      .getArchivedTournaments(),
                )
              : ref.watch(tournamentRepositoryProvider).watchTournaments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
            }

            final filteredTournaments = snapshot.data ?? [];
            filteredTournaments.sort((a, b) => b.date.compareTo(a.date));

            // ★ 直感UX改修：透かしアイコン（kendo_icon.png）を用いた極上のEmpty State
            if (filteredTournaments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/kendo_icon.png',
                      width: 80,
                      height: 80,
                      color: isDark
                          ? const Color(0xFF38383A)
                          : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isArchive ? '過去の大会記録はありません' : '今日の大会はまだありません',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArchive
                          ? '終了した大会がここにアーカイブされます。'
                          : '新しい大会を作成して、本日の運営をスタートしましょう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ★ Phase 6: 手動同期トリガー（引っ張って更新）の追加
            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(syncEngineProvider).forceSync();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ), // 余白の統一
                // ★ 最適化: 3画面分先読みキャッシュでスクロール時のレイアウト計算コストを削減
                // ignore: deprecated_member_use
                cacheExtent: 1500.0,
                itemCount: filteredTournaments.length,
                itemBuilder: (context, index) {
                  final tournament = filteredTournaments[index];
                  final id = tournament.id;

                  final currentMonth = DateFormat(
                    'yyyy年MM月',
                  ).format(tournament.date);
                  final previousMonth = index == 0
                      ? ''
                      : DateFormat(
                          'yyyy年MM月',
                        ).format(filteredTournaments[index - 1].date);
                  final showHeader = currentMonth != previousMonth;

                  Widget buildUnifiedCard() {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final Color effectiveCardColor = enableLiquidGlass
                        ? cardColor.withValues(alpha: isDark ? 0.35 : 0.65)
                        : cardColor;

                    final ShapeBorder cardShape = RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: enableLiquidGlass
                          ? BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.5,
                            )
                          : (isDark
                                ? BorderSide.none
                                : BorderSide(
                                    color: separatorColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 0.5,
                                  )),
                    );

                    final cardChild = Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: effectiveCardColor,
                      shape: cardShape,
                      child: InkWell(
                        onTap: () {
                          if (isReadOnly) {
                            context.push('/viewer-home/$id');
                          } else {
                            context.push('/home/$id');
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: softAccentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isArchive
                                      ? Icons.history
                                      : Icons.emoji_events,
                                  color: accentColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tournament.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          DateFormat(
                                            'yyyy年MM月dd日',
                                          ).format(tournament.date),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: subTextColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: subTextColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (enableLiquidGlass) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                          child: cardChild,
                        ),
                      );
                    }
                    return cardChild;
                  }

                  // ★ 修正：月別ヘッダーが背景に溶けないよう、アクセントカラーを適用
                  Widget header = const SizedBox.shrink();
                  if (showHeader) {
                    header = Padding(
                      padding: const EdgeInsets.only(
                        top: 24,
                        bottom: 12,
                        left: 4,
                      ),
                      child: Text(
                        currentMonth,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? accentColor
                              : Colors.grey.shade500, // ★ ダーク時はアイコンと同じ色で光らせる
                          letterSpacing: 1.5,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [header, buildUnifiedCard()],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
