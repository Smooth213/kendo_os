import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_edit_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('🛡️ 【第6条 ガバナンス監査】大会情報編集UI ドックボトムシート統合 ＆ 旧ダイアログ排除規約', () {
    final libDir = Directory('lib');

    test(
      'Rule 1: [静的スキャン] 旧来の TournamentEditDialog クラスおよびファイルが lib/ 配下に0件であること',
      () {
        final violations = <String>[];
        final files = libDir.listSync(recursive: true).whereType<File>();

        for (final file in files) {
          if (!file.path.endsWith('.dart')) continue;

          if (file.path.endsWith('tournament_edit_dialog.dart')) {
            violations.add('旧ダイアログファイルが存在します: ${file.path}');
          }

          final content = file.readAsStringSync();
          if (content.contains('TournamentEditDialog')) {
            violations.add('旧ダイアログへの参照が検出されました: ${file.path}');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '旧来の TournamentEditDialog が検出されました。'
              '大会情報の編集は TournamentEditBottomSheet に統一してください。\n'
              '違反一覧:\n${violations.join('\n')}',
        );
      },
    );

    test(
      'Rule 2: [静的スキャン] tournament_header_card.dart において TournamentEditBottomSheet.show が直接呼び出されていること',
      () {
        final headerCardFile = File(
          'lib/features/tournament/presentation/operate/components/home/tournament_header_card.dart',
        );
        expect(headerCardFile.existsSync(), isTrue);

        final content = headerCardFile.readAsStringSync();
        expect(
          content.contains('TournamentEditBottomSheet.show('),
          isTrue,
          reason:
              'tournament_header_card.dart は TournamentEditBottomSheet.show(...) を呼び出す必要があります。',
        );
        expect(
          content.contains('TournamentEditDialog'),
          isFalse,
          reason:
              'tournament_header_card.dart に TournamentEditDialog を含めることは禁止されています。',
        );
      },
    );

    testWidgets(
      'Rule 3: [動的規約] TournamentEditBottomSheet の可変シートサイズがドック仕様（0.58〜0.95）に適合していること',
      (tester) async {
        final tournament = TournamentModel(
          id: 'gov_t01',
          organizationId: 'org_001',
          name: 'ガバナンス検証大会',
          date: DateTime(2026, 10, 1),
          venue: '日本武道館',
          notes: 'メモ',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TournamentEditBottomSheet(tournament: tournament),
              ),
            ),
          ),
        );

        final sheetFinder = find.byType(DraggableScrollableSheet);
        expect(sheetFinder, findsOneWidget);

        final sheet = tester.widget<DraggableScrollableSheet>(sheetFinder);
        expect(
          sheet.initialChildSize,
          equals(0.58),
          reason: '初期サイズはドック規格の 0.58 である必要があります',
        );
        expect(
          sheet.maxChildSize,
          equals(0.95),
          reason: '最大サイズはドック規格の 0.95 である必要があります',
        );
        expect(
          sheet.minChildSize,
          lessThanOrEqualTo(0.40),
          reason: '最小サイズは 0.40 以下である必要があります',
        );
      },
    );

    test(
      'Rule 4: [静的スキャン] tournament_edit_bottom_sheet.dart において複数行メモとキーボード追従が実装されていること',
      () {
        final sheetFile = File(
          'lib/features/tournament/presentation/operate/components/home/tournament_edit_bottom_sheet.dart',
        );
        expect(sheetFile.existsSync(), isTrue);

        final content = sheetFile.readAsStringSync();

        // viewInsets.bottom によるキーボード追従
        expect(
          content.contains('MediaQuery.of(context).viewInsets.bottom'),
          isTrue,
          reason:
              'tournament_edit_bottom_sheet.dart はキーボード追従のため MediaQuery.of(context).viewInsets.bottom を考慮する必要があります。',
        );

        // メモ欄の複数行指定
        expect(
          content.contains('minLines: 4'),
          isTrue,
          reason: 'メモ欄は広々と推敲できるよう minLines: 4 以上である必要があります。',
        );
        expect(
          content.contains('keyboardType: TextInputType.multiline'),
          isTrue,
          reason: 'メモ欄は multiline である必要があります。',
        );
      },
    );
  });
}
