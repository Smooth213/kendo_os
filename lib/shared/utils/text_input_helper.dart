import 'package:flutter/material.dart';

/// 🥋 テキスト入力アシスト用共通ヘルパー
class TextInputHelper {
  TextInputHelper._();

  /// コントローラーの現在の選択位置（カーソル）または末尾に「, 」（カンマ）をスマートに挿入
  static void insertComma(TextEditingController controller) {
    final text = controller.text;

    if (text.isEmpty) {
      return;
    }

    final selection = controller.selection;

    // 選択範囲がある場合（start != end）
    if (selection.isValid &&
        selection.start >= 0 &&
        selection.end >= 0 &&
        selection.start != selection.end) {
      final newText = text.replaceRange(selection.start, selection.end, ', ');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + 2),
      );
      return;
    }

    // キャレット位置（カーソル）がある場合、またはフォーカスがない場合
    final int cursorOffset = (selection.isValid && selection.start >= 0)
        ? selection.start
        : text.length;

    // カーソル直前の文字列
    final textBefore = text.substring(0, cursorOffset);
    final textAfter = text.substring(cursorOffset);

    // 直前がすでにカンマや読点（例: ", ", ",", "、", "，"）で終わっている場合
    if (textBefore.endsWith(', ')) {
      return;
    } else if (textBefore.endsWith(',') ||
        textBefore.endsWith('、') ||
        textBefore.endsWith('，')) {
      // カンマや読点はあるがスペースがない場合、きれいに ', ' に置き換える
      final replacedBefore = textBefore.replaceAll(RegExp(r'[,、，]$'), ', ');
      final newText = replacedBefore + textAfter;
      final newOffset = replacedBefore.length;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
      return;
    }

    // 直前がカンマでなければ、カーソル位置に ', ' を挿入
    final newText = '$textBefore, $textAfter';
    final newOffset = textBefore.length + 2;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
