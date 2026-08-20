import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 オーダー設定画面 予測変換（サジェスト）と手入力を両立するチーム名入力フィールド
class OrderSetupTeamAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final String labelText;
  final String hintText;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final Color primaryAccent;
  final bool isDark;

  const OrderSetupTeamAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.labelText,
    required this.hintText,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.primaryAccent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (!focusNode.hasFocus) {
          return const Iterable<String>.empty();
        }
        if (textEditingValue.text.isEmpty) {
          return suggestions;
        }
        return const Iterable<String>.empty();
      },
      fieldViewBuilder:
          (context, fieldController, textFieldFocusNode, onFieldSubmitted) {
            return AppTextField(
              controller: fieldController,
              focusNode: textFieldFocusNode,
              onTap: () {
                if (fieldController.text.isEmpty) {
                  // ★ 1回目のタップ時にフォーカスが確実に当たるのを待つため、フレーム描画後に実行する
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final currentVal = fieldController.value;
                    fieldController.value = const TextEditingValue(text: ' ');
                    fieldController.value = currentVal;
                  });
                }
              },
              onChanged: (text) {},
              style: TextStyle(
                color: textColor,
                fontWeight: AppFontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(color: subTextColor),
                hintText: hintText,
                hintStyle: TextStyle(color: subTextColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: borderColor),
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: primaryAccent),
                ),
                prefixIcon: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF607D8B),
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppKendoColors.grey,
                ), // ▼アイコン
                fillColor: fillColor,
                filled: true,
                isDense: true,
              ),
            );
          },
      // 浮かび上がる候補リストのデザイン
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: AppRadius.medium,
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
            child: ConstrainedBox(
              // 幅を画面に合わせる
              constraints: BoxConstraints(
                maxHeight: 250,
                maxWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.add_circle_outline,
                      color: primaryAccent,
                      size: 18,
                    ),
                    onTap: () {
                      onSelected(option); // 選んだら入力完了
                      FocusScope.of(
                        context,
                      ).unfocus(); // ★ フォーカスを外してサジェストとキーボードをスッと消す
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
