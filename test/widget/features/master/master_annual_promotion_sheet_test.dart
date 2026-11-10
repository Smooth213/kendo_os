import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/admin/presentation/components/master_annual_promotion_sheet.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/organization_graduation_type.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  final samplePlayers = [
    PlayerModel(
      id: 'p_elem6',
      lastName: '小学',
      firstName: '六郎',
      lastNameKana: 'ショウガク',
      firstNameKana: 'ロクロウ',
      grade: 6,
    ),
    PlayerModel(
      id: 'p_jh3_a',
      lastName: '卒業',
      firstName: '太郎',
      lastNameKana: 'ソツギョウ',
      firstNameKana: 'タロウ',
      grade: 9,
    ),
    PlayerModel(
      id: 'p_jh3_b',
      lastName: '残留',
      firstName: '花子',
      lastNameKana: 'ザンリュウ',
      firstNameKana: 'ハナコ',
      grade: 9,
    ),
    PlayerModel(
      id: 'p_adult',
      lastName: '指導',
      firstName: '先生',
      lastNameKana: 'シドウ',
      firstNameKana: 'センセイ',
      grade: 99,
    ),
  ];

  Widget buildTestApp({
    required OrganizationPromotionConfig config,
    required List<PlayerModel> players,
    required ExecuteAnnualPromotionCallback onExecute,
    DateTime? nowOverride,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    return ProviderScope(
      overrides: [
        playerListProvider.overrideWith((ref) => Stream.value(players)),
        organizationPromotionConfigProvider.overrideWith(
          (ref) => Stream.value(config),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: MasterAnnualPromotionSheet(
            onExecutePromotion: onExecute,
            nowOverride: nowOverride ?? DateTime(2027, 4, 1),
          ),
        ),
      ),
    );
  }

  group('[Widget] MasterAnnualPromotionSheet 新年度一括進級プレビュー・警告テスト', () {
    testWidgets('卒業対象リストと例外残留スイッチが正しく表示され、進級実行引数へ反映されること', (tester) async {
      OrganizationGraduationType? capturedType;
      Set<String>? capturedRetain;
      int? capturedGradYear;
      int? capturedPromoYear;

      await tester.pumpWidget(
        buildTestApp(
          config: const OrganizationPromotionConfig(
            name: 'テスト道場',
            graduationType: OrganizationGraduationType.juniorDojo,
          ),
          players: samplePlayers,
          onExecute:
              ({
                required graduationType,
                required retainPlayerIds,
                required graduationFiscalYear,
                required promotionFiscalYear,
              }) async {
                capturedType = graduationType;
                capturedRetain = retainPlayerIds;
                capturedGradYear = graduationFiscalYear;
                capturedPromoYear = promotionFiscalYear;
                return const AnnualPromotionSummary(
                  promotedCount: 2,
                  graduatedCount: 1,
                  unchangedCount: 1,
                );
              },
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('卒業対象の選手（2名）'), findsOneWidget);
      await tester.ensureVisible(find.text('卒業 太郎'));
      expect(find.text('卒業 太郎'), findsOneWidget);
      await tester.ensureVisible(find.text('残留 花子'));
      expect(find.text('残留 花子'), findsOneWidget);
      expect(
        find.text('進級予定：1名  /  卒業(OB/OG)：2名  /  一般(維持)：1名'),
        findsOneWidget,
      );

      // 残留 花子 のスイッチを ON にする
      await tester.tap(find.text('残留 花子'));
      await tester.safePumpAndSettle();

      // ヘッダー位置へ戻してサマリー更新を確認
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.safePumpAndSettle();

      expect(
        find.text('進級予定：2名  /  卒業(OB/OG)：1名  /  一般(維持)：1名'),
        findsOneWidget,
      );

      await tester.tap(find.text('一括進級を実行'));
      await tester.safePumpAndSettle();

      expect(find.text('一括進級の最終確認'), findsOneWidget);
      await tester.tap(find.text('実行する'));
      await tester.safePumpAndSettle();

      expect(capturedType, equals(OrganizationGraduationType.juniorDojo));
      expect(capturedRetain, equals({'p_jh3_b'}));
      expect(capturedGradYear, equals(2026));
      expect(capturedPromoYear, equals(2027));
    });

    testWidgets('同年度すでに一括進級済みの場合に二重進級警告バナーと再実行確認ダイアログが表示されること', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          config: OrganizationPromotionConfig(
            name: 'テスト道場',
            graduationType: OrganizationGraduationType.juniorDojo,
            lastPromotedFiscalYear: 2027,
            lastPromotedAt: DateTime(2027, 4, 1),
          ),
          players: samplePlayers,
          onExecute:
              ({
                required graduationType,
                required retainPlayerIds,
                required graduationFiscalYear,
                required promotionFiscalYear,
              }) async => const AnnualPromotionSummary(
                promotedCount: 1,
                graduatedCount: 2,
                unchangedCount: 1,
              ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(
        find.textContaining('2027年度の一括進級は 2027/04/01 に実行済みです'),
        findsOneWidget,
      );
      expect(find.text('再実行を確認'), findsOneWidget);

      await tester.tap(find.text('再実行を確認'));
      await tester.safePumpAndSettle();

      expect(find.text('今年度は進級実行済みです'), findsOneWidget);
      expect(find.text('理解して再実行'), findsOneWidget);
    });
  });
}
