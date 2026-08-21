import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page1.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page2.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_sticky_bottom_action.dart';

void main() {
  group('CreateTournament Components Tests', () {
    testWidgets('renders CreateTournamentDynamicHeader correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateTournamentDynamicHeader(currentProgress: 0.5),
          ),
        ),
      );

      expect(find.text('大会を新規作成'), findsOneWidget);
    });

    testWidgets('renders CreateTournamentPage1 correctly', (tester) async {
      final nameCtrl = TextEditingController(text: '剣道大会');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateTournamentPage1(
              nameController: nameCtrl,
              selectedDate: DateTime(2026, 8, 21),
              onPickDate: () {},
            ),
          ),
        ),
      );

      expect(find.text('大会の名前と日付を\n教えてください'), findsOneWidget);
      expect(find.text('2026年08月21日'), findsOneWidget);
    });

    testWidgets('renders CreateTournamentPage2 correctly', (tester) async {
      final venueCtrl = TextEditingController(text: '武道館');
      final noteCtrl = TextEditingController(text: 'メモ');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateTournamentPage2(
              venueController: venueCtrl,
              notesController: noteCtrl,
              onOpenMap: () {},
            ),
          ),
        ),
      );

      expect(find.text('開催場所とメモを\n入力してください'), findsOneWidget);
    });

    testWidgets('renders CreateTournamentStickyBottomAction correctly', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: CreateTournamentStickyBottomAction(
                currentPage: 1,
                onPrevious: () {},
                onNextOrSave: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('保存してチーム登録へ'), findsOneWidget);
    });
  });
}
