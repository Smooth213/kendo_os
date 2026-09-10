import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_edit_dialog.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_select_sheet.dart';
import 'package:kendo_os/features/band/presentation/services/band_match_text_formatter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';

void main() {
  group('BandGroupModel Tests', () {
    test('toJson and fromJson serialize correctly', () {
      final now = DateTime(2026, 9, 10, 12, 0);
      final model = BandGroupModel(
        id: 'group_1',
        name: '道剣低学年',
        url: 'https://band.us/@dojo_low',
        order: 1,
        createdAt: now,
      );

      final json = model.toJson();
      expect(json['id'], 'group_1');
      expect(json['name'], '道剣低学年');
      expect(json['url'], 'https://band.us/@dojo_low');
      expect(json['order'], 1);

      final restored = BandGroupModel.fromJson(json);
      expect(restored.id, model.id);
      expect(restored.name, model.name);
      expect(restored.url, model.url);
      expect(restored.order, model.order);
      expect(restored, model);
    });
  });

  group('BandMatchTextFormatter Tests', () {
    test('formatFromMatchGroup produces correct text for individual match', () {
      final match = MatchModel(
        id: 'match_001',
        matchType: '個人戦',
        redName: '山田 太郎 (道上剣友会)',
        whiteName: '佐藤 次郎 (相手道場)',
        note: '第1試合場 1回戦 第1試合',
        tournamentId: 'tourney_1',
      );

      final text = BandMatchTextFormatter.formatFromMatchGroup(
        matches: [match],
        tournamentName: '第45回 記念剣道大会',
        dojoId: 'dojo_test',
      );

      expect(text, contains('【第45回 記念剣道大会】'));
      expect(text, contains('第1試合場 1回戦 第1試合'));
      expect(text, contains('赤: 山田 太郎 (道上剣友会) vs 白: 佐藤 次郎 (相手道場)'));
      expect(text, contains('▼ リアルタイム速報・スコア詳細'));
      expect(
        text,
        contains(
          'https://kendo-os-beta.web.app/viewer/match_001?dojoId=dojo_test',
        ),
      );
    });

    test(
      'formatFromMatchGroup produces correct text for team match with live position',
      () {
        final m1 = MatchModel(
          id: 'm1',
          matchType: '団体戦 (先鋒)',
          groupName: 'group_abc',
          redName: '道上剣友会:山田',
          whiteName: '相手チーム:佐藤',
          status: 'in_progress',
          note: '第2試合場 準決勝',
        );
        final m2 = MatchModel(
          id: 'm2',
          matchType: '団体戦 (次鋒)',
          groupName: 'group_abc',
          redName: '道上剣友会:田中',
          whiteName: '相手チーム:鈴木',
          status: 'waiting',
        );

        final text = BandMatchTextFormatter.formatFromMatchGroup(
          matches: [m1, m2],
          tournamentName: '秋季選抜大会',
          dojoId: 'dojo_abc',
        );

        expect(text, contains('【秋季選抜大会】'));
        expect(text, contains('第2試合場 準決勝'));
        expect(text, contains('道上剣友会 vs 相手チーム'));
        expect(text, contains('進行中: [先鋒] 赤:山田 vs 白:佐藤'));
        expect(
          text,
          contains(
            'https://kendo-os-beta.web.app/viewer/group_abc?dojoId=dojo_abc',
          ),
        );
      },
    );

    test('formatFromTeamStatus produces correct text for team progress', () {
      final liveMatch = MatchModel(
        id: 'live_1',
        matchType: '団体戦 (中堅)',
        redName: '道上剣友会:高橋',
        whiteName: '相手0012:伊藤',
        status: 'in_progress',
      );

      final status = TeamProgressStatus(
        teamName: '道上剣友会',
        categoryName: '小学生の部',
        currentCourtName: '第3試合場',
        matchupTitle: '団体戦：道上剣友会 vs 相手0012',
        targetGroupId: 'team_group_123',
        tournamentId: 't1',
        matches: [liveMatch],
        inProgressMatch: liveMatch,
        completedCount: 2,
        totalCount: 5,
        hasLiveMatch: true,
      );

      final text = BandMatchTextFormatter.formatFromTeamStatus(
        status: status,
        tournamentName: '地区少年大会',
        dojoId: 'my_dojo',
      );

      expect(text, contains('【地区少年大会】'));
      expect(text, contains('[小学生の部 第3試合場]'));
      expect(text, contains('団体戦：道上剣友会 vs 相手0012'));
      expect(text, contains('【試合中】[中堅] 高橋 vs 伊藤'));
      expect(
        text,
        contains(
          'https://kendo-os-beta.web.app/viewer/team_group_123?dojoId=my_dojo',
        ),
      );
    });
  });

  group('BandGroupEditDialog Widget Tests', () {
    testWidgets('BandGroupEditDialog renders without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => BandGroupEditDialog.show(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('新しいBANDグループを追加'), findsOneWidget);
    });

    testWidgets(
      'BandGroupSelectSheet opens and can trigger BandGroupEditDialog without error',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => BandGroupSelectSheet.show(
                      context,
                      formattedText: 'test',
                    ),
                    child: const Text('OpenSheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('OpenSheet'));
        await tester.pumpAndSettle();

        expect(find.text('BANDでLIVE配信・共有'), findsOneWidget);

        // 常設の「Bandを追加」ボタンをタップ
        final addBtn = find.text('Bandを追加');
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // ダイアログが正常に表示されること（クラッシュしないこと）
        expect(find.text('新しいBANDグループを追加'), findsOneWidget);
      },
    );
  });
}
