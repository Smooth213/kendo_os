import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_individual_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_group_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.Font ttf;
  late pw.Font ttfBold;

  setUpAll(() async {
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Regular.ttf',
    );
    ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final fontBoldData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Bold.ttf',
    );
    ttfBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
  });

  group('[E2E] 剣道形 試合運用ライフサイクル結合テスト', () {
    test('形競技の試合生成から判定決着・タイムライン分類・公式記録集約・PDF出力までの一連のフローが整合すること', () async {
      // 1. 形競技ルールの定義（時間計測なし・延長なし・判定有効）
      const kataRule = MatchRule(
        isKataMatch: true,
        matchTimeMinutes: 0.0,
        hasHantei: true,
        enchoCount: 0,
      );

      // 2. ペア選手の形競技試合モデル生成
      final kataMatch = MatchModel(
        id: 'kata_flow_match_1',
        tournamentId: 't_flow_1',
        order: 1.0,
        matchType: '日本剣道形',
        status: 'finished',
        redName: '道上剣友会:皿田 脩人・塚本 大道',
        whiteName: '友道館:佐藤 健一・鈴木 次郎',
        groupName: '道上剣友会 vs 友道館',
        rule: kataRule,
        redScore: 2,
        whiteScore: 1,
        events: [
          ScoreEventLegacyAdapter.fromLegacy(
            id: 'ev_1',
            type: PointType.hantei,
            side: Side.red,
            timestamp: SystemTimeSource().now(),
          ),
          ScoreEventLegacyAdapter.fromLegacy(
            id: 'ev_2',
            type: PointType.hantei,
            side: Side.red,
            timestamp: SystemTimeSource().now(),
          ),
          ScoreEventLegacyAdapter.fromLegacy(
            id: 'ev_3',
            type: PointType.hantei,
            side: Side.white,
            timestamp: SystemTimeSource().now(),
          ),
        ],
      );

      // 3. 試合形式・勝敗の判定（個人戦認識および赤が過半数2旗獲得で勝利）
      expect(TeamProgressHelper.isIndividualMatch(kataMatch), isTrue);
      expect(kataMatch.redScore, 2);
      expect(kataMatch.whiteScore, 1);
      final isRedWinner = kataMatch.redScore > kataMatch.whiteScore;
      expect(isRedWinner, isTrue);

      // 4. タイムライン表示ロジックでの分類検証
      final timelineClassified =
          TimelinePlayerMatchClassifier.classifyTeamMatches(
            teamMatchesList: [kataMatch],
            teamName: '道上剣友会',
            sanitizedQuery: '',
            matchedMatchIds: {},
            matchedGroupNames: {},
            ownTeams: ['道上剣友会'],
          );

      // 団体戦ではなく個人戦（sortedPlayers）として分類され、ペア名が保持されること
      expect(timelineClassified.sortedGroups.isEmpty, isTrue);
      expect(timelineClassified.sortedPlayers.length, 1);
      expect(timelineClassified.sortedPlayers.first.key, '皿田 脩人・塚本 大道');
      expect(
        timelineClassified.sortedPlayers.first.value.first.id,
        'kata_flow_match_1',
      );

      // 5. 大会公式記録集約ロジックでの検証
      final groupMap = {
        '道上剣友会 vs 友道館': [kataMatch],
      };
      final mergedRecords = OfficialRecordGroupHelper.mergeIndividualGroups(
        groupMap,
      );

      // 個人戦集約キー（__merged_individual__）にマージされること
      expect(mergedRecords.containsKey('__merged_individual__'), isTrue);
      final mergedMatches = mergedRecords['__merged_individual__']!;
      expect(mergedMatches.length, 1);
      expect(mergedMatches.first.id, 'kata_flow_match_1');

      // 6. 帳票（PDF）出力データパイプラインでの検証
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfIndividualList.build('形・基本判定', mergedMatches, ttf, ttfBold),
          ],
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      expect(pdfBytes, isNotEmpty);
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), '%PDF');
    });
  });
}
