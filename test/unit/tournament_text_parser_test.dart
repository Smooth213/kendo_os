import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_text_parser.dart';

void main() {
  group('TournamentTextParser Tests', () {
    const kuroseSampleText = '''
黒瀬杯争奪剣道大会
西日本選抜　第38回　黒瀬杯争奪剣道大会
日時 : 令和8年9月20日(日) 
場所 : 【大会会場】東広島市運動公園　メインアリーナ
住所 : 広島県東広島市西条町田口67-1
開館 8:30 / 開会式 9:15
集合場所: JA道上 5:30
遠征責任者: 皿田

低学年
先鋒　皿田 脩人
中堅　塚本 大道
大将　久安 智也⭐️

中学生A
先鋒　恵木 春陽
中堅　橋本 璃久⭐️
大将　皿田 唯人

中学生B
先鋒　平山 空⭐️
中堅　皿田 梓人
大将　前本 渚

※TimeTreeで共有されました
https://timetreeapp.com/sample
''';

    const ijiriSampleText = '''
第25回 井尻杯親善少年剣道大会
日時：2026年11月3日（祝）
会場：福岡市立南体育館
福岡市南区塩原2丁目8-1

【小学生高学年の部】
先鋒：佐藤 健
次鋒：鈴木 一郎
中堅：高橋 翔
副将：田中 蓮
大将：伊藤 勇気★

連絡事項：
入場制限なし。駐車場は台数制限あり。
''';

    const chatConversationExclusion = '''
お疲れ様です！
明日の打ち合わせの件ですが、14時からzoomでお願いできますでしょうか？
資料は事前に送付いたします。
よろしくお願いします。
''';

    const shortShoppingMemo = '''
日時: 明日18時
場所: 渋谷
買い物リスト:
・牛乳
・卵
''';

    test('黒瀬杯実例: isCandidateがtrueを返すこと', () {
      expect(TournamentTextParser.isCandidate(kuroseSampleText), isTrue);
    });

    test('井尻杯実例: isCandidateがtrueを返すこと', () {
      expect(TournamentTextParser.isCandidate(ijiriSampleText), isTrue);
    });

    test('日常の業務チャット: isCandidateがfalse（誤爆除外）となること', () {
      expect(
        TournamentTextParser.isCandidate(chatConversationExclusion),
        isFalse,
      );
    });

    test('短いメモ: isCandidateがfalse（文字数・行数除外）となること', () {
      expect(TournamentTextParser.isCandidate(shortShoppingMemo), isFalse);
    });

    test('黒瀬杯実例: 正確にパースされること', () {
      final parsed = TournamentTextParser.parse(kuroseSampleText);

      // 大会名（より詳細な行が選ばれる）
      expect(parsed.tournamentName, contains('黒瀬杯争奪剣道大会'));
      expect(parsed.tournamentName, contains('西日本選抜'));

      // 日付: 令和8年9月20日 -> 2026年9月20日
      expect(parsed.date, isNotNull);
      expect(parsed.date!.year, equals(2026));
      expect(parsed.date!.month, equals(9));
      expect(parsed.date!.day, equals(20));

      // 会場・住所
      expect(parsed.venue, contains('東広島市運動公園'));
      expect(parsed.venue, contains('メインアリーナ'));
      expect(parsed.address, contains('広島県東広島市'));

      // チーム
      expect(parsed.teams.length, equals(3));

      // 低学年チーム
      final teigakunen = parsed.teams[0];
      expect(teigakunen.teamName, equals('低学年'));
      expect(teigakunen.members.length, equals(3));
      expect(teigakunen.members[0].position, equals('先鋒'));
      expect(teigakunen.members[0].name, equals('皿田 脩人'));
      expect(teigakunen.members[1].position, equals('中堅'));
      expect(teigakunen.members[1].name, equals('塚本 大道'));
      expect(teigakunen.members[2].position, equals('大将'));
      expect(teigakunen.members[2].name, equals('久安 智也')); // ⭐️が除去されていること

      // 中学生Aチーム
      final chugakuA = parsed.teams[1];
      expect(chugakuA.teamName, equals('中学生A'));
      expect(chugakuA.members[0].name, equals('恵木 春陽'));
      expect(chugakuA.members[1].name, equals('橋本 璃久')); // ⭐️が除去されていること
      expect(chugakuA.members[2].name, equals('皿田 唯人'));

      // 中学生Bチーム
      final chugakuB = parsed.teams[2];
      expect(chugakuB.teamName, equals('中学生B'));
      expect(chugakuB.members[0].name, equals('平山 空')); // ⭐️が除去されていること
      expect(chugakuB.members[1].name, equals('皿田 梓人'));
      expect(chugakuB.members[2].name, equals('前本 渚'));

      // メモ
      expect(parsed.notes, contains('開館 8:30'));
      expect(parsed.notes, contains('集合場所: JA道上 5:30'));
      expect(parsed.notes, isNot(contains('timetreeapp.com')));
    });

    test('井尻杯実例: 5人制オーダーが正確にパースされること', () {
      final parsed = TournamentTextParser.parse(ijiriSampleText);

      expect(parsed.tournamentName, contains('第25回 井尻杯親善少年剣道大会'));
      expect(parsed.date!.year, equals(2026));
      expect(parsed.date!.month, equals(11));
      expect(parsed.date!.day, equals(3));

      expect(parsed.venue, contains('福岡市立南体育館'));
      expect(parsed.teams.length, equals(1));

      final team = parsed.teams[0];
      expect(team.teamName, contains('小学生高学年の部'));
      expect(team.members.length, equals(5));
      expect(team.members[0].position, equals('先鋒'));
      expect(team.members[0].name, equals('佐藤 健'));
      expect(team.members[4].position, equals('大将'));
      expect(team.members[4].name, equals('伊藤 勇気')); // ★が除去されていること
    });

    test(
      '無関係なテキスト（Gitコマンドやチャット文）: 大会名が空となり hasEffectiveContent が false となること',
      () {
        const gitCommands = '''
git add .
git push origin stage2-beta
''';
        final parsedGit = TournamentTextParser.parse(gitCommands);
        expect(parsedGit.tournamentName, isEmpty);
        expect(parsedGit.date, isNull);
        expect(parsedGit.venue, isEmpty);
        expect(parsedGit.teams, isEmpty);
        expect(parsedGit.hasEffectiveContent, isFalse);

        final parsedChat = TournamentTextParser.parse(
          chatConversationExclusion,
        );
        expect(parsedChat.tournamentName, isEmpty);
        expect(parsedChat.hasEffectiveContent, isFalse);
      },
    );

    test('正常な大会テキスト: hasEffectiveContent が true となること', () {
      final parsedKurose = TournamentTextParser.parse(kuroseSampleText);
      expect(parsedKurose.hasEffectiveContent, isTrue);

      final parsedIjiri = TournamentTextParser.parse(ijiriSampleText);
      expect(parsedIjiri.hasEffectiveContent, isTrue);
    });

    test('個人戦実例（選手ラベル指定）: 正確にパースされ個人戦エントリーとして認識されること', () {
      const individualSample = '''
第10回 広島市少年剣道個人選手権大会
日時: 令和8年10月10日
会場: 広島県立武道館
【小学生低学年個人戦】
選手: 皿田 脩人
選手: 塚本 大道
【中学生男子個人戦】
選手: 皿田 唯人
''';

      expect(TournamentTextParser.isCandidate(individualSample), isTrue);

      final parsed = TournamentTextParser.parse(individualSample);
      expect(parsed.tournamentName, contains('広島市少年剣道個人選手権大会'));
      expect(parsed.date!.year, equals(2026));
      expect(parsed.date!.month, equals(10));
      expect(parsed.date!.day, equals(10));
      expect(parsed.venue, contains('広島県立武道館'));

      // 3名の選手がそれぞれ個人戦エントリーとして展開されていること
      expect(parsed.teams.length, equals(3));

      expect(parsed.teams[0].teamName, contains('皿田 脩人'));
      expect(parsed.teams[0].matchType, equals('個人戦'));
      expect(parsed.teams[0].members.length, equals(1));
      expect(parsed.teams[0].members[0].position, equals('選手'));
      expect(parsed.teams[0].members[0].name, equals('皿田 脩人'));

      expect(parsed.teams[1].teamName, contains('塚本 大道'));
      expect(parsed.teams[1].matchType, equals('個人戦'));

      expect(parsed.teams[2].teamName, contains('皿田 唯人'));
      expect(parsed.teams[2].matchType, equals('個人戦'));
    });

    test('個人戦実例（見出し＋名前リスト）: 番号や箇条書き付きの名前が選手として個人戦認識されること', () {
      const individualListSample = '''
第5回 親善少年剣道錬成大会
日時: 2026年11月15日
会場: 市民武道館
【個人戦】
1. 皿田 脩人
2. 塚本 大道
3. 久安 智也★
''';

      expect(TournamentTextParser.isCandidate(individualListSample), isTrue);

      final parsed = TournamentTextParser.parse(individualListSample);
      expect(parsed.teams.length, equals(3));
      for (final team in parsed.teams) {
        expect(team.matchType, equals('個人戦'));
        expect(team.members.length, equals(1));
        expect(team.members[0].position, equals('選手'));
      }
      expect(parsed.teams[0].members[0].name, equals('皿田 脩人'));
      expect(parsed.teams[1].members[0].name, equals('塚本 大道'));
      expect(parsed.teams[2].members[0].name, equals('久安 智也'));
    });

    test('ユーザー指定形式（個人戦 ＞ 中学生 ＞ 複数選手）: 正確に個人戦・中学生の部として抽出・展開されること', () {
      const userSample = '''
第3回 錬成大会
日時: 2026年12月1日
場所: 道場

個人戦
中学生
皿田 唯人
皿田 梓人
橋本 璃久
''';

      expect(TournamentTextParser.isCandidate(userSample), isTrue);

      final parsed = TournamentTextParser.parse(userSample);
      expect(parsed.teams.length, equals(3));

      final names = ['皿田 唯人', '皿田 梓人', '橋本 璃久'];
      for (int i = 0; i < 3; i++) {
        final team = parsed.teams[i];
        expect(team.teamName, equals(names[i]));
        expect(team.matchType, equals('個人戦'));
        expect(team.category, equals('中学生'));
        expect(team.members.length, equals(1));
        expect(team.members[0].position, equals('選手'));
        expect(team.members[0].name, equals(names[i]));

        // 自動判別で「中学生の部」に解決されること
        final resolvedCat = TournamentTeamAutoRegisterService.resolveCategory(
          team,
        );
        expect(resolvedCat, equals('中学生の部'));
      }
    });

    test('全カテゴリ判別実証: 個人戦で低学年・高学年・小学生・中学生・高校生・一般が全て正確に判別されること', () {
      const multiCategorySample = '''
第50回 記念剣道選手権大会
2026年10月10日
会場: 広島県立武道館

個人戦
小学生低学年
皿田 脩人

小学生高学年
久安 智也

小学生
佐藤 健

中学生
皿田 唯人

高校生
鈴木 一郎

一般
高橋 翔
''';

      final parsed = TournamentTextParser.parse(multiCategorySample);
      expect(parsed.teams.length, equals(6));

      final expectedCategories = [
        '小学生低学年の部',
        '小学生高学年の部',
        '小学生の部',
        '中学生の部',
        '高校生の部',
        '一般の部',
      ];

      for (int i = 0; i < 6; i++) {
        final team = parsed.teams[i];
        expect(team.matchType, equals('個人戦'));
        final resolvedCat = TournamentTeamAutoRegisterService.resolveCategory(
          team,
        );
        expect(
          resolvedCat,
          equals(expectedCategories[i]),
          reason:
              '${team.teamName} (${team.category}) が ${expectedCategories[i]} に解決されること',
        );
      }

      // 大会カテゴリ一覧の抽出も全カテゴリ網羅されること
      final extractedCategories =
          TournamentTeamAutoRegisterService.extractCategories(parsed.teams);
      for (final exp in expectedCategories) {
        expect(
          extractedCategories.contains(exp),
          isTrue,
          reason: '$exp が抽出されること',
        );
      }
    });
  });
}
