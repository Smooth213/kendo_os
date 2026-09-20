import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart';

void main() {
  testWidgets('CategoryRuleEditorHeaderCard renders category and switches', (
    tester,
  ) async {
    final subtitleController = TextEditingController();
    final commentController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryRuleEditorHeaderCard(
              category: '一般男子の部',
              textColor: Colors.black,
              matchType: '個人戦',
              isMultiScene: false,
              useAdvancedRule: false,
              subtitleController: subtitleController,
              commentController: commentController,
              onMatchTypeChanged: (_) {},
              onMultiSceneChanged: (_) {},
              onUseAdvancedRuleChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('対象部門'), findsOneWidget);
    expect(find.text('一般男子の部'), findsOneWidget);
    expect(find.text('🏷️ サブタイトル（任意）'), findsOneWidget);
    expect(find.text('💬 ルールコメント・特記事項（任意）'), findsOneWidget);
    expect(find.text('試合方式'), findsOneWidget);
    expect(find.text('準決勝・決勝は別ルールにする'), findsOneWidget);
  });

  testWidgets(
    'CategoryRuleEditorHeaderCard previews title with (2) omitted when distinct',
    (tester) async {
      final subtitleController = TextEditingController(text: '決勝トーナメント');
      final commentController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleEditorHeaderCard(
                category: '小学生の部 (2)',
                textColor: Colors.black,
                matchType: '個人戦',
                isMultiScene: false,
                useAdvancedRule: false,
                subtitleController: subtitleController,
                commentController: commentController,
                allCategoryRules: const {},
                onMatchTypeChanged: (_) {},
                onMultiSceneChanged: (_) {},
                onUseAdvancedRuleChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // allCategoryRules 内に重複がなければ (2) が省略されて「表示名プレビュー: 小学生の部 決勝トーナメント」と表示される
      expect(find.text('表示名プレビュー: 小学生の部 決勝トーナメント'), findsOneWidget);
      expect(find.text('連番省略中'), findsOneWidget);
    },
  );
}
