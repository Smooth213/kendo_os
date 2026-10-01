import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/tournament_program_pdf.dart';

void main() {
  group('[Unit] 大会プログラムPDFオンデマンド動的遅延生成エンジン単体テスト', () {
    test('generateOnDemandにおいて試合リストが空の場合は空のバイト列が返却されること', () async {
      final bytes = await TournamentProgramPdfEngine.generateOnDemand(
        tournamentTitle: '秋季選抜剣道大会',
        matches: const [],
        type: 'tournament',
      );

      expect(bytes, isNotNull);
      expect(bytes!.isEmpty, isTrue);
    });

    test('generateOnDemandにおいて試合情報を含むプログラムバイナリが遅延生成されること', () async {
      final matches = <MatchModel>[
        const MatchModel(
          id: 'pdf-m-1',
          tournamentId: 't-1',
          matchType: '1回戦',
          order: 1.0,
          redName: '選手紅',
          whiteName: '選手白',
          status: 'finished',
        ),
        const MatchModel(
          id: 'pdf-m-2',
          tournamentId: 't-1',
          matchType: '1回戦',
          order: 2.0,
          redName: '選手赤',
          whiteName: '選手青',
          status: 'ongoing',
        ),
      ];

      final bytes = await TournamentProgramPdfEngine.generateOnDemand(
        tournamentTitle: '春季選手権大会',
        matches: matches,
        type: 'league',
      );

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);

      final content = utf8.decode(bytes);
      expect(content.contains('大会名: 春季選手権大会'), isTrue);
      expect(content.contains('総試合数: 2'), isTrue);
      expect(content.contains('形式: league'), isTrue);
      expect(content.contains('[1.0] 選手紅 vs 選手白'), isTrue);
    });

    test('大量100試合以上のデータであってもメモリクラッシュすることなく遅延生成できること', () async {
      final largeMatches = List<MatchModel>.generate(
        120,
        (i) => MatchModel(
          id: 'large-m-$i',
          tournamentId: 't-large',
          matchType: 'トーナメント',
          order: (i + 1).toDouble(),
          redName: '選手Red$i',
          whiteName: '選手White$i',
          status: i % 2 == 0 ? 'finished' : 'waiting',
        ),
      );

      final bytes = await TournamentProgramPdfEngine.generateOnDemand(
        tournamentTitle: '全国選抜錬成大会',
        matches: largeMatches,
        type: 'tournament',
      );

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
      final content = utf8.decode(bytes);
      expect(content.contains('総試合数: 120'), isTrue);
    });
  });
}
