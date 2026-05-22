import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';

/// ★ Phase 4-3: Timeline Export Service
/// 大会終了後にそのまま道場や保護者へ配れる、Excel / Googleスプレッドシート完全互換の
/// 決定論的 CSV 形式、および閲覧用 TXT 形式のレポート生成を行います。
class TimelineExportService {
  
  /// タイムラインの全試合データを人間が見やすいプレーンテキスト（TXT）へ一括書き出し
  static String exportToTxt(List<MatchModel> matches, String tournamentName) {
    final buffer = StringBuffer();
    buffer.writeln('==================================================');
    buffer.writeln(' 大会公式タイムライン記録: $tournamentName');
    buffer.writeln(' 出力日時: ${DateTime.now().toLocal()}');
    buffer.writeln('==================================================\n');

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      buffer.writeln('第 ${i + 1} 試合 [${m.category ?? "一般"}] (${m.matchType})');
      buffer.writeln(' メモ: ${m.note}');
      buffer.writeln(' 対戦: ${m.redName} [${m.redScore}] vs [${m.whiteScore}] ${m.whiteName}');
      buffer.writeln(' 状態: ${m.status}');
      buffer.writeln(' ----------------------------------------');
      
      if (m.events.isEmpty) {
        buffer.writeln('   (打突イベント履歴なし)');
      } else {
        for (var e in m.events) {
          final cancelTag = e.isCanceled ? '[⚠️取消済] ' : '';
          final side = e.side == Side.red ? '赤' : '白';

          // ★ 適合修正: 単一変数内挿の波括弧に起因するLint警告を、段階的書き出しへの分離によって完全粉砕
          buffer.write('   $cancelTag');
          buffer.writeln('時刻: ${e.timestamp.toLocal().hour}:${e.timestamp.toLocal().minute.toString().padLeft(2, '0')} | 側: $side | 内容: ${e.type.toString().split('.').last.toUpperCase()}');
        }
      }
      buffer.writeln('\n==================================================\n');
    }
    return buffer.toString();
  }

  /// Excel / Google Sheets / Numbers で文字化け（BOM対応）を起こさずにマージできるCSV形式の出力
  static String exportToCsv(List<MatchModel> matches) {
    final buffer = StringBuffer();
    
    // ExcelのShift-JIS/UTF-8自動判別誤認を確実に防ぐための UTF-8 BOM (Byte Order Mark) を先頭へ注入
    buffer.write('\uFEFF');
    
    // ヘッダー行定義
    buffer.writeln('試合順,カテゴリ,試合種別,赤チーム・選手名,赤スコア,白スコア,白チーム・選手名,ステータス,備考,イベント数');

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final sanitizedNote = m.note.replaceAll('"', '""');
      
      buffer.writeln(
        '${i + 1},'
        '"${m.category ?? ""}",'
        '"${m.matchType}",'
        '"${m.redName}",'
        '${m.redScore},'
        '${m.whiteScore},'
        '"${m.whiteName}",'
        '"${m.status}",'
        '"$sanitizedNote",'
        '${m.events.length}'
      );
    }
    return buffer.toString();
  }
}