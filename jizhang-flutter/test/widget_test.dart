import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang/主入口.dart';
import 'package:jizhang/数据/数据库.dart';
import 'package:jizhang/数据/种子数据.dart';
import 'package:jizhang/数据/仓库/账户仓库.dart';
import 'package:jizhang/数据/仓库/交易仓库.dart';
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
    expect(find.text('还没有记录'), findsOneWidget);
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

  testWidgets('profile opens categories and settings without Material error', (tester) async {
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

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('类别管理'));
    await tester.pumpAndSettle();
    expect(find.text('类别管理'), findsWidgets);
    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('已用 0 笔'), findsWidgets);
  });

  testWidgets('settings page renders WebDAV and backup', (tester) async {
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

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('WebDAV 备份'), findsOneWidget);
    expect(find.text('备份与恢复'), findsOneWidget);
    expect(find.text('默认记账账户'), findsOneWidget);
  });

  testWidgets('record sheet opens for expense', (tester) async {
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

    await tester.tap(find.text('记一笔').last);
    await tester.pumpAndSettle();
    expect(find.text('支出'), findsOneWidget);
    expect(find.text('收入'), findsOneWidget);
    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('record sheet saves expense and home refreshes', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPresetData(db);
    final bank = await AccountRepository(db).createBankAccount(name: '测试卡', openingBalance: 100000);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const JizhangApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('记一笔').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '12.34');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(await AccountRepository(db).balanceOf(bank), 98766);
    expect(find.text('-¥12.34'), findsWidgets);
    expect(find.text('¥12.34'), findsWidgets);
  });

  testWidgets('report page renders metrics without AI summary', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPresetData(db);
    final accounts = AccountRepository(db);
    final bank = await accounts.createBankAccount(name: '测试卡', openingBalance: 100000);
    final categories = await (db.select(db.categories)).get();
    final food = categories.firstWhere((c) => c.name == '餐饮' && c.type == 'expense');
    await TransactionRepository(db).addExpense(
      amount: 10000,
      accountId: bank,
      categoryId: food.id,
      occurredAt: DateTime.now(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const JizhangApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('报表').last);
    await tester.pumpAndSettle();

    expect(find.text('收支报表'), findsOneWidget);
    expect(find.text('本月支出'), findsOneWidget);
    expect(find.text('支出趋势'), findsOneWidget);
    expect(find.text('支出分类构成'), findsOneWidget);
    expect(find.text('月支出对比'), findsOneWidget);
    expect(find.textContaining('AI'), findsNothing);
    expect(find.text('¥100.00'), findsWidgets);
  });
}
