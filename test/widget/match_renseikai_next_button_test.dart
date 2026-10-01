import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_renseikai_next_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/renseikai_master_timer_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  final String confirmBehavior;
  _MockSettingsNotifier({required this.confirmBehavior});

  @override
  SettingsModel build() {
    return SettingsModel(confirmBehavior: confirmBehavior, haptic: false);
  }
}

class _MockTimerNotifier extends RenseikaiMasterTimerNotifier {
  final int initialValue;
  _MockTimerNotifier(this.initialValue);

  @override
  int build(String arg) {
    return initialValue;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  MatchModel createMatch({String? scorerId, String? groupName = '会場A'}) {
    return MatchModel(
      id: 'match-renseikai-1',
      matchType: '個人戦',
      redName: '赤選手',
      whiteName: '白選手',
      groupName: groupName,
      scorerId: scorerId,
      status: 'in_progress',
    );
  }

  Widget createTestWidget({
    required MatchModel match,
    required String currentUserId,
    required bool isViewOnly,
    required VoidCallback onAddNext,
    required Future<void> Function() onConfirmAndFinish,
    int masterTimeOverride = 120,
    String confirmBehavior = 'single',
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        settingsProvider.overrideWith(
          () => _MockSettingsNotifier(confirmBehavior: confirmBehavior),
        ),
        renseikaiMasterTimerProvider.overrideWith(
          () => _MockTimerNotifier(masterTimeOverride),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MatchRenseikaiNextButton(
            match: match,
            isViewOnly: isViewOnly,
            currentUserId: currentUserId,
            onAddNext: onAddNext,
            onConfirmAndFinish: onConfirmAndFinish,
          ),
        ),
      ),
    );
  }

  group('[Widget] MatchRenseikaiNextButton ウィジェットテスト', () {
    testWidgets('通常状態で追加および確定ボタンが正常に動作すること', (tester) async {
      bool addNextCalled = false;
      bool confirmCalled = false;

      final match = createMatch(scorerId: 'user_1');

      await tester.pumpWidget(
        createTestWidget(
          match: match,
          currentUserId: 'user_1',
          isViewOnly: false,
          onAddNext: () {
            addNextCalled = true;
          },
          onConfirmAndFinish: () async {
            confirmCalled = true;
          },
          masterTimeOverride: 120,
        ),
      );

      expect(find.text('追加して継続'), findsOneWidget);
      expect(find.text('確定して終了'), findsOneWidget);

      await tester.tap(find.text('追加して継続'));
      await tester.pump();
      expect(addNextCalled, isTrue);

      await tester.tap(find.text('確定して終了'));
      await tester.pump();
      expect(confirmCalled, isTrue);
    });

    testWidgets('残り時間が0秒のとき追加して継続が無効化されること', (tester) async {
      bool addNextCalled = false;
      final match = createMatch(scorerId: 'user_1');

      await tester.pumpWidget(
        createTestWidget(
          match: match,
          currentUserId: 'user_1',
          isViewOnly: false,
          onAddNext: () {
            addNextCalled = true;
          },
          onConfirmAndFinish: () async {},
          masterTimeOverride: 0,
        ),
      );

      await tester.tap(find.text('追加して継続'));
      await tester.pump();

      expect(addNextCalled, isFalse);
    });

    testWidgets('他者がスコア入力中のとき追加ボタンが無効化されること', (tester) async {
      bool addNextCalled = false;
      final match = createMatch(scorerId: 'user_other');

      await tester.pumpWidget(
        createTestWidget(
          match: match,
          currentUserId: 'user_1',
          isViewOnly: false,
          onAddNext: () {
            addNextCalled = true;
          },
          onConfirmAndFinish: () async {},
          masterTimeOverride: 120,
        ),
      );

      await tester.tap(find.text('追加して継続'));
      await tester.pump();

      expect(addNextCalled, isFalse);
    });
  });
}
