import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/match_model.dart';

// ★ Phase 3: アプリ全体から呼び出せる共有機能の合鍵
final shareProvider = Provider((ref) => ShareService(ref));

class ShareService {
  final Ref ref;
  ShareService(this.ref);

  // 試合結果（または速報）をテキストとURLでシェアする
  Future<void> shareMatch(MatchModel match) async {
    // ★ 本番環境のホスティングURL（Firebase Hosting等のURLに変更してください）
    const String baseUrl = 'https://kendo-os.web.app'; 
    
    // ロードマップ通り、完全分離されたViewer専用のルーティングを発行
    final String matchUrl = '$baseUrl/viewer/${match.id}';

    final rScore = match.redScore;
    final wScore = match.whiteScore;
    final rName = _cleanName(match.redName);
    final wName = _cleanName(match.whiteName);

    // 試合状況に応じてヘッダーを変更
    final isFinished = match.status == 'approved' || match.status == 'finished';
    final String statusText = isFinished ? '【試合結果】' : '【試合速報 (進行中)】';
    
    // シェアされる美しいテキストテンプレート
    final String shareText = '''
$statusText
🔴 $rName $rScore - $wScore $wName ⚪️

▼ リアルタイムスコア＆詳細はこちらから（ブラウザで開きます）
$matchUrl
''';

    // OS標準のシェアシート（LINE, Twitter, コピーなど）を呼び出す
    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  // 表示用に「道場名：選手名」から選手名だけを綺麗に抜き出すヘルパー
  String _cleanName(String n) {
    if (!n.contains(':')) return n;
    return n.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim();
  }
}