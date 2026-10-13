import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart';

void main() {
  group('[Widget] CategoryRuleEditorHeaderCard 単体検証', () {
    testWidgets('CategoryRuleEditorHeaderCardにおいて 部門情報およびスイッチが正しく描画されること', (
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
      'CategoryRuleEditorHeaderCardにおいて 識別可能な場合に(2)を省略してタイトルプレビューが表示されること',
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

        expect(find.text('表示名プレビュー: 小学生の部 決勝トーナメント'), findsOneWidget);
        expect(find.text('連番省略中'), findsOneWidget);
      },
    );

    testWidgets('CategoryRuleEditorHeaderCardにおいて 剣道形が選択でき、コールバックが通知されること', (
      tester,
    ) async {
      final subtitleController = TextEditingController();
      final commentController = TextEditingController();
      String selectedType = '個人戦';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: CategoryRuleEditorHeaderCard(
                    category: '形の部',
                    textColor: Colors.black,
                    matchType: selectedType,
                    isMultiScene: false,
                    useAdvancedRule: false,
                    subtitleController: subtitleController,
                    commentController: commentController,
                    onMatchTypeChanged: (val) {
                      setState(() {
                        selectedType = val;
                      });
                    },
                    onMultiSceneChanged: (_) {},
                    onUseAdvancedRuleChanged: (_) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      // ドロップダウンを開く
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // 「日本剣道形（判定戦）」を選択
      await tester.tap(find.text('日本剣道形（判定戦）').last);
      await tester.pumpAndSettle();

      expect(selectedType, '日本剣道形');
    });
  });
}
