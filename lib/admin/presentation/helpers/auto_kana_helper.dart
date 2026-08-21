import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

/// 漢字入力からよみがな（ひらがな）を自動抽出・推測して連動設定するヘルパー
class AutoKanaHelper {
  /// nameController の入力変更を監視し、kanaController に自動反映
  static void setupAutoKana(
    TextEditingController nameCtrl,
    TextEditingController kanaCtrl,
  ) {
    String lastText = nameCtrl.text;
    String lastValidKana = '';
    DateTime lastClearedTime = DateTime.fromMillisecondsSinceEpoch(0);

    String keepKanaOnly(String s) {
      return s.replaceAll(RegExp(r'[^ぁ-んァ-ヶー]'), '');
    }

    String keepKanjiOnly(String s) {
      return s.replaceAll(RegExp(r'[^一-龠々]'), '');
    }

    void processChange(String fromText, String toText) {
      if (toText.isEmpty) {
        if (kanaCtrl.text.isNotEmpty) {
          lastValidKana = kanaCtrl.text;
          lastClearedTime = clock.now();
        }
        kanaCtrl.text = '';
        return;
      }

      final lastKana = keepKanaOnly(fromText);
      final currentKana = keepKanaOnly(toText);

      final lastKanjiCount = keepKanjiOnly(fromText).length;
      final currentKanjiCount = keepKanjiOnly(toText).length;

      // 1. かな文字が増加した場合
      if (currentKana.startsWith(lastKana) &&
          currentKana.length > lastKana.length) {
        final added = currentKana.substring(lastKana.length);
        kanaCtrl.text = kanaCtrl.text + added;
        lastValidKana = kanaCtrl.text;
      }
      // 2. 文字が純粋に削除された場合
      else if (toText.length < fromText.length &&
          currentKanjiCount <= lastKanjiCount) {
        final diffLen = fromText.length - toText.length;
        if (kanaCtrl.text.length >= diffLen) {
          kanaCtrl.text = kanaCtrl.text.substring(
            0,
            kanaCtrl.text.length - diffLen,
          );
        } else {
          kanaCtrl.text = '';
        }
        lastValidKana = kanaCtrl.text;
      }
      // 3. 全クリアやひらがなのみのコピペ時のフォールバック
      else if (RegExp(r'^[ぁ-んァ-ヶーa-zA-Z0-9]*$').hasMatch(toText)) {
        kanaCtrl.text = toText;
        lastValidKana = kanaCtrl.text;
      }
      // 4. Web等でIME確定時の自己修復
      else if (kanaCtrl.text.isEmpty &&
          lastValidKana.isNotEmpty &&
          currentKanjiCount > 0 &&
          clock.now().difference(lastClearedTime).inMilliseconds < 150) {
        kanaCtrl.text = lastValidKana;
      }
    }

    nameCtrl.addListener(() {
      final text = nameCtrl.text;
      if (text == lastText) return;

      Future.microtask(() {
        final finalText = nameCtrl.text;
        if (finalText == lastText) return;

        processChange(lastText, finalText);
        lastText = finalText;
      });
    });
  }
}
