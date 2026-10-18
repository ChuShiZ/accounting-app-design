import 'package:drift/drift.dart';

import '../数据库.dart';
class AccountRepository {
  AccountRepository(this.db);

  final AppDatabase db;

  Future<List<Account>> listAccounts() {
    return (db.select(db.accounts)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
  }

  Future<Account?> findById(int id) {
    return (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createBankAccount({
    required String name,
    String? institution,
    int openingBalance = 0,
    String icon = 'bank',
    String? note,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.into(db.accounts).insert(AccountsCompanion.insert(
          type: 'bank',
          name: name,
          institution: Value(institution),
          icon: icon,
          openingBalance: Value(openingBalance),
          note: Value(note),
          createdAt: Value(now),
        ));
  }

  Future<int> createStoredAccount({
    required String name,
    String? institution,
    int openingBalance = 0,
    int? defaultCategoryId,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction(() async {
      final accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
            type: 'stored',
            name: name,
            institution: Value(institution),
            icon: 'cart',
            openingBalance: Value(openingBalance),
            note: Value(note),
            createdAt: Value(now),
          ));
      await db.into(db.cardDetails).insert(CardDetailsCompanion.insert(
            accountId: Value(accountId),
            defaultCategoryId: Value(defaultCategoryId),
          ));
      return accountId;
    });
  }

  Future<int> createLoanAccount({
    required String name,
    String? institution,
    required String kind,
    required int originalPrincipal,
    required int remainingPrincipal,
    required int rateBp,
    required int termMonths,
    required DateTime startAt,
    required DateTime nextDueAt,
    int? perAmount,
    String repaymentMethod = 'equal_principal_interest',
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction(() async {
      final accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
            type: 'loan',
            name: name,
            institution: Value(institution),
            icon: kind == 'car' ? 'car' : (kind == 'mortgage' ? 'mortgage' : 'loan'),
            openingBalance: Value(-remainingPrincipal),
            note: Value(note),
            createdAt: Value(now),
          ));
      await db.into(db.loanDetails).insert(LoanDetailsCompanion.insert(
            accountId: Value(accountId),
            kind: kind,
            originalPrincipal: originalPrincipal,
            rateBp: rateBp,
            termMonths: termMonths,
            startAt: startAt.millisecondsSinceEpoch,
            nextDueAt: nextDueAt.millisecondsSinceEpoch,
            perAmount: Value(perAmount),
            repaymentMethod: repaymentMethod,
          ));
      return accountId;
    });
  }

  Future<void> updateBankAccount(
    int id, {
    required String name,
    String? institution,
    String? note,
  }) {
    return (db.update(db.accounts)..where((t) => t.id.equals(id))).write(AccountsCompanion(
      name: Value(name),
      institution: Value(institution),
      note: Value(note),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> updateStoredAccount(
    int id, {
    required String name,
    String? institution,
    int? defaultCategoryId,
    String? note,
  }) async {
    await db.transaction(() async {
      await (db.update(db.accounts)..where((t) => t.id.equals(id))).write(AccountsCompanion(
        name: Value(name),
        institution: Value(institution),
        note: Value(note),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
      await (db.update(db.cardDetails)..where((t) => t.accountId.equals(id))).write(
        CardDetailsCompanion(defaultCategoryId: Value(defaultCategoryId)),
      );
    });
  }

  Future<void> updateLoanAccount(
    int id, {
    required String name,
    String? institution,
    required String kind,
    required int originalPrincipal,
    required int remainingPrincipal,
    required int rateBp,
    required int termMonths,
    required DateTime startAt,
    required DateTime nextDueAt,
    int? perAmount,
    String repaymentMethod = 'equal_principal_interest',
    String? note,
  }) async {
    await db.transaction(() async {
      await (db.update(db.accounts)..where((t) => t.id.equals(id))).write(AccountsCompanion(
        name: Value(name),
        institution: Value(institution),
        icon: Value(kind == 'car' ? 'car' : (kind == 'mortgage' ? 'mortgage' : 'loan')),
        openingBalance: Value(-remainingPrincipal),
        note: Value(note),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
      await (db.update(db.loanDetails)..where((t) => t.accountId.equals(id))).write(LoanDetailsCompanion(
        kind: Value(kind),
        originalPrincipal: Value(originalPrincipal),
        rateBp: Value(rateBp),
        termMonths: Value(termMonths),
        startAt: Value(startAt.millisecondsSinceEpoch),
        nextDueAt: Value(nextDueAt.millisecondsSinceEpoch),
        perAmount: Value(perAmount),
        repaymentMethod: Value(repaymentMethod),
      ));
    });
  }

  Future<int> balanceOf(int accountId) async {
    final account = await findById(accountId);
    if (account == null) return 0;
    final rows = await db.select(db.transactions).get();
    var balance = account.openingBalance;
    for (final t in rows) {
      if (t.type == 'income' && t.accountId == accountId) balance += t.amount;
      if (t.type == 'expense' && t.accountId == accountId) balance -= t.amount;
      if (t.type == 'transfer' && t.accountId == accountId) balance -= t.amount;
      if (t.type == 'transfer' && t.toAccountId == accountId) balance += t.amount;
    }
    return balance;
  }
}
