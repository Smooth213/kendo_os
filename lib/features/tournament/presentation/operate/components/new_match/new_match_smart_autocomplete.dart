import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 新規試合作成画面における選手・チーム名スマートオートコンプリート入力欄
class NewMatchSmartAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final String labelText;
  final bool isDark;

  const NewMatchSmartAutocomplete({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.labelText,
    required this.isDark,
  });

  @override
  State<NewMatchSmartAutocomplete> createState() =>
      _NewMatchSmartAutocompleteState();
}

class _NewMatchSmartAutocompleteState extends State<NewMatchSmartAutocomplete> {
  bool _isTapped = false; // ボトムシート的な動きをさせるためのローカルフラグ

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: widget.focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        // 確実な制御：フォーカスが無い、またはタップされていない時は絶対に出さない
        if (!widget.focusNode.hasFocus || !_isTapped) {
          return const Iterable<String>.empty();
        }
        final query = textEditingValue.text.trim();
        // 空欄の場合は全件表示、入力があれば絞り込み
        if (query.isEmpty) {
          return widget.suggestions;
        }
        return widget.suggestions.where((s) => s.contains(query));
      },
      fieldViewBuilder:
          (context, fieldController, textFieldFocusNode, onFieldSubmitted) {
            return AppTextField(
              controller: fieldController,
              focusNode: textFieldFocusNode,
              onTap: () {
                setState(() {
                  _isTapped = true;
                });
                // 魔法のハック：1文字空欄を入れて戻すことで、Flutterのキャッシュを貫通して強制的にリストを描画する
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final currentVal = fieldController.value;
                  fieldController.value = const TextEditingValue(text: ' ');
                  fieldController.value = currentVal;
                });
              },
              onChanged: (text) {
                setState(() {
                  _isTapped = true;
                });
              },
              onSubmitted: (text) {
                setState(() {
                  _isTapped = false;
                });
                onFieldSubmitted();
              },
              style: TextStyle(color: context.appColors.textColor),
              decoration: InputDecoration(
                labelText: widget.labelText,
                prefixIcon: const Icon(
                  Icons.person,
                  color: AppKendoColors.blueGrey,
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppKendoColors.grey,
                ),
                border: OutlineInputBorder(borderRadius: AppRadius.small),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? const Color(0xFF38383A)
                        : const Color(0x8A000000),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: AppKendoColors.redAccent),
                ),
                filled: true,
                fillColor: widget.isDark
                    ? const Color(0xFF1C1C1E)
                    : context.appColors.inputBackground,
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: AppRadius.medium,
            color: widget.isDark
                ? const Color(0xFF2C2C2E)
                : context.appColors.cardBackground,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 250,
                // 親がmaxWidth:600なので、画面幅に応じて適切に制限
                maxWidth: MediaQuery.of(context).size.width > 600
                    ? 568
                    : MediaQuery.of(context).size.width - 32,
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
                        color: context.appColors.textColor,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.add_circle_outline,
                      color: AppKendoColors.redAccent,
                      size: 18,
                    ),
                    onTap: () {
                      onSelected(option);
                      setState(() {
                        _isTapped = false;
                      }); // 選択完了後にフラグを下げてリストを隠す
                      FocusScope.of(context).unfocus(); // キーボードも隠す
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
