import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang/主入口.dart';
import 'package:jizhang/数据/数据库.dart';
import 'package:jizhang/数据/种子数据.dart';
import 'package:jizhang/状态/提供者.dart';

void main() {
  testWidgets('4 Tab shell renders', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPresetData(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const JizhangApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的账单'), findsOneWidget);
    expect(find.text('工程骨架已就绪'), findsOneWidget);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('报表'), findsWidgets);
    expect(find.text('资产'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });

  testWidgets('assets empty state and add sheet', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPresetData(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const JizhangApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('资产').last);
    await tester.pumpAndSettle();
    expect(find.text('还没有账户'), findsOneWidget);

    await tester.tap(find.text('添加账户').last);
    await tester.pumpAndSettle();
    expect(find.text('银行卡'), findsOneWidget);
    expect(find.text('储值卡'), findsOneWidget);
    expect(find.text('贷款'), findsOneWidget);

    await tester.tap(find.text('银行卡'));
    await tester.pumpAndSettle();
    expect(find.text('添加银行卡'), findsOneWidget);
  });
}
