import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_data_cleanup_dialog.dart';

void main() {
  testWidgets('MasterDataCleanupDialog displays options and close button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: MasterDataCleanupDialog())),
      ),
    );

    expect(find.text('データとストレージ管理'), findsOneWidget);
    expect(find.text('一時キャッシュをクリア'), findsOneWidget);
    expect(find.text('全データをJSONでバックアップ'), findsOneWidget);
    expect(find.text('閉じる'), findsOneWidget);
  });
}
