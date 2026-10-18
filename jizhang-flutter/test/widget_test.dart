import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang/主入口.dart';
import 'package:jizhang/数据/数据库.dart';
import 'package:jizhang/数据/种子数据.dart';
import 'package:jizhang/数据/仓库/账户仓库.dart';
import 'package:jizhang/数据/仓库/类别仓库.dart';
import 'package:jizhang/数据/仓库/交易仓库.dart';
import 'package:jizhang/数据/仓库/设置仓库.dart';
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
    expect(find.text('本月结余'), findsNothing);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('报表'), findsWidgets);
    expect(find.text('资产'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });

  testWidgets('assets default account and add sheet', (tester) async {
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
    expect(find.text('默认账户'), findsWidgets);

    await tester.tap(find.byTooltip('添加账户'));
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
    expect(find.textContaining('已用 0 笔'), findsWidgets);
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
    await SettingsRepository(db).set('default_account_id', bank.toString());
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

  testWidgets('long press transaction asks to delete and removes it', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPresetData(db);
    final account = (await AccountRepository(db).listWithBalances())
        .firstWhere((view) => view.account.type == 'default');
    final category = (await db.select(db.categories).get())
        .firstWhere((row) => row.name == '餐饮' && row.type == 'expense');
    await TransactionRepository(db).addExpense(
      amount: 1234,
      accountId: account.account.id,
      categoryId: category.id,
      occurredAt: DateTime.now(),
      note: '长按删除测试',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const JizhangApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('餐饮'));
    await tester.pumpAndSettle();
    expect(find.text('删除流水'), findsOneWidget);
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();

    expect(find.text('还没有记录'), findsOneWidget);
    expect((await db.select(db.transactions).get()), isEmpty);
  });

  testWidgets('report page renders metrics without AI summary', (tester) async {    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPresetData(db);
    final accounts = AccountRepository(db);
    final bank = await accounts.createBankAccount(name: '测试卡', openingBalance: 100000);
    final categories = await (db.select(db.categories)).get();
    final food = categories.firstWhere((c) => c.name == '午餐' && c.type == 'expense');
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
    expect(find.text('餐饮'), findsWidgets);
  });

  test('seed creates two-level preset categories', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPresetData(db);
    final categories = await db.select(db.categories).get();
    final food = categories.firstWhere((c) => c.name == '餐饮' && c.type == 'expense');
    final lunch = categories.firstWhere((c) => c.name == '午餐' && c.type == 'expense');
    final invest = categories.firstWhere((c) => c.name == '投资' && c.type == 'income');
    final interest = categories.firstWhere((c) => c.name == '利息' && c.type == 'income');
    final other = categories.firstWhere((c) => c.name == '其他' && c.type == 'expense');
    expect(food.parentId, isNull);
    expect(lunch.parentId, food.id);
    expect(invest.parentId, isNull);
    expect(interest.parentId, invest.id);
    expect(other.parentId, isNull);
    expect(other.isFixed, isTrue);
    expect(categories.where((c) => c.type == 'expense').length, greaterThan(50));
  });

  testWidgets('record sheet saves a second-level category', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPresetData(db);
    final categories = await db.select(db.categories).get();
    final lunch = categories.firstWhere((c) => c.name == '午餐' && c.type == 'expense');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const JizhangApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('记一笔').last);
    await tester.pumpAndSettle();
    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('午餐'), findsOneWidget);
    await tester.tap(find.text('午餐'));
    await tester.enterText(find.byType(TextFormField).first, '23.45');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final transaction = (await db.select(db.transactions).get()).single;
    expect(transaction.categoryId, lunch.id);
    expect(find.text('餐饮 · 午餐'), findsOneWidget);
  });

  test('existing one-level categories migrate into the two-level tree', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = CategoryRepository(db);
    await repository.create(name: '餐饮', type: 'expense', icon: 'food', isPreset: true);
    await repository.create(name: '房贷', type: 'expense', icon: 'mortgage', isPreset: true);
    await repository.create(name: '奖金', type: 'income', icon: 'gift', isPreset: true);
    await repository.create(name: '利息', type: 'income', icon: 'interest', isPreset: true);
    await repository.create(name: '其他', type: 'expense', icon: 'other', isPreset: true, isFixed: true);
    await repository.create(name: '其他', type: 'income', icon: 'other', isPreset: true, isFixed: true);

    await seedPresetData(db);
    final categories = await db.select(db.categories).get();
    final food = categories.firstWhere((c) => c.name == '餐饮' && c.type == 'expense');
    final lunch = categories.firstWhere((c) => c.name == '午餐' && c.type == 'expense');
    final finance = categories.firstWhere((c) => c.name == '金融' && c.type == 'expense');
    final mortgage = categories.firstWhere((c) => c.name == '房贷' && c.type == 'expense');
    final salary = categories.firstWhere((c) => c.name == '工资' && c.type == 'income');
    final bonus = categories.firstWhere((c) => c.name == '奖金' && c.type == 'income');
    final invest = categories.firstWhere((c) => c.name == '投资' && c.type == 'income');
    final interest = categories.firstWhere((c) => c.name == '利息' && c.type == 'income');
    expect(lunch.parentId, food.id);
    expect(mortgage.parentId, finance.id);
    expect(bonus.parentId, salary.id);
    expect(interest.parentId, invest.id);
    expect(categories.where((c) => c.name == '其他').length, 2);
  });
}
