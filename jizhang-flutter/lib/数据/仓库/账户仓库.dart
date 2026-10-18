import 'package:drift/drift.dart';

import '../数据库.dart';

class AccountWithBalance {
  const AccountWithBalance({
    required this.account,
    required this.balance,
    this.card,
    this.loan,
    this.deposit,
  });

  final Account account;
  final int balance;
  final CardDetailRow? card;
  final LoanDetailRow? loan;
  final DepositDetailRow? deposit;
}

class AccountRepository {
  AccountRepository(this.db);

  final AppDatabase db;

  Future<List<Account>> listAccounts({bool includeArchived = false}) {
    final query = db.select(db.accounts)
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    if (!includeArchived) {
      query.where((t) => t.archived.equals(false));
    }
    return query.get();
  }

  Future<List<AccountWithBalance>> listWithBalances() async {
    final accounts = await listAccounts();
    final rows = await db.select(db.transactions).get();
    final cards = await db.select(db.cardDetails).get();
    final loans = await db.select(db.loanDetails).get();
    final deposits = await db.select(db.depositDetails).get();
    final cardMap = {for (final c in cards) c.accountId: c};
    final loanMap = {for (final l in loans) l.accountId: l};
    final depositMap = {for (final d in deposits) d.accountId: d};
    return accounts.map((account) {
      var balance = account.openingBalance;
      for (final t in rows) {
        if (t.type == 'income' && t.accountId == account.id) balance += t.amount;
        if (t.type == 'expense' && t.accountId == account.id) balance -= t.amount;
        if (t.type == 'transfer' && t.accountId == account.id) balance -= t.amount;
        if (t.type == 'transfer' && t.toAccountId == account.id) balance += t.amount;
      }
      return AccountWithBalance(
        account: account,
        balance: balance,
        card: cardMap[account.id],
        loan: loanMap[account.id],
        deposit: depositMap[account.id],
      );
    }).toList();
  }

  Future<CardDetailRow?> cardDetailOf(int id) {
    return (db.select(db.cardDetails)..where((t) => t.accountId.equals(id))).getSingleOrNull();
  }

  Future<LoanDetailRow?> loanDetailOf(int id) {
    return (db.select(db.loanDetails)..where((t) => t.accountId.equals(id))).getSingleOrNull();
  }

  Future<bool> hasTransactions(int id) async {
    final rows = await (db.select(db.transactions)
          ..where((t) => t.accountId.equals(id) | t.toAccountId.equals(id)))
        .get();
    return rows.isNotEmpty;
  }

  Future<void> archiveAccount(int id) {
    return (db.update(db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        archived: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<bool> deleteOrArchiveAccount(int id) async {
    final has = await hasTransactions(id);
    if (has) {
      await archiveAccount(id);
      return false;
    }
    await db.transaction(() async {
      await (db.delete(db.cardDetails)..where((t) => t.accountId.equals(id))).go();
      await (db.delete(db.loanDetails)..where((t) => t.accountId.equals(id))).go();
      await (db.delete(db.depositDetails)..where((t) => t.accountId.equals(id))).go();
      await (db.delete(db.accounts)..where((t) => t.id.equals(id))).go();
    });
    return true;
  }

  Future<Account?> findById(int id) {
    return (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<bool> nameExists(String name, {int? excludeId}) async {
    final rows = await (db.select(db.accounts)..where((t) => t.name.equals(name))).get();
    return rows.any((row) => row.id != excludeId);
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

  Future<int> createCreditAccount({
    required String name,
    String? institution,
    int openingDebt = 0,
    int? creditLimit,
    int? billingDay,
    int? repaymentDay,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction(() async {
      final accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
            type: 'credit',
            name: name,
            institution: Value(institution),
            icon: 'credit',
            openingBalance: Value(-openingDebt.abs()),
            note: Value(note),
            createdAt: Value(now),
          ));
      await db.into(db.cardDetails).insert(CardDetailsCompanion.insert(
            accountId: Value(accountId),
            creditLimit: Value(creditLimit),
            billingDay: Value(billingDay),
            repaymentDay: Value(repaymentDay),
          ));
      return accountId;
    });
  }

  Future<void> updateCreditAccount(
    int id, {
    required String name,
    String? institution,
    int? creditLimit,
    int? billingDay,
    int? repaymentDay,
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
        CardDetailsCompanion(
          creditLimit: Value(creditLimit),
          billingDay: Value(billingDay),
          repaymentDay: Value(repaymentDay),
        ),
      );
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
