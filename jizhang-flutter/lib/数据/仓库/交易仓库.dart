import 'package:drift/drift.dart';

import '../数据库.dart';
class TransactionRepository {
  TransactionRepository(this.db);

  final AppDatabase db;

  Future<int> addIncome({
    required int amount,
    required int accountId,
    int? categoryId,
    required DateTime occurredAt,
    String? note,
    String? groupId,
    String? groupKind,
    bool reportable = true,
    bool locked = false,
    String? imagePath,
  }) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', '金额必须大于 0');
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          type: 'income',
          amount: amount,
          occurredAt: occurredAt.millisecondsSinceEpoch,
          categoryId: Value(categoryId),
          accountId: accountId,
          groupId: Value(groupId),
          groupKind: Value(groupKind),
          reportable: Value(reportable),
          locked: Value(locked),
          note: Value(note),
          imagePath: Value(imagePath),
          createdAt: Value(now),
        ));
  }

  Future<int> addExpense({
    required int amount,
    required int accountId,
    int? categoryId,
    required DateTime occurredAt,
    String? note,
    String? groupId,
    String? groupKind,
    bool reportable = true,
    bool locked = false,
    String? imagePath,
  }) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', '金额必须大于 0');
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          type: 'expense',
          amount: amount,
          occurredAt: occurredAt.millisecondsSinceEpoch,
          categoryId: Value(categoryId),
          accountId: accountId,
          groupId: Value(groupId),
          groupKind: Value(groupKind),
          reportable: Value(reportable),
          locked: Value(locked),
          note: Value(note),
          imagePath: Value(imagePath),
          createdAt: Value(now),
        ));
  }

  Future<int> addTransfer({
    required int amount,
    required int accountId,
    required int toAccountId,
    required DateTime occurredAt,
    String? note,
    String? groupId,
    String? groupKind,
  }) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', '金额必须大于 0');
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          type: 'transfer',
          amount: amount,
          occurredAt: occurredAt.millisecondsSinceEpoch,
          accountId: accountId,
          toAccountId: Value(toAccountId),
          groupId: Value(groupId),
          groupKind: Value(groupKind),
          reportable: const Value(false),
          locked: const Value(true),
          note: Value(note),
          createdAt: Value(now),
        ));
  }

  Future<List<TransactionRow>> listRecent({int limit = 50, bool reportableOnly = false}) {
    final query = db.select(db.transactions)
      ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)])
      ..limit(limit);
    if (reportableOnly) {
      query.where((t) => t.reportable.equals(true));
    }
    return query.get();
  }

  Future<TransactionRow?> findById(int id) {
    return (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateTransaction(
    int id, {
    required String type,
    required int amount,
    required int accountId,
    int? categoryId,
    required DateTime occurredAt,
    String? note,
    required bool reportable,
    String? imagePath,
  }) {
    return (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        type: Value(type),
        amount: Value(amount),
        occurredAt: Value(occurredAt.millisecondsSinceEpoch),
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        note: Value(note),
        reportable: Value(reportable),
        imagePath: Value(imagePath),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<List<TransactionRow>> listForAccount(int accountId) {
    return (db.select(db.transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<void> updateCategory(int id, int? categoryId) {
    return (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(categoryId: Value(categoryId)),
    );
  }

  Future<void> deleteById(int id) {
    return (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }
}
