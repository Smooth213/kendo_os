import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/painters/pdf_kachinuki_painter.dart';

void main() {
  group('[Unit] PDF Kachinuki Painter Color 検証 テスト', () {
    test(
      'Verify Red team uses PdfColors.red700 and Red player name uses PdfColors.blackであること',
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

        expect(widget, isA<pw.Inseparable>());
        final inseparable = widget as pw.Inseparable;
        expect(inseparable.canSpan, isFalse, reason: 'タイトルとスコア表が改ページで分割されないこと');
        expect(inseparable.child, isA<pw.Column>());
        final column = inseparable.child as pw.Column;

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

        // Find all Positioned widgets and verify text style colors
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
              if (center.child is pw.FittedBox) {
                final fb = center.child as pw.FittedBox;
                pw.Text? teamTextWidget;
                if (fb.child is pw.Text) {
                  teamTextWidget = fb.child as pw.Text;
                } else if (fb.child is pw.SizedBox) {
                  final sb = fb.child as pw.SizedBox;
                  if (sb.child is pw.Text) {
                    teamTextWidget = sb.child as pw.Text;
                  }
                }

                if (teamTextWidget != null) {
                  // 横書きチーム名
                  final textSpan = teamTextWidget.text as pw.TextSpan;
                  final textContent = textSpan.text;
                  final textStyle = textSpan.style;
                  if (textContent == 'A道場') {
                    expect(textStyle?.color, equals(PdfColors.red700));
                    foundRedTeam = true;
                  }
                  if (textContent == 'B道場') {
                    expect(textStyle?.color, equals(PdfColors.black));
                    foundWhiteTeam = true;
                  }
                } else if (fb.child is pw.Row) {
                  // 縦書き選手名（Row: 苗字Text + 頭文字Text）
                  final textRow = fb.child as pw.Row;
                  for (var child in textRow.children) {
                    if (child is pw.Text) {
                      final text = child;
                      final textSpan = text.text as pw.TextSpan;
                      final textStyle = textSpan.style;
                      final textContent = textSpan.text ?? '';

                      if (textContent.contains('赤')) {
                        expect(textStyle?.color, equals(PdfColors.black));
                        foundRedPlayer = true;
                      }
                      if (textContent.contains('白')) {
                        expect(textStyle?.color, equals(PdfColors.black));
                        foundWhitePlayer = true;
                      }
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
          reason: 'Red player name (赤代表) should be rendered in black',
        );
        expect(
          foundWhitePlayer,
          isTrue,
          reason: 'White player name (白代表) should be rendered in black',
        );
      },
    );

    test('長いチーム名（昇龍館一福道場A）でも横書き全文字が生成されFittedBoxで枠内に収まること', () async {
      final ttf = pw.Font.helvetica();
      final ttfBold = pw.Font.helveticaBold();

      const longRedTeam = '昇龍館一福道場A';
      const longWhiteTeam = '道上剣友会A';

      final mockMatches = [
        const MatchModel(
          id: 'match_long_1',
          matchType: 'individual',
          redName: '$longRedTeam:新山',
          whiteName: '$longWhiteTeam:恵木',
          status: 'finished',
          redScore: 1,
          whiteScore: 0,
        ),
      ];

      final widget = PdfKachinukiPainter.build(
        '中学生の部',
        mockMatches,
        ttf,
        ttfBold,
      );

      expect(widget, isA<pw.Inseparable>());
      final inseparable = widget as pw.Inseparable;
      expect(inseparable.canSpan, isFalse, reason: 'タイトルとスコア表が改ページで分割されないこと');
      expect(inseparable.child, isA<pw.Column>());
      final column = inseparable.child as pw.Column;
      final fittedBox = column.children[2] as pw.FittedBox;
      final container = fittedBox.child as pw.Container;
      final stack = container.child as pw.Stack;

      final positionedWidgets = stack.children
          .whereType<pw.Positioned>()
          .toList();

      String foundRedTeamText = '';
      String foundWhiteTeamText = '';

      for (var pos in positionedWidgets) {
        if (pos.child is pw.Container) {
          final posContainer = pos.child as pw.Container;
          if (posContainer.child is pw.Center) {
            final center = posContainer.child as pw.Center;
            if (center.child is pw.FittedBox) {
              final fb = center.child as pw.FittedBox;
              expect(fb.fit, equals(pw.BoxFit.scaleDown));
              pw.Text? teamTextWidget;
              if (fb.child is pw.Text) {
                teamTextWidget = fb.child as pw.Text;
              } else if (fb.child is pw.SizedBox) {
                final sb = fb.child as pw.SizedBox;
                if (sb.child is pw.Text) {
                  teamTextWidget = sb.child as pw.Text;
                }
              }
              if (teamTextWidget != null) {
                final span = teamTextWidget.text as pw.TextSpan;
                final textContent = span.text ?? '';
                if (textContent == longRedTeam) {
                  foundRedTeamText = textContent;
                } else if (textContent == longWhiteTeam) {
                  foundWhiteTeamText = textContent;
                }
              }
            }
          }
        }
      }

      // 横書きで欠落なく含まれていること
      expect(
        foundRedTeamText,
        equals('昇龍館一福道場A'),
        reason: '「昇龍館一福道場A」まで欠落せず全文字が含まれていること',
      );
      expect(
        foundWhiteTeamText,
        equals('道上剣友会A'),
        reason: '「道上剣友会A」まで欠落せず全文字が含まれていること',
      );

      // PDF文書に組み込んで正常にバイト列が生成されること
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(pageFormat: PdfPageFormat.a4, build: (context) => widget),
      );
      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });

    test('改ページ発生時にタイトルとスコア表が分断されず同一ページに保持されること', () async {
      final ttf = pw.Font.helvetica();
      final ttfBold = pw.Font.helveticaBold();

      final mockMatches = [
        const MatchModel(
          id: 'match_page_break',
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

      // Inseparable であることを確認
      expect(widget, isA<pw.Inseparable>());
      final inseparable = widget as pw.Inseparable;
      expect(inseparable.canSpan, isFalse);

      // MultiPage で 1ページ目に入り切らない高さの場合、タイトルだけ残らず丸ごと次ページに送られることを確認
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: const PdfPageFormat(500, 250),
          margin: pw.EdgeInsets.zero,
          build: (context) => [
            // 1ページ目の大半を埋めるダミー要素（タイトルだけなら収まるが全体は収まらないスペースを残す）
            pw.SizedBox(height: 120),
            widget, // 全体で約175ptのため、120 + 175 = 295 > 250 となり、2ページ目へ送られる
          ],
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(pdf.document.pdfPageList.pages.length, equals(2));
    });

    test('1ページ（A4）に3試合が改ページされず確実に収まること', () async {
      final ttf = pw.Font.helvetica();
      final ttfBold = pw.Font.helveticaBold();

      final match1 = [
        const MatchModel(
          id: 'm1',
          matchType: 'individual',
          redName: '道場A:選手1',
          whiteName: '道場B:選手1',
          status: 'finished',
          redScore: 1,
          whiteScore: 0,
        ),
      ];
      final match2 = [
        const MatchModel(
          id: 'm2',
          matchType: 'individual',
          redName: '道場C:選手1',
          whiteName: '道場D:選手1',
          status: 'finished',
          redScore: 0,
          whiteScore: 1,
        ),
      ];
      final match3 = [
        const MatchModel(
          id: 'm3',
          matchType: 'individual',
          redName: '道場E:選手1',
          whiteName: '道場F:選手1',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
        ),
      ];

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            PdfKachinukiPainter.build('試合1', match1, ttf, ttfBold),
            pw.SizedBox(height: 10),
            PdfKachinukiPainter.build('試合2', match2, ttf, ttfBold),
            pw.SizedBox(height: 10),
            PdfKachinukiPainter.build('試合3', match3, ttf, ttfBold),
          ],
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      // 3試合が改ページされずに1ページに収まっていること
      expect(
        pdf.document.pdfPageList.pages.length,
        equals(1),
        reason: 'A4用紙1ページに3試合すべてが収まること',
      );
    });

    test('通常団体戦に準拠し、名字のみ縦書き表示＆同姓選手時の頭文字表示が正しく機能すること', () async {
      final ttf = pw.Font.helvetica();
      final ttfBold = pw.Font.helveticaBold();

      final mockMatches = [
        const MatchModel(
          id: 'm_same_1',
          matchType: 'individual',
          redName: 'A道場:田中 太郎',
          whiteName: 'B道場:佐藤 一郎',
          status: 'finished',
          redScore: 0,
          whiteScore: 1,
        ),
        const MatchModel(
          id: 'm_same_2',
          matchType: 'individual',
          redName: 'A道場:田中 次郎',
          whiteName: 'B道場:佐藤 一郎',
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

      final inseparable = widget as pw.Inseparable;
      final column = inseparable.child as pw.Column;
      final fittedBox = column.children[2] as pw.FittedBox;
      final container = fittedBox.child as pw.Container;
      final stack = container.child as pw.Stack;

      final positionedWidgets = stack.children
          .whereType<pw.Positioned>()
          .toList();

      bool foundTanakaTaro = false;
      bool foundTanakaJiro = false;
      bool foundSatoIchiro = false;

      for (var pos in positionedWidgets) {
        if (pos.child is pw.Container) {
          final posContainer = pos.child as pw.Container;
          if (posContainer.child is pw.Center) {
            final center = posContainer.child as pw.Center;
            if (center.child is pw.FittedBox) {
              final fb = center.child as pw.FittedBox;
              if (fb.child is pw.Row) {
                final textRow = fb.child as pw.Row;
                String lastName = '';
                String initial = '';

                for (var child in textRow.children) {
                  if (child is pw.Text) {
                    final span = child.text as pw.TextSpan;
                    lastName = span.text ?? '';
                  } else if (child is pw.Padding) {
                    final paddingChild = child.child;
                    if (paddingChild is pw.Text) {
                      final span = paddingChild.text as pw.TextSpan;
                      initial = span.text ?? '';
                    }
                  }
                }

                if (lastName == '田\n中' && initial == '太') {
                  foundTanakaTaro = true;
                }
                if (lastName == '田\n中' && initial == '次') {
                  foundTanakaJiro = true;
                }
                if (lastName == '佐\n藤') {
                  // 佐藤は1人だけなのでinitialは空
                  if (initial.isEmpty) {
                    foundSatoIchiro = true;
                  }
                }
              }
            }
          }
        }
      }

      expect(
        foundTanakaTaro,
        isTrue,
        reason: '同姓「田中 太郎」は名字「田\\n中」と頭文字「太」が表示されること',
      );
      expect(
        foundTanakaJiro,
        isTrue,
        reason: '同姓「田中 次郎」は名字「田\\n中」と頭文字「次」が表示されること',
      );
      expect(
        foundSatoIchiro,
        isTrue,
        reason: '単独の「佐藤 一郎」は名字「佐\\n藤」のみが表示され頭文字は表示されないこと',
      );
    });
  });
}
