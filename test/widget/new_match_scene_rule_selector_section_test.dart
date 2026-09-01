import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_scene_rule_selector_section.dart';

void main() {
  group('🛡️ NewMatchSceneRuleSelectorSection Widget Tests', () {
    testWidgets('Renders default 3 scene rule cards and handles selection', (
      tester,
    ) async {
      String selectedScene = 'honsen';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NewMatchSceneRuleSelectorSection(
                  categoryRules: const {},
                  category: '',
                  selectedScene: selectedScene,
                  onSceneSelected: (scene) =>
                      setState(() => selectedScene = scene),
                  isDark: false,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('⚔️ 錬成（練習試合）'), findsOneWidget);
      expect(find.text('🏆 本戦（通常戦）'), findsOneWidget);
      expect(find.text('🤝 申合せ（自由対戦）'), findsOneWidget);

      await tester.tap(find.text('⚔️ 錬成（練習試合）'));
      await tester.pump();

      expect(selectedScene, 'renseikai');
    });
  });
}
