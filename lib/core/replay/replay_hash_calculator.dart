import 'package:kendo_os/application/projections/match_projection.dart';

class ReplayHashCalculator {
  /// ★ Phase 2-2: Replay Hashの完全決定論的固定
  /// 実行端末の環境情報（deviceInfo, locale, memoryAddress）に一切左右されず、
  /// 試合の純粋なコア要素（イベントの型、本数、順序、時刻）のみから一意の指紋（ハッシュ）を生成します。
  static String calculate(MatchProjection projection) {
    final buffer = StringBuffer();
    
    // ハッシュの種に含める決定論的コアメタデータ
    buffer.write('matchId:${projection.matchId};');
    buffer.write('status:${projection.statusText};');
    buffer.write('lastEvent:${projection.lastEventText};');
    
    // projectionが持つクリーンシリアライズ文字列（環境依存アセットを排除した歴史の種）を結合
    buffer.write('history:${projection.rebuildHash};');
    
    return buffer.toString(); // 内容が1文字でも違えば一致しないため、厳格な歴史指紋として完全に機能します
  }
}