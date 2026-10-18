import '../数据库.dart';

class ReportTotals {
  const ReportTotals({required this.income, required this.expense});

  final int income;
  final int expense;

  int get balance => income - expense;
}

class ReportCategory {
  const ReportCategory({
    required this.name,
    required this.icon,
    required this.amount,
    required this.count,
    required this.pct,
  });

  final String name;
  final String icon;
  final int amount;
  final int count;
  final int pct;
}

class ReportItem {
  const ReportItem({
    required this.transaction,
    required this.categoryName,
    required this.categoryIcon,
    required this.accountName,
  });

  final TransactionRow transaction;
  final String categoryName;
  final String categoryIcon;
  final String accountName;
}

class ReportComparison {
  const ReportComparison({required this.label, required this.amount, required this.current});

  final String label;
  final int amount;
  final bool current;
}

class ReportData {
  const ReportData({
    required this.from,
    required this.to,
    required this.income,
    required this.expense,
    required this.total,
    required this.prevTotal,
    required this.changePct,
    required this.daily,
    required this.categories,
    required this.trend,
    required this.top,
    required this.comparison,
    required this.trendLabels,
  });

  final DateTime from;
  final DateTime to;
  final int income;
  final int expense;
  final int total;
  final int prevTotal;
  final int? changePct;
  final int daily;
  final List<ReportCategory> categories;
  final List<int> trend;
  final List<ReportItem> top;
  final List<ReportComparison> comparison;
  final List<String> trendLabels;

  int get balance => income - expense;
  int get change => total - prevTotal;
}

class ReportRepository {
  ReportRepository(this.db);

  final AppDatabase db;

  Future<List<TransactionRow>> _reportable() async {
    final rows = await (db.select(db.transactions)..where((t) => t.reportable.equals(true))).get();
    return rows;
  }

  Future<ReportData> build({
    required String period,
    required String kind,
    required int offset,
    DateTime? now,
  }) async {
    final base = now ?? DateTime.now();
    final from = _rangeStart(period, offset, base);
    final to = _rangeEnd(period, offset, base);
    final rows = await _reportable();
    final categories = await db.select(db.categories).get();
    final accounts = await db.select(db.accounts).get();
    final categoryMap = {for (final c in categories) c.id: c.name};
    final categoryIconMap = {for (final c in categories) c.id: c.icon};
    final accountMap = {for (final a in accounts) a.id: a.name};

    final current = rows.where((t) => _inRange(t, from, to)).toList();
    final currentKind = current.where((t) => t.type == kind).toList();
    final income = current.where((t) => t.type == 'income').fold<int>(0, (s, t) => s + t.amount);
    final expense = current.where((t) => t.type == 'expense').fold<int>(0, (s, t) => s + t.amount);
    final total = kind == 'income' ? income : expense;

    final prevFrom = _rangeStart(period, offset - 1, base);
    final prevTo = _rangeEnd(period, offset - 1, base);
    final prevRows = rows.where((t) => _inRange(t, prevFrom, prevTo) && t.type == kind).toList();
    final prevTotal = prevRows.fold<int>(0, (s, t) => s + t.amount);
    final change = total - prevTotal;
    final changePct = prevTotal == 0 ? null : (change / prevTotal * 100).round();

    final dayCount = to.difference(from).inDays + 1;
    final daily = dayCount <= 0 ? 0 : (total / dayCount).round();

    final categoryMapAmounts = <int?, ReportCategory>{};
    for (final t in currentKind) {
      final key = t.categoryId;
      final existing = categoryMapAmounts[key];
      final name = categoryMap[key] ?? '其他';
      if (existing == null) {
        categoryMapAmounts[key] = ReportCategory(
          name: name,
          icon: categoryIconMap[key] ?? 'other',
          amount: t.amount,
          count: 1,
          pct: 0,
        );
      } else {
        categoryMapAmounts[key] = ReportCategory(
          name: existing.name,
          icon: existing.icon,
          amount: existing.amount + t.amount,
          count: existing.count + 1,
          pct: 0,
        );
      }
    }
    final cats = categoryMapAmounts.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
    final withPct = cats
        .map((c) => ReportCategory(
              name: c.name,
              icon: c.icon,
              amount: c.amount,
              count: c.count,
              pct: total == 0 ? 0 : (c.amount / total * 100).round(),
            ))
        .toList();

    final trend = _buildTrend(period, from, to, currentKind);
    final top = currentKind
        .sorted((a, b) => b.amount.compareTo(a.amount))
        .take(20)
        .map((t) => ReportItem(
              transaction: t,
              categoryName: categoryMap[t.categoryId] ?? '其他',
              categoryIcon: categoryIconMap[t.categoryId] ?? 'other',
              accountName: accountMap[t.accountId] ?? '',
            ))
        .toList();

    final comparison = <ReportComparison>[];
    for (var i = 4; i >= 0; i--) {
      final o = offset - i;
      final start = _rangeStart(period, o, base);
      final end = _rangeEnd(period, o, base);
      final amount = rows
          .where((t) => t.type == kind && _inRange(t, start, end))
          .fold<int>(0, (s, t) => s + t.amount);
      comparison.add(ReportComparison(label: _shortLabel(period, o, base), amount: amount, current: o == offset));
    }

    return ReportData(
      from: from,
      to: to,
      income: income,
      expense: expense,
      total: total,
      prevTotal: prevTotal,
      changePct: changePct,
      daily: daily,
      categories: withPct,
      trend: trend,
      top: top,
      comparison: comparison,
      trendLabels: _trendLabels(period, from),
    );
  }

