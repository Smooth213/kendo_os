import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'dart:io';

// ※ プロジェクトの実際のパスに合わせてインポートを調整してください
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';

void main() {
  group('LocalMatchRepository (Isar Database) Tests', () {
    late Isar isar;
    late LocalMatchRepository repository;

    // =========================================================================
    // 【CI環境対応】Isarの安全な初期化（二重起動・衝突を完全防止）
    // =========================================================================
    setUpAll(() async {
      try {
        await Isar.initializeIsarCore(download: true);
      } catch (_) {}

      // 既に他のテストファイルでIsarが開かれている場合は再利用する
      if (Isar.instanceNames.isNotEmpty) {
        isar = Isar.getInstance(Isar.instanceNames.first)!;
      } else {
        final tempDir = Directory.systemTemp.createTempSync('isar_repo_test_');
        isar = await Isar.open(
          [MatchEntitySchema],
          directory: tempDir.path,
          inspector: false, // CI環境でのポート衝突を防ぐためインスペクターは無効化
        );
      }

      // テスト対象のリポジトリをインスタンス化
      repository = LocalMatchRepository(isar);
    });

    tearDownAll(() async {
      try {
        await isar.close(deleteFromDisk: true);
      } catch (_) {}
    });

    setUp(() async {
      // 各テストの直前に、データベースの中身を空っぽにする（テストの独立性を担保）
      await isar.writeTxn(() async {
        await isar.clear();
      });
    });

    // =========================================================================
    // テストケース
    // =========================================================================
    test('saveMatch: MatchModelをIsarデータベースに正常に保存できること', () async {
      // Given: 保存するためのモックデータを作成
      final match = const MatchModel(
        id: 'repo_test_1',
        tournamentId: 'test_tournament',
        matchType: '個人戦',
        redName: '赤太郎',
        whiteName: '白次郎',
        status: 'in_progress',
      );

      // When: リポジトリを経由して保存を実行
      await repository.saveMatch(match);

      // Then: 保存されたデータをストリームから取得して検証
      final stream = repository.watchMatches();
      final savedMatches = await stream.first;

      expect(savedMatches.length, 1, reason: 'データベースに1件の試合が保存されているべき');
      expect(savedMatches.first.id, 'repo_test_1');
      expect(savedMatches.first.redName, '赤太郎');
      expect(savedMatches.first.status, 'in_progress');
    });

    test('saveMatch (Update): 既存の試合データを上書き更新できること', () async {
      // Given: 初期データを保存
      final initialMatch = const MatchModel(
        id: 'repo_test_2',
        matchType: '先鋒',
        redScore: 0,
        redName: '赤選手', // 追加
        whiteScore: 0,
        whiteName: '白選手', // 追加
      );
      await repository.saveMatch(initialMatch);

      // When: スコアが更新された同IDのデータを再度保存（上書き）
      final updatedMatch = initialMatch.copyWith(redScore: 1);
      await repository.saveMatch(updatedMatch);

      // Then: データが重複せず、1件のまま内容が更新されていることを検証
      final stream = repository.watchMatches();
      final savedMatches = await stream.first;

      expect(savedMatches.length, 1, reason: '同IDで保存した場合は新規追加ではなく上書きされるべき');
      expect(savedMatches.first.redScore, 1, reason: 'スコアの更新が正しく反映されているべき');
    });
  });
}