import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_daihyo_handler.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchCommandService extends Mock implements MatchCommandService {}

class _FixedTimeSource implements TimeSource {
  final DateTime _fixedTime;
  _FixedTimeSource(this._fixedTime);

  @override
  DateTime now() => _fixedTime;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'dummy',
        matchType: '代表戦',
        redName: '赤チーム',
        whiteName: '白チーム',
      ),
    );
  });

  group('[Widget] TeamScoreboardDaihyoHandler 代表戦追加とダイアログ遷移の検証', () {
    late _MockMatchCommandService mockMatchCommand;
    final fixedDate = DateTime(2025, 5, 1, 10, 30);
    final expectedMatchId = 'match_${fixedDate.millisecondsSinceEpoch}';

    final baseMatch = MatchModel(
      id: 'bout_senpo',
      matchType: '先鋒',
      redName: '赤チーム:先鋒',
      whiteName: '白チーム:先鋒',
      order: 1.0,
      matchTimeMinutes: 3.0,
    );

    setUp(() {
      mockMatchCommand = _MockMatchCommandService();
      when(() => mockMatchCommand.addMatch(any())).thenAnswer((_) async {});
    });

    Widget buildTestApp({
      required void Function(BuildContext context, WidgetRef ref) onTrigger,
    }) {
      final router = GoRouter(
        initialLocation: '/scoreboard',
        routes: [
          GoRoute(
            path: '/scoreboard',
            builder: (context, state) => Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () => onTrigger(context, ref),
                    child: const Text('代表戦追加ボタン'),
                  );
                },
              ),
            ),
          ),
          GoRoute(
            path: '/match/:id',
            builder: (context, state) =>
                Scaffold(body: Text('試合画面: ${state.pathParameters['id']}')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          matchCommandProvider.overrideWithValue(mockMatchCommand),
          timeSourceProvider.overrideWithValue(_FixedTimeSource(fixedDate)),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('代表戦追加時に新しい試合モデルが生成され確認ダイアログが表示されること', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onTrigger: (context, ref) {
            TeamScoreboardDaihyoHandler.handleAddDaihyo(
              context: context,
              ref: ref,
              teamMatches: [baseMatch],
              redTeam: '修武館',
              whiteTeam: '玄武館',
              isDark: false,
            );
          },
        ),
      );

      await tester.tap(find.text('代表戦追加ボタン'));
      await tester.pumpAndSettle();

      // 新規代表戦モデルが正しく構築されて追加されたことの検証
      final captured = verify(
        () => mockMatchCommand.addMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final addedMatch = captured.first as MatchModel;
      expect(addedMatch.id, equals(expectedMatchId));
      expect(addedMatch.matchType, equals('代表戦'));
      expect(addedMatch.redName, equals('修武館 : 代表選手'));
      expect(addedMatch.whiteName, equals('玄武館 : 代表選手'));
      expect(addedMatch.order, equals(2.0));

      // ダイアログUIの表示検証
      expect(find.text('代表戦を追加しました'), findsOneWidget);
      expect(find.text('代表戦のスコア入力に進みますか？'), findsOneWidget);
      expect(find.text('一覧に戻る'), findsOneWidget);
      expect(find.text('試合へ進む'), findsOneWidget);
    });

    testWidgets('ダイアログで試合へ進む選択時に試合画面へ遷移すること', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onTrigger: (context, ref) {
            TeamScoreboardDaihyoHandler.handleAddDaihyo(
              context: context,
              ref: ref,
              teamMatches: [baseMatch],
              redTeam: '修武館',
              whiteTeam: '玄武館',
              isDark: false,
            );
          },
        ),
      );

      await tester.tap(find.text('代表戦追加ボタン'));
      await tester.pumpAndSettle();

      // 「試合へ進む」ボタンをタップ
      await tester.tap(find.text('試合へ進む'));
      await tester.pumpAndSettle();

      // 試合画面への遷移とIDの一致を検証
      expect(find.text('試合画面: $expectedMatchId'), findsOneWidget);
      expect(find.text('代表戦を追加しました'), findsNothing);
    });

    testWidgets('ダイアログで一覧に戻る選択時にダイアログが閉じられ現在の画面に留まること', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onTrigger: (context, ref) {
            TeamScoreboardDaihyoHandler.handleAddDaihyo(
              context: context,
              ref: ref,
              teamMatches: [baseMatch],
              redTeam: '修武館',
              whiteTeam: '玄武館',
              isDark: false,
            );
          },
        ),
      );

      await tester.tap(find.text('代表戦追加ボタン'));
      await tester.pumpAndSettle();

      // 「一覧に戻る」ボタンをタップ
      await tester.tap(find.text('一覧に戻る'));
      await tester.pumpAndSettle();

      // ダイアログが閉じられ、スコアボード（元の画面）に留まること
      expect(find.text('代表戦を追加しました'), findsNothing);
      expect(find.text('代表戦追加ボタン'), findsOneWidget);
      expect(find.textContaining('試合画面:'), findsNothing);
    });
  });
}
