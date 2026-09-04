import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart'; // 姓名分割用
import 'package:kendo_os/shared/utils/kendo_compute_helper.dart';

/// 🧵 【Phase 4】Isolate内で実行される重いCSV生成・バイナリエンコード処理
Uint8List _encodeCsvToBytes((String, List<Map<String, dynamic>>) input) {
  final csvString = CsvService.generateCsvString(input.$1, input.$2);
  return Uint8List.fromList(utf8.encode(csvString));
}

class CsvService {
  /// 大会結果をCSVとして生成する
  static String generateCsvString(
    String categoryName,
    List<Map<String, dynamic>> groupDataList,
  ) {
    StringBuffer buffer = StringBuffer();

    // 1. ヘッダー行の作成（BOM付きUTF-8でExcel文字化けを防ぐ）
    buffer.write('\uFEFF');
    buffer.writeln('カテゴリ,グループ名,試合順,赤チーム,赤選手,白チーム,白選手,赤スコア,白スコア,勝敗,備考');

    // 2. データの流し込み
    for (final group in groupDataList) {
      final String groupName = group['groupName'] as String;
      final List<MatchModel> matches = group['matches'] as List<MatchModel>;

      for (final m in matches) {
        final redInfo = BunaiksenHelper.parseName(m.redName);
        final whiteInfo = BunaiksenHelper.parseName(m.whiteName);

        final redTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : '';
        final whiteTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : '';

        // 勝敗の判定
        String result = '引き分け';
        if (m.redScore > m.whiteScore) result = '赤勝ち';
        if (m.whiteScore > m.redScore) result = '白勝ち';

        // CSV一行分を書き込み（カンマや改行の混入を防ぐためクォート囲み）
        buffer.writeln(
          [
            categoryName,
            groupName,
            m.order.toString(),
            redTeam,
            redInfo['last'] ?? '',
            whiteTeam,
            whiteInfo['last'] ?? '',
            m.redScore.toString(),
            m.whiteScore.toString(),
            result,
            m.note.replaceAll('\n', ' '),
          ].map((e) => '"$e"').join(','),
        );
      }
    }
    return buffer.toString();
  }

  /// 🧵 【Phase 4】重計算Isolate分離: 大量試合データのCSV生成とUTF-8変換を別スレッドで実行
  static Future<Uint8List> generateCsvBytesAsync(
    String categoryName,
    List<Map<String, dynamic>> groupDataList,
  ) async {
    return KendoComputeHelper.run(_encodeCsvToBytes, (
      categoryName,
      groupDataList,
    ));
  }

  // シェア処理は Isolate非同期で生成したバイナリを直接使用
  static Future<void> shareOfficialRecordAsCsv(
    String categoryName,
    List<Map<String, dynamic>> groupDataList,
  ) async {
    final bytes = await generateCsvBytesAsync(categoryName, groupDataList);
    final fileName =
        '公式記録_${categoryName}_${DateTime.now().millisecondsSinceEpoch}.csv';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
        text: '【$categoryName】の公式記録データ（CSV）を共有します。',
      ),
    );
  }
}
