import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_display_card.dart';

void main() {
  group('[Governance] 常設ドックタイマー入力整合およびジグル浮遊保証規約', () {
    test('TimerCardInputMode列挙型が通常および手入力とダイヤルの全状態を過不足なく定義していること', () {
      expect(
        TimerCardInputMode.values,
        containsAll([
          TimerCardInputMode.normal,
          TimerCardInputMode.editMinutes,
          TimerCardInputMode.editSeconds,
          TimerCardInputMode.wheelPicker,
        ]),
      );
    });

    test('タイマー表示カード実装において実行中およびストップウォッチ時の編集遮断ガードが存在すること', () {
      final file = File(
        'lib/features/tournament/presentation/components/program_management/dock_timer_display_card.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(
        content.contains('if (widget.isRunning || widget.isStopwatch) return;'),
        isTrue,
      );
      expect(content.contains('TimerCardInputMode.wheelPicker'), isTrue);
      expect(content.contains('AppHaptics'), isTrue);
    });

    test('ドックジグルラッパー実装において編集モードに応じたTransform適用が担保されていること', () {
      final file = File(
        'lib/features/tournament/presentation/components/program_management/dock_jiggle_drag_wrapper.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('isEditMode'), isTrue);
      expect(content.contains('Transform.rotate'), isTrue);
      expect(content.contains('Transform.scale'), isTrue);
      expect(content.contains('jiggleAnimation'), isTrue);
    });
  });
}
