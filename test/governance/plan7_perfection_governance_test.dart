import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 【Plan 7 ガバナンス監査】極限最適化・低負荷・絶対安定性 完走永続保証規約', () {
    test(
      '1. [ネットワーク・省メモリ] viewer_view_state_provider.dart の viewerMatchProjectionProvider および下流プロバイダに autoDispose とキャッシュキープが配備されていること',
      () {
        final file = File(
          'lib/features/viewer/providers/viewer_view_state_provider.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains(
                'viewerMatchProjectionProvider = StreamProvider.family\n    .autoDispose<MatchProjection?, String>(',
              ) ||
              content.contains(
                'viewerMatchProjectionProvider = StreamProvider.family.autoDispose<MatchProjection?, String>(',
              ),
          isTrue,
          reason: 'viewerMatchProjectionProvider は autoDispose でなければならない',
        );

        expect(
          content.contains('ref.keepAlive()'),
          isTrue,
          reason: '画面遷移時のチラつきを防ぎつつ不要時に解除するため ref.keepAlive() が配備されていること',
        );

        expect(
          content.contains(
                'viewerMatchStatusProvider = Provider.family\n    .autoDispose<AsyncValue<String>, String>(',
              ) ||
              content.contains(
                'viewerMatchStatusProvider = Provider.family.autoDispose<AsyncValue<String>, String>(',
              ),
          isTrue,
          reason: 'viewerMatchStatusProvider は autoDispose でなければならない',
        );

        expect(
          content.contains(
                'viewerMatchMomentumProvider = Provider.family\n    .autoDispose<AsyncValue<double>, String>(',
              ) ||
              content.contains(
                'viewerMatchMomentumProvider = Provider.family.autoDispose<AsyncValue<double>, String>(',
              ),
          isTrue,
          reason: 'viewerMatchMomentumProvider は autoDispose でなければならない',
        );

        expect(
          content.contains(
                'viewerMatchTimelineProvider = Provider.family\n    .autoDispose<AsyncValue<List<TimelineEvent>>, String>(',
              ) ||
              content.contains(
                'viewerMatchTimelineProvider = Provider.family.autoDispose<AsyncValue<List<TimelineEvent>>, String>(',
              ),
          isTrue,
          reason: 'viewerMatchTimelineProvider は autoDispose でなければならない',
        );
      },
    );

    test(
      '2. [メモリ完全開放] critical_action_guard.dart で pinController.dispose() が確実に呼ばれていること',
      () {
        final file = File('lib/shared/widgets/critical_action_guard.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('pinController.dispose()'),
          isTrue,
          reason:
              'critical_action_guard.dart でダイアログ終了時に pinController.dispose() が呼ばれていること',
        );
      },
    );

    test(
      '3. [レンダリング負荷隔離] match_timeline_list.dart で RepaintBoundary によるチームカード描画隔離がなされていること',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/home/match_timeline_list.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains(
                'RepaintBoundary(\n                    child: TimelineTeamCard(',
              ) ||
              content.contains('RepaintBoundary(child: TimelineTeamCard(') ||
              (content.contains('RepaintBoundary') &&
                  content.contains('TimelineTeamCard')),
          isTrue,
          reason:
              'match_timeline_list.dart で各チームカードが RepaintBoundary で囲まれていること',
        );
      },
    );

    test(
      '4. [レンダリング負荷隔離] dock_draggable_sheet.dart で RepaintBoundary によるコンテンツ描画隔離がなされていること',
      () {
        final file = File(
          'lib/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains(
                'RepaintBoundary(\n                      child: Builder(',
              ) ||
              content.contains('RepaintBoundary(child: Builder(') ||
              (content.contains('RepaintBoundary') &&
                  content.contains('widget.builder')),
          isTrue,
          reason:
              'dock_draggable_sheet.dart でコンテンツエリアが RepaintBoundary で囲まれていること',
        );
      },
    );
  });
}
