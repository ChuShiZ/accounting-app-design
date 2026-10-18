import 'package:drift/drift.dart';

import '../数据库.dart';

class ReportTotals {
  const ReportTotals({
    required this.from,
    required this.to,
    required this.income,
    required this.expense,
  });

  final DateTime from;
  final DateTime to;
  final int income;
  final int expense;

  int get balance => income - expense;
}

class ReportRepository {
  ReportRepository(this.db);

  final AppDatabase db;

  Future<ReportTotals> totalsFor(DateTime from, DateTime to) async {
    final start = from.millisecondsSinceEpoch;
    final end = to.millisecondsSinceEpoch;
    final rows = await (db.select(db.transactions)
          ..where((t) => t.occurredAt.isBetweenValues(start, end)))
        .get();
    var income = 0;
    var expense = 0;
    for (final row in rows) {
      if (row.type == 'income') income += row.amount;
      if (row.type == 'expense') expense += row.amount;
    }
    return ReportTotals(from: from, to: to, income: income, expense: expense);
  }
}
