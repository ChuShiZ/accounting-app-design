import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang/数据/数据库.dart';
import 'package:jizhang/数据/仓库/交易仓库.dart';
import 'package:jizhang/数据/仓库/报表仓库.dart';
import 'package:jizhang/数据/仓库/类别仓库.dart';
import 'package:jizhang/数据/仓库/设置仓库.dart';
import 'package:jizhang/数据/仓库/账户仓库.dart';
import 'package:jizhang/数据/仓库/资产仓库.dart';
import 'package:jizhang/数据/种子数据.dart';
import 'package:jizhang/数据/首页数据.dart';
import 'package:jizhang/同步/备份服务.dart';

void main() {
  late AppDatabase db;
  late AccountRepository accounts;
  late TransactionRepository transactions;
  late CategoryRepository categories;
  late ReportRepository reports;
  late SettingsRepository settings;
  late AssetRepository assets;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    accounts = AccountRepository(db);
    transactions = TransactionRepository(db);
    categories = CategoryRepository(db);
    reports = ReportRepository(db);
    settings = SettingsRepository(db);
    assets = AssetRepository(db);
    await seedPresetData(db);
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

  test('账户编辑、重名检查与无流水删除', () async {
    final id = await accounts.createBankAccount(name: '招行卡', openingBalance: 10000);
    expect(await accounts.nameExists('招行卡'), isTrue);
    expect(await accounts.nameExists('招行卡', excludeId: id), isFalse);
    await accounts.updateBankAccount(id, name: '招行储蓄卡', institution: '招商银行');
    final updated = await accounts.findById(id);
    expect(updated!.name, '招行储蓄卡');
    expect(updated.institution, '招商银行');

    final deleted = await accounts.deleteOrArchiveAccount(id);
    expect(deleted, isTrue);
    expect(await accounts.findById(id), isNull);
  });

  test('有流水账户只归档，列表不再显示', () async {
    final id = await accounts.createBankAccount(name: '有流水卡', openingBalance: 10000);
    await transactions.addExpense(amount: 100, accountId: id, occurredAt: DateTime(2026, 6, 22));
    final deleted = await accounts.deleteOrArchiveAccount(id);
    expect(deleted, isFalse);
    final archived = await accounts.findById(id);
    expect(archived!.archived, isTrue);
    final active = await accounts.listWithBalances();
    expect(active.any((a) => a.account.id == id), isFalse);
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

  test('储值卡充值/消费：充值计支出、赠送计收入、消费不重复计支出', () async {
    final bank = await accounts.createBankAccount(name: '银行', openingBalance: 100000);
    final stored = await accounts.createStoredAccount(name: '储值卡', openingBalance: 0);
    final date = DateTime(2026, 6, 22, 12);
    await assets.rechargeStored(
      storedAccountId: stored,
      fromAccountId: bank,
      paid: 10000,
      bonus: 1000,
      occurredAt: date,
    );
    expect(await accounts.balanceOf(bank), 90000);
    expect(await accounts.balanceOf(stored), 11000);

    var totals = await reports.totalsFor(DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59, 59));
    expect(totals.expense, 10000);
    expect(totals.income, 1000);

    await transactions.addExpense(
      amount: 2000,
      accountId: stored,
      categoryId: (await categories.findByName('购物', 'expense'))!.id,
      occurredAt: date,
      reportable: false,
    );
    expect(await accounts.balanceOf(stored), 9000);
    totals = await reports.totalsFor(DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59, 59));
    expect(totals.expense, 10000);
  });

  test('信用卡消费计支出，还款为转账不重复计支出', () async {
    final bank = await accounts.createBankAccount(name: '还款卡', openingBalance: 100000);
    final credit = await accounts.createCreditAccount(name: '信用卡', openingDebt: 0, repaymentDay: 20);
    final date = DateTime(2026, 6, 22);
    await transactions.addExpense(
      amount: 5000,
      accountId: credit,
      categoryId: (await categories.findByName('餐饮', 'expense'))!.id,
      occurredAt: date,
    );
    expect(await accounts.balanceOf(credit), -5000);
    await assets.repayCredit(
      creditAccountId: credit,
      fromAccountId: bank,
      amount: 5000,
      occurredAt: date,
    );
    expect(await accounts.balanceOf(credit), 0);
    expect(await accounts.balanceOf(bank), 95000);
    final totals = await reports.totalsFor(DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59, 59));
    expect(totals.expense, 5000);
  });

  test('贷款还款整笔计支出，剩余本金同步减少', () async {
    final bank = await accounts.createBankAccount(name: '还款卡', openingBalance: 200000);
    final loan = await accounts.createLoanAccount(
      name: '房贷',
      kind: 'mortgage',
      originalPrincipal: 100000,
      remainingPrincipal: 100000,
      rateBp: 350,
      termMonths: 120,
      startAt: DateTime(2026, 1, 1),
      nextDueAt: DateTime(2026, 7, 1),
    );
    await assets.repayLoan(
      loanAccountId: loan,
      fromAccountId: bank,
      amount: 10000,
      occurredAt: DateTime(2026, 6, 22),
    );
    expect(await accounts.balanceOf(loan), -90000);
    expect(await accounts.balanceOf(bank), 190000);
    final totals = await reports.totalsFor(DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59, 59));
    expect(totals.expense, 10000);
    final detail = await accounts.loanDetailOf(loan);
    expect(DateTime.fromMillisecondsSinceEpoch(detail!.nextDueAt).month, 8);
  });

  test('存单购买/到期：本金不计收支，利息计收入', () async {
    final bank = await accounts.createBankAccount(name: '银行', openingBalance: 200000);
    final deposit = await assets.createDeposit(
      name: '存单',
      bank: '招商银行',
      principal: 100000,
      rateBp: 325,
      termMonths: 36,
      startAt: DateTime(2026, 1, 1),
      sourceAccountId: bank,
    );
    expect(await accounts.balanceOf(bank), 100000);
    expect(await accounts.balanceOf(deposit), 100000);
    var totals = await reports.totalsFor(DateTime(2026, 1, 1), DateTime(2026, 12, 31, 23, 59, 59));
    expect(totals.income, 0);
    expect(totals.expense, 0);

    await assets.settleDeposit(
      depositAccountId: deposit,
      toAccountId: bank,
      actualInterest: 3000,
      mode: 'maturity',
      occurredAt: DateTime(2026, 6, 22),
    );
    expect(await accounts.balanceOf(deposit), 0);
    expect(await accounts.balanceOf(bank), 203000);
    totals = await reports.totalsFor(DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59, 59));
    expect(totals.income, 3000);
    expect(totals.expense, 0);
    final detail = await assets.depositDetailOf(deposit);
    expect(detail!.closedAt, isNotNull);
  });

  test('存单转存：旧存单关闭，新存单本息正确', () async {
    final bank = await accounts.createBankAccount(name: '银行', openingBalance: 200000);
    final old = await assets.createDeposit(
      name: '旧存单',
      bank: '招商银行',
      principal: 100000,
      rateBp: 300,
      termMonths: 12,
      startAt: DateTime(2025, 1, 1),
      sourceAccountId: bank,
    );
    final newId = await assets.renewDeposit(
      oldDepositAccountId: old,
      name: '新存单',
      actualInterest: 3000,
      newPrincipal: 103000,
      rateBp: 300,
      termMonths: 12,
      startAt: DateTime(2026, 1, 1),
    );
    expect(await accounts.balanceOf(old), 0);
    expect(await accounts.balanceOf(newId), 103000);
    expect((await assets.depositDetailOf(old))!.closedAt, isNotNull);
    expect((await assets.depositDetailOf(newId))!.principal, 103000);
  });

  test('报表月报：分类、趋势、五期对比与排行', () async {
    final bank = await accounts.createBankAccount(name: '银行', openingBalance: 500000);
    final food = (await categories.findByName('餐饮', 'expense'))!.id;
    final salary = (await categories.findByName('工资', 'income'))!.id;
    await transactions.addExpense(amount: 10000, accountId: bank, categoryId: food, occurredAt: DateTime(2026, 6, 10));
    await transactions.addExpense(amount: 5000, accountId: bank, categoryId: food, occurredAt: DateTime(2026, 6, 20));
    await transactions.addIncome(amount: 300000, accountId: bank, categoryId: salary, occurredAt: DateTime(2026, 6, 1));
    await transactions.addExpense(amount: 7000, accountId: bank, categoryId: food, occurredAt: DateTime(2026, 5, 10));
    final data = await reports.build(period: '月', kind: 'expense', offset: 0, now: DateTime(2026, 6, 22));
    expect(data.expense, 15000);
    expect(data.income, 300000);
    expect(data.total, 15000);
    expect(data.prevTotal, 7000);
    expect(data.changePct, 114);
    expect(data.categories.first.name, '餐饮');
    expect(data.categories.first.amount, 15000);
    expect(data.trend.length, 30);
    expect(data.trend[9], 10000);
    expect(data.trend[19], 5000);
    expect(data.comparison.length, 5);
    expect(data.comparison.last.current, isTrue);
    expect(data.top.length, 2);
    expect(data.top.first.transaction.amount, 10000);
  });

  test('删除已用类别归入其他，固定类别不可删除', () async {
    final custom = await categories.create(name: '测试类', type: 'expense', icon: 'cart');
    final bank = await accounts.createBankAccount(name: '银行', openingBalance: 10000);
    await transactions.addExpense(amount: 1000, accountId: bank, categoryId: custom, occurredAt: DateTime(2026, 6, 22));
    await categories.deleteCategory(custom);
    expect(await categories.findByName('测试类', 'expense'), isNull);
    final row = await (db.select(db.transactions)).getSingle();
    final other = await categories.findByName('其他', 'expense');
    expect(row.categoryId, other!.id);
    final fixed = await categories.findByName('其他', 'expense');
    expect(() => categories.deleteCategory(fixed!.id), throwsStateError);
  });

  test('流水编辑与删除回退余额、报表与首页', () async {
    final bank = await accounts.createBankAccount(name: '银行', openingBalance: 100000);
    final food = (await categories.findByName('餐饮', 'expense'))!.id;
    final id = await transactions.addExpense(
      amount: 5000,
      accountId: bank,
      categoryId: food,
      occurredAt: DateTime.now(),
    );
    expect(await accounts.balanceOf(bank), 95000);
    await transactions.updateTransaction(
      id,
      type: 'expense',
      amount: 3000,
      accountId: bank,
      categoryId: food,
      occurredAt: DateTime.now(),
      reportable: true,
    );
    expect(await accounts.balanceOf(bank), 97000);
    await transactions.deleteById(id);
    expect(await accounts.balanceOf(bank), 100000);
    final home = await HomeRepository(db).snapshot();
    expect(home.groups, isEmpty);
  });

  test('首页待办：30 天内存单、7 天内信用卡还款', () async {
    final bank = await accounts.createBankAccount(name: '银行', openingBalance: 500000);
    await assets.createDeposit(
      name: '快到期存单',
      bank: '招商银行',
      principal: 10000,
      rateBp: 300,
      termMonths: 12,
      startAt: DateTime(2025, 10, 25),
      sourceAccountId: bank,
    );
    final credit = await accounts.createCreditAccount(name: '信用卡', repaymentDay: 20);
    await transactions.addExpense(
      amount: 5000,
      accountId: credit,
      categoryId: (await categories.findByName('餐饮', 'expense'))!.id,
      occurredAt: DateTime(2026, 10, 18),
    );
    final home = await HomeRepository(db).snapshot(now: DateTime(2026, 10, 18));
    expect(home.dueItems.any((item) => item.kind == 'deposit'), isTrue);
    expect(home.dueItems.any((item) => item.kind == 'credit'), isTrue);
  });

  test('WebDAV 配置：备份目录不落根、图片默认不备份', () {
    final config = WebDavConfig(
      baseUrl: 'https://dav.jianguoyun.com/dav/',
      username: 'user',
      password: 'pass',
    );
    expect(config.folder, '记账备份');
    expect(config.includeImages, isFalse);
    expect(WebDavConfig(baseUrl: 'https://example.com/dav/', username: 'u', password: 'p', folder: '/').folder, '记账备份');
    expect(WebDavConfig(baseUrl: 'https://example.com/dav/', username: 'u', password: 'p', folder: 'foo/bar').folderSegments, ['foo', 'bar']);
  });
}
