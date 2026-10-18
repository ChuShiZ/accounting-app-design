import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang/数据/数据库.dart';
import 'package:jizhang/数据/仓库/交易仓库.dart';
import 'package:jizhang/数据/仓库/报表仓库.dart';
import 'package:jizhang/数据/仓库/类别仓库.dart';
import 'package:jizhang/数据/仓库/设置仓库.dart';
import 'package:jizhang/数据/仓库/账户仓库.dart';

void main() {
  late AppDatabase db;
  late AccountRepository accounts;
  late TransactionRepository transactions;
  late CategoryRepository categories;
  late ReportRepository reports;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    accounts = AccountRepository(db);
    transactions = TransactionRepository(db);
    categories = CategoryRepository(db);
    reports = ReportRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('余额由期初 + 收入 - 支出派生', () async {
    final id = await accounts.createBankAccount(name: '招商银行卡', openingBalance: 100000);
    await transactions.addIncome(amount: 5000, accountId: id, occurredAt: DateTime(2026, 6, 22));
    await transactions.addExpense(amount: 3000, accountId: id, occurredAt: DateTime(2026, 6, 22));
    expect(await accounts.balanceOf(id), 102000);
  });

  test('储值卡创建详情与余额口径', () async {
    final categoryId = await categories.create(name: '购物', type: 'expense', icon: 'cart');
    final id = await accounts.createStoredAccount(
      name: '银座购物卡',
      openingBalance: 85000,
      defaultCategoryId: categoryId,
    );
    final card = await (db.select(db.cardDetails)..where((t) => t.accountId.equals(id))).getSingle();
    expect(card.defaultCategoryId, categoryId);
    expect(await accounts.balanceOf(id), 85000);
  });

  test('贷款账户余额为负且详情完整', () async {
    final start = DateTime(2026, 1, 1);
    final id = await accounts.createLoanAccount(
      name: '测试房贷',
      kind: 'mortgage',
      originalPrincipal: 2000000,
      remainingPrincipal: 1500000,
      rateBp: 350,
      termMonths: 120,
      startAt: start,
      nextDueAt: DateTime(2026, 7, 1),
      perAmount: 180000,
    );
    final account = await accounts.findById(id);
    expect(account!.openingBalance, -1500000);
    final loan = await (db.select(db.loanDetails)..where((t) => t.accountId.equals(id))).getSingle();
    expect(loan.kind, 'mortgage');
    expect(loan.originalPrincipal, 2000000);
    expect(loan.rateBp, 350);
  });

  test('报表区间只统计收入和支出', () async {
    final id = await accounts.createBankAccount(name: '现金卡', openingBalance: 0);
    await transactions.addIncome(amount: 100000, accountId: id, occurredAt: DateTime(2026, 6, 22));
    await transactions.addExpense(amount: 30000, accountId: id, occurredAt: DateTime(2026, 6, 22));
    final totals = await reports.totalsFor(DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59, 59));
    expect(totals.income, 100000);
    expect(totals.expense, 30000);
    expect(totals.balance, 70000);
  });

  test('类别与设置读写', () async {
    await categories.create(name: '工资', type: 'income', icon: 'salary');
    final list = await categories.list('income');
    expect(list.map((e) => e.name), contains('工资'));

    await settings.set('default_account_id', '1');
    expect(await settings.get('default_account_id'), '1');
    await settings.set('default_account_id', '2');
    expect(await settings.get('default_account_id'), '2');
  });
}
