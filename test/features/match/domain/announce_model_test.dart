import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/announce_model.dart';

void main() {
  group('🛡️ AnnounceModel Serialization & Validation Tests', () {
    test('1. fromJson with raw ISO String timestamp', () {
      final json = {
        'id': 'ann_1',
        'tournamentId': 'tourney_99',
        'title': '試合開始のお知らせ',
        'body': '第1コートで第2試合が開始されました。',
        'timestamp': '2026-07-05T12:00:00.000Z',
        'type': 'matchStarted',
        'isRead': false,
      };

      final model = AnnounceModel.fromJson(json);

      expect(model.id, equals('ann_1'));
      expect(model.tournamentId, equals('tourney_99'));
      expect(model.title, equals('試合開始のお知らせ'));
      expect(model.body, equals('第1コートで第2試合が開始されました。'));
      expect(model.timestamp.isUtc, isTrue);
      expect(model.timestamp.year, equals(2026));
      expect(model.type, equals(AnnounceType.matchStarted));
      expect(model.isRead, isFalse);
    });

    test('2. fromJson with Cloud Firestore Timestamp type', () {
      final firestoreTimestamp = Timestamp.fromDate(
        DateTime.utc(2026, 7, 5, 13, 30),
      );
      final json = {
        'id': 'ann_2',
        'tournamentId': 'tourney_99',
        'title': '緊急避難のお知らせ',
        'body': '熱中症警戒アラートのため、15分間休憩とします。',
        'timestamp': firestoreTimestamp,
        'type': 'emergency',
        'isRead': true,
      };

      final model = AnnounceModel.fromJson(json);

      expect(model.id, equals('ann_2'));
      expect(model.type, equals(AnnounceType.emergency));
      expect(model.timestamp.year, equals(2026));
      expect(model.timestamp.month, equals(7));
      expect(model.timestamp.day, equals(5));
      expect(model.isRead, isTrue);
    });

    test('3. toJson serialization verification', () {
      final time = DateTime.utc(2026, 7, 5, 14, 0);
      final model = AnnounceModel(
        id: 'ann_3',
        tournamentId: 'tourney_99',
        title: '結果のお知らせ',
        body: '決勝戦が決着しました。',
        timestamp: time,
        type: AnnounceType.result,
        isRead: false,
      );

      final json = model.toJson();

      expect(json['id'], equals('ann_3'));
      expect(json['tournamentId'], equals('tourney_99'));
      expect(json['title'], equals('結果のお知らせ'));
      expect(json['body'], equals('決勝戦が決着しました。'));
      expect(json['timestamp'], equals('2026-07-05T14:00:00.000Z'));
      expect(json['type'], equals('result'));
      expect(json['isRead'], isFalse);
    });

    test('4. copyWith verification', () {
      final time = DateTime.now();
      final model = AnnounceModel(
        id: 'ann_4',
        tournamentId: 'tourney_99',
        title: '初期タイトル',
        body: '初期本文',
        timestamp: time,
        type: AnnounceType.matchAdded,
        isRead: false,
      );

      final updated = model.copyWith(
        title: '更新タイトル',
        isRead: true,
        timestamp: time,
      );

      expect(updated.id, equals('ann_4'));
      expect(updated.title, equals('更新タイトル'));
      expect(updated.body, equals('初期本文'));
      expect(updated.isRead, isTrue);
      expect(updated.timestamp, equals(time));
    });
  });
}
