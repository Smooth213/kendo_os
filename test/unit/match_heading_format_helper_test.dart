import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';

void main() {
  group('[Unit] MatchHeadingFormatHelper Tests', () {
    test('試合場番号と試合順の抽出ができること', () {
      expect(
        MatchHeadingFormatHelper.extractCourtNumber('第1試合場, 3試合目, 準決勝'),
        1,
      );
      expect(MatchHeadingFormatHelper.extractMatchOrder('第1試合場, 3試合目, 準決勝'), 3);
      expect(MatchHeadingFormatHelper.extractRound('第1試合場, 3試合目, 準決勝'), '準決勝');
    });

    test('updateHeadingで正しく組み立てられること', () {
      final heading = MatchHeadingFormatHelper.updateHeading(
        currentText: '',
        courtNumber: 2,
        matchOrder: 5,
        selectedRound: '決勝',
      );
      expect(heading, '第2試合場, 5試合目, 決勝');
    });

    test('既存のカスタムメモを保持して更新できること', () {
      final heading = MatchHeadingFormatHelper.updateHeading(
        currentText: '第1試合場, 1試合目, 部内戦特例',
        courtNumber: 2,
        matchOrder: 4,
      );
      expect(heading, contains('第2試合場'));
      expect(heading, contains('4試合目'));
      expect(heading, contains('部内戦特例'));
    });

    test('toggleRoundでラウンドがトグル・置換されること', () {
      // 追加
      final h1 = MatchHeadingFormatHelper.toggleRound(
        currentText: '第1試合場, 3試合目',
        roundPreset: '準決勝',
      );
      expect(h1, '第1試合場, 3試合目, 準決勝');

      // 解除
      final h2 = MatchHeadingFormatHelper.toggleRound(
        currentText: h1,
        roundPreset: '準決勝',
      );
      expect(h2, '第1試合場, 3試合目');

      // 別ラウンドへの置換
      final h3 = MatchHeadingFormatHelper.toggleRound(
        currentText: h1,
        roundPreset: '決勝',
      );
      expect(h3, '第1試合場, 3試合目, 決勝');
    });

    test('extractPublicHeadingとextractPrivateNoteで公開見出しと運営メモが正しく分離されること', () {
      const combined = '第1試合場, 3試合目, 準決勝\n相手先鋒上段、主審交代注意';

      expect(
        MatchHeadingFormatHelper.extractPublicHeading(combined),
        '第1試合場, 3試合目, 準決勝',
      );
      expect(
        MatchHeadingFormatHelper.extractPrivateNote(combined),
        '相手先鋒上段、主審交代注意',
      );

      // メモがない場合
      const headingOnly = '第2試合場, 1試合目';
      expect(
        MatchHeadingFormatHelper.extractPublicHeading(headingOnly),
        '第2試合場, 1試合目',
      );
      expect(MatchHeadingFormatHelper.extractPrivateNote(headingOnly), '');
    });
  });
}
