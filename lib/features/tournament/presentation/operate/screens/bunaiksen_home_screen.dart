import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import '../providers/match_list_provider.dart';
import 'package:kendo_os/shared/widgets/infinite_streak_leaderboard.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
// ★ Phase 8: 削除機能と権限管理用プロバイダを追加
import '../providers/match_command_provider.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../components/bulk_rule_edit_sheet.dart';

import 'package:uuid/uuid.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

class BunaiksenHomeScreen extends ConsumerWidget {
  const BunaiksenHomeScreen({super.key});

  // ★ 究極版：記号化しつつ、区切り文字を「中央揃えのアイコン」で美しく表示するWidgetエンジン
  Widget _buildScoreMarks(
    MatchModel match,
    bool isDark, {
    bool isFinished = true,
  }) {
    final textColor = isFinished
        ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
        : (isDark ? Colors.white : Colors.black87);
    // 区切り文字を少しグレーにして、スコア本体(メやコ)と明確に区別する
    final iconColor = isFinished
        ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    // 完全無得点の引き分け
    if (match.redScore == 0 && match.whiteScore == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Icon(Icons.close, size: 18, color: iconColor), // 完璧な中央揃えの「✕」アイコン
      );
    }

    // ★ 修正: KendoRuleEngine を使用し、Undoされたイベントを除外した正確な結果を使用
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(match.events, match, match.rule);

    final rDisplays = analysis.displays[Side.red] ?? [];
    final wDisplays = analysis.displays[Side.white] ?? [];

    // 表示用のマークを抽出して、1本目なら丸囲み文字に変換
    String rMarksStr = rDisplays
        .map((d) {
          if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
          if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
          if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
          if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
          if (d.mark == '反') return '反';
          if (d.mark == '判定') return '判';
          if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
          return d.mark;
        })
        .join('');

    String wMarksStr = wDisplays
        .map((d) {
          if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
          if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
          if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
          if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
          if (d.mark == '反') return '反';
          if (d.mark == '判定') return '判';
          if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
          return d.mark;
        })
        .join('');

