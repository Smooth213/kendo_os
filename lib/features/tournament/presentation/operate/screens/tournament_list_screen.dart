import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import '../providers/sync_provider.dart';
import '../providers/tournament_list_provider.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart'; // ファイル上部
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';

import 'package:kendo_os/features/tournament/application/clipboard_import_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/clipboard_import_button.dart';

// ★ アーカイブ画面の即時反映用トリガー（下位互換性維持）
final archiveRefreshProvider = StateProvider.autoDispose<int>((ref) => 0);

class TournamentListScreen extends ConsumerStatefulWidget {
  final bool isArchive;
  const TournamentListScreen({super.key, this.isArchive = false});

  @override
  ConsumerState<TournamentListScreen> createState() =>
      _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.isArchive) {
        ref
            .read(clipboardImportServiceProvider)
            .checkClipboardOnResume(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !widget.isArchive) {
      ref.read(clipboardImportServiceProvider).checkClipboardOnResume(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArchive = widget.isArchive;
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
    final Color textColor = themeColors.textColor;
    final Color subTextColor = themeColors.subTextColor;

    final tournamentAsync = widget.isArchive
        ? ref.watch(archivedTournamentListProvider)
        : ref.watch(tournamentListProvider);

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: accentColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: widget.isArchive ? '過去の大会 (アーカイブ)' : '最近の大会',
          backgroundColor: enableLiquidGlass
              ? AppKendoColors.transparent
              : themeColors.cardBackground,
          actions: [
            if (!widget.isArchive && !isReadOnly) const ClipboardImportButton(),
            const ManualHelpButton(manualPath: 'docs/manuals/manual_index.md'),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: tournamentAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoadingIndicator(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.isArchive ? '過去の大会記録を読み込んでいます...' : '大会一覧を読み込んでいます...',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'クラウドから最新のデータを取得中',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
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
                    '大会一覧の取得に失敗しました',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.body,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'エラーが発生しました。通信状況をご確認のうえ、再読み込みをお試しください\n($error)',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: AppFontSize.small,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.isArchive) {
                        ref.invalidate(archivedTournamentListProvider);
                      } else {
                        ref.invalidate(tournamentListProvider);
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          ),
          data: (tournaments) {
            final filteredTournaments = [...tournaments];
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
                          : const Color(0x33000000),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isArchive ? '過去の大会記録はありません' : '今日の大会はまだありません',
                      style: TextStyle(
                        fontSize: AppFontSize.headline,
                        fontWeight: AppFontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isArchive
                          ? '終了した大会がここにアーカイブされます。'
                          : '新しい大会を作成して、本日の運営をスタートしましょう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: AppFontSize.body,
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
                if (isArchive) {
                  ref.invalidate(archivedTournamentListProvider);
                  await ref.read(archivedTournamentListProvider.future);
                } else {
                  await ref.read(syncEngineProvider).forceSync();
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
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
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      borderRadius: AppSemanticTokens.cardRadius,
                      borderWidth: AppSemanticTokens.cardBorderWidth,
                      onTap: () {
                        if (isReadOnly) {
                          context.push('/viewer-home/$id');
                        } else {
                          context.push('/home/$id');
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: softAccentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isArchive ? Icons.history : Icons.emoji_events,
                              color: accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tournament.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: AppFontWeight.semiBold,
                                        color: textColor,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
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
                    );
                  }

                  // ★ 修正：月別ヘッダーが背景に溶けないよう、アクセントカラーを適用
                  Widget header = const SizedBox.shrink();
                  if (showHeader) {
                    header = Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.xl,
                        bottom: AppSpacing.md,
                        left: AppSpacing.xs,
                      ),
                      child: Text(
                        currentMonth,
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: isDark
                              ? accentColor
                              : AppKendoColors
                                    .grey
                                    .shade500, // ★ ダーク時はアイコンと同じ色で光らせる
                          letterSpacing: 1.5,
                        ),
                      ),
                    );
                  }

                  // ⚡ 【Plan 1-3】RepaintBoundaryによるリストアイテム描画カリング＆GPU再ラスタライズ防止
                  return RepaintBoundary(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [header, buildUnifiedCard()],
                    ),
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
