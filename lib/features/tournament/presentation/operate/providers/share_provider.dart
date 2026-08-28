import 'package:flutter/services.dart'; // ★ クリップボード操作用
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

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
    const String baseUrl = 'https://kendo-os-beta.web.app';
    final dojoId = ref.read(currentDojoIdProvider);
    final String matchUrl = '$baseUrl/viewer/${match.id}?dojoId=$dojoId';

    // クリップボードへ共有URLを先回りして自動強制格納（コピーの手間を破壊）
    await Clipboard.setData(ClipboardData(text: matchUrl));

    // そのままスマホのブラウザで開くだけで即座にQRコードとしてレンダリングされる、高互換URLを自動生成
    final String qrUrl =
        'https://chart.googleapis.com/chart?chs=200x200&cht=qr&chl=${Uri.encodeComponent(matchUrl)}';

    final isFinished = match.status == 'approved' || match.status == 'finished';
    final String statusText = isFinished ? '【試合結果】' : '【試合速報 (進行中)】';
    final String scoreDisplayLine = buildMatchScoreDisplay(match);

    final String shareText =
        '''
$statusText
$scoreDisplayLine

▼ リアルタイムスコア＆詳細（URLはコピー済です）
$matchUrl

▼ スマホ掲示用・入場QRコードの表示はこちら
$qrUrl
''';

    // ★ 適合修正: プロジェクト固有の型定義（ShareParams）オブジェクトでラップして確実に引き渡します
    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  /// 剣道のスコア（一本の決まり技、最初の一本は丸囲みなど）を表現したテキスト行を構築する
  String buildMatchScoreDisplay(MatchModel match) {
    // 1. アクティブなイベントを抽出（取り消されたものを正確に除外）
    final activeEvents = <ScoreEvent>[];
    final undoneIds = <String>{};
    for (var e in match.events.reversed) {
      if (e.isCanceled) continue;
      if (e.isUndo) {
        if (e.targetId.isNotEmpty) {
          undoneIds.add(e.targetId);
        }
        continue;
      }
      if (undoneIds.contains(e.id)) {
        undoneIds.remove(e.id);
        continue;
      }
      activeEvents.insert(0, e);
    }

    // 2. 打突・反則による一本のマークを時系列で処理
    final redMarks = <String>[];
    final whiteMarks = <String>[];
    bool isFirstPointOfMatch = true;

    int rHansokuCount = 0;
    int wHansokuCount = 0;

    for (var e in activeEvents) {
      if (e.isHansoku) {
        if (e.side == Side.red) {
          rHansokuCount++;
          if (rHansokuCount % 2 == 0) {
            whiteMarks.add('反');
            isFirstPointOfMatch = false;
          }
        } else if (e.side == Side.white) {
          wHansokuCount++;
          if (wHansokuCount % 2 == 0) {
            redMarks.add('反');
            isFirstPointOfMatch = false;
          }
        }
      } else if (e.isFusen) {
        if (e.side == Side.red) {
          redMarks.add('◯');
          redMarks.add('◯');
        } else if (e.side == Side.white) {
          whiteMarks.add('◯');
          whiteMarks.add('◯');
        }
        isFirstPointOfMatch = false;
      } else if (e.isIppon) {
        String? mark;
        switch (e.strikeType) {
          case StrikeType.men:
            mark = isFirstPointOfMatch ? '㋱' : 'メ';
            break;
          case StrikeType.kote:
            mark = isFirstPointOfMatch ? '㋙' : 'コ';
            break;
          case StrikeType.dou:
            mark = isFirstPointOfMatch ? '㋣' : 'ド';
            break;
          case StrikeType.tsuki:
            mark = isFirstPointOfMatch ? '㋡' : 'ツ';
            break;
          default:
            if (e.isHantei) {
              mark = '判定';
            }
            break;
        }

        if (mark != null) {
          if (e.side == Side.red) {
            redMarks.add(mark);
          } else if (e.side == Side.white) {
            whiteMarks.add(mark);
          }
          isFirstPointOfMatch = false;
        }
      }
    }

    final rName = _cleanName(match.redName);
    final wName = _cleanName(match.whiteName);

    final rScoreStr = match.redScore.toString() + redMarks.join('');
    final wScoreStr = match.whiteScore.toString() + whiteMarks.join('');

    return '🔴 $rName $rScoreStr - $wScoreStr $wName ⚪️';
  }

  String _cleanName(String n) {
    if (!n.contains(':')) return n;
    return n.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim();
  }
}
