import 'package:flutter/services.dart'; // ★ クリップボード操作用
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

// ★ Phase 3: アプリ全体から呼び出せる共有機能の合鍵
final shareProvider = Provider((ref) => ShareService(ref));

class ShareService {
  final Ref ref;
  ShareService(this.ref);

  /// ★ Phase 5-2: Share UX改善（QR・コピー・再共有の完全一元統一プロトコル）
  /// 操作員がこのメソッドを1回呼び出すだけで、OS標準シェアの起動と同時に、
  /// 1. クリップボードへの即時自動格納
  /// 2. メッセージ内へのQRコード自動生成用URL（Google Chart API連携）の埋め込み
  /// をすべて全自動で同時に執行し、現地共有の手間を完全ゼロ化します。
  Future<void> shareMatch(MatchModel match) async {
    const String baseUrl = 'https://kendo-os.web.app';
    final String matchUrl = '$baseUrl/viewer/${match.id}';

    // クリップボードへ共有URLを先回りして自動強制格納（コピーの手間を破壊）
    await Clipboard.setData(ClipboardData(text: matchUrl));

    // そのままスマホのブラウザで開くだけで即座にQRコードとしてレンダリングされる、高互換URLを自動生成
    final String qrUrl =
        'https://chart.googleapis.com/chart?chs=200x200&cht=qr&chl=${Uri.encodeComponent(matchUrl)}';

    final rScore = match.redScore;
    final wScore = match.whiteScore;
    final rName = _cleanName(match.redName);
    final wName = _cleanName(match.whiteName);

    final isFinished = match.status == 'approved' || match.status == 'finished';
    final String statusText = isFinished ? '【試合結果】' : '【試合速報 (進行中)】';

    final String shareText =
        '''
$statusText
🔴 $rName $rScore - $wScore $wName ⚪️

▼ リアルタイムスコア＆詳細（URLはコピー済です）
$matchUrl

▼ スマホ掲示用・入場QRコードの表示はこちら
$qrUrl
''';

    // ★ 適合修正: プロジェクト固有の型定義（ShareParams）オブジェクトでラップして確実に引き渡します
    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  String _cleanName(String n) {
    if (!n.contains(':')) return n;
    return n.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim();
  }
}
