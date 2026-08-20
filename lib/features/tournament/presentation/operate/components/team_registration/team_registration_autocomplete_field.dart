import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 チーム登録画面 予測変換（サジェスト）と手入力を両立するチーム名入力フィールド
class TeamRegistrationAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final String labelText;
  final String hintText;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final bool isDark;

  const TeamRegistrationAutocompleteField({
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
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text;

        if (text.isEmpty) {
          return suggestions;
        }
        return suggestions.where((option) => option.contains(text));
      },
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: fieldController,
              focusNode: focusNode,
              style: TextStyle(
                color: textColor,
                fontWeight: AppFontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(
                  color: subTextColor,
                  fontWeight: AppFontWeight.bold,
                ),
                hintText: hintText,
                hintStyle: const TextStyle(color: AppKendoColors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide(color: borderColor),
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide(color: subTextColor, width: 2),
                ),
                prefixIcon: Icon(Icons.shield, color: subTextColor),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppKendoColors.grey,
                ),
                fillColor: fillColor,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: AppSpacing.lg,
                ),
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: AppRadius.medium,
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
            child: ConstrainedBox(
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
                      color: subTextColor,
                      size: 18,
                    ),
                    onTap: () {
                      onSelected(option);
                      FocusScope.of(
                        context,
                      ).unfocus(); // ★ タップ直後にキーボードとサジェストを隠す
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
