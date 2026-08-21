import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_name_edit_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late MockPlayerRepository mockPlayerRepo;
  late MockTeamRepository mockTeamRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPlayerRepo = MockPlayerRepository();
    mockTeamRepo = MockTeamRepository();

    when(
      () => mockPlayerRepo.getPlayers(),
    ).thenAnswer((_) => Stream.value(<PlayerModel>[]));
    when(
      () => mockTeamRepo.watchTeamsByTournament(any()),
    ).thenAnswer((_) => Stream.value(<TeamModel>[]));
  });

  testWidgets('MatchPlayerNameEditBottomSheet renders properly', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    final match = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: '先鋒戦',
      order: 1,
      redName: 'チームA : 選手1',
      whiteName: 'チームB : 選手2',
      status: 'pending',
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
            body: MatchPlayerNameEditBottomSheet(match: match, side: 'red'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('選手名の変更'), findsOneWidget);
    expect(find.text('チームA'), findsOneWidget);
    expect(find.text('確定'), findsOneWidget);
    expect(find.text('このポジションを「欠員」にする'), findsOneWidget);
  });
}
