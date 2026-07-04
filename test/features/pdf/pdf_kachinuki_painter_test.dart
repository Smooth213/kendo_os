import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/painters/pdf_kachinuki_painter.dart';

void main() {
  group('🛡️ PDF Kachinuki Painter Color Verification Tests', () {
    test(
      '1. Verify Red side uses PdfColors.red700 and White side uses PdfColors.black',
      () {
        final ttf = pw.Font.helvetica();
        final ttfBold = pw.Font.helveticaBold();

        final mockMatches = [
          const MatchModel(
            id: 'match_1',
            matchType: 'individual',
            redName: 'A道場:赤代表',
            whiteName: 'B道場:白代表',
            status: 'finished',
            redScore: 1,
            whiteScore: 0,
          ),
        ];

        final widget = PdfKachinukiPainter.build(
          'テストグループ',
          mockMatches,
          ttf,
          ttfBold,
        );

        expect(widget, isA<pw.Column>());
        final column = widget as pw.Column;

        // The child at index 0 is pw.Text (Title)
        // The child at index 1 is pw.SizedBox (Spacing)
        // The child at index 2 is pw.FittedBox (Bracket)
        expect(column.children[2], isA<pw.FittedBox>());
        final fittedBox = column.children[2] as pw.FittedBox;

        // FittedBox child is Container
        expect(fittedBox.child, isA<pw.Container>());
        final container = fittedBox.child as pw.Container;

        // Container child is Stack
        expect(container.child, isA<pw.Stack>());
        final stack = container.child as pw.Stack;

        // Find all vertText Positioned widgets and verify text style colors
        final positionedWidgets = stack.children
            .whereType<pw.Positioned>()
            .toList();
        expect(positionedWidgets.isNotEmpty, isTrue);

        bool foundRedTeam = false;
        bool foundWhiteTeam = false;
        bool foundRedPlayer = false;
        bool foundWhitePlayer = false;

        for (var pos in positionedWidgets) {
          if (pos.child is pw.Container) {
            final posContainer = pos.child as pw.Container;
            if (posContainer.child is pw.Center) {
              final center = posContainer.child as pw.Center;
              if (center.child is pw.Column) {
                final textColumn = center.child as pw.Column;
                for (var child in textColumn.children) {
                  if (child is pw.Text) {
                    final text = child;
                    final textSpan = text.text as pw.TextSpan;
                    final textStyle = textSpan.style;
                    final textContent = textSpan.text;

                    if (textContent == 'A') {
                      // Part of 'A道場'
                      expect(textStyle?.color, equals(PdfColors.red700));
                      foundRedTeam = true;
                    }
                    if (textContent == 'B') {
                      // Part of 'B道場'
                      expect(textStyle?.color, equals(PdfColors.black));
                      foundWhiteTeam = true;
                    }
                    if (textContent == '赤') {
                      // Part of '赤代表'
                      expect(textStyle?.color, equals(PdfColors.red700));
                      foundRedPlayer = true;
                    }
                    if (textContent == '白') {
                      // Part of '白代表'
                      expect(textStyle?.color, equals(PdfColors.black));
                      foundWhitePlayer = true;
                    }
                  }
                }
              }
            }
          }
        }

        expect(
          foundRedTeam,
          isTrue,
          reason: 'Red team name (A道場) should be rendered in red',
        );
        expect(
          foundWhiteTeam,
          isTrue,
          reason: 'White team name (B道場) should be rendered in black',
        );
        expect(
          foundRedPlayer,
          isTrue,
          reason: 'Red player name (赤代表) should be rendered in red',
        );
        expect(
          foundWhitePlayer,
          isTrue,
          reason: 'White player name (白代表) should be rendered in black',
        );
      },
    );
  });
}
