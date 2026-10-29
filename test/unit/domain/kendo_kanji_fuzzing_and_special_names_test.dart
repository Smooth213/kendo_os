import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';

void main() {
  group('[Unit] 剣道旧字体・異体字・サロゲートペア・特殊文字ファジング耐性テスト', () {
    test('旧字体（髙・邊・齋・黑・塚・澁）、アクセント、絵文字、長文氏名が破損せず完全保持されること', () {
      final specialNames = [
        '髙橋 邊見',
        '齋藤 黑田',
        '塚本 澁谷',
        'José Müller 🥋',
        '超絶に長くて三十文字以上ある特異な登録選手名株式会社剣道道場連盟所属の剣士氏名',
      ];

      for (int i = 0; i < specialNames.length; i++) {
        final name = specialNames[i];
        final match = MatchModel(
          id: 'fuzzy_match_$i',
          matchType: '個人戦',
          redName: name,
          whiteName: '通常 選手',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          note: '旧字体テスト: $name',
        );

        // JSONシリアライズ/デシリアライズの可逆性
        final json = match.toJson();
        final recovered = MatchModel.fromJson(json);
        expect(recovered.redName, name);
        expect(recovered.note, contains(name));

        // CSV生成の安全性（文字化け・例外ゼロ）
        final csv = CsvService.generateCsvString('一般の部', [
          {
            'groupName': '決勝',
            'matches': [match],
          },
        ]);
        expect(csv.startsWith('\uFEFF'), isTrue);
        expect(csv.contains(name.replaceAll('\n', ' ')), isTrue);

        // UTF-8バイト変換安全性
        final bytes = utf8.encode(csv);
        final decoded = utf8.decode(bytes);
        expect(decoded, contains(name.replaceAll('\n', ' ')));
      }
    });
  });
}
