import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_edit_dialog.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

void main() {
  group('TournamentEditDialog テスト', () {
    testWidgets('初期値（大会名、会場、メモ）が正常に描画されること', (tester) async {
      final tournament = TournamentModel(
        id: 't_001',
        organizationId: 'org_001',
        name: '全国剣道大会2026',
        venue: '日本武道館',
        date: DateTime(2026, 10, 15),
        notes: '開会式は9:00開始',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return TournamentEditDialog(
                    tournament: tournament,
                    ref: ref,
                    cardColor: AppKendoColors.pureWhite,
                    textColor: AppKendoColors.black,
                    subTextColor: AppKendoColors.grey,
                    borderColor: AppKendoColors.grey,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('大会情報の編集'), findsOneWidget);
      expect(find.text('全国剣道大会2026'), findsOneWidget);
      expect(find.text('日本武道館'), findsOneWidget);
      expect(find.text('開会式は9:00開始'), findsOneWidget);
      expect(find.text('2026年10月15日'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });
  });
}
