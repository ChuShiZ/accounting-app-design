import 'package:drift/drift.dart';

import '../数据库.dart';
import '交易仓库.dart';
import '类别仓库.dart';
import '账户仓库.dart';

/// 资产动作的领域规则：所有余额变化都由交易派生，不直接写余额。
class AssetRepository {
  AssetRepository(this.db);

  final AppDatabase db;

  TransactionRepository get _tx => TransactionRepository(db);
  AccountRepository get _accounts => AccountRepository(db);
  CategoryRepository get _categories => CategoryRepository(db);

  Future<int?> _categoryId(String name, String type) async {
    final row = await _categories.findByName(name, type);
    return row?.id;
  }

  Future<void> _requireBalance(int accountId, int amount) async {
    final balance = await _accounts.balanceOf(accountId);
    if (amount > balance) {
      throw ArgumentError('付款账户余额不足');
    }
  }

  /// 储值卡充值：银行支出实付、储值卡到账实付 + 赠送；赠送计收入。
  Future<void> rechargeStored({
    required int storedAccountId,
    required int fromAccountId,
    required int paid,
    required int bonus,
    required DateTime occurredAt,
    String? note,
  }) async {
    if (paid <= 0) throw ArgumentError('请输入实付金额');
    if (bonus < 0) throw ArgumentError('赠送金额不能为负');
    await _requireBalance(fromAccountId, paid);
    final groupId = 'recharge-${DateTime.now().microsecondsSinceEpoch}';
    final rechargeCategory = await _categoryId('储值卡充值', 'expense');
    final giftCategory = await _categoryId('赠送', 'income');
    await db.transaction(() async {
      await _tx.addExpense(
        amount: paid,
        accountId: fromAccountId,
        categoryId: rechargeCategory,
        occurredAt: occurredAt,
        note: note?.isNotEmpty == true ? note : '储值卡充值',
        groupId: groupId,
        groupKind: 'recharge',
        locked: true,
      );
      // 实付从银行“搬”到储值卡，内部收入不再计一次收入。
      await _tx.addIncome(
        amount: paid,
        accountId: storedAccountId,
        categoryId: null,
        occurredAt: occurredAt,
        note: '充值到账（内部）',
        groupId: groupId,
        groupKind: 'recharge',
        reportable: false,
        locked: true,
      );
      if (bonus > 0) {
        await _tx.addIncome(
          amount: bonus,
          accountId: storedAccountId,
          categoryId: giftCategory,
          occurredAt: occurredAt,
          note: '充值赠送',
          groupId: groupId,
          groupKind: 'recharge',
          locked: true,
        );
      }
    });
  }

  /// 信用卡还款：银行 → 信用卡，转账不计支出。
  Future<void> repayCredit({
    required int creditAccountId,
    required int fromAccountId,
    required int amount,
    required DateTime occurredAt,
    String? note,
  }) async {
    if (amount <= 0) throw ArgumentError('请输入还款金额');
    final balance = await _accounts.balanceOf(creditAccountId);
    if (amount > -balance) throw ArgumentError('还款金额不能超过待还金额');
    await _requireBalance(fromAccountId, amount);
    await _tx.addTransfer(
      amount: amount,
      accountId: fromAccountId,
      toAccountId: creditAccountId,
      occurredAt: occurredAt,
      note: note?.isNotEmpty == true ? note : '信用卡还款',
      groupKind: 'credit_repay',
    );
  }

  /// 贷款还款：月供整笔计支出；贷款余额通过内部收入回补，不计收入。
  Future<void> repayLoan({
    required int loanAccountId,
    required int fromAccountId,
    required int amount,
    required DateTime occurredAt,
    String? note,
  }) async {
    if (amount <= 0) throw ArgumentError('请输入还款金额');
    final balance = await _accounts.balanceOf(loanAccountId);
    if (amount > -balance) throw ArgumentError('还款金额不能超过剩余本金');
    await _requireBalance(fromAccountId, amount);
    final loan = await _accounts.loanDetailOf(loanAccountId);
    if (loan == null) throw StateError('贷款详情不存在');
    final categoryName = loan.kind == 'car' ? '车贷' : (loan.kind == 'mortgage' ? '房贷' : '贷款');
    final categoryId = await _categoryId(categoryName, 'expense');
    final groupId = 'loan-${DateTime.now().microsecondsSinceEpoch}';
    await db.transaction(() async {
      await _tx.addExpense(
        amount: amount,
        accountId: fromAccountId,
        categoryId: categoryId,
        occurredAt: occurredAt,
        note: note?.isNotEmpty == true ? note : '贷款月供',
        groupId: groupId,
        groupKind: 'loan_payment',
        locked: true,
      );
      await _tx.addIncome(
        amount: amount,
        accountId: loanAccountId,
        categoryId: null,
        occurredAt: occurredAt,
        note: '贷款余额回补（内部）',
        groupId: groupId,
        groupKind: 'loan_payment',
        reportable: false,
        locked: true,
      );
      final currentDue = DateTime.fromMillisecondsSinceEpoch(loan.nextDueAt);
      final next = addMonths(currentDue, 1);
      await (db.update(db.loanDetails)..where((t) => t.accountId.equals(loanAccountId))).write(
        LoanDetailsCompanion(nextDueAt: Value(next.millisecondsSinceEpoch)),
      );
    });
  }

