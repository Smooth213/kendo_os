import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🥋 KendoOS - 【第3層 視認性防衛】ツリー走査型コントラスト自動検査ヘルパー
///
/// 画面テストの末尾で [expectValidThemeContrast] を 1 行呼び出すだけで、
/// レンダリングされているすべてのテキストと背後にある背景色を自動走査し、
/// WCAG 2.1 基準（コントラスト比 4.5:1 / 3.0:1）を下回る不可視テキストを
/// 1 件の漏れもなく即座に検知・FAIL します。
class ContrastTestHelper {
  /// WCAG 2.1 に基づく2色のコントラスト比を計算 (1.0 〜 21.0)
  static double calculateContrastRatio(Color foreground, Color background) {
    final double l1 = foreground.computeLuminance();
    final double l2 = background.computeLuminance();
    final double lighter = l1 > l2 ? l1 : l2;
    final double darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 指定された Element の祖先ツリーを遡り、有効な背景色を探索
  static Color findBackgroundColor(Element textElement) {
    Color? resolvedBackground;

    textElement.visitAncestorElements((ancestor) {
      final RenderObject? renderObject = ancestor.renderObject;
      if (renderObject is RenderDecoratedBox) {
        final Decoration decoration = renderObject.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          if (decoration.color!.a > 0.05) {
            resolvedBackground = decoration.color;
            return false; // 探索終了
          }
        }
      } else if (renderObject is RenderPhysicalModel) {
        if (renderObject.color.a > 0.05) {
          resolvedBackground = renderObject.color;
          return false;
        }
      } else if (ancestor.widget is Material) {
        final material = ancestor.widget as Material;
        if (material.color != null && material.color!.a > 0.05) {
          resolvedBackground = material.color;
          return false;
        }
      } else if (ancestor.widget is Scaffold) {
        final scaffold = ancestor.widget as Scaffold;
        if (scaffold.backgroundColor != null &&
            scaffold.backgroundColor!.a > 0.05) {
          resolvedBackground = scaffold.backgroundColor;
          return false;
        }
      }
      return true; // さらに親へ遡る
    });

    if (resolvedBackground != null) {
      return resolvedBackground!;
    }

    // フォールバック: テーマの scaffoldBackgroundColor または canvasColor
    final theme = Theme.of(textElement);
    return theme.scaffoldBackgroundColor;
  }
}

/// 画面内の全テキスト要素の視認性コントラスト比を自動検証
Future<void> expectValidThemeContrast(
  WidgetTester tester, {
  double minRatio = 4.5,
  double minLargeTextRatio = 3.0,
  List<String> ignoreTexts = const [],
}) async {
  final List<String> violations = [];

  for (final element in tester.allElements) {
    final renderObject = element.renderObject;
    if (renderObject is RenderParagraph) {
      final TextSpan? textSpan = renderObject.text as TextSpan?;
      if (textSpan == null) continue;

      final String plainText = textSpan.toPlainText().trim();
      if (plainText.isEmpty) continue;
      if (ignoreTexts.contains(plainText)) continue;

      // 文字色の解決
      Color? textColor = textSpan.style?.color;
      double? fontSize = textSpan.style?.fontSize;

      if (textColor == null) {
        final defaultTextStyle = DefaultTextStyle.of(element);
        textColor = defaultTextStyle.style.color;
        fontSize ??= defaultTextStyle.style.fontSize;
      }

      if (textColor == null || textColor.a < 0.05) {
        continue; // 透明文字は意図的な非表示とみなす
      }

      // 背景色の解決
      final Color backgroundColor = ContrastTestHelper.findBackgroundColor(
        element,
      );

      // コントラスト比の計算
      final double ratio = ContrastTestHelper.calculateContrastRatio(
        textColor,
        backgroundColor,
      );

      // 大きな文字 (18pt 以上、または 14pt 以上の太字) は 3.0:1、通常は 4.5:1
      final bool isLargeText =
          (fontSize != null && fontSize >= 18.0) ||
          (fontSize != null &&
              fontSize >= 14.0 &&
              (textSpan.style?.fontWeight == FontWeight.bold ||
                  textSpan.style?.fontWeight == FontWeight.w700));

      final double requiredRatio = isLargeText ? minLargeTextRatio : minRatio;

      if (ratio < requiredRatio) {
        violations.add(
          "テキスト: '$plainText' (比率: ${ratio.toStringAsFixed(2)}:1 < 基準 $requiredRatio:1, "
          "文字色: 0x${textColor.toARGB32().toRadixString(16).padLeft(8, '0')}, "
          "背景色: 0x${backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0')})",
        );
      }
    }
  }

  if (violations.isNotEmpty) {
    final details = violations.map((v) => '  ❌ $v').join('\n');
    fail('🚨 【視認性不良検知】画面内にコントラスト不足のテキストが検出されました (WCAG 2.1 違反):\n$details');
  }
}

/// 🥋 背景色（またはグラデーション）とアイコン色のコントラスト比を検証するカスタムマッチャー
class HasValidContrastMatcher extends Matcher {
  final List<Color> backgroundColors;
  final double minRatio;

  const HasValidContrastMatcher({
    required this.backgroundColors,
    this.minRatio = 3.0,
  });

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Color) return false;
    for (final bg in backgroundColors) {
      final ratio = ContrastTestHelper.calculateContrastRatio(item, bg);
      if (ratio < minRatio) {
        matchState['failedBg'] = bg;
        matchState['ratio'] = ratio;
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('コントラスト比が $minRatio:1 以上の視認性を満たすアイコン色');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final failedBg = matchState['failedBg'] as Color?;
    final ratio = matchState['ratio'] as double?;
    return mismatchDescription.add(
      '比率が ${ratio?.toStringAsFixed(2)}:1 で基準 ($minRatio:1) 未満 '
      '(前景色: $item, 背景色: $failedBg)',
    );
  }
}

/// 背景（グラデーションまたは単色）と前景色が [minRatio] 以上の視認性比率を持つことをアサートするマッチャー
Matcher hasValidContrastWith(dynamic background, {double minRatio = 3.0}) {
  final List<Color> bgColors = (background is List<Color>)
      ? background
      : [background as Color];
  return HasValidContrastMatcher(
    backgroundColors: bgColors,
    minRatio: minRatio,
  );
}

/// ドック等の主要フローティングコンポーネントに対するコントラスト比を厳格検証
void expectFloatingDockContrast({
  required Color iconColor,
  required List<Color> backgroundColors,
  double minRatio = 3.0,
  String label = 'フローティングドック',
}) {
  expect(
    iconColor,
    hasValidContrastWith(backgroundColors, minRatio: minRatio),
    reason: '🚨 【視認性不良検知】$label のアイコンと背景のコントラスト比が不足しています (WCAG 基準 $minRatio:1)',
  );
}
