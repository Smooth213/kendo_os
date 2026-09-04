import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/text_input_helper.dart';

void main() {
  group('TextInputHelper.insertComma Tests', () {
    test('空文字の場合はカンマのみを挿入しないか、あるいはスマートに扱うか', () {
      final controller = TextEditingController();
      TextInputHelper.insertComma(controller);

      // 空の場合はカンマは挿入されず空のまま
      expect(controller.text, isEmpty);
      expect(controller.selection.baseOffset, -1);
    });

    test('既存テキストの末尾にカーソルがある場合、カンマと半角スペースを挿入する', () {
      final controller = TextEditingController(text: '第1試合場');
      controller.selection = const TextSelection.collapsed(offset: 5);

      TextInputHelper.insertComma(controller);

      expect(controller.text, '第1試合場, ');
      expect(controller.selection.baseOffset, '第1試合場, '.length);
    });

    test('既に末尾がカンマまたはカンマ+空白で終わっている場合、二重にカンマを挿入しない', () {
      final controller = TextEditingController(text: '第1試合場, ');
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );

      TextInputHelper.insertComma(controller);

      expect(controller.text, '第1試合場, ');
      expect(controller.selection.baseOffset, '第1試合場, '.length);

      // 半角カンマのみで終わっている場合も重複防止
      final controller2 = TextEditingController(text: '第1試合場,');
      controller2.selection = TextSelection.collapsed(
        offset: controller2.text.length,
      );

      TextInputHelper.insertComma(controller2);

      expect(controller2.text, '第1試合場, ');
      expect(controller2.selection.baseOffset, '第1試合場, '.length);
    });

    test('全角読点（、）や全角カンマ（，）で終わっている場合も重複挿入せず適切にフォーマット', () {
      final controller = TextEditingController(text: '第1試合場、');
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );

      TextInputHelper.insertComma(controller);

      expect(controller.text, '第1試合場, ');
      expect(controller.selection.baseOffset, '第1試合場, '.length);
    });

    test('文章の途中にカーソルがある場合、その位置にカンマと空白を挿入しカーソルを進める', () {
      final controller = TextEditingController(text: '第1試合場12試合目');
      controller.selection = const TextSelection.collapsed(
        offset: 5,
      ); // '第1試合場'の直後

      TextInputHelper.insertComma(controller);

      expect(controller.text, '第1試合場, 12試合目');
      expect(controller.selection.baseOffset, 7); // 5 + 2
    });

    test('選択範囲がある場合、選択範囲をカンマと空白で置換する', () {
      final controller = TextEditingController(text: '第1試合場 XXX 12試合目');
      controller.selection = const TextSelection(
        baseOffset: 5,
        extentOffset: 10,
      );

      TextInputHelper.insertComma(controller);

      expect(controller.text, '第1試合場, 12試合目');
      expect(controller.selection.baseOffset, 7);
    });
  });
}
