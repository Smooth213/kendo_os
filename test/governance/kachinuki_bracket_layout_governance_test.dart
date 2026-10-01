import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Governance] 勝ち抜き戦ブラケット描画・スリム化レイアウト ガバナンステスト', () {
    test('KachinukiBracketPainter がPDF準拠スリム寸法パラメータを遵守していること', () {
      final file = File(
        'lib/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart',
      );
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();

      // 改定寸法（スリム化）の検証
      expect(content, contains('const double dx = 50.0;'));
      expect(content, contains('const double startX = 70.0;'));
      expect(content, contains('const double y0 = 0.0;'));
      expect(content, contains('const double y1 = 65.0;'));
      expect(content, contains('const double y2 = 155.0;'));
      expect(content, contains('const double y3 = 220.0;'));

      // チーム名が横書きメソッドで描画されていること
      expect(
        content,
        contains('KachinukiDrawingHelper.drawTeamNameHorizontal('),
      );
    });

    test('KachinukiDrawingHelper に横書き2行自動折り返し描画が実装されていること', () {
      final file = File(
        'lib/features/tournament/presentation/components/kachinuki/kachinuki_drawing_helper.dart',
      );
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();

      expect(content, contains('static void drawTeamNameHorizontal('));

      // 生の fontSize 指定（fontSize: 12.0 等）がなく、AppFontSize または変数を使用していること
      final rawFontSizeMatch = RegExp(
        r'fontSize:\s*(?!AppFontSize\.)\d+(\.\d+)?',
      ).allMatches(content);
      expect(
        rawFontSizeMatch,
        isEmpty,
        reason: 'KachinukiDrawingHelper 内に生のフォントサイズ数値指定があってはなりません',
      );
    });

    test('公式記録・観戦用カードのコンテナ高さがスリム化（250px）されていること', () {
      final cardFiles = [
        'lib/features/tournament/presentation/components/official_record/official_record_kachinuki_card.dart',
        'lib/features/viewer/components/viewer_kachinuki_record_card.dart',
        'lib/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_kachinuki_record_card.dart',
      ];

      for (final path in cardFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path が存在しません');
        final content = file.readAsStringSync();
        expect(
          content,
          contains('height: 250,'),
          reason: '$path のブラケットコンテナ高さはスリム化された 250px である必要があります',
        );
      }

      // スコアボード画面の伝統様式タブ高さ
      final scoreboardFile = File(
        'lib/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart',
      );
      expect(scoreboardFile.existsSync(), isTrue);
      expect(scoreboardFile.readAsStringSync(), contains('height: 260,'));
    });
  });
}
