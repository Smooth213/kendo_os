import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/admin/presentation/components/master_edit_organization_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_empty_state_card.dart';
import 'package:kendo_os/admin/presentation/components/master_menu_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_organization_header_bar.dart';
import 'package:kendo_os/admin/presentation/components/master_register_organization_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_team_name_management_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _MockTeamNameNotifier extends TeamNameHistoryNotifier {
  final List<String> initial;
  _MockTeamNameNotifier(this.initial) : super();

  @override
  List<String> build() => initial;

  @override
  Future<void> addName(String name, String orgName) async {
    state = [...state, name];
  }

  @override
  Future<void> deleteName(String name, String orgName) async {
    state = state.where((item) => item != name).toList();
  }
}

void main() {
  group('[Widget] マスター組織・チーム管理コンポーネント統合テスト', () {
    // ----------------------------------------------------------
    // 組織ヘッダーバー
    // ----------------------------------------------------------
    group('MasterOrganizationHeaderBarヘッダーバーテスト', () {
      final player = PlayerModel(
        id: 'p1',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'ヤマダ',
        firstNameKana: 'タロウ',
        grade: 5,
        organization: '練馬道場',
      );

      testWidgets('MasterOrganizationHeaderBarがライトモードで正しく描画されること', (
        tester,
      ) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MasterOrganizationHeaderBar(
                orgName: '練馬道場',
                players: [player],
                groupingMode: 0,
                isSelectionMode: false,
                isReadOnly: false,
                canManageMaster: true,
                isDark: false,
                primaryColor: AppKendoColors.indigo,
                onGroupingModeChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('練馬道場'), findsOneWidget);
        expect(find.text('学年別'), findsOneWidget);
        expect(find.text('カテゴリ別'), findsOneWidget);
      });

      testWidgets('MasterOrganizationHeaderBarがダークモードで正しく描画されること', (
        tester,
      ) async {
        final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MasterOrganizationHeaderBar(
                orgName: '練馬道場',
                players: [player],
                groupingMode: 1,
                isSelectionMode: false,
                isReadOnly: false,
                canManageMaster: true,
                isDark: true,
                primaryColor: AppKendoColors.purpleAccent,
                onGroupingModeChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('練馬道場'), findsOneWidget);
        expect(find.text('学年別'), findsOneWidget);
        expect(find.text('カテゴリ別'), findsOneWidget);
      });
    });

    // ----------------------------------------------------------
    // 空状態カード
    // ----------------------------------------------------------
    group('MasterEmptyStateCard空状態カードテスト', () {
      testWidgets(
        'not readOnlyにおいて 空状態 テキスト一覧 and registration buttonが正しく描画されること',
        (WidgetTester tester) async {
          bool buttonTapped = false;
          final themeColors = AppThemeColors.ofMode(
            isDark: false,
            mode: 'normal',
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: ThemeData(extensions: [themeColors]),
                home: Scaffold(
                  body: MasterEmptyStateCard(
                    primaryColor: Colors.purple,
                    isReadOnly: false,
                    iconWidget: const Icon(Icons.shield, size: 80),
                    buttonWidget: ElevatedButton.icon(
                      onPressed: () => buttonTapped = true,
                      icon: const Icon(Icons.account_balance),
                      label: const Text('道場名を登録する'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(find.text('まだ選手が登録されていません'), findsOneWidget);
          expect(
            find.text('選手を追加する前に、まずはあなたたちの道場名・学校名を登録することから始めましょう！'),
            findsOneWidget,
          );
          expect(find.text('道場名を登録する'), findsOneWidget);

          await tester.tap(find.text('道場名を登録する'));
          await tester.pump();
          expect(buttonTapped, isTrue);
        },
      );

      testWidgets('読み取り専用モード時は登録ボタンが非表示になること', (WidgetTester tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(extensions: [themeColors]),
              home: const Scaffold(
                body: MasterEmptyStateCard(
                  primaryColor: Colors.blue,
                  isReadOnly: true,
                  iconWidget: Icon(Icons.shield, size: 80),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('まだ選手が登録されていません'), findsOneWidget);
        expect(find.text('道場名を登録する'), findsNothing);
      });
    });

    // ----------------------------------------------------------
    // 所属名編集
    // ----------------------------------------------------------
    group('MasterEditOrganizationBottomSheet所属名編集テスト', () {
      testWidgets(
        'MasterEditOrganizationBottomSheetにおいて 入力フィールドおよび更新ボタンが表示されること',
        (tester) async {
          final samplePlayer = PlayerModel(
            id: 'p1',
            lastName: '山田',
            firstName: '太郎',
            lastNameKana: 'ヤマダ',
            firstNameKana: 'タロウ',
            grade: 1,
            organization: '旧道場',
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: MasterEditOrganizationBottomSheet(
                    currentName: '旧道場',
                    players: [samplePlayer],
                  ),
                ),
              ),
            ),
          );

          expect(find.text('所属名の変更'), findsOneWidget);
          expect(find.text('新しい道場名・学校名'), findsOneWidget);
          expect(find.text('一括更新'), findsOneWidget);
        },
      );
    });

    // ----------------------------------------------------------
    // 組織登録・メニューボトムシート
    // ----------------------------------------------------------
    group('MasterRegisterOrganizationBottomSheet登録シートテスト', () {
      testWidgets('MasterRegisterOrganizationBottomSheetが正常に表示されること', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () =>
                          MasterRegisterOrganizationBottomSheet.show(
                            context,
                            ref,
                          ),
                      child: const Text('組織登録開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('組織登録開く'));
        await tester.safePumpAndSettle();

        expect(find.text('道場名・学校名の登録'), findsOneWidget);
        expect(find.text('選手を追加する前に、道場名または学校名を入力してください。'), findsOneWidget);
        expect(find.text('登録'), findsOneWidget);
        expect(find.text('キャンセル'), findsOneWidget);

        await tester.tap(find.text('キャンセル'));
        await tester.safePumpAndSettle();
        expect(find.text('道場名・学校名の登録'), findsNothing);
      });

      testWidgets('MasterRegisterOrganizationBottomSheetの未登録警告ダイアログが表示されること', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () =>
                          MasterRegisterOrganizationBottomSheet.showMustRegisterDialog(
                            context,
                            ref,
                          ),
                      child: const Text('警告開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('警告開く'));
        await tester.safePumpAndSettle();

        expect(find.text('道場名の登録が必要です'), findsOneWidget);
        expect(find.text('道場名を入力'), findsOneWidget);

        await tester.tap(find.text('キャンセル'));
        await tester.safePumpAndSettle();
        expect(find.text('道場名の登録が必要です'), findsNothing);
      });

      testWidgets('MasterMenuBottomSheetが正常に展開されメニュー項目が描画されること', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => MasterMenuBottomSheet.show(context, ref),
                      child: const Text('メニュー開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('メニュー開く'));
        await tester.safePumpAndSettle();

        expect(find.text('データとストレージ管理'), findsOneWidget);
        expect(find.text('新年度の一括進級'), findsOneWidget);
      });
    });

    // ----------------------------------------------------------
    // チーム名管理シート
    // ----------------------------------------------------------
    group('MasterTeamNameManagementSheetチーム名管理テスト', () {
      testWidgets(
        'MasterTeamNameManagementSheetにおいて チーム名一覧および入力フィールドが表示されること',
        (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                teamNameHistoryProvider.overrideWith(
                  () => _MockTeamNameNotifier(['道場A', '道場B']),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: MasterTeamNameManagementSheet(orgName: 'テスト組織'),
                ),
              ),
            ),
          );

          expect(find.text('チーム名の管理'), findsOneWidget);
          expect(find.text('道場A'), findsOneWidget);
          expect(find.text('道場B'), findsOneWidget);
          expect(find.text('追加'), findsOneWidget);
        },
      );
    });
  });
}
