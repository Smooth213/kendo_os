import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_text_parser.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_sheet.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

final clipboardImportServiceProvider = Provider<ClipboardImportService>((ref) {
  return ClipboardImportService();
});

class ClipboardImportService {
  static const String _storageKey = 'kendoos_processed_clipboard_hashes';

  /// テキストのSHA-256ハッシュを算出
  String _computeHash(String text) {
    final bytes = utf8.encode(text.trim());
    return sha256.convert(bytes).toString();
  }

  /// 処理済みハッシュ一覧を取得
  Future<Set<String>> _getProcessedHashes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? [];
    return list.toSet();
  }

  /// ハッシュを処理済みとして保存（直近50件を保持）
  Future<void> markAsProcessed(String text) async {
    final hash = _computeHash(text);
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_storageKey) ?? []).toSet();
    current.add(hash);
    final list = current.toList();
    if (list.length > 50) {
      list.removeRange(0, list.length - 50);
    }
    await prefs.setStringList(_storageKey, list);
  }

  /// クリップボードを非侵入で自動検知し、該当する場合のみ控えめなスナックバーを表示
  Future<void> checkClipboardOnResume(BuildContext context) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;
      if (text == null || text.trim().isEmpty) return;

      // 3重安全フィルター判定（日常文や短文は完全スルー）
      if (!TournamentTextParser.isCandidate(text)) return;

      final hash = _computeHash(text);
      final processed = await _getProcessedHashes();
      if (processed.contains(hash)) {
        // すでに表示済み・処理済みなら二重通知しない
        return;
      }

      // 今回検知したためハッシュを記憶
      await markAsProcessed(text);

      if (!context.mounted) return;

      final parsed = TournamentTextParser.parse(text);
      final name = parsed.tournamentName.isNotEmpty
          ? parsed.tournamentName
          : '大会情報';

      // 控えめなスナックバーで通知（全画面割り込みはゼロ）
      AppSnackBar.showWithAction(
        context,
        '「$name」の大会情報を検出しました',
        icon: Icons.content_paste_go,
        actionLabel: '確認する',
        onAction: () {
          TournamentShareImportSheet.show(context, initialData: parsed);
        },
      );
    } catch (e) {
      debugPrint('クリップボード検知エラー (安全に無視): $e');
    }
  }

  /// ユーザーの手動タップによる取り込み（AppBarボタンなどから起動）
  Future<void> importManually(BuildContext context) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim() ?? '';

      if (text.isEmpty) {
        if (context.mounted) {
          AppSnackBar.show(context, 'クリップボードにテキストがコピーされていません');
        }
        return;
      }

      final parsed = TournamentTextParser.parse(text);

      // 大会名・開催日・会場・チームオーダーのいずれも検出できない場合は通知して中断
      if (!parsed.hasEffectiveContent) {
        if (context.mounted) {
          AppSnackBar.show(context, 'クリップボードに大会情報やオーダーが見つかりませんでした');
        }
        return;
      }

      if (!context.mounted) return;

      TournamentShareImportSheet.show(
        context,
        initialData: parsed,
        rawText: text,
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'クリップボードの読み取りに失敗しました: $e');
      }
    }
  }
}
