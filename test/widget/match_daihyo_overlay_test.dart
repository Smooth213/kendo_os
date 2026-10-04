import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_daihyo_overlay.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] MatchDaihyoOverlay', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget buildSubject(MatchModel match) {
      return ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: MatchDaihyoOverlay(match: match, onSelectDaihyo: () {}),
          ),
        ),
      );
    }

    testWidgets('代表者未設定なら選択案内を表示すること', (tester) async {
      const match = MatchModel(
        id: 'representative-match',
        matchType: '代表戦',
        redName: '赤チーム : 代表選手',
        whiteName: '白チーム : 代表選手',
        status: 'waiting',
      );

      await tester.pumpWidget(buildSubject(match));

      expect(find.text('代表戦の選手が未設定です'), findsOneWidget);
      expect(find.text('代表者を選択する'), findsOneWidget);
    });

    testWidgets('代表者名確定後は選択案内を表示しないこと', (tester) async {
      const match = MatchModel(
        id: 'representative-match',
        matchType: '代表戦',
        redName: '赤チーム : 山田',
        whiteName: '白チーム : 鈴木',
        status: 'waiting',
      );

      await tester.pumpWidget(buildSubject(match));

      expect(find.text('代表戦の選手が未設定です'), findsNothing);
      expect(find.text('代表者を選択する'), findsNothing);
    });

    testWidgets('代表者が片側だけ未設定なら選択案内を表示すること', (tester) async {
      const match = MatchModel(
        id: 'representative-match',
        matchType: '代表戦',
        redName: '赤チーム : 山田',
        whiteName: '白チーム : 代表選手',
        status: 'waiting',
      );

      await tester.pumpWidget(buildSubject(match));

      expect(find.text('代表戦の選手が未設定です'), findsOneWidget);
    });
  });
}