  Future<int> createDeposit({
    required String name,
    required String bank,
    required int principal,
    required int rateBp,
    required int termMonths,
    required DateTime startAt,
    String? certificateNo,
    String? note,
    int? sourceAccountId,
  }) async {
    if (principal <= 0) throw ArgumentError('请输入本金');
    if (termMonths <= 0) throw ArgumentError('请输入存期');
    if (sourceAccountId != null) {
      await _requireBalance(sourceAccountId, principal);
    }
    final maturity = addMonths(startAt, termMonths);
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction(() async {
      final id = await db.into(db.accounts).insert(AccountsCompanion.insert(
            type: 'deposit',
            name: name,
            institution: Value(bank),
            icon: 'deposit',
            openingBalance: Value(sourceAccountId == null ? principal : 0),
            note: Value(note),
            createdAt: Value(now),
          ));
      await db.into(db.depositDetails).insert(DepositDetailsCompanion.insert(
            accountId: Value(id),
            certificateNo: Value(certificateNo),
            principal: principal,
            rateBp: rateBp,
            termMonths: termMonths,
            startAt: startAt.millisecondsSinceEpoch,
            maturityAt: maturity.millisecondsSinceEpoch,
          ));
      if (sourceAccountId != null) {
        await _tx.addTransfer(
          amount: principal,
          accountId: sourceAccountId,
          toAccountId: id,
          occurredAt: startAt,
          note: '购买存单',
          groupKind: 'deposit_buy',
        );
      }
      return id;
    });
  }

