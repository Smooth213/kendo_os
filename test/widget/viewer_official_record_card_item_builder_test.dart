import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_card_item_builder.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ ViewerOfficialRecordCardItemBuilder Tests', () {
    test(
      '1. generateDescriptiveLeagueTitle generates title correctly for team league',
      () {
        final matches = [
          const MatchListProjection(
            id: 'm1',
            tournamentId: 't1',
            matchOrder: 1,
            redName: '東京道場 : 佐藤',
            whiteName: '大阪道場 : 鈴木',
            redScore: 2,
            whiteScore: 0,
            status: 'finished',
            matchType: '先鋒',
            note: '',
          ),
        ];

        final title =
            ViewerOfficialRecordCardItemBuilder.generateDescriptiveLeagueTitle(
              matches,
              ['東京道場'],
            );

        expect(title, contains('東京道場'));
        expect(title, contains('2チームリーグ'));
      },
    );
  });
}
