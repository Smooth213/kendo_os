import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    '[Governance] 第29条 ガバナンス監査において データベース整合性・Firestore複合クエリ ＆ インデックス契約完全保証規約',
    () {
      test('firestore.indexes.json が存在し、必須インデックスが定義されていること', () {
        final indexFile = File('firestore.indexes.json');
        expect(indexFile.existsSync(), isTrue);

        final jsonString = indexFile.readAsStringSync();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(data.containsKey('indexes'), isTrue);
        final indexes = data['indexes'] as List<dynamic>;

        // matches, programs, announcements のインデックス契約を検証
        final collections = indexes
            .map(
              (e) => (e as Map<String, dynamic>)['collectionGroup'] as String,
            )
            .toSet();

        expect(
          collections.contains('matches'),
          isTrue,
          reason: 'matches コレクションの複合インデックス定義が必要です。',
        );
        expect(
          collections.contains('announcements'),
          isTrue,
          reason: 'announcements コレクションの複合インデックス定義が必要です。',
        );
      });

      test('コード内の Firestore 複合クエリが firestore.indexes.json の契約と合致していること', () {
        final indexFile = File('firestore.indexes.json');
        expect(indexFile.existsSync(), isTrue);
        final jsonString = indexFile.readAsStringSync();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final indexes = data['indexes'] as List<dynamic>;

        // announcements クエリのインデックス契約照合
        final hasAnnounceIndex = indexes.any((idx) {
          final m = idx as Map<String, dynamic>;
          if (m['collectionGroup'] != 'announcements') return false;
          final fields = (m['fields'] as List<dynamic>)
              .map((f) => (f as Map<String, dynamic>)['fieldPath'] as String)
              .toList();
          return fields.contains('tournamentId') &&
              fields.contains('timestamp');
        });

        expect(
          hasAnnounceIndex,
          isTrue,
          reason: 'announcements の tournamentId + timestamp 複合インデックスが存在すること',
        );

        // matches クエリのインデックス契約照合
        final hasMatchesIndex = indexes.any((idx) {
          final m = idx as Map<String, dynamic>;
          if (m['collectionGroup'] != 'matches') return false;
          final fields = (m['fields'] as List<dynamic>)
              .map((f) => (f as Map<String, dynamic>)['fieldPath'] as String)
              .toList();
          return fields.contains('tournamentId') &&
              fields.contains('matchOrder');
        });

        expect(
          hasMatchesIndex,
          isTrue,
          reason: 'matches の tournamentId + matchOrder 複合インデックスが存在すること',
        );
      });
    },
  );
}
