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
  }) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', '金额必须大于 0');
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          type: 'income',
          amount: amount,
          occurredAt: occurredAt.millisecondsSinceEpoch,
          categoryId: Value(categoryId),
          accountId: accountId,
          note: Value(note),
          createdAt: Value(now),
        ));
  }

  Future<int> addExpense({
    required int amount,
    required int accountId,
    int? categoryId,
    required DateTime occurredAt,
    String? note,
  }) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', '金额必须大于 0');
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          type: 'expense',
          amount: amount,
          occurredAt: occurredAt.millisecondsSinceEpoch,
          categoryId: Value(categoryId),
          accountId: accountId,
          note: Value(note),
          createdAt: Value(now),
        ));
  }

  Future<List<TransactionRow>> listRecent({int limit = 50}) {
    return (db.select(db.transactions)
          ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  Future<List<TransactionRow>> listForAccount(int accountId) {
    return (db.select(db.transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<void> deleteById(int id) {
    return (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }
}
