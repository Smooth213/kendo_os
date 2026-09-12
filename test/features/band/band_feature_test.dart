import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_edit_dialog.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_select_sheet.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/band/presentation/services/band_match_text_formatter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

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
          'https://kendo-os-beta.web.app/viewer/match_001?tournamentId=tourney_1&role=viewer&dojoId=dojo_test',
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
          tournamentId: 't_abc',
          redName: '道上剣友会:山田',
          whiteName: '相手チーム:佐藤',
          status: 'in_progress',
          note: '第2試合場 準決勝',
        );
        final m2 = MatchModel(
          id: 'm2',
          matchType: '団体戦 (次鋒)',
          groupName: 'group_abc',
          tournamentId: 't_abc',
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
            'https://kendo-os-beta.web.app/viewer-team/group_abc?tournamentId=t_abc&role=viewer&dojoId=dojo_abc',
          ),
        );
      },
    );

    test(
      'formatFromMatchGroup produces viewer-kachinuki URL for kachinuki matches',
      () {
        final m1 = MatchModel(
          id: 'm1',
          matchType: '団体戦 (先鋒)',
          groupName: '勝ち抜き第1試合',
          tournamentId: 't_kachinuki',
          isKachinuki: true,
          redName: '道上剣友会:山田',
          whiteName: '相手チーム:佐藤',
        );

        final text = BandMatchTextFormatter.formatFromMatchGroup(
          matches: [m1],
          dojoId: 'dojo_kachinuki',
        );

        expect(
          text,
          contains(
            'https://kendo-os-beta.web.app/viewer-kachinuki/${Uri.encodeComponent('勝ち抜き第1試合')}?tournamentId=t_kachinuki&role=viewer&dojoId=dojo_kachinuki',
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
          'https://kendo-os-beta.web.app/viewer-team/team_group_123?tournamentId=t1&role=viewer&dojoId=my_dojo',
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

  group('Band URL Guarantee Tests (厳格なURL検証)', () {
    test('ユーザー実例: 第2試合場, 3回戦, 2試合目の団体戦URLが viewer-team かつ全パラメータを保持すること', () {
      final match = MatchModel(
        id: 'match_court2_r3_m2',
        matchType: '団体戦 (先鋒)',
        groupName: '第2試合場, 3回戦, 2試合目',
        tournamentId: 'test204_tourney',
        redName: '道剣A:山田',
        whiteName: '道剣B:佐藤',
        note: '第2試合場 3回戦 2試合目',
      );

      final text = BandMatchTextFormatter.formatFromMatchGroup(
        matches: [match],
        tournamentName: 'テスト大会204',
        tournamentId: 'test204_tourney',
        dojoId: 'test204',
      );

      // URLを抽出
      final urlRegExp = RegExp(r'https://[^\s]+');
      final matchUrl = urlRegExp.firstMatch(text);
      expect(matchUrl, isNotNull, reason: 'URLがテキスト内に存在すること');

      final uri = Uri.parse(matchUrl!.group(0)!);
      expect(uri.scheme, 'https');
      expect(uri.host, 'kendo-os-beta.web.app');
      expect(
        uri.path,
        '/viewer-team/${Uri.encodeComponent('第2試合場, 3回戦, 2試合目')}',
        reason: 'パスが /viewer-team/ かつエンコードされたgroupNameであること',
      );
      expect(uri.queryParameters['tournamentId'], 'test204_tourney');
      expect(uri.queryParameters['role'], 'viewer');
      expect(uri.queryParameters['dojoId'], 'test204');
    });

    test(
      '個人戦: パスが /viewer/{matchId} かつ role, dojoId, tournamentId を保持すること',
      () {
        final match = MatchModel(
          id: 'individual_match_999',
          matchType: '個人戦',
          tournamentId: 'ind_tourney_1',
          redName: '選手赤',
          whiteName: '選手白',
        );

        final text = BandMatchTextFormatter.formatFromMatchGroup(
          matches: [match],
          dojoId: 'dojo_ind',
        );

        final urlRegExp = RegExp(r'https://[^\s]+');
        final matchUrl = urlRegExp.firstMatch(text);
        expect(matchUrl, isNotNull);

        final uri = Uri.parse(matchUrl!.group(0)!);
        expect(uri.path, '/viewer/individual_match_999');
        expect(uri.queryParameters['tournamentId'], 'ind_tourney_1');
        expect(uri.queryParameters['role'], 'viewer');
        expect(uri.queryParameters['dojoId'], 'dojo_ind');
      },
    );

    test('勝ち抜き戦: パスが /viewer-kachinuki/{groupName} になること', () {
      final match = MatchModel(
        id: 'kachinuki_m1',
        matchType: '団体戦 (先鋒)',
        groupName: '勝ち抜き決勝戦',
        tournamentId: 'tourney_k',
        isKachinuki: true,
        redName: '赤軍:選手A',
        whiteName: '白軍:選手B',
      );

      final text = BandMatchTextFormatter.formatFromMatchGroup(
        matches: [match],
        dojoId: 'dojo_k',
      );

      final urlRegExp = RegExp(r'https://[^\s]+');
      final matchUrl = urlRegExp.firstMatch(text);
      expect(matchUrl, isNotNull);

      final uri = Uri.parse(matchUrl!.group(0)!);
      expect(uri.path, '/viewer-kachinuki/${Uri.encodeComponent('勝ち抜き決勝戦')}');
      expect(uri.queryParameters['tournamentId'], 'tourney_k');
      expect(uri.queryParameters['role'], 'viewer');
      expect(uri.queryParameters['dojoId'], 'dojo_k');
    });

    test('TeamProgressStatus: 正しい団体戦URLが生成されること', () {
      final status = TeamProgressStatus(
        teamName: '代表チーム',
        categoryName: '高学年',
        currentCourtName: '第1コート',
        matchupTitle: '代表チーム vs ライバルチーム',
        targetGroupId: '第1試合場, 準々決勝, 1試合目',
        tournamentId: 't_progress_100',
        matches: [],
        completedCount: 1,
        totalCount: 5,
        hasLiveMatch: false,
      );

      final text = BandMatchTextFormatter.formatFromTeamStatus(
        status: status,
        tournamentName: '進捗テスト大会',
        dojoId: 'progress_dojo',
      );

      final urlRegExp = RegExp(r'https://[^\s]+');
      final matchUrl = urlRegExp.firstMatch(text);
      expect(matchUrl, isNotNull);

      final uri = Uri.parse(matchUrl!.group(0)!);
      expect(
        uri.path,
        '/viewer-team/${Uri.encodeComponent('第1試合場, 準々決勝, 1試合目')}',
      );
      expect(uri.queryParameters['tournamentId'], 't_progress_100');
      expect(uri.queryParameters['role'], 'viewer');
      expect(uri.queryParameters['dojoId'], 'progress_dojo');
    });

    testWidgets('BandShareButtonタップ時にクリップボードへ正しいURLが書き込まれること', (tester) async {
      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              final args = methodCall.arguments as Map<dynamic, dynamic>?;
              copiedText = args?['text'] as String?;
              return null;
            }
            if (methodCall.method == 'Clipboard.getData') {
              return <String, dynamic>{'text': copiedText};
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final match = MatchModel(
        id: 'widget_test_match',
        matchType: '団体戦 (先鋒)',
        groupName: '第2試合場, 3回戦, 2試合目',
        tournamentId: 'widget_tourney_id',
        redName: '紅葉道場:先鋒',
        whiteName: '白菊道場:先鋒',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'test_widget_dojo'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'widget_tourney_id',
            ),
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value(<BandGroupModel>[]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BandShareButton(
                matches: [match],
                tournamentName: 'ウィジェットテスト大会',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BandShareButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // クリップボードの内容を取得
      expect(copiedText, isNotNull);
      final text = copiedText!;

      final urlRegExp = RegExp(r'https://[^\s]+');
      final matchUrl = urlRegExp.firstMatch(text);
      expect(matchUrl, isNotNull);

      final uri = Uri.parse(matchUrl!.group(0)!);
      expect(
        uri.path,
        '/viewer-team/${Uri.encodeComponent('第2試合場, 3回戦, 2試合目')}',
      );
      expect(uri.queryParameters['tournamentId'], 'widget_tourney_id');
      expect(uri.queryParameters['role'], 'viewer');
      expect(uri.queryParameters['dojoId'], 'test_widget_dojo');

      // シートを閉じる
      final closeBtn = find.text('コピーのみで閉じる');
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    });
  });
}
