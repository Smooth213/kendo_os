import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Governance] 試合会場・試合順Picker及び運営メモ隔離ガバナンス規約', () {
    test(
      '試合作成・編集・形式設定画面でMatchCourtSlotPickerとMatchPrivateNoteAccordionが統一使用されていること',
      () {
        final targetFiles = [
          'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_heading_and_note_section.dart',
          'lib/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart',
          'lib/features/tournament/presentation/operate/components/new_match/new_match_heading_notes_card.dart',
        ];

        for (final path in targetFiles) {
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: '$path が存在しません');

          final content = file.readAsStringSync();

          // 1. MatchCourtSlotPicker が使われていること
          expect(
            content.contains('MatchCourtSlotPicker'),
            isTrue,
            reason: '$path で MatchCourtSlotPicker が使用されていません',
          );

          // 2. MatchPrivateNoteAccordion が使われていること
          expect(
            content.contains('MatchPrivateNoteAccordion'),
            isTrue,
            reason: '$path で MatchPrivateNoteAccordion が使用されていません',
          );
        }
      },
    );

    test('lib配下のすべての試合作成編集関連ファイルに旧仕様の直接文字列組み立てUIが残存していないこと', () {
      final operateDir = Directory(
        'lib/features/tournament/presentation/operate',
      );
      expect(operateDir.existsSync(), isTrue);

      final dartFiles = operateDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where(
            (f) =>
                !f.path.contains('match_heading_format_helper.dart') &&
                !f.path.contains('match_court_slot_picker.dart'),
          )
          .toList();

      for (final file in dartFiles) {
        final content = file.readAsStringSync();

        // 旧仕様: '第$court試合場, ${order}試合目' のようなハードコードされた見出し合成
        final hasLegacyFormat = RegExp(
          r"['\x22]第\s*[\$]\{?.*\}?\s*試合場.*試合目",
        ).hasMatch(content);
        expect(
          hasLegacyFormat,
          isFalse,
          reason:
              '${file.path} に旧仕様の見出し直接合成が残存しています。MatchHeadingFormatHelper を使用してください',
        );
      }
    });

    test('lib配下のビュアーおよびPDF全画面で内部特記事項の生note直接描画が0件であること', () {
      final targetDirs = [
        Directory('lib/features/viewer'),
        Directory('lib/features/pdf'),
      ];

      final violations = <String>[];

      for (final dir in targetDirs) {
        if (!dir.existsSync()) continue;
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in files) {
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];

            // Text(..., match.note, ...) や Text(m.note) などの生note直接描画パターンを検出
            // ただし extractPublicHeading や RegExp でサニタイズされている行は除外
            final rawNoteMatch = RegExp(
              r'Text\s*\(\s*(\w+\.note)\s*[,)]',
            ).firstMatch(line);
            if (rawNoteMatch != null) {
              final noteExpr = rawNoteMatch.group(1);
              final isSanitized =
                  line.contains('extractPublicHeading') ||
                  line.contains('replaceAll') ||
                  line.contains('split');
              if (!isSanitized) {
                violations.add(
                  '${file.path}:${i + 1} -> 生の $noteExpr が直接 Text() に渡されています',
                );
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '外部出力（ビュアー/PDF）に内部特記事項の生note直接描画が残存しています:\n${violations.join('\n')}',
      );
    });

    test('運営メモの表示許可コンポーネントが大会ホームとチーム試合状況のみに限定されていること', () {
      final libDir = Directory('lib');
      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      // 許可されたファイルリスト
      final allowedFiles = [
        // 定義元
        'lib/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart',
        'lib/features/tournament/presentation/operate/components/common/match_private_note_accordion.dart',
        'lib/features/tournament/presentation/operate/components/cards/match_card_note_row.dart',
        // 許可された運営画面
        'lib/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart', // 大会ホームのカード
        'lib/features/tournament/presentation/operate/components/court_status/team_status_card.dart', // チーム試合状況
        // 入力・編集画面（アコーディオン内での編集値保持）
        'lib/features/tournament/presentation/operate/components/new_match/new_match_heading_notes_card.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_heading_and_note_section.dart',
        'lib/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart',
        // 画面全体の一括保存ヘルパー（必要時）
        'lib/features/tournament/presentation/operate/screens/setup_match_format_screen.dart',
      ];

      final violations = <String>[];

      for (final file in files) {
        final relativePath = file.path.replaceAll('\\', '/');
        if (allowedFiles.any((allowed) => relativePath.endsWith(allowed))) {
          continue;
        }

        final content = file.readAsStringSync();
        if (content.contains('extractPrivateNote')) {
          violations.add('$relativePath -> extractPrivateNote が無許可画面で使用されています');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '運営メモ（extractPrivateNote）が許可外の画面で使用されています:\n${violations.join('\n')}',
      );
    });
  });
}
