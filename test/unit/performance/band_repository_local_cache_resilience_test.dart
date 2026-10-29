import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/infrastructure/repository/band_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ErrorFirebaseFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    throw FirebaseException(
      plugin: 'firestore',
      message: 'Offline network error',
    );
  }
}

void main() {
  group('[Unit] BandRepository ローカルキャッシュと耐障害性の検証', () {
    const dojoId = 'band_test_org';
    const localPrefKey = 'kendo_os_band_groups_cache';

    test('Firestore例外発生時においてローカルキャッシュから安全に読み込まれること', () async {
      final cachedGroup = BandGroupModel(
        id: 'band_cached_01',
        name: 'キャッシュグループ',
        url: 'https://band.us/cached',
        order: 0,
      );
      SharedPreferences.setMockInitialValues({
        localPrefKey: jsonEncode([cachedGroup.toJson()]),
      });

      final errorFirestore = _ErrorFirebaseFirestore();
      final repository = BandRepository(errorFirestore, dojoId);
      final groups = await repository.getBandGroups();

      expect(groups.length, equals(1));
      expect(groups.first.id, equals('band_cached_01'));
      expect(groups.first.name, equals('キャッシュグループ'));
    });

    test('ローカルキャッシュの形式が不正な場合において安全に空リストへフォールバックすること', () async {
      SharedPreferences.setMockInitialValues({
        localPrefKey: 'this_is_broken_json{{{{',
      });

      final errorFirestore = _ErrorFirebaseFirestore();
      final repository = BandRepository(errorFirestore, dojoId);
      final groups = await repository.getBandGroups();

      expect(groups, isEmpty);
    });

    test('新規グループ追加時において空IDの場合に自動採番および表示順が設定されること', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeFirestore = FakeFirebaseFirestore();
      final repository = BandRepository(fakeFirestore, dojoId);

      final newGroup = const BandGroupModel(
        id: '',
        name: '新規青年部',
        url: 'https://band.us/new_group',
      );

      await repository.saveBandGroup(newGroup);

      final groups = await repository.getBandGroups();
      expect(groups.length, equals(1));
      expect(groups.first.id, startsWith('band_'));
      expect(groups.first.name, equals('新規青年部'));
      expect(groups.first.order, equals(0));

      // SharedPreferences のキャッシュも同期されていること
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(localPrefKey);
      expect(cachedJson, isNotNull);
      expect(cachedJson, contains('新規青年部'));
    });

    test('グループ削除時においてリストから除外されローカルキャッシュも更新されること', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeFirestore = FakeFirebaseFirestore();
      final repository = BandRepository(fakeFirestore, dojoId);

      final group1 = const BandGroupModel(
        id: 'group_1',
        name: '指導部',
        url: 'https://band.us/group1',
        order: 0,
      );
      final group2 = const BandGroupModel(
        id: 'group_2',
        name: '保護者会',
        url: 'https://band.us/group2',
        order: 1,
      );

      await repository.saveBandGroup(group1);
      await repository.saveBandGroup(group2);

      var current = await repository.getBandGroups();
      expect(current.length, equals(2));

      await repository.deleteBandGroup('group_1');

      final remaining = await repository.getBandGroups();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('group_2'));
      expect(remaining.first.name, equals('保護者会'));

      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(localPrefKey);
      expect(cachedJson, isNotNull);
      expect(cachedJson, isNot(contains('group_1')));
      expect(cachedJson, contains('group_2'));
    });
  });
}
