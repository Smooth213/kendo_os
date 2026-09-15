import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('🔋 【Plan 2 ガバナンス監査】端末低負荷・発熱ゼロ・省バッテリー・省メモリ 永続保証テスト', () {
    testWidgets(
      '1. [LiquidBackground] isAnimated: false で静止モードとなり AnimatedBuilder をバイパスすること',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: LiquidBackground(
                isAnimated: false,
                child: Text('Static Match Screen'),
              ),
            ),
          ),
        );

        expect(find.text('Static Match Screen'), findsOneWidget);
        // LiquidBackground 内で AnimatedBuilder が使われていないこと（静止描画バイパス）
        expect(
          find.descendant(
            of: find.byType(LiquidBackground),
            matching: find.byType(AnimatedBuilder),
          ),
          findsNothing,
        );
        // RepaintBoundary で保護されていること
        expect(find.byType(RepaintBoundary), findsWidgets);
      },
    );

    test(
      '2. [タイマー更新適正化] getTickIntervalForMatch は通常試合で1000ms、代表戦・延長戦で100msを返却すること',
      () {
        final governor = ThermalPowerGovernor();

        // 通常モード: 通常試合は1000ms（90%間引き）
        expect(
          governor.getTickIntervalForMatch(isHighPrecision: false),
          equals(const Duration(milliseconds: 1000)),
        );

        // 通常モード: 代表戦・延長戦の高精度要求時は100ms
        expect(
          governor.getTickIntervalForMatch(isHighPrecision: true),
          equals(const Duration(milliseconds: 100)),
        );

        // エコ冷却モード時: 500ms
        governor.setMode(ThermalPowerMode.ecoCooling);
        expect(
          governor.getTickIntervalForMatch(isHighPrecision: false),
          equals(const Duration(milliseconds: 500)),
        );
        expect(
          governor.getTickIntervalForMatch(isHighPrecision: true),
          equals(const Duration(milliseconds: 500)),
        );
      },
    );

    test(
      '3. [コード監査] match_screen.dart で LiquidBackground に isAnimated: false が指定されていること',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('isAnimated: false'), isTrue);
      },
    );

    test('4. [コード監査] match_list_provider.dart 内で重複Firestoreリスナーが排除されていること', () {
      final file = File(
        'lib/features/tournament/presentation/operate/providers/match_list_provider.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      // Native側の matchesCollection.snapshots().listen が撤廃されていること
      expect(
        content.contains('matchesCollection.snapshots().listen'),
        isFalse,
        reason: 'Native側での二重Firestoreリスナーは撤廃されSyncEngineに一本化されること',
      );
      expect(content.contains('watchLocalMatches(tournamentId)'), isTrue);
    });

    test('5. [コード監査] Isar maxSizeMiB が 128 に適正化されていること', () {
      final startupFile = File('lib/bootstrap/app_startup.dart');
      expect(startupFile.existsSync(), isTrue);
      final startupContent = startupFile.readAsStringSync();
      expect(startupContent.contains('maxSizeMiB = 128'), isTrue);

      final helperFile = File('lib/shared/bootstrap/app_bootstrap_helper.dart');
      expect(helperFile.existsSync(), isTrue);
      final helperContent = helperFile.readAsStringSync();
      expect(helperContent.contains('maxSizeMiB: 128'), isTrue);
    });

    test(
      '6. [コード監査] local_match_repository.dart に最新3世代ローテーション機構が配備されていること',
      () {
        final file = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('_saveEmergencyBackupWithRotation'), isTrue);
        expect(content.contains('backupFiles.length > 3'), isTrue);
        expect(content.contains('oldFile.deleteSync()'), isTrue);
      },
    );

    test('7. [コード監査] settings_provider.dart のバッテリーポーリングが60秒に緩和されていること', () {
      final file = File(
        'lib/shared/presentation/providers/settings_provider.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.contains('Duration(seconds: 60)'), isTrue);
    });

    test(
      '8. [Plan 2-1 VRR制御] ThermalPowerGovernor の targetFps / isVrrThrottled 規約',
      () {
        final governor = ThermalPowerGovernor();
        // 通常時は60fps
        expect(governor.targetFps, equals(60));
        expect(governor.isVrrThrottled, isFalse);

        // ecoCooling 時は30fpsスロットリング
        governor.setMode(ThermalPowerMode.ecoCooling);
        expect(governor.targetFps, equals(30));
        expect(governor.isVrrThrottled, isTrue);

        // ultraSave 時は15fps極限スロットリング
        governor.setMode(ThermalPowerMode.ultraSave);
        expect(governor.targetFps, equals(15));
        expect(governor.isVrrThrottled, isTrue);
      },
    );

    test(
      '9. [Plan 2-2 コールドスリープ] match_timer_provider.dart の enterColdSleep / resumeFromColdSleep 規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/match_timer_provider.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('void enterColdSleep()'), isTrue);
        expect(content.contains('void resumeFromColdSleep()'), isTrue);
        expect(content.contains('AppLifecycleListener'), isTrue);
      },
    );

    test(
      '10. [Plan 2-3 マイクロバッチング] local_match_repository.dart の saveMatchBatched / flushMicroBatch 規約',
      () {
        final file = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('saveMatchBatched'), isTrue);
        expect(content.contains('flushMicroBatch'), isTrue);
      },
    );

    test(
      '11. [Plan 2-4 メモリ即時解放] program_viewer_screen.dart & pdf_service.dart のキャッシュ解放規約',
      () {
        final viewerFile = File(
          'lib/features/tournament/presentation/operate/screens/program_viewer_screen.dart',
        );
        expect(viewerFile.existsSync(), isTrue);
        final viewerContent = viewerFile.readAsStringSync();
        expect(
          viewerContent.contains('ProgramViewerPdfPageCache.shared.clear()'),
          isTrue,
        );
        expect(
          viewerContent.contains('PaintingBinding.instance.imageCache.clear()'),
          isTrue,
        );

        final pdfFile = File('lib/features/pdf/pdf_service.dart');
        expect(pdfFile.existsSync(), isTrue);
        final pdfContent = pdfFile.readAsStringSync();
        expect(
          pdfContent.contains('PaintingBinding.instance.imageCache.clear()'),
          isTrue,
        );
      },
    );

    test(
      '12. [Plan 2-5 差分デルタ伝送] local_p2p_broadcaster.dart の broadcastMatchDelta 規約',
      () {
        final file = File(
          'lib/features/p2p/infrastructure/local_p2p_broadcaster.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('broadcastMatchDelta'), isTrue);
        expect(content.contains('MATCH_DELTA'), isTrue);
      },
    );
  });
}
