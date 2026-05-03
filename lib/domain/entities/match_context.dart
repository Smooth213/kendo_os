// ==========================================
// ★ ⑥ Contextの純化：副作用を持たない純粋なデータ構造
// ルールエンジンが計算した「現在の状況」をUIや保存処理へ伝えるための器です。
// ==========================================

enum MatchResultStatus { inProgress, redWin, whiteWin, draw }

class MatchContext {
  final int redIppon;
  final int whiteIppon;
  final int redHansoku;
  final int whiteHansoku;
  final bool isTimeUp;
  final int targetIppon;
  final bool hasHantei; 

  MatchContext({
    required this.redIppon,
    required this.whiteIppon,
    required this.redHansoku,
    required this.whiteHansoku,
    required this.isTimeUp,
    required this.targetIppon,
    required this.hasHantei,
  });
}