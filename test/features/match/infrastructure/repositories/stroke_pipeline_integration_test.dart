import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:isar_community/isar.dart';

import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';

class MockLocalStrokeModelCollection extends Mock
    implements IsarCollection<LocalStrokeModel> {}

class MockIsar extends Mock implements Isar {
  final IsarCollection<LocalStrokeModel> mockCollection;
  MockIsar(this.mockCollection);

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    return callback();
  }

  @override
  IsarCollection<OBJ> collection<OBJ>() {
    return mockCollection as IsarCollection<OBJ>;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(LocalStrokeModel());
  });

  group('🛡️ Stroke Pipeline Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockLocalStrokeModelCollection mockCollection;
    late MockIsar mockIsar;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockCollection = MockLocalStrokeModelCollection();
      mockIsar = MockIsar(mockCollection);

      when(() => mockCollection.put(any())).thenAnswer((_) async => 1);
    });

    test('1. 共有ペン（Shared Stroke）の Firestore 保存・監視の直列ネストパス検証', () async {
      final repository = StrokeRepository(
        dojoId: 'dojo_test_123',
        firestore: fakeFirestore,
      );

      final stroke = StrokeModel(
        id: 'stroke_shared_1',
        programId: 'program_test_999',
        points: const [Offset(10, 20), Offset(30, 40)],
        color: Colors.red,
        strokeWidth: 5.0,
        isShared: true,
        pageIndex: 1,
      );

      // Firestoreへ保存
      await repository.addStroke(stroke);

      // 正しい直列ネスト階層にデータが書き込まれたか検証
      final docSnapshot = await fakeFirestore
          .collection('organizations')
          .doc('dojo_test_123')
          .collection('strokes')
          .doc('stroke_shared_1')
          .get();

      expect(docSnapshot.exists, isTrue);
      expect(docSnapshot.data()?['programId'], equals('program_test_999'));
      expect(docSnapshot.data()?['isShared'], isTrue);
      expect(docSnapshot.data()?['pageIndex'], equals(1));

      // 監視ストリームから美しく抽出・復元できること
      final stream = repository.watchStrokes('program_test_999');
      final list = await stream.first;

      expect(list, hasLength(1));
      expect(list.first.id, equals('stroke_shared_1'));
      expect(list.first.points, hasLength(2));
      expect(list.first.points.first.dx, equals(10.0));
      expect(list.first.isShared, isTrue);
    });

    test('2. 個人ペン（Local Stroke）のネイティブ環境（!kIsWeb）での Isar 保存フロー検証', () async {
      // isar を渡すことでネイティブ環境（Isar活性化）をシミュレート
      final repository = LocalStrokeRepository(
        mockIsar,
        dojoId: 'dojo_test_123',
        deviceId: 'device_mac_999',
        firestore: fakeFirestore,
      );

      final localStroke = LocalStrokeModel()
        ..programId = 'program_test_999'
        ..pointsX = [100.0, 150.0]
        ..pointsY = [200.0, 250.0]
        ..colorValue = Colors.blue.toARGB32()
        ..strokeWidth = 3.0
        ..createdAt = DateTime.now();

      await repository.addStroke(localStroke);

      // Isarに保存されたこと（Mockへのput呼び出し）を検証
      verify(() => mockCollection.put(localStroke)).called(1);
    });

    test(
      '3. 個人ペン（Local Stroke）の Web環境（Isar非活性）での Firestore フォールバック保存・監視・Undo・Clear検証',
      () async {
        // isar に null を渡すことで Web環境/Isar非活性のフォールバックをエミュレート
        final repository = LocalStrokeRepository(
          null,
          dojoId: 'dojo_test_123',
          deviceId: 'device_web_777',
          firestore: fakeFirestore,
        );

        final localStroke = LocalStrokeModel()
          ..programId = 'program_test_999'
          ..pointsX = [100.0, 150.0]
          ..pointsY = [200.0, 250.0]
          ..colorValue = Colors.blue.toARGB32()
          ..strokeWidth = 3.0
          ..createdAt = DateTime.now();

        // Webフォールバック保存
        await repository.addStroke(localStroke);

        // Firestoreの同ネストパスに isShared: false かつ deviceId が付与されて保存されたこと
        final querySnapshot = await fakeFirestore
            .collection('organizations')
            .doc('dojo_test_123')
            .collection('strokes')
            .where('isShared', isEqualTo: false)
            .get();

        expect(querySnapshot.docs, hasLength(1));
        final docData = querySnapshot.docs.first.data();
        expect(docData['isShared'], isFalse);
        expect(docData['deviceId'], equals('device_web_777'));
        expect(docData['programId'], equals('program_test_999'));

        // Web用監視ストリームから安全に抽出できること
        final list = await repository.watchStrokes('program_test_999').first;
        expect(list, hasLength(1));
        expect(list.first.programId, equals('program_test_999'));
        expect(list.first.pointsX.first, equals(100.0));

        // 異なる deviceId の端末からは個人メモが見えない（安全隔離）ことの検証
        final peerRepository = LocalStrokeRepository(
          null,
          dojoId: 'dojo_test_123',
          deviceId: 'device_peer_888',
          firestore: fakeFirestore,
        );
        final peerList = await peerRepository
            .watchStrokes('program_test_999')
            .first;
        expect(peerList, isEmpty); // 別デバイスIDからは取得できない

        // Undo（取り消し）の連動検証
        await repository.undoLastStroke('program_test_999');
        final afterUndoList = await repository
            .watchStrokes('program_test_999')
            .first;
        expect(afterUndoList, isEmpty); // 削除されたため空になる

        // 再度保存して全消去（Clear）を検証
        await repository.addStroke(localStroke);
        final beforeClearList = await repository
            .watchStrokes('program_test_999')
            .first;
        expect(beforeClearList, hasLength(1));

        await repository.clearStrokes('program_test_999');
        final afterClearList = await repository
            .watchStrokes('program_test_999')
            .first;
        expect(afterClearList, isEmpty); // 全消去されたため空になる
      },
    );
  });
}
