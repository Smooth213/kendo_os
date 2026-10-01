import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_jiggle_drag_wrapper.dart';

void main() {
  group('[Widget] DockJiggleDragWrapper ウィジェットテスト', () {
    testWidgets('非編集モード時に通常の子ウィジェットが描画されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DockJiggleDragWrapper(
              index: 0,
              isEditMode: false,
              child: Text('通常アイテム'),
            ),
          ),
        ),
      );

      expect(find.text('通常アイテム'), findsOneWidget);
    });

    testWidgets('編集モードかつアニメーション提供時にTransformが適用されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return _TestJiggleHost();
              },
            ),
          ),
        ),
      );

      expect(find.byType(Transform), findsWidgets);
      expect(find.text('ジグルアイテム'), findsOneWidget);
    });

    testWidgets('ドラッグ中にスケール拡大Transformが適用されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DockJiggleDragWrapper(
              index: 0,
              isEditMode: true,
              isDragging: true,
              child: Text('ドラッグ中アイテム'),
            ),
          ),
        ),
      );

      final transformFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Transform && widget.transform.getMaxScaleOnAxis() > 1.0,
      );
      expect(transformFinder, findsOneWidget);
    });
  });
}

class _TestJiggleHost extends StatefulWidget {
  @override
  State<_TestJiggleHost> createState() => _TestJiggleHostState();
}

class _TestJiggleHostState extends State<_TestJiggleHost>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DockJiggleDragWrapper(
      index: 1,
      isEditMode: true,
      isDragging: false,
      jiggleAnimation: _controller,
      child: const Text('ジグルアイテム'),
    );
  }
}
