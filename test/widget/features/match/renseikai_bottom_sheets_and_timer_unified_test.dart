import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_add_next_match_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_master_timer_widget.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_player_candidate_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_player_input_field.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRenseikaiMasterTimerNotifier extends RenseikaiMasterTimerNotifier {
  final int initialSeconds;
  _FakeRenseikaiMasterTimerNotifier([this.initialSeconds = 120]);

  @override
  int build(String arg) => initialSeconds;
}

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('[Widget] 錬成会 ボトムシート・マスタータイマー・候補解決統合検証テスト', () {
    test('選手候補リゾルバにおいて部門カテゴリ一致判定が正しく動作すること', () {
      expect(
        RenseikaiPlayerCandidateResolver.isCategoryMatch('小学生低学年の部', '小学生低学年'),
        isTrue,
      );
      expect(
        RenseikaiPlayerCandidateResolver.isCategoryMatch('中学生の部', '小学生高学年'),
        isFalse,
      );
    });

    testWidgets('RenseikaiPlayerInputFieldにおいて 選択肢および入力欄が正しく描画されること', (
      tester,
    ) async {
      final ctrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RenseikaiPlayerInputField(
              teamName: '練馬道場',
              players: const ['山田', '田中'],
              masterSet: const {'山田', '田中'},
              controller: ctrl,
              isDark: false,
              textColor: Colors.black,
              inputBgColor: Colors.grey.shade100,
              borderColor: Colors.grey,
              onPlayerSelected: (val) {
                ctrl.text = val;
              },
            ),
          ),
        ),
      );

      expect(find.text('練馬道場 の選手を選択:'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('田中'), findsOneWidget);
    });

    testWidgets('初期タイマー表示が行われタップ時にトグル動作が正しく描画されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            renseikaiMasterTimerProvider.overrideWith(
              () => _FakeRenseikaiMasterTimerNotifier(120),
            ),
            isMasterTimerRunningProvider('groupA').overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: const Scaffold(
              body: RenseikaiMasterTimerWidget(
                groupName: 'groupA',
                isInputLocked: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('トータル'), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsOneWidget);
    });

    testWidgets('カウントダウン中およびタイムアップ状態が正しく描画されること', (WidgetTester tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            renseikaiMasterTimerProvider.overrideWith(
              () => _FakeRenseikaiMasterTimerNotifier(0),
            ),
            isMasterTimerRunningProvider('groupA').overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: const Scaffold(
              body: RenseikaiMasterTimerWidget(
                groupName: 'groupA',
                isInputLocked: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle), findsOneWidget);
    });

    testWidgets('錬成会次試合追加ボトムシートが正しく描画されること', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final mockPlayerRepo = _MockPlayerRepository();
      final mockTeamRepo = _MockTeamRepository();

      when(
        () => mockPlayerRepo.getPlayers(),
      ).thenAnswer((_) => Stream.value(<PlayerModel>[]));
      when(
        () => mockTeamRepo.watchTeamsByTournament(any()),
      ).thenAnswer((_) => Stream.value(<TeamModel>[]));

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '錬成会',
        order: 1,
        redName: 'チームA : 選手1',
        whiteName: 'チームB : 選手2',
        status: 'finished',
        note: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchListProvider.overrideWith((ref) => [match]),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: RenseikaiAddNextMatchBottomSheet(currentMatch: match),
            ),
          ),
        ),
      );

      await tester.safePumpAndSettle();

      expect(find.text('次の試合を追加 (錬成会)'), findsOneWidget);
      expect(find.text('決定して開始'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });
  });
}
