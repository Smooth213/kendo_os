import 'package:kendo_os/application/projections/match_projection.dart';

class ReplayHashCalculator {
  static String calculate(MatchProjection projection) {
    // 完全に決定論的なハッシュ（文字列の厳密な比較ベース）を生成する
    // 外部パッケージ依存を避けるため、カスタムシリアライズ文字列をそのままハッシュとして扱う
    final rawHash = projection.rebuildHash;
    return rawHash; // 内容が1文字でも違えば一致しないため、ハッシュとして機能する
  }
}