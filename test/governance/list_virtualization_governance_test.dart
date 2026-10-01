import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Governance] 第11条 ガバナンス監査において リスト仮想化 ＆ ビューポート描画最適化（一括生成禁止）規約', () {
    test(
      '選手候補入力仮想化に関して、 smart_player_input.dart で全選手の一斉生成が禁止され、ListView.builder が使用されていること',
      () {
        final file = File('lib/shared/widgets/smart_player_input.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('ListView.builder('),
          isTrue,
          reason: 'smart_player_input.dart では ListView.builder による仮想化が必須',
        );

        final hasUnvirtualizedList = RegExp(
          r'child:\s*ListView\(\s*children:\s*\[',
        ).hasMatch(content);
        expect(
          hasUnvirtualizedList,
          isFalse,
          reason:
              'smart_player_input.dart 内で非仮想化 ListView(children: [...]) が使われていないこと',
        );
      },
    );

    test(
      '選手一括選択入力仮想化に関して、 multi_player_select_input.dart で全選手の一斉生成が禁止され、ListView.builder が使用されていること',
      () {
        final file = File('lib/shared/widgets/multi_player_select_input.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('ListView.builder('),
          isTrue,
          reason:
              'multi_player_select_input.dart では ListView.builder による仮想化が必須',
        );

        final hasUnvirtualizedList = RegExp(
          r'child:\s*ListView\(\s*children:\s*\[',
        ).hasMatch(content);
        expect(
          hasUnvirtualizedList,
          isFalse,
          reason:
              'multi_player_select_input.dart 内で非仮想化 ListView(children: [...]) が使われていないこと',
        );
      },
    );

    test(
      'チーム選手選択仮想化に関して、 team_registration_player_select_bottom_sheet.dart で CustomScrollView + SliverList.builder が使用されていること',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('CustomScrollView('),
          isTrue,
          reason: 'CustomScrollView が使用されていること',
        );
        expect(
          content.contains('SliverList.builder('),
          isTrue,
          reason: 'SliverList.builder による仮想スクロールが使用されていること',
        );

        final hasUnvirtualizedList = RegExp(
          r'child:\s*ListView\(\s*children:\s*\[',
        ).hasMatch(content);
        expect(
          hasUnvirtualizedList,
          isFalse,
          reason: '非仮想化 ListView(children: [...]) が使われていないこと',
        );
      },
    );

    test(
      'オーダー選手選択仮想化に関して、 order_setup_player_select_bottom_sheet.dart で ListView.builder が使用されていること',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('ListView.builder('),
          isTrue,
          reason:
              'order_setup_player_select_bottom_sheet.dart では ListView.builder が必須',
        );

        final hasUnvirtualizedList = RegExp(
          r'child:\s*ListView\(\s*children:\s*\[',
        ).hasMatch(content);
        expect(
          hasUnvirtualizedList,
          isFalse,
          reason: '非仮想化 ListView(children: [...]) が使われていないこと',
        );
      },
    );

    test(
      '公式記録スクロール仮想化復権に関して、 official_record_screen.dart & viewer_official_record_screen.dart の Expanded 下で不要な shrinkWrap: true が排除されていること',
      () {
        final officialFile = File(
          'lib/features/tournament/presentation/operate/official_record_screen.dart',
        );
        expect(officialFile.existsSync(), isTrue);
        final officialContent = officialFile.readAsStringSync();
        expect(
          officialContent.contains('shrinkWrap: true'),
          isFalse,
          reason:
              'official_record_screen.dart の ListView.builder に shrinkWrap: true が混入してはなりません',
        );

        final viewerFile = File(
          'lib/features/viewer/screens/viewer_official_record_screen.dart',
        );
        expect(viewerFile.existsSync(), isTrue);
        final viewerContent = viewerFile.readAsStringSync();
        expect(
          viewerContent.contains('shrinkWrap: true'),
          isFalse,
          reason:
              'viewer_official_record_screen.dart の ListView.builder に shrinkWrap: true が混入してはなりません',
        );
      },
    );
  });
}
