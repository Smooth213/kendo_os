import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_reorderable_file_list.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required List<PlatformFile> files,
    required int selectedIndex,
    required bool isDark,
    required void Function(int, int) onReorder,
    required ValueChanged<int> onFileSelected,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
      ),
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: ProgramReorderableFileList(
            orderedFiles: files,
            selectedIndex: selectedIndex,
            isDark: isDark,
            onReorder: onReorder,
            onFileSelected: onFileSelected,
          ),
        ),
      ),
    );
  }

  group('[Widget] ProgramReorderableFileList ウィジェットテスト', () {
    testWidgets('ファイル一覧が表示されタップ選択できること', (tester) async {
      final files = [
        PlatformFile(name: '大会要項.pdf', size: 1024),
        PlatformFile(name: 'トーナメント表.pdf', size: 2048),
      ];

      int selectedIdx = -1;

      await tester.pumpWidget(
        createTestWidget(
          files: files,
          selectedIndex: 0,
          isDark: false,
          onReorder: (oldIdx, newIdx) {},
          onFileSelected: (idx) {
            selectedIdx = idx;
          },
        ),
      );

      expect(find.text('大会要項.pdf'), findsOneWidget);
      expect(find.text('トーナメント表.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

      // 2つ目のアイテムをタップ
      await tester.tap(find.text('トーナメント表.pdf'));
      await tester.pump();

      expect(selectedIdx, 1);
    });

    testWidgets('ダークモードでも正しく装飾および番号バッジが描画されること', (tester) async {
      final files = [PlatformFile(name: '大会案内.pdf', size: 512)];

      await tester.pumpWidget(
        createTestWidget(
          files: files,
          selectedIndex: 0,
          isDark: true,
          onReorder: (oldIdx, newIdx) {},
          onFileSelected: (_) {},
        ),
      );

      expect(find.text('大会案内.pdf'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
