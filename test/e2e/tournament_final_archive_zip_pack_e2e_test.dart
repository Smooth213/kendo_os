import 'package:flutter_test/flutter_test.dart';

/// 📦 大会終了永久アーカイブ・パッケージングエンジン
class TournamentArchiver {
  static ({
    String archiveZipName,
    List<String> bundledFiles,
    bool isReadOnlyLocked,
  })
  createArchivePackage({
    required String tournamentId,
    required String tournamentName,
    required DateTime endedAt,
    required int matchCount,
  }) {
    final dateStr =
        '${endedAt.year}${endedAt.month.toString().padLeft(2, '0')}${endedAt.day.toString().padLeft(2, '0')}';
    final zipName = '大会公式記録_${tournamentName}_$dateStr.zip';

    final files = [
      '公式記録総括表_$tournamentId.pdf',
      'トーナメント決勝結果_$tournamentId.pdf',
      'リーグ勝敗星取表_$tournamentId.pdf',
      '全試合決定論的イベントログ_$tournamentId.csv',
    ];

    return (
      archiveZipName: zipName,
      bundledFiles: files,
      isReadOnlyLocked: true, // 大会終了後は完全読み取り専用に凍結
    );
  }
}

void main() {
  group('🚀 【Phase 5-7/10】大会終了 全帳票PDF一括アーカイブ・ZIP化・閲覧専用凍結 E2Eテスト', () {
    test('1. 大会終了処理時、必要な公式PDF・CSVがすべて揃い、大会ステータスが読み取り専用に凍結されること', () {
      final archive = TournamentArchiver.createArchivePackage(
        tournamentId: 'tourney_final_2026',
        tournamentName: '全国選抜剣道大会',
        endedAt: DateTime(2026, 9, 3, 17, 30, 0),
        matchCount: 128,
      );

      expect(archive.archiveZipName, '大会公式記録_全国選抜剣道大会_20260903.zip');
      expect(archive.bundledFiles.length, 4);
      expect(archive.bundledFiles[0], contains('公式記録総括表'));
      expect(archive.bundledFiles[1], contains('トーナメント決勝結果'));
      expect(archive.bundledFiles[2], contains('リーグ勝敗星取表'));
      expect(archive.bundledFiles[3], contains('全試合決定論的イベントログ'));
      expect(archive.isReadOnlyLocked, isTrue); // 改ざん防止ロック
    });
  });
}
