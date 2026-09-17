import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('⚡ 【第9条 ガバナンス監査】UI再描画局所化 ＆ Jank防止規約', () {
    test(
      'Rule 1: [ルート購読局所化] main.dart で settingsProvider を丸ごと購読せず、.select((s) => s.themeMode) で局所化されていること',
      () {
        final mainFile = File('lib/main.dart');
        expect(mainFile.existsSync(), isTrue);
        final content = mainFile.readAsStringSync();

        final hasFullWatch = RegExp(
          r'ref\.watch\(\s*settingsProvider\s*\)',
        ).hasMatch(content);
        expect(
          hasFullWatch,
          isFalse,
          reason:
              'main.dart のルートで settingsProvider を丸ごと購読してはならない。設定変更時のアプリ全体再ビルドを防ぐため select で局所化すること。',
        );

        expect(
          content.contains('settingsProvider.select((s) => s.themeMode)'),
          isTrue,
          reason: 'main.dart では themeMode のみをピンポイント購読していなければならない',
        );
      },
    );

    test(
      'Rule 2: [動的ProviderScope排除] match_screen.dart の build() 内で動的 ProviderScope が生成されず、MatchScoreboard へ直接プロパティ注入されていること',
      () {
        final screenFile = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        final scoreboardFile = File('lib/shared/widgets/scoreboard.dart');

        final screenContent = screenFile.readAsStringSync();
        final scoreboardContent = scoreboardFile.readAsStringSync();

        expect(
          scoreboardContent.contains('final String? matchId;'),
          isTrue,
          reason: 'MatchScoreboard は matchId プロパティを受け取れる構造でなければならない',
        );
        expect(
          scoreboardContent.contains('final MatchModel? match;'),
          isTrue,
          reason: 'MatchScoreboard は match プロパティを受け取れる構造でなければならない',
        );

        expect(
          screenContent.contains('scoreboardMatchIdProvider.overrideWithValue'),
          isFalse,
          reason:
              'match_screen.dart 内で scoreboardMatchIdProvider を動的オーバーライドしてはならない',
        );
        expect(
          screenContent.contains('scoreboardMatchProvider.overrideWithValue'),
          isFalse,
          reason:
              'match_screen.dart 内で scoreboardMatchProvider を動的オーバーライドしてはならない',
        );

        expect(
          screenContent.contains('MatchScoreboard('),
          isTrue,
          reason:
              'match_screen.dart は MatchScoreboard を直接インスタンス化してElementを再利用しなければならない',
        );
        expect(screenContent.contains('matchId: match.id'), isTrue);
        expect(screenContent.contains('match: match'), isTrue);
      },
    );

    test(
      'Rule 3: [singleMatchProvider配備] match_screen.dart における singleMatchProvider 局所購読規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('singleMatchProvider(widget.matchId)'),
          isTrue,
          reason:
              '他試合の更新による再描画を遮断するため、MatchScreenは singleMatchProvider を監視しなければなりません。',
        );
      },
    );

    test(
      'Rule 4: [Rebuild Storm根絶] ListEqualityWrapper が要素同一リストの等価性を担保し、リスナー再通知を抑止すること',
      () {
        final listFile = File(
          'lib/features/tournament/presentation/operate/providers/match_list_provider.dart',
        );
        final screenFile = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );

        expect(listFile.existsSync(), isTrue);
        expect(screenFile.existsSync(), isTrue);

        final listContent = listFile.readAsStringSync();
        final screenContent = screenFile.readAsStringSync();

        expect(
          listContent.contains('class ListEqualityWrapper'),
          isTrue,
          reason:
              'match_list_provider.dart に ListEqualityWrapper が定義されていなければならない',
        );
        expect(
          listContent.contains('ListEqualityWrapper('),
          isTrue,
          reason:
              'teamMatchesByGroupProvider 内で ListEqualityWrapper を使用していなければならない',
        );
        expect(
          screenContent.contains('ListEqualityWrapper<MatchModel>('),
          isTrue,
          reason:
              'match_screen.dart の Web セレクターで ListEqualityWrapper を使用していなければならない',
        );

        final m1 = MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '選手1',
          whiteName: '選手2',
        );
        final m2 = MatchModel(
          id: 'm2',
          matchType: '個人戦',
          redName: '選手3',
          whiteName: '選手4',
        );

        final wrapperA = ListEqualityWrapper([m1, m2]);
        final wrapperB = ListEqualityWrapper([m1, m2]);
        final wrapperC = ListEqualityWrapper([m2, m1]);

        expect(
          wrapperA == wrapperB,
          isTrue,
          reason: '中身が同一なら別インスタンスでも == が true であること',
        );
        expect(wrapperA == wrapperC, isFalse, reason: '順序が異なる場合は false であること');
      },
    );

    test(
      'Rule 5: [スコアボード局所購読] スコアボード画面で matchListProvider の無差別 ref.watch が禁止され、select シグネチャ購読されていること',
      () {
        final teamScoreboard = File(
          'lib/features/tournament/presentation/operate/team_scoreboard_screen.dart',
        );
        final viewerScoreboard = File(
          'lib/features/viewer/screens/viewer_team_scoreboard_screen.dart',
        );
        final kachinukiScoreboard = File(
          'lib/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart',
        );

        expect(teamScoreboard.existsSync(), isTrue);
        expect(viewerScoreboard.existsSync(), isTrue);
        expect(kachinukiScoreboard.existsSync(), isTrue);

        for (final file in [
          teamScoreboard,
          viewerScoreboard,
          kachinukiScoreboard,
        ]) {
          final content = file.readAsStringSync();

          final hasUnscopedWatch = RegExp(
            r'ref\.watch\(\s*matchListProvider\s*\)',
          ).hasMatch(content);
          expect(
            hasUnscopedWatch,
            isFalse,
            reason:
                '${file.path} で無差別な ref.watch(matchListProvider) を行ってはならない。他コートのタイマー更新による全画面リビルドを防ぐため select シグネチャを使用すること。',
          );

          expect(
            content.contains('matchListProvider.select('),
            isTrue,
            reason:
                '${file.path} で matchListProvider.select によるシグネチャ監視が行われていること',
          );
        }
      },
    );

    test(
      'Rule 6: [極小粒度select] match_score_action_section.dart における leftHanded 極小粒度 select 規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/match_screen/match_score_action_section.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('settingsProvider.select((s) => s.leftHanded)'),
          isTrue,
          reason:
              'settingsProvider 全体ではなく、leftHanded のみを select 監視して不要リビルドを根絶しなければなりません。',
        );
      },
    );
  });
}
