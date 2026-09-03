import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_preset_helper.dart';

void main() {
  group('MatchFormatPresetHelper テスト', () {
    test('defaultNoteHistory に主要な対戦名プリセットが含まれていること', () {
      expect(
        MatchFormatPresetHelper.defaultNoteHistory,
        containsAll(['1回戦', '2回戦', '準決勝', '決勝']),
      );
    });

    group('togglePreset - プリセットトグル処理', () {
      test('空文字列にプリセットを追加すると、そのプリセットのみが返ること', () {
        expect(MatchFormatPresetHelper.togglePreset('', '第1コート'), '第1コート');
        expect(MatchFormatPresetHelper.togglePreset('   ', '第1コート'), '第1コート');
      });

      test('既存の文字列に別のプリセットを追加すると、カンマ区切りで追記されること', () {
        expect(
          MatchFormatPresetHelper.togglePreset('第1コート', '第2コート'),
          '第1コート, 第2コート',
        );
      });

      test('既に含まれているプリセットを指定すると、削除されること', () {
        expect(
          MatchFormatPresetHelper.togglePreset('第1コート, 第2コート', '第1コート'),
          '第2コート',
        );
        expect(
          MatchFormatPresetHelper.togglePreset('第1コート, 第2コート', '第2コート'),
          '第1コート',
        );
      });

      test('前後のスペースがあっても安全にトリムされて処理されること', () {
        expect(
          MatchFormatPresetHelper.togglePreset(' 第1コート , 第2コート ', ' 第1コート '),
          '第2コート',
        );
      });

      test('空のプリセットが渡された場合は元の文字列がそのまま返ること', () {
        expect(MatchFormatPresetHelper.togglePreset('第1コート', ''), '第1コート');
        expect(MatchFormatPresetHelper.togglePreset('第1コート', '   '), '第1コート');
      });
    });

    group('normalizeCsv - CSV文字列正規化', () {
      test('余計なスペースや空のカンマが綺麗に整形されること', () {
        expect(
          MatchFormatPresetHelper.normalizeCsv(' 第1試合 , , 第2試合 '),
          '第1試合, 第2試合',
        );
      });

      test('空文字列は空文字列を返すこと', () {
        expect(MatchFormatPresetHelper.normalizeCsv(''), '');
        expect(MatchFormatPresetHelper.normalizeCsv('  , , '), '');
      });
    });
  });
}