  Future<ReportTotals> totalsFor(DateTime from, DateTime to) async {
    final rows = await _reportable();
    var income = 0;
    var expense = 0;
    for (final t in rows) {
      if (!_inRange(t, from, to)) continue;
      if (t.type == 'income') income += t.amount;
      if (t.type == 'expense') expense += t.amount;
    }
    return ReportTotals(income: income, expense: expense);
  }

  bool _inRange(TransactionRow t, DateTime from, DateTime to) {
    final at = DateTime.fromMillisecondsSinceEpoch(t.occurredAt);
    return !at.isBefore(from) && !at.isAfter(to);
  }

  DateTime _rangeStart(String period, int offset, DateTime base) {
    switch (period) {
      case '周':
        final monday = DateTime(base.year, base.month, base.day).subtract(Duration(days: base.weekday - 1));
        return monday.add(Duration(days: offset * 7));
      case '季':
        final q = (base.month - 1) ~/ 3;
        return DateTime(base.year, (q + offset) * 3 + 1, 1);
      case '年':
        return DateTime(base.year + offset, 1, 1);
      default:
        return DateTime(base.year, base.month + offset, 1);
    }
  }

  DateTime _rangeEnd(String period, int offset, DateTime base) {
    switch (period) {
      case '周':
        final start = _rangeStart(period, offset, base);
        return DateTime(start.year, start.month, start.day, 23, 59, 59, 999).add(const Duration(days: 6));
      case '季':
        final start = _rangeStart(period, offset, base);
        return DateTime(start.year, start.month + 3, 0, 23, 59, 59, 999);
      case '年':
        return DateTime(base.year + offset, 12, 31, 23, 59, 59, 999);
      default:
        final start = _rangeStart(period, offset, base);
        return DateTime(start.year, start.month + 1, 0, 23, 59, 59, 999);
    }
  }

  List<int> _buildTrend(String period, DateTime from, DateTime to, List<TransactionRow> rows) {
    if (period == '季' || period == '年') {
      final count = period == '季' ? 3 : 12;
      return List<int>.generate(count, (i) {
        final start = DateTime(from.year, from.month + i, 1);
        final end = DateTime(from.year, from.month + i + 1, 0, 23, 59, 59, 999);
        return rows.where((t) => _inRange(t, start, end)).fold<int>(0, (s, t) => s + t.amount);
      });
    }
    final days = to.difference(from).inDays + 1;
    return List<int>.generate(days, (i) {
      final day = DateTime(from.year, from.month, from.day + i);
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
      return rows.where((t) => _inRange(t, start, end)).fold<int>(0, (s, t) => s + t.amount);
    });
  }

  List<String> _trendLabels(String period, DateTime from) {
    if (period == '年') return List<String>.generate(12, (i) => '${i + 1}月');
    if (period == '季') return List<String>.generate(3, (i) => '${from.month + i}月');
    if (period == '周') {
      return List<String>.generate(7, (i) => '${from.month}-${(from.day + i).toString().padLeft(2, '0')}');
    }
    final daysInMonth = DateTime(from.year, from.month + 1, 0).day;
    final picks = <int>[1, 5, 10, 15, 20, 25, daysInMonth];
    return picks.map((d) => '$d日').toList();
  }

  String _shortLabel(String period, int offset, DateTime base) {
    final start = _rangeStart(period, offset, base);
    switch (period) {
      case '周':
        return '${start.month}/${start.day}';
      case '季':
        return 'Q${((start.month - 1) ~/ 3) + 1}';
      case '年':
        return '${start.year}';
      default:
        return '${start.month}月';
    }
  }
}

extension _Sorted<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final copy = List<T>.from(this);
    copy.sort(compare);
    return copy;
  }
}