  Future<void> updateDeposit(
    int accountId, {
    required String name,
    required String bank,
    required int principal,
    required int rateBp,
    required int termMonths,
    required DateTime startAt,
    String? certificateNo,
    String? note,
  }) async {
    final detail = await depositDetailOf(accountId);
    if (detail == null) throw StateError('存单详情不存在');
    final currentBalance = await _accounts.balanceOf(accountId);
    final account = await _accounts.findById(accountId);
    final newOpening = (account?.openingBalance ?? 0) + (principal - currentBalance);
    final maturity = addMonths(startAt, termMonths);
    await db.transaction(() async {
      await (db.update(db.accounts)..where((t) => t.id.equals(accountId))).write(
        AccountsCompanion(
          name: Value(name),
          institution: Value(bank),
          openingBalance: Value(newOpening),
          note: Value(note),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await (db.update(db.depositDetails)..where((t) => t.accountId.equals(accountId))).write(
        DepositDetailsCompanion(
          certificateNo: Value(certificateNo),
          principal: Value(principal),
          rateBp: Value(rateBp),
          termMonths: Value(termMonths),
          startAt: Value(startAt.millisecondsSinceEpoch),
          maturityAt: Value(maturity.millisecondsSinceEpoch),
        ),
      );
    });
  }

  Future<DepositDetailRow?> depositDetailOf(int accountId) {
    return (db.select(db.depositDetails)..where((t) => t.accountId.equals(accountId))).getSingleOrNull();
  }

  Future<void> settleDeposit({
    required int depositAccountId,
    required int toAccountId,
    required int actualInterest,
    required String mode,
    required DateTime occurredAt,
  }) async {
    if (actualInterest < 0) throw ArgumentError('利息不能为负');
    final detail = await depositDetailOf(depositAccountId);
    if (detail == null) throw StateError('存单详情不存在');
    if (detail.closedAt != null) throw StateError('存单已关闭');
    final interestCategory = await _categoryId('利息', 'income');
    final groupId = 'deposit-settle-${DateTime.now().microsecondsSinceEpoch}';
    await db.transaction(() async {
      await _tx.addTransfer(
        amount: detail.principal,
        accountId: depositAccountId,
        toAccountId: toAccountId,
        occurredAt: occurredAt,
        note: mode == 'early' ? '存单提前支取本金' : '存单到期支取本金',
        groupId: groupId,
        groupKind: 'deposit_settle',
      );
      if (actualInterest > 0) {
        await _tx.addIncome(
          amount: actualInterest,
          accountId: toAccountId,
          categoryId: interestCategory,
          occurredAt: occurredAt,
          note: mode == 'early' ? '存单提前支取利息' : '存单到期利息',
          groupId: groupId,
          groupKind: 'deposit_settle',
          locked: true,
        );
      }
      await (db.update(db.depositDetails)..where((t) => t.accountId.equals(depositAccountId))).write(
        DepositDetailsCompanion(
          closedAt: Value(occurredAt.millisecondsSinceEpoch),
          closeType: Value(mode == 'early' ? 'early' : 'maturity'),
          actualInterest: Value(actualInterest),
        ),
      );
    });
  }

  Future<int> renewDeposit({
    required int oldDepositAccountId,
    required String name,
    required int actualInterest,
    required int newPrincipal,
    required int rateBp,
    required int termMonths,
    required DateTime startAt,
    String? certificateNo,
    String? note,
  }) async {
    if (actualInterest < 0) throw ArgumentError('利息不能为负');
    final oldDetail = await depositDetailOf(oldDepositAccountId);
    if (oldDetail == null) throw StateError('存单详情不存在');
    if (oldDetail.closedAt != null) throw StateError('存单已关闭');
    final oldAccount = await _accounts.findById(oldDepositAccountId);
    if (oldAccount == null) throw StateError('存单账户不存在');
    final maturity = addMonths(startAt, termMonths);
    final now = DateTime.now().millisecondsSinceEpoch;
    final interestCategory = await _categoryId('利息', 'income');
    final groupId = 'deposit-renew-${DateTime.now().microsecondsSinceEpoch}';
    return db.transaction(() async {
      final newId = await db.into(db.accounts).insert(AccountsCompanion.insert(
            type: 'deposit',
            name: name,
            institution: Value(oldAccount.institution),
            icon: 'deposit',
            openingBalance: const Value(0),
            note: Value(note),
            createdAt: Value(now),
          ));
      await db.into(db.depositDetails).insert(DepositDetailsCompanion.insert(
            accountId: Value(newId),
            certificateNo: Value(certificateNo),
            principal: newPrincipal,
            rateBp: rateBp,
            termMonths: termMonths,
            startAt: startAt.millisecondsSinceEpoch,
            maturityAt: maturity.millisecondsSinceEpoch,
          ));
      await _tx.addTransfer(
        amount: oldDetail.principal,
        accountId: oldDepositAccountId,
        toAccountId: newId,
        occurredAt: startAt,
        note: '存单转存本金',
        groupId: groupId,
        groupKind: 'deposit_renew',
      );
      if (actualInterest > 0) {
        await _tx.addIncome(
          amount: actualInterest,
          accountId: newId,
          categoryId: interestCategory,
          occurredAt: startAt,
          note: '存单转存利息',
          groupId: groupId,
          groupKind: 'deposit_renew',
          locked: true,
        );
      }
      await (db.update(db.depositDetails)..where((t) => t.accountId.equals(oldDepositAccountId))).write(
        DepositDetailsCompanion(
          closedAt: Value(startAt.millisecondsSinceEpoch),
          closeType: const Value('renew'),
          actualInterest: Value(actualInterest),
        ),
      );
      return newId;
    });
  }

  Future<bool> deleteDeposit(int accountId) async {
    final hasTransactions = await _accounts.hasTransactions(accountId);
    if (hasTransactions) {
      await _accounts.archiveAccount(accountId);
      return false;
    }
    await db.transaction(() async {
      await (db.delete(db.depositDetails)..where((t) => t.accountId.equals(accountId))).go();
      await (db.delete(db.accounts)..where((t) => t.id.equals(accountId))).go();
    });
    return true;
  }

  int expectedInterest(DepositDetailRow detail) {
    return (detail.principal * detail.rateBp * detail.termMonths / (10000 * 12)).round();
  }
}

DateTime addMonths(DateTime date, int months) {
  final total = date.month - 1 + months;
  final year = date.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
}
