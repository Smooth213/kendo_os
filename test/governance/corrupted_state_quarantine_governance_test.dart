import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/match_corrupted_state.dart';
import 'package:kendo_os/shared/domain/entities/match_corruption_exception.dart';
import 'package:kendo_os/shared/widgets/corrupted_match_banner.dart';

void main() {
  group('[Governance] 障害データ隔離およびフェイルセーフ二次破壊完全阻止規約', () {
    test('破損試合において新規編集が完全に阻止され生データ救済が許可されること', () {
      final corruptedMatch = MatchModel(
        id: 'corrupted-gov-1',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'corrupted',
      );

      final state = MatchCorruptedState(corruptedMatch);

      // 二次破壊完全阻止
      expect(state.isCorrupted, isTrue);
      expect(state.allowEdit, isFalse);

      // 現地混乱防止のための閲覧継続許可
      expect(state.allowViewer, isTrue);

      // 生データ救済書き出し許可
      expect(state.allowExport, isTrue);
    });

    testWidgets('CorruptedMatchBannerにおいてユーザー向け警告文が明瞭に表示されること', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CorruptedMatchBanner(matchId: 'm-123')),
          ),
        ),
      );

      expect(find.text('データに問題が発生しました'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    test('MatchCorruptionExceptionが識別子を包含した明確な文字列表現を持つこと', () {
      final ex = MatchCorruptionException('イベント破損', matchId: 'm-target');
      expect(ex.toString(), contains('MatchCorruptionException: イベント破損'));
      expect(ex.toString(), contains('(Match ID: m-target)'));
    });

    test('静的解析において障害リカバリ防衛モデルと例外クラスが整合していること', () {
      final stateFile = File(
        'lib/shared/domain/entities/match_corrupted_state.dart',
      );
      final exFile = File(
        'lib/shared/domain/entities/match_corruption_exception.dart',
      );
      final bannerFile = File('lib/shared/widgets/corrupted_match_banner.dart');

      expect(stateFile.existsSync(), isTrue);
      expect(exFile.existsSync(), isTrue);
      expect(bannerFile.existsSync(), isTrue);

      final stateContent = stateFile.readAsStringSync();
      expect(stateContent.contains('allowEdit => !isCorrupted'), isTrue);
      expect(stateContent.contains('allowViewer => true'), isTrue);
      expect(stateContent.contains('allowExport => isCorrupted'), isTrue);
    });
  });
}
