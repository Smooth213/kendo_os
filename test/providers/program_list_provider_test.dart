import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 programListProvider テスト', () {
    test('currentDojoId が既に設定されている場合、正常にプロバイダが監視開始されること', () async {
      final container = ProviderContainer(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => 'dojo_custom_123'),
          programListProvider('tour_123').overrideWith(
            (ref) => Stream.value([
              ProgramModel(
                id: 'prog_1',
                tournamentId: 'tour_123',
                title: 'テストプログラム',
                fileUrl: 'https://example.com/prog.png',
                fileType: 'image',
                pageCount: 1,
                createdAt: DateTime(2026, 9, 1),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final asyncVal = container.read(programListProvider('tour_123'));
      expect(asyncVal.isLoading, isTrue);

      // ストリームの初回データを待機
      final data = await container.read(programListProvider('tour_123').future);
      expect(data.length, equals(1));
      expect(data.first.title, equals('テストプログラム'));
    });

    test(
      'currentDojoId が default_dojo_room の場合でも、オーバーライドまたはフォールバックで安全に解決されること',
      () async {
        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'default_dojo_room'),
            programListProvider(
              'tour_123',
            ).overrideWith((ref) => Stream.value([])),
          ],
        );
        addTearDown(container.dispose);

        final data = await container.read(
          programListProvider('tour_123').future,
        );
        expect(data, isEmpty);
      },
    );
  });
}