    final bool isDraw = match.redScore == match.whiteScore;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // ここで完璧な垂直中央揃えを実現
      children: [
        Text(
          rMarksStr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          // 引き分けなら「✕（close）」、勝敗がついていれば「-（remove）」のアイコンを表示
          child: Icon(
            isDraw ? Icons.close : Icons.remove,
            size: 16,
            color: iconColor,
          ),
        ),
        Text(
          wMarksStr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;

    // ★ 修正：今日ではなく「選択された日付」を基準にする
    final viewDate = ref.watch(bunaiksenViewDateProvider);
    final dateId = 'bunaiksen_${DateFormat('yyyyMMdd').format(viewDate)}';
    final dateDisplay = DateFormat('yyyy/MM/dd').format(viewDate);
    final isToday =
        DateFormat('yyyyMMdd').format(viewDate) ==
        DateFormat('yyyyMMdd').format(DateTime.now());

    final availableDates =
        ref.watch(bunaiksenAvailableDatesProvider).value ?? const <String>{};

    // 選択された日の部内戦のみ表示
    final matches = ref.watch(bunaiksenMatchesProvider(dateId));

    // 🌟 本部一斉ポップアップ監視トリガーをアタッチ（運営スタッフ用フラグ: true）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        listenGlobalAnnouncements(context, ref, dateId, isStaffRoom: true);
      }
    });

    // 無限勝ち抜きモード of 試合が存在するかどうか
    final hasInfiniteKachinuki = matches.any(
      (m) => m.isKachinuki && m.matchType == '無限勝ち抜き',
    );

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: enableLiquidGlass
              ? Colors.transparent
              : themeColors.cardBackground,
          foregroundColor: isDark ? Colors.white : themeColors.primaryAccent,
          // ★ 修正：タイトルはシンプルにテキストのみ表示
          title: Text(
            isToday ? '今日の部内戦' : '$dateDisplay の記録',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: themeColors.textColor,
            ),
          ),
          elevation: 0,
          centerTitle: true,
          actions: [
            // ★ 新設：カレンダーボタン（ここをタップで過去の日付へ）
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: '日付を選択して過去の記録を見る',
              onPressed: () async {
                // 🛡️ クラッシュ防止仕様：初期表示日(initialDate)は必ず選択可能(selectableDayPredicateがtrueを返す)でなければならない。
                // 選択された日付(viewDate)が、今日の道場IDにおける「試合がある日」または「今日」に含まれていない場合、
                // アサーションエラーを回避するために DateTime.now() にフォールバックする。
                final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
                final viewDateStr = DateFormat('yyyyMMdd').format(viewDate);
                final bool isViewDateSelectable =
                    viewDateStr == todayStr ||
                    availableDates.contains(viewDateStr);
                final safeInitialDate = isViewDateSelectable
                    ? viewDate
                    : DateTime.now();

                final picked = await showDatePicker(
                  context: context,
                  initialDate: safeInitialDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  selectableDayPredicate: (DateTime date) {
                    // 🍏 厳密なるカレンダー制限仕様の完成：全 OS 全期間にわたり、試合のあった日だけを美しく点灯させます
                    final dStr = DateFormat('yyyyMMdd').format(date);
                    final tStr = DateFormat('yyyyMMdd').format(DateTime.now());

                    return dStr == tStr || availableDates.contains(dStr);
                  },
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: isDark
                            ? ColorScheme.dark(
                                primary: themeColors.primaryAccent,
                                onPrimary: Colors.white,
                                surface: themeColors.cardBackground,
                                onSurface: Colors.white,
                              )
                            : ColorScheme.light(
                                primary: themeColors.primaryAccent,
                                onPrimary: Colors.white,
                                surface: themeColors.cardBackground,
                                onSurface: Colors.black87,
                              ),
                        dialogTheme: DialogThemeData(
                          backgroundColor: themeColors.cardBackground,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  ref.read(bunaiksenViewDateProvider.notifier).state = picked;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: '観客席プレビュー',
              onPressed: () {
                ref.read(bunaiksenViewDateProvider.notifier).state = viewDate;
                final dojoId = ref.read(currentDojoIdProvider);
                context.push(
                  '/bunaiksen-viewer-home/$dateId?role=viewer&dojoId=$dojoId&tournamentId=$dateId',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: '観戦リンクを共有する',
              onPressed: () =>
                  _showShareDialog(context, ref, dateId, dateDisplay),
            ),
            IconButton(
              // ★ 修正：チェックマークから、成績や順位表を表す「リーダーボード」のアイコンに変更
              icon: const Icon(Icons.leaderboard_outlined),
              onPressed: () => context.push('/bunaiksen-record'),
              tooltip: '成績一覧',
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/'),
          ),
        ),
        body: matches.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isToday ? '今日の試合はまだありません' : 'この日の記録はありません',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () =>
                            _showQuickMatchSheet(context, ref, dateId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColors.primaryAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'クイック対戦を始める',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  if (hasInfiniteKachinuki) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      color: Colors.deepOrange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '無限勝ち抜き 連勝ランキング',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                const InfiniteStreakLeaderboard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      color: themeColors.softAccent, // ★ 修正
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '本日の試合一覧',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeColors.primaryAccent,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    _showQuickMatchSheet(context, ref, dateId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColors.primaryAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'クイック対戦',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              if (matches.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                OutlinedButton.icon(
                                  onPressed: () => showBulkRuleEditSheet(
                                    context,
                                    dateId,
                                    matches,
                                    isBunaiksen: true,
                                  ),
                                  icon: Icon(
                                    Icons.gavel,
                                    size: 14,
                                    color: themeColors.primaryAccent,
                                  ),
                                  label: Text(
                                    'ルール一括変更',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: themeColors.primaryAccent,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: themeColors.primaryAccent,
                                    side: BorderSide(
                                      color: themeColors.primaryAccent
                                          .withValues(alpha: 0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final match = matches[index];
                      final hasScore =
                          match.redScore > 0 ||
                          match.whiteScore > 0 ||
                          match.events.isNotEmpty;
                      final isPlaying = match.status == 'in_progress';
                      final isFinished =
                          (match.status == 'finished' ||
                              match.status == 'approved' ||
                              hasScore) &&
                          !isPlaying;

                      final Color bg = isFinished
                          ? (isDark
                                ? const Color(0xFF161618)
                                : Colors.grey.shade50)
                          : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
                      final Color textC = isFinished
                          ? (isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade500)
                          : (isDark ? Colors.white : Colors.black87);
                      final Color noteC = isFinished
                          ? (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade500)
                          : Colors.grey;

                      // ★ 修正：一体化のため、外側のPaddingでリストの余白を管理
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        child: Slidable(
                          key: ValueKey(match.id),
                          endActionPane: ActionPane(
                            // ★ 修正：選手マスタ画面と完全に同じ滑らかな物理エンジン（ScrollMotion）に統一
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) =>
                                    _showEditNoteDialog(context, ref, match),
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: '編集',
                              ),
                              SlidableAction(
                                onPressed: (context) =>
                                    _confirmDeleteMatch(context, ref, match.id),
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: '削除',
                                // ★ 修正：カードの角丸と完全に一致させる
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(16),
                                ),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            margin: EdgeInsets.zero, // ★ 重要：ここをゼロにすることで隙間を消す
                            color: bg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final dojoId = ref.read(currentDojoIdProvider);
                                context.push(
                                  '/match/${match.id}?tournamentId=$dateId&dojoId=$dojoId',
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            match.note.isNotEmpty
                                                ? match.note
                                                : '部内稽古',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: noteC,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPlaying
                                                ? Colors.blue.shade600
                                                : (isFinished
                                                      ? (isDark
                                                            ? Colors
                                                                  .grey
                                                                  .shade800
                                                            : Colors
                                                                  .grey
                                                                  .shade300)
                                                      : (isDark
                                                            ? const Color(
                                                                0xFF2C2C2E,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade200)),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isPlaying
                                                ? '進行中'
                                                : (isFinished ? '終了' : '待機中'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isPlaying
                                                  ? Colors.white
                                                  : (isFinished
                                                        ? (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade600)
                                                        : (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade700)),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '第${index + 1}試合',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: noteC,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            match.redName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textC,
                                            ),
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: isFinished
                                              ? _buildScoreMarks(
                                                  match,
                                                  isDark,
                                                  isFinished: isFinished,
                                                )
                                              : Text(
                                                  'VS',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: textC,
                                                  ),
                                                ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            match.whiteName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textC,
                                            ),
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: matches.length),
                  ),
                ],
              ),
        floatingActionButton: isToday
            ? FloatingActionButton.extended(
                backgroundColor: themeColors.primaryAccent, // ★ 修正
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text(
                  '試合作成',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.push('/bunaiksen-setup'),
              )
            : null, // ★ 今日以外を表示している時は作成ボタンを出さない
      ),
    );
  }

  void _confirmDeleteMatch(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('試合の削除'),
        content: const Text('この試合データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(matchCommandProvider).deleteMatch(matchId);
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
  ) {
    final controller = TextEditingController(text: match.note);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        title: Text(
          '試合詳細（コメント）の編集',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeColors.textColor,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: themeColors.textColor),
          decoration: InputDecoration(
            hintText: '試合に関するメモや詳細を入力',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: themeColors.primaryAccent),
            ),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNote = controller.text.trim();
              if (newNote != match.note) {
                final updatedMatch = match.copyWith(note: newNote);
                await ref.read(matchApplicationServiceProvider).saveMatchesBulk(
                  [updatedMatch],
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors.primaryAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '保存',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
    String dateDisplay,
  ) {
    final dojoId = ref.read(currentDojoIdProvider);
    // 🛡️ ドメイン同期パッチ：部内戦の管理ホーム（BunaiksenHomeScreen）側QR共有リンクも、確実に本物のベータ環境（kendo-os-beta.web.app）を指すように修正
    final String shareUrl =
        'https://kendo-os-beta.web.app/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$dojoId';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '$dateDisplay 観戦リンク',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'この部内戦の全試合・スコアを\n観客用に安全に共有できます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: QrImageView(
                  data: shareUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                // ★ Phase 9最適化: 名称から「AI/OS」を排し、現場に寄り添った文言へブラッシュアップ
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
                        'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
                        'リンク: $shareUrl',
                  ),
                ),
                icon: const Icon(Icons.share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showQuickMatchSheet(
    BuildContext context,
    WidgetRef ref,
    String dateId,
  ) {
    String redPlayer = '選手A';
    String whitePlayer = '選手B';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setStateSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'クイック対戦',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColors.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '赤・白の選手を選択して「試合スタート」を押すとすぐに計測が始まります',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // 赤選手
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.shade400.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '赤',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await _selectSinglePlayerSheet(
                                context,
                                ref,
                                '赤',
                                Colors.red.shade700,
                              );
                              if (picked != null) {
                                setStateSheet(() => redPlayer = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade300.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      redPlayer,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeColors.textColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.red.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // 白選手
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.blueGrey.shade400
                              : Colors.blueGrey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '白',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.blueGrey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await _selectSinglePlayerSheet(
                                context,
                                ref,
                                '白',
                                isDark
                                    ? Colors.blueGrey.shade300
                                    : Colors.blueGrey.shade700,
                              );
                              if (picked != null) {
                                setStateSheet(() => whitePlayer = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.blueGrey.shade600
                                      : Colors.blueGrey.shade300.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      whitePlayer,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeColors.textColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.blueGrey.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final dojoId = ref.read(currentDojoIdProvider);
                    final rule = ref.read(bunaiksenRuleProvider);
                    final matchId = const Uuid().v4();

                    final newMatch = MatchModel(
                      id: matchId,
                      tournamentId: dateId,
                      groupName: const Uuid().v4(),
                      matchType: '個人戦',
                      redName: redPlayer,
                      whiteName: whitePlayer,
                      matchTimeMinutes: rule.matchTimeMinutes,
                      hasExtension:
                          rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited,
                      extensionTimeMinutes: rule.enchoTimeMinutes,
                      status: 'in_progress',
                      order: DateTime.now().millisecondsSinceEpoch.toDouble(),
                      rule: rule,
                      note: 'クイック対戦',
                    );

                    await ref
                        .read(matchApplicationServiceProvider)
                        .saveMatch(newMatch);

                    if (context.mounted) {
                      context.push(
                        '/match/${newMatch.id}?tournamentId=$dateId&dojoId=$dojoId',
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text(
                    '試合スタート',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _selectSinglePlayerSheet(
    BuildContext context,
    WidgetRef ref,
    String sideName,
    Color accentColor,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = ref.read(playerRepositoryProvider);
    final masterPlayers = await repo.getPlayers().first;

    if (!context.mounted) return null;

    String searchText = '';
    String selectedFilter = 'すべて';

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = masterPlayers.where((p) {
              final matchSearch =
                  searchText.isEmpty ||
                  p.name.contains(searchText) ||
                  p.nameKana.contains(searchText);
              final matchFilter =
                  selectedFilter == 'すべて' || p.gradeName == selectedFilter;
              return matchSearch && matchFilter;
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person_search, color: accentColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '$sideNameの選手を選択',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 検索窓・自由テキスト入力
                  TextField(
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: '名前を入力または名簿から1タップ選択',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () => Navigator.pop(ctx, searchText),
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) => setModalState(() => searchText = val),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        Navigator.pop(ctx, val.trim());
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  // カテゴリフィルター
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
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
                          ].map((filterName) {
                            final isSel = selectedFilter == filterName;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Text(filterName),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSel
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                ),
                                selected: isSel,
                                selectedColor: accentColor,
                                backgroundColor: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : Colors.grey.shade200,
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(
                                      () => selectedFilter = filterName,
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 名簿リスト (ワンタップ決定)
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              searchText.isNotEmpty
                                  ? '「$searchText」をタップして決定できます'
                                  : '該当する選手がいません',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (itemCtx, index) {
                              final p = filtered[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : Colors.grey.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: accentColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: Text(
                                      p.name.isNotEmpty
                                          ? p.name.substring(0, 1)
                                          : '?',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    p.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    p.gradeName,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.touch_app,
                                    color: accentColor,
                                  ),
                                  onTap: () => Navigator.pop(ctx, p.name),
                                ),
                              );
                            },
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
}
