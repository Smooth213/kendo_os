import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_bottom_action_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

void main() {
  group('MatchBottomActionHelper テスト', () {
    group('getConfirmButtonLabel', () {
      test('引き分けかつ真の団体戦の場合、「記録確定・星取表へ」を返すこと', () {
        final label = MatchBottomActionHelper.getConfirmButtonLabel(
          isTie: true,
          isTrulyTeamMatch: true,
          isAllDone: false,
          tournamentId: 't1',
        );
        expect(label, '記録確定・星取表へ');
      });

      test('全試合完了時、部内戦の場合は「確定・部内戦ホームへ」を返すこと', () {
        final label = MatchBottomActionHelper.getConfirmButtonLabel(
          isTie: false,
          isTrulyTeamMatch: false,
          isAllDone: true,
          tournamentId: 'bunaiksen_123',
        );
        expect(label, '確定・部内戦ホームへ');
      });

      test('全試合完了時、通常大会の場合は「確定・大会ホームへ」を返すこと', () {
        final label = MatchBottomActionHelper.getConfirmButtonLabel(
          isTie: false,
          isTrulyTeamMatch: false,
          isAllDone: true,
          tournamentId: 'regular_tour_1',
        );
        expect(label, '確定・大会ホームへ');
      });

      test('通常進行中は「確定・次へ」を返すこと', () {
        final label = MatchBottomActionHelper.getConfirmButtonLabel(
          isTie: false,
          isTrulyTeamMatch: false,
          isAllDone: false,
          tournamentId: 't1',
        );
        expect(label, '確定・次へ');
      });
    });

    group('getConfirmButtonColor & Icon', () {
      test('引き分け時は赤系カラーとbalanceアイコンを返すこと', () {
        expect(
          MatchBottomActionHelper.getConfirmButtonColor(
            isTie: true,
            isAllDone: false,
          ),
          AppKendoColors.hansokuRed,
        );
        expect(
          MatchBottomActionHelper.getConfirmButtonIcon(
            isTie: true,
            isTrulyTeamMatch: true,
            isAllDone: false,
          ),
          Icons.balance,
        );
      });
    });

    group('determineWinnerColor', () {
      test('赤がリードしている場合は red を返すこと', () {
        final match = MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          redScore: 2,
          whiteScore: 1,
        );
        expect(MatchBottomActionHelper.determineWinnerColor(match), 'red');
      });

      test('白がリードしている場合は white を返すこと', () {
        final match = MatchModel(
          id: 'm2',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          redScore: 0,
          whiteScore: 1,
        );
        expect(MatchBottomActionHelper.determineWinnerColor(match), 'white');
      });

      test('同点の場合は draw を返すこと', () {
        final match = MatchModel(
          id: 'm3',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          redScore: 1,
          whiteScore: 1,
        );
        expect(MatchBottomActionHelper.determineWinnerColor(match), 'draw');
      });
    });

    group('formatExtensionCountString', () {
      test('初回延長は「延長1回目」を返すこと', () {
        expect(MatchBottomActionHelper.formatExtensionCountString(''), '延長1回目');
      });

      test('既に延長1回が行われている場合は「延長2回目」を返すこと', () {
        expect(
          MatchBottomActionHelper.formatExtensionCountString('本戦 (延長1回目)'),
          '延長2回目',
        );
      });
    });

    group('calculateExtensionMinutes', () {
      test('matchに明示的なextensionTimeMinutesがある場合はそれを優先すること', () {
        final match = MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          extensionTimeMinutes: 5.0,
        );
        final mins = MatchBottomActionHelper.calculateExtensionMinutes(
          match: match,
          lastSettings: {},
        );
        expect(mins, 5.0);
      });

      test('代表戦かつルールのdaihyoEnchoTimeMinutesが適用されること', () {
        final match = MatchModel(
          id: 'm2',
          redName: '赤',
          whiteName: '白',
          matchType: '代表戦',
          rule: MatchRule(daihyoEnchoTimeMinutes: 4.0),
        );
        final mins = MatchBottomActionHelper.calculateExtensionMinutes(
          match: match,
          lastSettings: {},
        );
        expect(mins, 4.0);
      });
    });
  });
}
